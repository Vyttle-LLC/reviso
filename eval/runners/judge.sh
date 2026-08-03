#!/bin/sh
# judge.sh <baseline.json> <candidate.json> <outdir> — bucket findings as
# matched / missed / claimed_wins and compute metrics. Misses are P0
# regressions and are listed individually, never only as a percentage.
# Claimed wins are suspects until verified real (see eval/README.md).
set -eu
BASELINE="${1:?usage: judge.sh <baseline.json> <candidate.json> <outdir>}"
CANDIDATE="${2:?usage: judge.sh <baseline.json> <candidate.json> <outdir>}"
OUT="${3:?usage: judge.sh <baseline.json> <candidate.json> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT"

sh "$HERE/match.sh" "$BASELINE" "$CANDIDATE" > "$OUT/match-bc.json"

jq -n \
  --slurpfile b "$BASELINE" \
  --slurpfile c "$CANDIDATE" \
  --slurpfile m "$OUT/match-bc.json" '
  ($b[0]) as $b | ($c[0]) as $c | ($m[0]) as $m |
  ($m | map(.a_idx)) as $bm | ($m | map(.b_idx)) as $cm |
  {
    matched: [ $m[] | {baseline: $b[.a_idx], candidate: $c[.b_idx]} ],
    missed_P0_regressions: [ $b | to_entries[] | select((.key as $i | $bm | index($i)) == null) | .value ],
    claimed_wins_unverified: [ $c | to_entries[] | select((.key as $j | $cm | index($j)) == null) | .value ],
    metrics: {
      baseline_count: ($b | length),
      candidate_count: ($c | length),
      matched_count: ($m | length),
      parity_pct: (if ($b | length) > 0 then (($m | length) / ($b | length) * 100 | floor) else null end)
    }
  }
' > "$OUT/judge.json"

jq -r '"parity: \(.metrics.parity_pct // "n/a (empty baseline)")%  matched: \(.metrics.matched_count)/\(.metrics.baseline_count)  misses(P0): \(.missed_P0_regressions | length)  claimed wins (unverified): \(.claimed_wins_unverified | length)"' "$OUT/judge.json" >&2
if jq -e '.missed_P0_regressions | length > 0' "$OUT/judge.json" >/dev/null; then
  echo "MISSES (each is a P0 regression):" >&2
  jq -r '.missed_P0_regressions[] | "  - \(.title) (\(.file // "?"):\(.line // 0))"' "$OUT/judge.json" >&2
fi
