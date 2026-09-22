---
name: reviso-finder-slop
description: Reviso finder — the anti-slop lens. Flags the P0 slop set relative to the codebase's own norms. Returns structured candidates only.
tools: Read, Grep, Glob
model: sonnet
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-finder-slop.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
