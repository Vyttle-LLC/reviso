---
description: Deep multi-agent review of base..HEAD + uncommitted changes — the pre-PR gate; report-only
argument-hint: "[--base <ref>] [--out <path>] [--explain]"
model: opus
allowed-tools: Read, Grep, Glob, Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git blame:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*), Bash(rg:*)
---

Run the shared Reviso audit workflow.

- Host: Claude Code. Mode: `audit`. Options: `$ARGUMENTS`.
- Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
- Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/execution.md`
  and `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/workflows/audit.md`.
- Preserve this command’s model and tool permissions.
