#!/bin/sh
# extract.sh <review-text-file> — parse a review's output into a findings
# JSON array on stdout. LOUD on failure: a review that mentions issues but
# yields no parseable findings is an error, never an empty baseline.
#
# Fast path first: headless, the built-in /code-review's output contract is
# a JSON findings array (file/line/summary/failure_scenario, plus category
# and verdict when a verify pass ran). Parse it directly when present —
# cheaper, deterministic, and it preserves `category` for the judge's tier
# bucketing (design D2/D3). Prose extraction via a model is the fallback.
set -eu
F="${1:?usage: extract.sh <review-text-file>}"

# Normalize a direct-parsed array to the harness finding schema.
NORMALIZE='map({
  file: (.file // null),
  line: (.line // 0),
  title: (.summary // .title // ""),
  severity: (.verdict // .severity // null),
  category: (.category // null),
  description: (.failure_scenario // .description // "")
})'

is_findings_array() {
  printf '%s\n' "$1" | jq -e '
    type == "array" and
    all(.[]; type == "object" and has("file") and (has("summary") or has("title")))
  ' >/dev/null 2>&1
}

# Candidate 1: the whole file is the JSON array.
WHOLE=$(cat "$F")
if is_findings_array "$WHOLE"; then
  printf '%s\n' "$WHOLE" | jq "$NORMALIZE"
  exit 0
fi

# Candidate 2: a fenced ```json block containing the array.
FENCED=$(awk '/^```json[[:space:]]*$/{inb=1; next} /^```[[:space:]]*$/{if(inb) exit} inb' "$F")
if [ -n "$FENCED" ] && is_findings_array "$FENCED"; then
  printf '%s\n' "$FENCED" | jq "$NORMALIZE"
  exit 0
fi

PROMPT="Below is the raw output of a code review tool. Extract every distinct finding it reports.
Return ONLY a JSON array (no prose, no code fences). Each element:
{\"file\": \"path or null\", \"line\": 0, \"title\": \"one line\", \"severity\": \"as stated or null\", \"category\": \"the finding's stated category/kind (e.g. correctness, efficiency, cleanup) or null\", \"description\": \"the finding, condensed\"}
Rules: one element per distinct issue; do not invent findings; never guess a category the review didn't state; if the review explicitly reports no issues, return [].
Review output follows:
----
$WHOLE"

# Pinned to haiku: extraction is mechanical parsing; cheap and reproducible.
RES=$(claude -p "$PROMPT" --model "${EXTRACT_MODEL:-haiku}" --output-format json --setting-sources project,local ${EXTRACT_CLAUDE_FLAGS:-} | jq -r '.result')
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

printf '%s\n' "$CLEAN" | jq 'map(.category //= null)'
