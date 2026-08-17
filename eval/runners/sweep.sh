#!/bin/sh
# sweep.sh <gold|parity> <outroot> [case-id] — run a corpus sweep.
#
# gold: every gold-labeled entry (all of them unless [case-id] narrows it)
#   through gold.sh; aggregate metrics land in <outroot>/summary.json.
#   Cases without labels (e.g. pre-import parity-only entries) are skipped
#   with a note — never silently.
# parity: entries marked active_parity through the full baseline +
#   candidate + judge pipeline. Synthetic cases are REFUSED, not skipped
#   quietly — they are gold-mode-only by spec.
#
# Env: REVISO_TIER (required: review|audit — which product this sweep
# measures), REVISO_SWEEP_SUBSET (optional name for a deliberate partial
# sweep, e.g. "audit-smoke"; recorded in summary.json), CORPUS_FILE
# (default eval/corpus/public.jsonl) plus everything the per-case runners
# honor. To sweep the private tier:
#   CORPUS_FILE="$REVISO_EVAL_PRIVATE_CORPUS" sh sweep.sh gold eval/runs/private/<name>
# Entry-relative paths (labels, fixture) resolve against the corpus file's own
# directory, so a private corpus carries its labels beside it. Keep private
# output under eval/runs/private/ — that path is gitignored.
#
# Audit-tier sweeps cost roughly 3x a review-tier sweep per case, so they
# run on a named subset while full-corpus sweeps stay on the review tier.
# summary.json records which subset actually ran, so a partial sweep can
# never be read as a full one.
set -eu
MODE="${1:?usage: sweep.sh <gold|parity> <outroot> [case-id]}"
OUTROOT="${2:?usage: sweep.sh <gold|parity> <outroot> [case-id]}"
ONLY="${3:-}"
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/review-tier.sh"
resolve_review_tier
CORPUS_DIR=$(cd "$HERE/../corpus" && pwd)
CORPUS_FILE="${CORPUS_FILE:-$CORPUS_DIR/public.jsonl}"
[ -f "$CORPUS_FILE" ] || { echo "sweep.sh: corpus file not found: $CORPUS_FILE" >&2; exit 1; }
# Export so the per-case runners read the SAME corpus this loop iterates.
# Without it a caller's non-exported CORPUS_FILE would have sweep walking the
# private corpus while gold.sh resolved ids against the public one — every
# case failing with "not in <file>" for no visible reason.
export CORPUS_FILE
CACHE="$(cd "$HERE/.." && pwd)/.cache/clones"
mkdir -p "$OUTROOT" "$CACHE"

worktree_at() { # <repo> <clone_url> <sha...> — prints worktree path
  _repo="$1"; _url="$2"; shift 2
  _cdir="$CACHE/$(printf '%s' "$_repo" | tr '/' '__')"
  [ -d "$_cdir" ] || git clone -q --filter=blob:none "$_url" "$_cdir" >&2
  git -C "$_cdir" fetch -q origin "$@" >&2
  _wt=$(mktemp -d "${TMPDIR:-/tmp}/reviso-sweep.XXXXXX")/repo
  git -C "$_cdir" worktree add -q --detach "$_wt" "$1" >&2
  printf '%s\n' "$_wt"
}
drop_worktree() { # <repo> <worktree>
  git -C "$CACHE/$(printf '%s' "$1" | tr '/' '__')" worktree remove --force "$2" 2>/dev/null || true
  rm -rf "$(dirname "$2")"
}

