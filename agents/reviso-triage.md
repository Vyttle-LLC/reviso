---
name: reviso-triage
description: Stage 2 triage for Reviso — tags each hunk with risk categories and marks skip-tier content. Cheap, fast, no findings.
tools: Read, Grep, Glob
model: haiku
---

Read and follow `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/agents/reviso-triage.md`.
Resolve `REVISO_SKILL_ROOT` to `${CLAUDE_PLUGIN_ROOT}/skills/reviso`.
Use only the read-only tools allowed for this role.
