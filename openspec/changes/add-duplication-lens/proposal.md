# Add the duplication lens

## Why

Reviso's slop set covers new code that reimplements an *existing* repo
utility, but nothing owns duplication *within* the diff — and even the
existing item under-fires (issue #9: a third verbatim copy of a typealias
drew no note). Three labeled cases now agree this matters and where the
bar sits: human review feedback on termic#162 flagged a 1-line collision
predicate copy-pasted across five call sites plus a closure and asked for
a shared helper; watchos-202's three-copy `Transport` typealias was
adjudicated apply-now; sagechat-15's two-instance dups were ruled
out-of-lane. Upstream's `reuse`/`simplification` angles both cover this
lane; Reviso is silent in it by construction.

## What Changes

- **Slop set gains item 5 — Duplication** (both commands' inline lens and
  the `reviso-finder-slop` agent): (a) new-vs-existing, sharpened with an
  explicit search protocol (grep distinctive identifiers from each added
  block before clearing it); (b) new-vs-new within the diff. Ships only
  above the calibrated bar — **≥3 occurrences of a rule-encoding
  expression, or a substantial verbatim block (~8+ lines)** — with
  `suggested_fix` naming the concrete helper: name, signature, proposed
  location following the repo's layout, and the drift-risk failure
  scenario ("N sites encode the same rule; they drift when it changes").
  Below the bar: the report's notes tier, never a shipped finding.
- **Deterministic assist (design-gated)**: a zero-token pass that lists
  verbatim duplicate runs (added lines appearing ≥3× in the diff or
  matching existing repo lines) as *hints fed to the slop finder* — not
  direct findings, since "worth extracting" is judgment even when "is
  duplicated" is fact.
- **Version bump to 0.3.0** + CHANGELOG roll: this is the first
  plugin-surface change since 0.2.0, so it carries the pending Unreleased
  notes out the door (and is what makes the change reach installed
  copies — the plugin cache is version-keyed).
- Closes #9.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `review-pipeline`: the anti-slop finder's P0 slop set gains the
  duplication item with its bar and helper-naming fix requirement.
- `review-command`: the single-pass review's lens list gains the same
  item (the two surfaces must not drift — SKILL.md's shared-material rule).

## Impact

- `agents/reviso-finder-slop.md`, `commands/review.md`,
  `commands/audit.md` (lens lists), possibly a new detector-assist under
  `skills/reviso/detectors/`.
- `.claude-plugin/plugin.json` → 0.3.0; `CHANGELOG.md` Unreleased → 0.3.0.
- Calibration: termic-162 (human-labeled, private corpus), watchos-202 and
  sagechat-15 duplication labels as above/below-bar exemplars; the gold
  sweep's CRB duplication-category findings as regression data.
- No harness changes; gold/parity tooling measures the effect.
