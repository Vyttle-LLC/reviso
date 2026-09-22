---
name: reviso-finder-conventions
description: Reviso finder — audits a change against the repo's CLAUDE.md / AGENTS.md conventions. Returns structured candidates only.
tools: Read, Grep, Glob
model: sonnet
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-finder-conventions.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
