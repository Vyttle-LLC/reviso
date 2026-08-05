#!/bin/sh
# match.sh <a.json> <b.json> — conservatively match two findings lists on
# underlying root cause. Emits [{"a_idx": i, "b_idx": j}] (0-based; a finding
# matches at most once). Used for baseline majority AND baseline-vs-candidate
# judging, so its calibration (eval/calibration/) covers both.
set -eu
A="${1:?usage: match.sh <a.json> <b.json>}"
B="${2:?usage: match.sh <a.json> <b.json>}"

if jq -e 'length == 0' "$A" >/dev/null || jq -e 'length == 0' "$B" >/dev/null; then
  echo "[]"
  exit 0
fi

PROMPT="You match code-review findings from two tools run on the SAME code change.
List A:
$(jq -c 'to_entries | map({idx: .key, f: .value})' "$A")
List B:
$(jq -c 'to_entries | map({idx: .key, f: .value})' "$B")
Two findings match ONLY if they describe the same underlying defect (same
root cause), even if worded differently or anchored to nearby-but-unequal
lines. Similar topic, same file, or same category is NOT a match. Be
conservative: when unsure, do not match. Each finding matches at most one on
the other side.
Return ONLY a JSON array (no prose, no code fences): [{\"a_idx\": 0, \"b_idx\": 0}]. Empty array if nothing matches."

# Pinned to sonnet by default: matching is judgment, but doesn't need the top
# tier. Calibration (eval/calibration/) validates whatever model is set here.
RES=$(claude -p "$PROMPT" --model "${JUDGE_MODEL:-sonnet}" --output-format json --setting-sources project,local ${MATCH_CLAUDE_FLAGS:-} | jq -r '.result')
CLEAN=$(printf '%s\n' "$RES" | sed -e 's/^```json$//' -e 's/^```$//')

LA=$(jq 'length' "$A"); LB=$(jq 'length' "$B")
if ! printf '%s\n' "$CLEAN" | jq -e --argjson la "$LA" --argjson lb "$LB" '
    type == "array"
    and all(.[]; has("a_idx") and has("b_idx")
                 and .a_idx >= 0 and .a_idx < $la
                 and .b_idx >= 0 and .b_idx < $lb)
    and (map(.a_idx) | unique | length == length)
    and (map(.b_idx) | unique | length == length)
  ' >/dev/null 2>&1; then
  echo "match.sh: model output is not a valid match array (shape, range, or duplicate index)" >&2
  printf '%s\n' "$RES" >&2
  exit 1
fi

printf '%s\n' "$CLEAN" | jq '.'
