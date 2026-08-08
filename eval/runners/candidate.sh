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

# Report-only invariant baseline. A gold-mode synthetic case arrives with
# its diff as deliberate uncommitted changes, so "tree must end clean"
# would false-positive; the invariant is "the run changed nothing", so
# snapshot state before and compare after. For dirty-by-design trees the
# porcelain list alone can't see edits to untracked files — hash them too.
PRE_STATUS=$(git -C "$WD" status --porcelain -uall)
PRE_HASH=""
if [ -n "$PRE_STATUS" ]; then
  PRE_HASH=$( (cd "$WD" && git status --porcelain -uall | cut -c4- \
    | while read -r f; do [ -f "$f" ] && shasum "$f" || :; done) )
fi

# Clean context: project/local settings only — no user-level CLAUDE.md,
# memory, or plugins. The candidate is this plugin, not this machine.
# The detector suite is pre-approved by absolute path — headless, its
# Bash call is otherwise denied and the deterministic lens silently
# drops out of the review (observed in the 2026-08-07 gold sweep).
(cd "$WD" && claude --plugin-dir "$PLUGIN_DIR" \
    -p "/reviso:review --base $BASE_SHA" --output-format json \
    --setting-sources project,local \
    --allowedTools "Bash(sh $PLUGIN_DIR/skills/reviso/detectors/run.sh:*)" \
    ${CANDIDATE_CLAUDE_FLAGS:-}) > "$OUT/candidate-raw.json"

# An API-level failure (rate limit, auth, outage) is not a review — fail
# with the actual message, not a downstream parse error.
if jq -e '.is_error == true' "$OUT/candidate-raw.json" >/dev/null 2>&1; then
  echo "candidate.sh: claude run errored: $(jq -r '.result // "unknown error"' "$OUT/candidate-raw.json")" >&2
  exit 1
fi
jq -r '.result' "$OUT/candidate-raw.json" > "$OUT/candidate-report.md"
sh "$HERE/extract.sh" "$OUT/candidate-report.md" > "$OUT/candidate.json"

# Report-only invariant check: the run must not have changed the tree —
# compared against the pre-run snapshot, so dirty-by-design gold-mode
# trees pass as long as the review touched nothing.
POST_STATUS=$(git -C "$WD" status --porcelain -uall)
POST_HASH=""
if [ -n "$POST_STATUS" ]; then
  POST_HASH=$( (cd "$WD" && git status --porcelain -uall | cut -c4- \
    | while read -r f; do [ -f "$f" ] && shasum "$f" || :; done) )
fi
if [ "$PRE_STATUS" != "$POST_STATUS" ] || [ "$PRE_HASH" != "$POST_HASH" ]; then
  echo "candidate.sh: REPORT-ONLY VIOLATION — review run changed the tree:" >&2
  printf 'before:\n%s\nafter:\n%s\n' "$PRE_STATUS" "$POST_STATUS" >&2
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
