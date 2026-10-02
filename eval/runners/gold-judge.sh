#!/bin/sh
# gold-judge.sh <labels.json> <candidate.json> <outdir> — score a candidate
# against gold labels and write <outdir>/gold-judge.json.
#
# Split out of gold.sh so a RECORDED run can be re-judged without paying for
# the review again. Tiering is a calibration decision (see tiers.sh) and moves
# over time; when it does, every archived run's verdict is stale until it is
# re-derived from the same recorded output. That re-derivation must run the
# identical expression the live path runs, which is why there is one copy.
#
# An existing <outdir>/match-gc.json is REUSED rather than recomputed: the
# matcher is a model call, and a re-judge must not silently re-decide what
# matched — only how the matches are tiered.
set -eu
LABELS="${1:?usage: gold-judge.sh <labels.json> <candidate.json> <outdir>}"
CANDIDATE="${2:?usage: gold-judge.sh <labels.json> <candidate.json> <outdir>}"
OUT="${3:?usage: gold-judge.sh <labels.json> <candidate.json> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT"
. "$HERE/tiers.sh"

if ! jq -e 'all(.findings[]?; (.adjudication.status // "unreviewed") as $s |
    (["unreviewed", "real-miss", "policy-excluded", "label-wrong"] | index($s)) != null)' "$LABELS" >/dev/null; then
  echo "gold-judge.sh: unknown adjudication status" >&2
  exit 1
fi

# Expected-clean short-circuits: any candidate finding is a false positive,
# no matcher call needed (gold-eval spec).
if [ "$(jq -r '.expected_clean // false' "$LABELS")" = "true" ]; then
  jq -n --slurpfile c "$CANDIDATE" '{
    mode: "gold", expected_clean: true,
    clean_case_fp_count: ($c[0] | length),
    false_positives: $c[0]
  }' > "$OUT/gold-judge.json"
  exit 0
fi

jq '.findings' "$LABELS" > "$OUT/gold-labels.json"
if [ -f "$OUT/match-gc.json" ]; then
  echo "gold-judge.sh: reusing recorded match-gc.json (re-judge)" >&2
else
  # Keep original indices so archived matches remain replayable. New model
  # calls see only eligible gold, then map their indices back to that array.
  jq 'to_entries | map(select(.value.policy_excluded != true and
      .value.adjudication.status != "policy-excluded" and
      .value.adjudication.status != "label-wrong"))' \
    "$OUT/gold-labels.json" > "$OUT/gold-active-entries.json"
  jq 'map(.value)' "$OUT/gold-active-entries.json" > "$OUT/gold-active-labels.json"
  sh "$HERE/match.sh" "$OUT/gold-active-labels.json" "$CANDIDATE" \
    | jq --slurpfile g "$OUT/gold-active-entries.json" \
      'map(.a_idx = $g[0][.a_idx].key)' > "$OUT/match-gc.json"
fi

jq -n --arg re "$CLEANUP_RE" \
  --slurpfile g "$OUT/gold-labels.json" \
  --slurpfile c "$CANDIDATE" \
  --slurpfile m "$OUT/match-gc.json" '
  ($g[0] | map(. + {tier: (if .policy_excluded == true or
      .adjudication.status == "policy-excluded" or .adjudication.status == "label-wrong"
      then "excluded" elif (.category // "" | test($re)) then "cleanup" else "correctness" end)})) as $g |
  ($c[0]) as $c | ($m[0]) as $recorded |
  ($recorded | map(select($g[.a_idx].tier != "excluded"))) as $m |
  ($m | map(.a_idx)) as $gm | ($m | map(.b_idx)) as $cm |
  ($g | to_entries | map(select(.value.tier == "correctness"))) as $gcorr |
  {
    mode: "gold", expected_clean: false,
    excluded_gold: [ $g[] | select(.tier == "excluded") ],
    excluded_recorded_matches: [ $recorded[] | select($g[.a_idx].tier == "excluded") ],
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
