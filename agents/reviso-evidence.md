---
name: reviso-evidence
description: Reviso Stage 4 evidence agent — re-examines one candidate against the code and returns findings of fact. No score, no verdict, no veto.
tools: Read, Grep, Glob, Bash(git blame:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*)
model: sonnet
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-evidence.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
