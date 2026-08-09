#!/bin/sh
# judge.sh <baseline.json> <candidate.json> <outdir> — bucket findings as
# matched / missed / claimed_wins and compute metrics. Parity and P0 misses
# are scoped to the CORRECTNESS TIER of the baseline (design D3): cleanup-tier
# baseline findings Reviso deliberately gates are reported informationally,
# never as regressions. Misses in scope are P0 and listed individually,
# never only as a percentage. Claimed wins are suspects until verified real
# (see eval/README.md).
set -eu
BASELINE="${1:?usage: judge.sh <baseline.json> <candidate.json> <outdir>}"
CANDIDATE="${2:?usage: judge.sh <baseline.json> <candidate.json> <outdir>}"
OUT="${3:?usage: judge.sh <baseline.json> <candidate.json> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT"

# Comparability gate (design D4): when both sides recorded identity metadata,
# their CLI versions must match — the built-in review changes with the CLI,
# so cross-version parity numbers are meaningless. Set
# JUDGE_ALLOW_VERSION_MISMATCH=1 to proceed anyway; the report is then
# labeled non_comparable rather than silently trusted.
BMETA="$(dirname "$BASELINE")/meta.json"
CMETA="$(dirname "$CANDIDATE")/meta.json"
NON_COMPARABLE=false
if [ -f "$BMETA" ] && [ -f "$CMETA" ]; then
  BV=$(jq -r '.cli_version // ""' "$BMETA")
  CV=$(jq -r '.cli_version // ""' "$CMETA")
  if [ -n "$BV" ] && [ -n "$CV" ] && [ "$BV" != "$CV" ]; then
    if [ "${JUDGE_ALLOW_VERSION_MISMATCH:-}" = "1" ]; then
      NON_COMPARABLE=true
      echo "judge.sh: WARNING — CLI versions differ (baseline $BV vs candidate $CV); report labeled non_comparable" >&2
    else
      echo "judge.sh: refusing comparison — CLI versions differ (baseline $BV vs candidate $CV). Re-baseline on the current CLI, or set JUDGE_ALLOW_VERSION_MISMATCH=1 to label the result non-comparable." >&2
      exit 1
    fi
  fi
fi

# Tier the baseline findings (D3). Out-of-lane (cleanup-family) categories are
# informational; everything else — including unknown slugs — is correctness
# tier, because ambiguity must fail toward P0 scope, never hide a miss.
# The list itself lives in tiers.sh so parity and gold cannot disagree.
. "$HERE/tiers.sh"
jq --arg re "$CLEANUP_RE" 'map(. + {tier: (if (.category // "" | test($re)) then "cleanup" else "correctness" end)})' \
  "$BASELINE" > "$OUT/baseline-tiered.json"

# Findings with no category get classified by a model; a failed or invalid
# classification defaults to correctness — the loud direction (inflates P0
# scope; can make us look worse, never better).
UNCAT=$(jq '[to_entries[] | select(.value.category == null) | {idx: .key, title: .value.title, description: .value.description}]' "$OUT/baseline-tiered.json")
if [ "$(printf '%s' "$UNCAT" | jq 'length')" -gt 0 ]; then
  PROMPT="Classify each code-review finding below as \"correctness\" (a runtime bug, broken behavior, data loss, security or robustness defect — and also copy-paste/duplication findings, which Reviso ships) or \"cleanup\" (simplification, reuse, efficiency, conventions/style, test coverage, maintainability). When genuinely ambiguous, choose \"correctness\".
