---
name: reviso-finder-prior-reviews
description: Reviso finder — checks review feedback on prior PRs touching the same files and applies it to the current change. Returns structured candidates only.
tools: Read, Grep, Glob, Bash(git log:*), Bash(git show:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*)
model: sonnet
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-finder-prior-reviews.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
