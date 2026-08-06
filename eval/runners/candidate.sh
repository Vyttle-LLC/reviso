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

# Clean context: project/local settings only — no user-level CLAUDE.md,
# memory, or plugins. The candidate is this plugin, not this machine.
(cd "$WD" && claude --plugin-dir "$PLUGIN_DIR" \
    -p "/reviso:review --base $BASE_SHA" --output-format json \
    --setting-sources project,local \
    ${CANDIDATE_CLAUDE_FLAGS:-}) > "$OUT/candidate-raw.json"
jq -r '.result' "$OUT/candidate-raw.json" > "$OUT/candidate-report.md"
sh "$HERE/extract.sh" "$OUT/candidate-report.md" > "$OUT/candidate.json"

# Report-only invariant check: the eval clone must be untouched by the run.
if [ -n "$(git -C "$WD" status --porcelain)" ]; then
  echo "candidate.sh: REPORT-ONLY VIOLATION — review run left the tree dirty:" >&2
  git -C "$WD" status --porcelain >&2
  exit 1
fi

# D11: record resolved model IDs — comparisons are only valid between runs
# whose resolved model pairs match.
jq '{cost: .total_cost_usd, duration_ms: .duration_ms, num_turns: .num_turns, models: (.modelUsage // {} | keys)}' \
  "$OUT/candidate-raw.json" > "$OUT/candidate-cost.json"

# Identity metadata (design D4): judge.sh refuses baseline/candidate
# comparisons across differing CLI versions — the built-in review the
# baseline measures changes with the CLI.
jq -n --arg v "$(claude --version 2>/dev/null | awk '{print $1}')" \
  --slurpfile r "$OUT/candidate-raw.json" \
  '{cli_version: $v, models: ($r[0].modelUsage // {} | keys)}' > "$OUT/meta.json"

echo "candidate: $(jq 'length' "$OUT/candidate.json") findings, cost \$$(jq -r '.cost' "$OUT/candidate-cost.json") → $OUT/candidate.json" >&2
