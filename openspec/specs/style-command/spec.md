# style-command

## Purpose

The `/reviso:style` verb: a single-pass, style-only review — AI slop, drift from the repo's own norms, comment and method length, duplication — calibrated against the codebase itself, never against absolute thresholds.

## Requirements

### Requirement: `/reviso:style` is a single-pass, style-only review

The plugin SHALL provide `/reviso:style`, a review performed entirely by
the command's own session (no subagents), pinned to the `opus` tier alias
(D1), assembling its mock PR by the same deterministic sequence the other
verbs use (see mock-pr-assembly). Scope (`base..HEAD` plus uncommitted
changes, `--base`), the report-only contract (`--out`), and `--explain`
diagnostics are the every-command obligations of review-command, which
bind this verb identically.

#### Scenario: Style spawns no agents

- **WHEN** `/reviso:style` runs
- **THEN** no subagent is launched; the session performs assembly,
  detection, review, self-verification, and reporting itself

### Requirement: Five style lenses, and no bug hunting

`/reviso:style` SHALL apply exactly five lenses:

1. **Anti-slop** — the P0 slop set as specified for the pipeline's
   anti-slop finder: drift from codebase patterns, ~3× verbosity,
   reimplementing an existing utility (cited, or it is not a finding),
   and comment slop with the tightened rewrite in `suggested_fix`.
2. **Duplication** — the same 4-or-more / exactly-3 / 2-or-fewer bar,
   helper-naming fix requirement, and search protocol as the pipeline's
   anti-slop finder and `/reviso:review`, with `/reviso:review`'s
   below-bar silence at reporting time; the three surfaces SHALL NOT
   drift in the item's definition or thresholds, while severity and
   gating remain each surface's own.
3. **Conventions** — compliance with CLAUDE.md / AGENTS.md guidance and
   lint configs governing changed paths, code-shaped rules only.
4. **Repo-style drift** — the change writes this kind of code differently
   from how the repo demonstrably writes it (naming, error-handling
   shape, module layout, test structure).
5. **Outlier length** — a method/function or comment far outside the size
   of comparable units in this repo.

The command SHALL NOT report bugs, and SHALL NOT apply the bugs, history,
or code-comment-compliance lenses. Its report SHALL point users to
`/reviso:review` and `/reviso:audit` for bug-finding coverage. Each lens
SHALL get a coverage-ledger row recorded as it resolves, exactly as the
sibling verbs keep theirs.

#### Scenario: A bug is noticed mid-review

- **WHEN** the style pass happens to notice a likely bug in a changed hunk
- **THEN** no bug finding ships; the report's scope note directs the user
  to `/reviso:review` or `/reviso:audit`

#### Scenario: Duplication bar matches the sibling surfaces

- **WHEN** `/reviso:style` reviews a diff containing the same predicate
  added at five call sites
- **THEN** it ships the same single consolidated duplication finding the
  audit pipeline would, with every occurrence cited and the helper named

### Requirement: Every style finding cites the repo baseline it was measured against

Style judgments SHALL be calibrated against the repository's own norms,
never against absolute thresholds or general taste:

- A **repo-style drift** finding MUST cite at least two existing examples
  of the established pattern by `file:line` in its evidence; with no cited
  baseline there is no finding.
- An **outlier length** finding MUST name the comparable functions or
  comments in this repo it was measured against and their approximate
  sizes; fixed numeric thresholds (e.g. "functions over N lines") SHALL
  NOT be used as evidence.
- A deliberate, established style in this repo is never a finding: when
  the repo itself is verbose, verbose new code matches its norms.

#### Scenario: Drift finding without a cited baseline

- **WHEN** a candidate claims the change drifts from repo style but no
  existing `file:line` examples of the established pattern are cited
- **THEN** the candidate is dropped and does not ship

#### Scenario: Long method in a long-method codebase

- **WHEN** a changed function is long, and comparable functions in the
  repo run about the same length
- **THEN** no outlier-length finding ships

### Requirement: Style severity is capped below blocking

Style findings SHALL be P2 by default and P1 only when the finding
actively misleads (a wrong comment, a shadowed utility with different
behavior) or duplicated copies have already diverged in behavior. The
style lenses SHALL NOT emit P0. Deterministic detector findings keep their
own severities.

#### Scenario: Ordinary slop finding

- **WHEN** a verbose-but-correct block is flagged
- **THEN** it ships at P2

#### Scenario: Comment that misleads

- **WHEN** a changed comment asserts behavior the code does not have
- **THEN** the finding may ship at P1

### Requirement: The style command reuses the shared harness unchanged

`/reviso:style` SHALL run the deterministic detector suite before its own
pass, record candidates in the shared finding schema, self-verify every
candidate against the false-positive exclusion list and the confidence
rubric, and silently drop candidates scoring below 80. Its reporting
policy SHALL match `/reviso:review`: no finding below P2 ships, related
findings are consolidated, at most 8 findings ship most-severe-first, and
`--explain` carries the ledger and gated candidates per the shared
diagnostics requirement.

#### Scenario: Detectors run first and free

- **WHEN** a style review starts
- **THEN** the deterministic detectors complete against the diff before
  the lens pass, consuming no model tokens

#### Scenario: Confidence gate applies

- **WHEN** a style candidate scores 79 against the rubric
- **THEN** it is silently dropped, appearing only in `--explain`
  diagnostics when that flag was passed
