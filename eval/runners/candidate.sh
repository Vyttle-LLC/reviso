#!/bin/sh
# candidate.sh <workdir> <base_sha> <head_sha> <outdir> — run /reviso:review
# on the identical range the PR covered, capture the report, extract findings.
# <workdir> is a throwaway clone (this script checks out head_sha, detached).
# Env: REVISO_PLUGIN_DIR (default: this repo root), CANDIDATE_CLAUDE_FLAGS.
set -eu
WD="${1:?usage: candidate.sh <workdir> <base_sha> <head_sha> <outdir>}"
BASE_SHA="${2:?usage: candidate.sh <workdir> <base_sha> <head_sha> <outdir>}"
HEAD_SHA="${3:?usage: candidate.sh <workdir> <base_sha> <head_sha> <outdir>}"
OUT="${4:?usage: candidate.sh <workdir> <base_sha> <head_sha> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
PLUGIN_DIR="${REVISO_PLUGIN_DIR:-$(cd "$HERE/../.." && pwd)}"
mkdir -p "$OUT"

git -C "$WD" fetch -q origin "$BASE_SHA" "$HEAD_SHA" 2>/dev/null || true
git -C "$WD" checkout -q --detach "$HEAD_SHA"

(cd "$WD" && claude --plugin-dir "$PLUGIN_DIR" \
    -p "/reviso:review --base $BASE_SHA" --output-format json \
    ${CANDIDATE_CLAUDE_FLAGS:-}) > "$OUT/candidate-raw.json"
jq -r '.result' "$OUT/candidate-raw.json" > "$OUT/candidate-report.md"
sh "$HERE/extract.sh" "$OUT/candidate-report.md" > "$OUT/candidate.json"

# Report-only invariant check: the eval clone must be untouched by the run.
if [ -n "$(git -C "$WD" status --porcelain)" ]; then
  echo "candidate.sh: REPORT-ONLY VIOLATION — review run left the tree dirty:" >&2
  git -C "$WD" status --porcelain >&2
  exit 1
fi

echo "candidate: $(jq 'length' "$OUT/candidate.json") findings → $OUT/candidate.json" >&2
