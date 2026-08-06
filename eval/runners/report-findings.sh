#!/bin/sh
# report-findings.sh <run-cwd> <session-id> — harvest the typed ReportFindings
# call from a headless run's transcript. Prints {"level": ..., "findings":
# [...]} (harness schema) on stdout; exits 1 if no ReportFindings call exists.
#
# Headless, the built-in /code-review delegates to an agent that reports via
# the ReportFindings tool; the -p result text is a prose rendering. The tool
# call is the deterministic source — it carries level, category, and verdict
# exactly (design D2). Callers fall back to prose extraction when this exits
# non-zero (transcript layout is a CLI internal and may move).
set -eu
CWD="${1:?usage: report-findings.sh <run-cwd> <session-id>}"
SID="${2:?usage: report-findings.sh <run-cwd> <session-id>}"

# Project transcript dir: the run cwd with path separators munged to dashes.
MUNGED=$(printf '%s' "$CWD" | sed 's|[/.]|-|g')
PDIR="$HOME/.claude/projects/$MUNGED"
[ -d "$PDIR" ] || { echo "report-findings.sh: no transcript dir $PDIR" >&2; exit 1; }

# The call may be in the session itself or in a delegated subagent.
FILES=$(ls "$PDIR/$SID.jsonl" "$PDIR/$SID"/subagents/*.jsonl 2>/dev/null || true)
[ -n "$FILES" ] || { echo "report-findings.sh: no transcript files for session $SID" >&2; exit 1; }

# Last ReportFindings call wins (re-reports supersede earlier ones).
RF=$(cat $FILES | jq -c '
  select(.type == "assistant") | .message.content[]?
  | select(.type == "tool_use" and .name == "ReportFindings") | .input
' 2>/dev/null | tail -1)
[ -n "$RF" ] || { echo "report-findings.sh: no ReportFindings call in session $SID" >&2; exit 1; }

printf '%s\n' "$RF" | jq '{
  level: (.level // null),
  findings: (.findings // [] | map({
    file: (.file // null),
    line: (.line // 0),
    title: (.summary // ""),
    severity: (.verdict // null),
    category: (.category // null),
    description: (.failure_scenario // "")
  }))
}'
