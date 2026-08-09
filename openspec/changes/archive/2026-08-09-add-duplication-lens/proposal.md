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
  above the calibrated bar — occurrences of the same unit of logic (a
  rule-encoding expression, a declaration, or a verbatim block), counting
  pre-existing copies: **≥4 ships; exactly 3 ships only if the unit
  encodes a changeable rule; ≤2 never ships** — with
  `suggested_fix` naming the concrete helper: name, signature, proposed
  location following the repo's layout, and the drift-risk failure
  scenario ("N sites encode the same rule; they drift when it changes").
  Below the bar: silence — no finding, no mention (see design D1).
- **Deterministic assist: evaluated and dropped.** The design gated a
  zero-token duplicate-run hint pass on proving a recall gain;
  prototyped against the seed case it missed the target duplication
  outright and emitted only test-scaffolding noise, so it fails the gate
  and does not ship. Line-level matching is the wrong instrument —
  extractable duplication is similar under renaming, which is
  token-level. See design D4 and `detectors/DISCOVERY.md`.
- **Version bump to 0.3.0** + CHANGELOG roll: this is the first
  plugin-surface change since 0.2.0, so it carries the pending Unreleased
  notes out the door (and is what makes the change reach installed
  copies — the plugin cache is version-keyed).
- Addresses the verbatim-duplicate-declaration half of #9. That report
  also names a second recall gap — redundant derived state (a stored
  property always equal to a projection of another) — which is a
  different shape from textual duplication, has one labeled instance and
  so no calibrated bar, and is deliberately left out of scope here.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `review-pipeline`: the anti-slop finder's P0 slop set gains the
  duplication item with its bar and helper-naming fix requirement.
- `review-command`: the single-pass review's lens list gains the same
  item (the two surfaces must not drift — SKILL.md's shared-material rule).
- `parity-eval`: the tier split is defined as in-lane vs out-of-lane from
  one shared list, so a shipped lens leaves the cleanup family; and the
  private corpus tier becomes runnable rather than merely described.
- `gold-eval`: judging is separable from the candidate leg, so a recorded
  run can be re-judged when calibration moves.

## Impact

- `agents/reviso-finder-slop.md`, `commands/review.md`,
  `commands/audit.md` (lens lists), and `detectors/DISCOVERY.md` (the
  rejected-assist record — no new detector ships).
- `.claude-plugin/plugin.json` → 0.3.0; `CHANGELOG.md` Unreleased → 0.3.0.
- Calibration: termic-162 (human-labeled, private corpus), watchos-202 and
  sagechat-15 duplication labels as above/below-bar exemplars.
- **Public regression coverage, newly created.** This proposal originally
  named "the gold sweep's CRB duplication-category findings" as regression
  data; that data did not exist — the public corpus labelled only
  correctness (103), security (23), robustness (13), and efficiency (6),
  not one duplication item across 63 cases, so every duplication finding
  was unmatchable by construction. Fixed by promoting `termic-162` (public,
  AGPL-3.0, pointer-only) into `public.jsonl` with a hand-authored
  duplication label. Two limits remain: the private above/below-bar
  exemplars still can't be swept (the runners never read
  `REVISO_EVAL_PRIVATE_CORPUS`), and `judge.sh` tiers `duplication` as
  cleanup, so a miss is informational rather than a loud regression.
- No harness changes; gold/parity tooling measures the effect.
