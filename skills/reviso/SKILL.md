---
name: reviso
description: Shared harness material for Reviso's review pipeline — the finding schema, the confidence rubric, the false-positive exclusion list, and the deterministic detector suite. Used by /reviso:review and its subagents; not meant for direct invocation.
---

# Reviso harness

Shared, single-source material for both review tiers. `commands/review.md`
is the single-pass inner-loop review; `commands/audit.md` orchestrates the
multi-agent pipeline over the agents in `agents/`. Everything here exists so
the commands and agents cite one copy instead of drifting apart.

- `references/finding-schema.md` — the one finding format every stage speaks.
- `references/confidence-rubric.md` — the 0–100 verification rubric
  (forked from the official code-review plugin, Apache-2.0; see
  `eval/reference/` for the dated snapshot).
- `references/false-positives.md` — the exclusion list: what is never a
  finding, no matter how plausible it looks.
- `detectors/` — the zero-token Stage 1 suite. `run.sh <base-ref>` runs every
  detector; each is FP-free by construction or it does not ship
  (`detectors/DISCOVERY.md` records what was evaluated and why).
- `feedback/` — the deterministic false-positive payload builder
  (`build-payload.sh`). The only thing in the plugin permitted to make a
  network write, and only to the Reviso issue tracker with the user's
  explicit approval; `docs/feedback.md` is the contract it implements.

Invariant, stated once more because every piece of this plugin inherits it:
**report-only**. Nothing in this skill, the command, or the agents may
create, modify, or delete files in the user's repository.
