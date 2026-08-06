# Reference

## The live upstream: the CLI-embedded skill

The `/review` (`/code-review`) Reviso benchmarks against is a skill built
into the Claude Code CLI binary, effort-scaled by level. It is **not** the
marketplace plugin below, and it has no license permitting its prompt text
in this repo. What lives here instead:

- `extract-builtin.sh` — extracts the skill text from a CLI binary into
  `private/` (gitignored, local reading only) and prints a drift
  fingerprint.
- `builtin-skill-notes.md` — the committed facts: observed structure
  (levels, angles, caps, stances, output contract) and the per-version
  fingerprint table.

Drift detection is behavioral: a CLI version roll is a re-baseline event
(`eval/README.md`); the fingerprint tells you cheaply whether the skill
text itself moved. Do not commit anything from `private/`.

## Superseded: the marketplace snapshot

`code-review-recipe-2026-08-03.md` is a verbatim, dated snapshot of the
official marketplace `code-review` plugin command that Reviso's pipeline is
forked from (see the `add-reviso-review` change, D1/D9). **Superseded as a
parity reference on 2026-08-06**: the marketplace plugin stopped being what
`/review` runs (the CLI built-in replaced it; the marketplace file was
last touched upstream in early 2026, identical to this snapshot). It stays
as history — it documents the recipe Reviso forked — but hashing it detects
nothing anymore.

- **Source:** `claude-plugins-official/plugins/code-review/commands/code-review.md`
  (marketplace checkout on the vendoring machine)
- **Snapshot date:** 2026-08-03
- **SHA-256:** `7d5a0bc9a41babad32a387152f9680316997bc4ad376928827d670b1760cc890`
- **License:** Apache-2.0 (upstream license preserved verbatim as
  `code-review-recipe-LICENSE`; © Anthropic)

Do not edit the snapshot.