fail=0
case "$MODE" in
gold)
  jq -c '.' "$CORPUS_FILE" | while IFS= read -r entry; do
    id=$(printf '%s' "$entry" | jq -r '.id')
    [ -n "$ONLY" ] && [ "$id" != "$ONLY" ] && continue
    if [ "$(printf '%s' "$entry" | jq -r '.labels // ""')" = "" ]; then
      echo "sweep: $id has no labels file — skipped (parity-only entry)" >&2
      continue
    fi
    if [ -f "$OUTROOT/$id/gold-judge.json" ]; then
      echo "sweep: $id already judged — skipped (resume)" >&2
      continue
    fi
    echo "sweep: gold[$REVIEW_TIER] $id" >&2
    # </dev/null: claude/model calls inside the loop must not eat the
    # corpus lines feeding this while-read (one case ran, 62 vanished).
    # Tier named at the call site, never inherited silently.
    if ! REVISO_TIER="$REVIEW_TIER" sh "$HERE/gold.sh" "$id" "$OUTROOT/$id" < /dev/null; then
      echo "sweep: $id FAILED" >&2
      : > "$OUTROOT/$id.FAILED"
    fi
  done

  # Aggregate whatever completed. Failures are listed, never absorbed, and
  # metrics are KEYED BY REVIEW TIER: /reviso:review and /reviso:audit are
  # different pipelines at different costs, so one pooled recall figure
  # would describe neither. Each judged case is annotated from the tier its
  # own meta.json recorded — not from this run's REVISO_TIER — so a resumed
  # tree that mixes tiers reports each separately, and a case recorded
  # before the tier field existed lands in a visible "unrecorded" bucket
  # instead of being absorbed into one of the real ones.
  ANNOTATED="$OUTROOT/.summary-input.jsonl"
  : > "$ANNOTATED"
  for judged in "$OUTROOT"/*/gold-judge.json; do
    [ -f "$judged" ] || continue
    cdir=$(dirname "$judged")
    ctier=$(jq -r '.tier // "unrecorded"' "$cdir/meta.json" 2>/dev/null) || ctier="unrecorded"
    [ -n "$ctier" ] || ctier="unrecorded"
    jq -c --arg t "$ctier" --arg id "$(basename "$cdir")" \
      '. + {tier: $t, case_id: $id}' "$judged" >> "$ANNOTATED"
  done

  if [ -s "$ANNOTATED" ]; then
    # Denominator for "did this sweep cover the corpus?" — labeled entries
    # are the only ones gold mode can run at all.
    LABELED=$(jq -s '[ .[] | select((.labels // "") != "") ] | length' "$CORPUS_FILE")
    jq -s --arg corpus "$CORPUS_FILE" --arg subset "${REVISO_SWEEP_SUBSET:-}" \
      --argjson labeled "$LABELED" '
      def agg: {
        cases: length,
        clean_cases: [ .[] | select(.expected_clean) ] | length,
        clean_case_fp_total: ([ .[] | select(.expected_clean) | .clean_case_fp_count ] | add // 0),
        gold_correctness_total: ([ .[] | select(.expected_clean | not) | .metrics.gold_correctness_count ] | add // 0),
        matched_correctness_total: ([ .[] | select(.expected_clean | not) | .metrics.matched_correctness_count ] | add // 0),
        aggregate_recall_correctness_pct: (
          ([ .[] | select(.expected_clean | not) | .metrics.gold_correctness_count ] | add // 0) as $g
          | if $g > 0 then (([ .[] | select(.expected_clean | not) | .metrics.matched_correctness_count ] | add) / $g * 100 | floor) else null end),
        candidate_total: ([ .[] | .metrics.candidate_count // .clean_case_fp_count ] | add // 0),
        matched_total: ([ .[] | .metrics.matched_count // 0 ] | add),
        aggregate_precision_proxy_pct: (
          ([ .[] | .metrics.candidate_count // .clean_case_fp_count ] | add // 0) as $c
          | if $c > 0 then (([ .[] | .metrics.matched_count // 0 ] | add) / $c * 100 | floor) else null end),
        case_ids: ([ .[] | .case_id ] | sort)
      };
      {
        corpus_file: $corpus,
        subset: {
          name: (if $subset == "" then null else $subset end),
          cases_judged: length,
          corpus_labeled_cases: $labeled,
          covers_full_corpus: (length >= $labeled),
          case_ids: ([ .[] | .case_id ] | sort)
        },
        by_tier: (group_by(.tier) | map({key: .[0].tier, value: agg}) | from_entries)
      }' "$ANNOTATED" > "$OUTROOT/summary.json"
    rm -f "$ANNOTATED"
  else
    rm -f "$ANNOTATED"
    echo "sweep: no completed cases to aggregate" >&2
  fi

  ls "$OUTROOT"/*.FAILED >/dev/null 2>&1 && { echo "sweep: some cases FAILED (see *.FAILED)" >&2; fail=1; }
  [ -f "$OUTROOT/summary.json" ] && jq -r '
    "gold sweep: \(.subset.cases_judged)/\(.subset.corpus_labeled_cases) labeled cases" +
      (if .subset.covers_full_corpus then " (full corpus)"
       else " (PARTIAL subset\(if .subset.name then ": " + .subset.name else "" end))" end),
    (.by_tier | to_entries[] |
      "  [\(.key)] \(.value.cases) cases  recall(correctness): \(.value.aggregate_recall_correctness_pct // "n/a")%  precision proxy: \(.value.aggregate_precision_proxy_pct // "n/a")%  clean-case FPs: \(.value.clean_case_fp_total)")
  ' "$OUTROOT/summary.json" >&2
  ;;
parity)
  jq -c 'select(.active_parity == true)' "$CORPUS_FILE" | while IFS= read -r entry; do
    id=$(printf '%s' "$entry" | jq -r '.id')
    [ -n "$ONLY" ] && [ "$id" != "$ONLY" ] && continue
    if [ "$(printf '%s' "$entry" | jq -r '.synthetic // false')" = "true" ]; then
      echo "sweep: REFUSED $id — synthetic cases are gold-mode-only; parity needs a real PR" >&2
      exit 1
    fi
    repo=$(printf '%s' "$entry" | jq -r '.repo')
    url=$(printf '%s' "$entry" | jq -r '.clone_url')
    pr=$(printf '%s' "$entry" | jq -r '.pr')
    base=$(printf '%s' "$entry" | jq -r '.base_sha')
    head=$(printf '%s' "$entry" | jq -r '.head_sha')
    echo "sweep: parity[$REVIEW_TIER] $id ($repo#$pr)" >&2
    out="$OUTROOT/$id"; mkdir -p "$out"
    wt=$(worktree_at "$repo" "$url" "$head" "$base")
    ( sh "$HERE/baseline.sh" "$wt" "$pr" "$out/baseline" \
      && REVISO_TIER="$REVIEW_TIER" sh "$HERE/candidate.sh" "$wt" "$base" "$head" "$out/candidate" \
      && sh "$HERE/judge.sh" "$out/baseline/baseline.json" "$out/candidate/candidate.json" "$out" ) < /dev/null \
      || { echo "sweep: $id FAILED" >&2; : > "$OUTROOT/$id.FAILED"; }
    drop_worktree "$repo" "$wt"
  done
  ls "$OUTROOT"/*.FAILED >/dev/null 2>&1 && fail=1
  ;;
*) echo "sweep.sh: unknown mode '$MODE'" >&2; exit 2 ;;
esac
exit $fail
