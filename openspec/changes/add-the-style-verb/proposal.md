# Add the style verb

## Why

Reviso cannot out-compete `/code-review` on bug finding — the built-in is
effort-scaled, recall-biased at high effort, and free to improve underneath
us. Where Reviso already has an edge is everything `/code-review` does not
claim: judging a change against the repo's *own* norms — AI slop, style
drift, bloated comments, oversized methods, duplication. Today that
judgment is buried inside `/reviso:audit` as one finder among six; a user
who wants only the style pass has to pay for (and wade through) a full
multi-agent bug hunt. Elevating it into its own cheap verb gives Reviso a
lane the built-in doesn't occupy.

## What Changes

- New command `/reviso:style` — a single-pass, report-only style review of
  `base..HEAD` plus uncommitted changes, same assembly and flags as
  `/reviso:review` (`--base`, `--out`, `--explain`).
- Scope is style-only, five lenses: AI slop (the existing P0 slop set),
  repo-style drift (conventions inferred from the codebase itself, not only
  CLAUDE.md), comment quality and length, method/function length, and
  duplication. Explicitly **no bug hunting** — the command tells users
  wanting bugs to run `/reviso:review` or `/reviso:audit`.
- Every lens is calibrated against the repo's own norms (the slop finder's
  cardinal rule): length and verbosity findings must cite the repo baseline
  they were measured against, never an absolute threshold.
- Reuses the shared harness: mock-PR assembly, the finding schema, the
  confidence rubric, the false-positive exclusion list, and the
  deterministic detector pass.
- `/reviso:audit` and `/reviso:review` are unchanged; the audit's slop
  finder stays where it is. The style verb is the dedicated fast lane, not
  a replacement.

## Capabilities

### New Capabilities

- `style-command`: the `/reviso:style` verb — its five style lenses,
  repo-norm calibration rules, single-pass architecture, report-only
  contract, and report format.

### Modified Capabilities

- `review-command`: the "two tiers" requirement becomes three verbs — the
  command roster gains `/reviso:style`, and each command's report must
  point users to the right sibling verb for out-of-scope concerns.

## Impact

- New file: `commands/style.md`.
- Delta to `openspec/specs/review-command/spec.md` (command roster).
- Read-only reuse of `skills/reviso/references/*` (finding schema,
  confidence rubric, false-positives) and `skills/reviso/detectors/`;
  no changes expected there.
- `.claude-plugin/` manifest gains the new command if commands are
  enumerated there.
- Eval corpus (`eval/`) eventually needs style-labeled cases to measure
  the verb; out of scope for this change beyond noting the gap.
