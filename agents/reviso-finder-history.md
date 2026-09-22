---
name: reviso-finder-history
description: Reviso finder — reads git blame and history of the modified code to find bugs in light of historical context. Returns structured candidates only.
tools: Read, Grep, Glob, Bash(git blame:*), Bash(git log:*), Bash(git show:*), Bash(git diff:*)
model: sonnet
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-finder-history.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
