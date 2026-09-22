---
description: Single-pass style-only review of base..HEAD + uncommitted changes — slop, drift, duplication, comments, dead weight, over-engineering, test slop, AI tells, derived state, naming, error handling, stale docs, surface area, type slop, plus the opt-in --web best-practices lens; report-only
argument-hint: "[--base <ref>] [--out <path>] [--explain] [--web]"
model: opus
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git blame:*), Bash(gh pr view:*), Bash(rg:*)
---

Run the shared Reviso style workflow.

- Host: Claude Code. Mode: `style`. Options: `$ARGUMENTS`.
- Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
- Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/execution.md`
  and `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/workflows/style.md`.
- Preserve this command’s model and tool permissions.
