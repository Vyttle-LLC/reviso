---
name: reviso-finder-comments
description: Reviso finder — reads code comments in the modified files and checks the change complies with guidance in them. Returns structured candidates only.
tools: Read, Grep, Glob
model: sonnet
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-finder-comments.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
