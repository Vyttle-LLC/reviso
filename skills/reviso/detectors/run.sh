#!/bin/sh
# Reviso Stage 1 — deterministic detectors.
# Read-only: inspects git output, never writes to the repository.
# Usage: run.sh <base-ref>   → JSON array of findings (shared schema) on stdout.
#
# Evaluates the FINAL state of the change (merge-base → working tree, plus
# untracked files), so a problem introduced in a commit but fixed uncommitted
# is not flagged. POSIX sh + git + awk only; zero token cost.
set -eu

BASE="${1:?usage: run.sh <base-ref>}"
MB=$(git merge-base "$BASE" HEAD)
HERE=$(dirname "$0")

{
  # Committed + staged + unstaged, as one diff against the merge base.
  git diff -U0 "$MB"
  # Untracked files: every line is an added line.
  git ls-files --others --exclude-standard | while IFS= read -r f; do
    [ -f "$f" ] && { git diff -U0 --no-index -- /dev/null "$f" || true; }
  done
} | awk -f "$HERE/detect.awk" | sort -u | awk -F'\t' '
  function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
  BEGIN {
    sev["conflict"]   = "P0"
    title["conflict"] = "Merge conflict markers committed"
    fail["conflict"]  = "The file ships with <<<<<<</=======/>>>>>>> lines; it renders or parses as conflict garbage, or fails to build"
    fix["conflict"]   = "Resolve the merge conflict and remove all three marker lines"
    sev["testfocus"]   = "P1"
    title["testfocus"] = "Focused test committed (.only / fit / fdescribe)"
    fail["testfocus"]  = "The runner executes only the focused spec; the rest of the suite is silently skipped in CI"
    fix["testfocus"]   = "Remove the focus modifier so the full suite runs"
    printf "["
  }
  {
    if (n++) printf ","
    printf "\n  {\"file\": \"%s\", \"line\": %d, \"severity\": \"%s\", \"dimension\": \"deterministic\", \"title\": \"%s\", \"failure_scenario\": \"%s\", \"suggested_fix\": \"%s\", \"evidence\": \"mechanical match in the diff at %s:%d\", \"confidence\": 100}",
      esc($1), $2, sev[$3], title[$3], fail[$3], fix[$3], esc($1), $2
  }
  END { if (n) printf "\n"; print "]" }
'
