#!/bin/sh
# extract.sh <review-text-file> — parse a review's prose into a findings
# JSON array on stdout. LOUD on failure: a review that mentions issues but
# yields no parseable findings is an error, never an empty baseline.
set -eu
F="${1:?usage: extract.sh <review-text-file>}"

PROMPT="Below is the raw output of a code review tool. Extract every distinct finding it reports.
Return ONLY a JSON array (no prose, no code fences). Each element:
{\"file\": \"path or null\", \"line\": 0, \"title\": \"one line\", \"severity\": \"as stated or null\", \"description\": \"the finding, condensed\"}
Rules: one element per distinct issue; do not invent findings; if the review explicitly reports no issues, return [].
Review output follows:
----
$(cat "$F")"

RES=$(claude -p "$PROMPT" --output-format json --setting-sources project,local ${EXTRACT_CLAUDE_FLAGS:-} | jq -r '.result')
CLEAN=$(printf '%s\n' "$RES" | sed -e 's/^```json$//' -e 's/^```$//')

if ! printf '%s\n' "$CLEAN" | jq -e 'type == "array"' >/dev/null 2>&1; then
  echo "extract.sh: model output is not a JSON array for $F" >&2
  printf '%s\n' "$RES" >&2
  exit 1
fi

# Loud-failure cross-check: review claims issues but extraction is empty.
if printf '%s\n' "$CLEAN" | jq -e 'length == 0' >/dev/null 2>&1 \
   && grep -qiE 'found [1-9][0-9]* issue' "$F"; then
  echo "extract.sh: review text claims issues but extraction is empty for $F" >&2
  exit 1
fi

printf '%s\n' "$CLEAN" | jq '.'