Findings:
$UNCAT
Return ONLY a JSON array (no prose, no code fences): [{\"idx\": 0, \"tier\": \"correctness\"}]. One element per finding, same idx values."
  RES=$(claude -p "$PROMPT" --model "${JUDGE_MODEL:-sonnet}" --output-format json --setting-sources project,local ${MATCH_CLAUDE_FLAGS:-} | jq -r '.result') || RES=""
  CLEAN=$(printf '%s\n' "$RES" | sed -e 's/^```json$//' -e 's/^```$//')
  # idx must be a valid index into the tiered array (mirrors match.sh):
  # an out-of-range idx would null-pad the array via `.[idx].tier = ...`,
  # silently corrupting baseline counts and the miss buckets.
  N=$(jq 'length' "$OUT/baseline-tiered.json")
  if printf '%s\n' "$CLEAN" | jq -e --argjson n "$N" 'type == "array" and all(.[]; has("idx") and (.idx | type == "number") and .idx >= 0 and .idx < $n and (.tier == "correctness" or .tier == "cleanup"))' >/dev/null 2>&1; then
    jq --argjson cls "$(printf '%s\n' "$CLEAN")" '
      reduce $cls[] as $c (.; if .[$c.idx].category == null then .[$c.idx].tier = $c.tier else . end)
    ' "$OUT/baseline-tiered.json" > "$OUT/baseline-tiered.tmp" && mv "$OUT/baseline-tiered.tmp" "$OUT/baseline-tiered.json"
  else
    echo "judge.sh: WARNING — tier classification unparseable; uncategorized findings stay correctness-tier (fail-loud default)" >&2
  fi
fi

sh "$HERE/match.sh" "$BASELINE" "$CANDIDATE" > "$OUT/match-bc.json"

jq -n \
  --slurpfile b "$OUT/baseline-tiered.json" \
  --slurpfile c "$CANDIDATE" \
  --slurpfile m "$OUT/match-bc.json" \
  --argjson nc "$NON_COMPARABLE" '
  ($b[0]) as $b | ($c[0]) as $c | ($m[0]) as $m |
  ($m | map(.a_idx)) as $bm | ($m | map(.b_idx)) as $cm |
  ($b | to_entries | map(select(.value.tier == "correctness"))) as $bcorr |
  {
    non_comparable: $nc,
    matched: [ $m[] | {baseline: $b[.a_idx], candidate: $c[.b_idx]} ],
    missed_P0_regressions: [ $b | to_entries[]
      | select(.value.tier == "correctness" and ((.key as $i | $bm | index($i)) == null))
      | .value ],
    missed_informational_cleanup: [ $b | to_entries[]
      | select(.value.tier == "cleanup" and ((.key as $i | $bm | index($i)) == null))
      | .value ],
    claimed_wins_unverified: [ $c | to_entries[] | select((.key as $j | $cm | index($j)) == null) | .value ],
    metrics: {
      baseline_count: ($b | length),
      baseline_correctness_count: ($bcorr | length),
      baseline_cleanup_count: (($b | length) - ($bcorr | length)),
      candidate_count: ($c | length),
      matched_count: ($m | length),
      matched_correctness_count: ([ $m[] | select($b[.a_idx].tier == "correctness") ] | length),
      parity_pct: (if ($bcorr | length) > 0
        then (([ $m[] | select($b[.a_idx].tier == "correctness") ] | length) / ($bcorr | length) * 100 | floor)
        else null end)
    }
  }
' > "$OUT/judge.json"

# Fold in cost when the runners recorded it (files live beside the findings).
BC="$(dirname "$BASELINE")/baseline-cost.json"
CC="$(dirname "$CANDIDATE")/candidate-cost.json"
if [ -f "$BC" ] && [ -f "$CC" ]; then
  jq '.metrics += {
      baseline_mean_cost_usd: $bc.mean,
      candidate_cost_usd: $cc.cost,
      cost_ratio: (if $bc.mean > 0 then (($cc.cost / $bc.mean * 100 | floor) / 100) else null end)
    }' --argjson bc "$(cat "$BC")" --argjson cc "$(cat "$CC")" \
    "$OUT/judge.json" > "$OUT/judge.tmp" && mv "$OUT/judge.tmp" "$OUT/judge.json"
fi

jq -r '"parity (correctness tier): \(.metrics.parity_pct // "n/a (no correctness-tier baseline)")%  matched: \(.metrics.matched_correctness_count)/\(.metrics.baseline_correctness_count) correctness (+\(.metrics.matched_count - .metrics.matched_correctness_count) cleanup)  misses(P0): \(.missed_P0_regressions | length)  cleanup misses (informational): \(.missed_informational_cleanup | length)  claimed wins (unverified): \(.claimed_wins_unverified | length)  cost: \(.metrics.cost_ratio // "n/a")x baseline (target <=1.5x)\(if .non_comparable then "  [NON-COMPARABLE: CLI version mismatch]" else "" end)"' "$OUT/judge.json" >&2
if jq -e '.missed_P0_regressions | length > 0' "$OUT/judge.json" >/dev/null; then
  echo "MISSES (each is a P0 regression):" >&2
  jq -r '.missed_P0_regressions[] | "  - \(.title) (\(.file // "?"):\(.line // 0))"' "$OUT/judge.json" >&2
fi
