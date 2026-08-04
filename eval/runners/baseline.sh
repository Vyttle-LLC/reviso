#!/bin/sh
# baseline.sh <workdir> <pr> <outdir> — capture the /review baseline for a
# corpus PR: 3 headless runs, majority = findings matched in ≥2 of 3.
# <workdir> is a throwaway clone of the corpus repo (gh-authenticated).
# Env: REVIEW_CMD (default "/review"), BASELINE_CLAUDE_FLAGS.
#
# Clean context: runs load project/local settings only (no user-level
# CLAUDE.md, memory, or plugins), so the baseline is stock /review — not
# /review shaped by whoever's personal config — and results reproduce
# across machines.
set -eu
WD="${1:?usage: baseline.sh <workdir> <pr> <outdir>}"
PR="${2:?usage: baseline.sh <workdir> <pr> <outdir>}"
OUT="${3:?usage: baseline.sh <workdir> <pr> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
REVIEW_CMD="${REVIEW_CMD:-/review}"
mkdir -p "$OUT"

for i in 1 2 3; do
  # Block PR mutation so the run prints instead of commenting.
  # Model pinned for reproducibility: the baseline is /review as a typical
  # subscriber runs it, not /review on whatever this machine's default is.
  (cd "$WD" && claude -p "$REVIEW_CMD $PR" --output-format json \
      --model "${BASELINE_MODEL:-opus}" \
      --setting-sources project,local \
      --disallowedTools "Bash(gh pr comment:*)" \
      ${BASELINE_CLAUDE_FLAGS:-}) > "$OUT/baseline-raw-$i.json"
  jq -r '.result' "$OUT/baseline-raw-$i.json" > "$OUT/baseline-text-$i.md"
  sh "$HERE/extract.sh" "$OUT/baseline-text-$i.md" > "$OUT/baseline-findings-$i.json"
done

# Pairwise matches for the majority rule.
sh "$HERE/match.sh" "$OUT/baseline-findings-1.json" "$OUT/baseline-findings-2.json" > "$OUT/match-12.json"
sh "$HERE/match.sh" "$OUT/baseline-findings-1.json" "$OUT/baseline-findings-3.json" > "$OUT/match-13.json"
sh "$HERE/match.sh" "$OUT/baseline-findings-2.json" "$OUT/baseline-findings-3.json" > "$OUT/match-23.json"

# Majority baseline: run-1 findings matched in run 2 or 3, plus run-2
# findings matched in run 3 that no run-1 finding already represents.
jq -n \
  --slurpfile f1 "$OUT/baseline-findings-1.json" \
  --slurpfile f2 "$OUT/baseline-findings-2.json" \
  --slurpfile m12 "$OUT/match-12.json" \
  --slurpfile m13 "$OUT/match-13.json" \
  --slurpfile m23 "$OUT/match-23.json" '
  ($f1[0]) as $f1 | ($f2[0]) as $f2 |
  ($m12[0] | map(.a_idx)) as $a12 |
  ($m13[0] | map(.a_idx)) as $a13 |
  ($m12[0] | map(.b_idx)) as $b12 |
  ($m23[0] | map(.a_idx)) as $a23 |
  [ $f1 | to_entries[] | select((.key as $i | $a12 | index($i)) != null
                             or (.key as $i | $a13 | index($i)) != null) | .value ]
  + [ $f2 | to_entries[] | select(((.key as $j | $a23 | index($j)) != null)
                              and ((.key as $j | $b12 | index($j)) == null)) | .value ]
' > "$OUT/baseline.json"

echo "baseline: $(jq 'length' "$OUT/baseline.json") majority findings ($(jq 'length' "$OUT/baseline-findings-1.json")/$(jq 'length' "$OUT/baseline-findings-2.json")/$(jq 'length' "$OUT/baseline-findings-3.json") per run) → $OUT/baseline.json" >&2
