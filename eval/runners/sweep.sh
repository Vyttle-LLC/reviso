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
# Env: CORPUS_FILE (default eval/corpus/public.jsonl) plus everything the
# per-case runners honor.
set -eu
MODE="${1:?usage: sweep.sh <gold|parity> <outroot> [case-id]}"
OUTROOT="${2:?usage: sweep.sh <gold|parity> <outroot> [case-id]}"
ONLY="${3:-}"
HERE=$(cd "$(dirname "$0")" && pwd)
CORPUS_DIR=$(cd "$HERE/../corpus" && pwd)
CORPUS_FILE="${CORPUS_FILE:-$CORPUS_DIR/public.jsonl}"
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
    echo "sweep: gold $id" >&2
    # </dev/null: claude/model calls inside the loop must not eat the
    # corpus lines feeding this while-read (one case ran, 62 vanished).
    if ! sh "$HERE/gold.sh" "$id" "$OUTROOT/$id" < /dev/null; then
      echo "sweep: $id FAILED" >&2
      : > "$OUTROOT/$id.FAILED"
    fi
  done
  # Aggregate whatever completed. Failures are listed, never absorbed.
  jq -s '{
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
      | if $c > 0 then (([ .[] | .metrics.matched_count // 0 ] | add) / $c * 100 | floor) else null end)
  }' "$OUTROOT"/*/gold-judge.json > "$OUTROOT/summary.json" 2>/dev/null || echo "sweep: no completed cases to aggregate" >&2
  ls "$OUTROOT"/*.FAILED >/dev/null 2>&1 && { echo "sweep: some cases FAILED (see *.FAILED)" >&2; fail=1; }
  [ -f "$OUTROOT/summary.json" ] && jq -r '"gold sweep: \(.cases) cases  recall(correctness): \(.aggregate_recall_correctness_pct // "n/a")%  precision proxy: \(.aggregate_precision_proxy_pct // "n/a")%  clean-case FPs: \(.clean_case_fp_total)"' "$OUTROOT/summary.json" >&2
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
    echo "sweep: parity $id ($repo#$pr)" >&2
    out="$OUTROOT/$id"; mkdir -p "$out"
    wt=$(worktree_at "$repo" "$url" "$head" "$base")
    ( sh "$HERE/baseline.sh" "$wt" "$pr" "$out/baseline" \
      && sh "$HERE/candidate.sh" "$wt" "$base" "$head" "$out/candidate" \
      && sh "$HERE/judge.sh" "$out/baseline/baseline.json" "$out/candidate/candidate.json" "$out" ) < /dev/null \
      || { echo "sweep: $id FAILED" >&2; : > "$OUTROOT/$id.FAILED"; }
    drop_worktree "$repo" "$wt"
  done
  ls "$OUTROOT"/*.FAILED >/dev/null 2>&1 && fail=1
  ;;
*) echo "sweep.sh: unknown mode '$MODE'" >&2; exit 2 ;;
esac
exit $fail
