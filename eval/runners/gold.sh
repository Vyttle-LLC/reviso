#!/bin/sh
# gold.sh <case-id> <outdir> — run the candidate against a gold-labeled
# corpus case and judge its findings against the labels. No upstream
# review is invoked at any point (gold-eval spec): the only model costs
# are the candidate run and the matcher.
#
# Real cases: blobless clone into the cache (eval/.cache/clones/), fetch
# the pinned SHAs, throwaway worktree, candidate leg via candidate.sh.
# Synthetic cases: materialize the fixture into a throwaway git repo (all
# files are full-content "added" patches) as uncommitted changes on an
# empty base commit, then review that.
#
# Env: CORPUS_FILE (default eval/corpus/public.jsonl), plus everything
# candidate.sh honors.
set -eu
CASE="${1:?usage: gold.sh <case-id> <outdir>}"
OUT="${2:?usage: gold.sh <case-id> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
CORPUS_DIR=$(cd "$HERE/../corpus" && pwd)
CORPUS_FILE="${CORPUS_FILE:-$CORPUS_DIR/public.jsonl}"
CACHE="$(cd "$HERE/.." && pwd)/.cache/clones"
mkdir -p "$OUT" "$CACHE"

ENTRY=$(jq -c --arg id "$CASE" 'select(.id == $id)' "$CORPUS_FILE")
[ -n "$ENTRY" ] || { echo "gold.sh: case '$CASE' not in $CORPUS_FILE" >&2; exit 1; }
LABELS="$CORPUS_DIR/$(printf '%s' "$ENTRY" | jq -r '.labels')"
[ -f "$LABELS" ] || { echo "gold.sh: labels file missing: $LABELS" >&2; exit 1; }

WD=$(mktemp -d "${TMPDIR:-/tmp}/reviso-gold-$CASE.XXXXXX")
RWD="$WD"      # where the review actually runs (worktree for real cases)
CDIR=""
cleanup() {
  if [ -n "$CDIR" ] && [ -d "$RWD" ]; then
    git -C "$CDIR" worktree remove --force "$RWD" 2>/dev/null || true
  fi
  rm -rf "$WD"
}
trap cleanup EXIT

if [ "$(printf '%s' "$ENTRY" | jq -r '.synthetic // false')" = "true" ]; then
  # Materialize (design D6): empty base commit, fixture files as
  # uncommitted additions — the working diff equals the fixture's diff.
  FIXTURE="$CORPUS_DIR/$(printf '%s' "$ENTRY" | jq -r '.fixture')"
  git -C "$WD" init -q
  git -C "$WD" -c user.email=eval@reviso -c user.name=reviso-eval \
    commit -q --allow-empty -m "base"
  n=$(jq '.files | length' "$FIXTURE")
  i=0
  while [ "$i" -lt "$n" ]; do
    fn=$(jq -r ".files[$i].filename" "$FIXTURE")
    mkdir -p "$WD/$(dirname "$fn")"
    # Full-content "added" patch: body = every +line minus the prefix.
    jq -r ".files[$i].patch" "$FIXTURE" \
      | sed -n 's/^+//p' > "$WD/$fn"
    i=$((i + 1))
  done
  BASE=$(git -C "$WD" rev-parse HEAD)
  HEAD_SHA=$BASE   # review scope = uncommitted changes on the base
else
  REPO=$(printf '%s' "$ENTRY" | jq -r '.repo')
  CLONE_URL=$(printf '%s' "$ENTRY" | jq -r '.clone_url')
  BASE=$(printf '%s' "$ENTRY" | jq -r '.base_sha')
  HEAD_SHA=$(printf '%s' "$ENTRY" | jq -r '.head_sha')
  CDIR="$CACHE/$(printf '%s' "$REPO" | tr '/' '__')"
  if [ ! -d "$CDIR" ]; then
    git clone -q --filter=blob:none "$CLONE_URL" "$CDIR"
  fi
  git -C "$CDIR" fetch -q origin "$BASE" "$HEAD_SHA"
  # A worktree (not a shared clone) so the cache's promisor config still
  # serves lazy blob fetches for the blobless clone during checkout.
  RWD="$WD/repo"
  git -C "$CDIR" worktree add -q --detach "$RWD" "$HEAD_SHA"
fi

sh "$HERE/candidate.sh" "$RWD" "$BASE" "$HEAD_SHA" "$OUT"

# Judge against the labels. Expected-clean short-circuits: any candidate
# finding is a false positive, no matcher call needed (gold-eval spec).
CLEANUP_RE='^(simplification|efficiency|reuse|altitude|conventions|test-coverage|duplication|observability|deploy-safety)$'
if [ "$(jq -r '.expected_clean // false' "$LABELS")" = "true" ]; then
  jq -n --slurpfile c "$OUT/candidate.json" '{
    mode: "gold", expected_clean: true,
    clean_case_fp_count: ($c[0] | length),
    false_positives: $c[0]
  }' > "$OUT/gold-judge.json"
else
  jq '.findings' "$LABELS" > "$OUT/gold-labels.json"
  sh "$HERE/match.sh" "$OUT/gold-labels.json" "$OUT/candidate.json" > "$OUT/match-gc.json"
  jq -n --arg re "$CLEANUP_RE" \
    --slurpfile g "$OUT/gold-labels.json" \
    --slurpfile c "$OUT/candidate.json" \
    --slurpfile m "$OUT/match-gc.json" '
    ($g[0] | map(. + {tier: (if (.category // "" | test($re)) then "cleanup" else "correctness" end)})) as $g |
    ($c[0]) as $c | ($m[0]) as $m |
    ($m | map(.a_idx)) as $gm | ($m | map(.b_idx)) as $cm |
    ($g | to_entries | map(select(.value.tier == "correctness"))) as $gcorr |
    {
      mode: "gold", expected_clean: false,
      matched: [ $m[] | {gold: $g[.a_idx], candidate: $c[.b_idx]} ],
      missed_correctness_gold: [ $g | to_entries[]
        | select(.value.tier == "correctness" and ((.key as $i | $gm | index($i)) == null)) | .value ],
      missed_cleanup_gold_informational: [ $g | to_entries[]
        | select(.value.tier == "cleanup" and ((.key as $i | $gm | index($i)) == null)) | .value ],
      promotion_candidates: [ $c | to_entries[] | select((.key as $j | $cm | index($j)) == null) | .value ],
      metrics: {
        gold_count: ($g | length),
        gold_correctness_count: ($gcorr | length),
        candidate_count: ($c | length),
        matched_count: ($m | length),
        matched_correctness_count: ([ $m[] | select($g[.a_idx].tier == "correctness") ] | length),
        gold_recall_correctness: (if ($gcorr | length) > 0
          then (([ $m[] | select($g[.a_idx].tier == "correctness") ] | length) / ($gcorr | length) * 100 | floor)
          else null end),
        precision_proxy_pct: (if ($c | length) > 0
          then (($m | length) / ($c | length) * 100 | floor)
          else null end)
      }
    }
  ' > "$OUT/gold-judge.json"
fi

jq -r 'if .expected_clean then
    "gold(clean): \(.clean_case_fp_count) false positive(s)"
  else
    "gold recall (correctness): \(.metrics.gold_recall_correctness // "n/a")%  (\(.metrics.matched_correctness_count)/\(.metrics.gold_correctness_count))  precision proxy: \(.metrics.precision_proxy_pct // "n/a")%  promotion candidates: \(.promotion_candidates | length)"
  end' "$OUT/gold-judge.json" >&2
