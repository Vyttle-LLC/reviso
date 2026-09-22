---
name: reviso
description: Review local Git changes before a PR with Reviso. Use for correctness review, style and duplication review, or a deeper multi-agent audit. Report findings without applying fixes.
---

# Reviso

Review the final state of a branch, including uncommitted and untracked
changes. Default to `review`; use `style` for style-only requests and `audit`
when the user requests the deeper multi-agent pass.

In Codex, examples are `$reviso review --base main`, `$reviso style --explain`,
and `$reviso audit`. Claude Code also retains `/reviso:review`,
`/reviso:style`, and `/reviso:audit`.

Resolve `REVISO_SKILL_ROOT` to the absolute directory containing this
`SKILL.md`, including when installed through a symlink. It is a notation
for paths in these instructions, not an environment variable supplied by
the host. Substitute the resolved, shell-quoted path when running helpers.
Keep the command working directory in the repository being reviewed.

Read [execution](references/execution.md), then only the selected workflow:

- [Review](references/workflows/review.md): single-pass correctness and style.
- [Style](references/workflows/style.md): single-pass style, optional `--web`.
- [Audit](references/workflows/audit.md): independent finders and evidence.

Parse `--base`, `--out`, `--explain`, and style's `--web` from the user's
invocation, including ordinary language equivalents. Follow the selected
workflow's schema, evidence gates, and coverage reporting. Load its linked
references as needed; do not load every mode or agent in advance.
