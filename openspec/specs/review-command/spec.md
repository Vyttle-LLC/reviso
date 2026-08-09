# review-command

## Purpose

The user-facing review commands: what `/reviso:review` and `/reviso:audit` cover, their report-only contract, and the shape of every reported finding.

## Requirements

### Requirement: Two tiers — single-pass review, multi-agent audit

The plugin SHALL provide two review commands (D10): `/reviso:review`, a
single-pass review performed entirely by the command's own session (no
subagents), pinned to the `opus` tier alias (D11) — the tier `/review`
typically runs on, keeping comparisons same-tier and cost predictable —
and `/reviso:audit`, the multi-agent pipeline (triage, blind finders,
per-finding verification) intended as the pre-PR deep pass.

#### Scenario: Review spawns no agents

- **WHEN** `/reviso:review` runs
- **THEN** no subagent is launched; the session performs assembly,
  detection, review, self-verification, and reporting itself

#### Scenario: Audit runs the pipeline

- **WHEN** `/reviso:audit` runs
- **THEN** the staged multi-agent pipeline executes (see review-pipeline)

### Requirement: Both commands review base..HEAD plus uncommitted changes

Each command SHALL review the full `base..HEAD` diff plus uncommitted
(working tree and index) changes. The default base SHALL be the
repository's default branch (via `origin/HEAD`), overridable with
`--base <branch-or-sha>`.

#### Scenario: Default invocation on a feature branch

- **WHEN** `/reviso:review` runs on a branch with commits ahead of the
  default branch and uncommitted edits
- **THEN** the review covers every change in `base..HEAD` and the
  uncommitted edits, not just the working-tree diff

#### Scenario: Base override

- **WHEN** `/reviso:review --base develop` runs
- **THEN** the diff is computed against `develop` instead of the default
  branch

### Requirement: Report-only — neither command mutates the working tree

Both commands and every subagent they spawn SHALL be restricted to
read-only tools. No file in the user's repository is created, edited, or
deleted by a review. Each command's `allowed-tools` frontmatter MUST NOT
include Edit, Write, or NotebookEdit, and MUST NOT include Bash patterns
that permit writes.

#### Scenario: Review of a dirty working tree

- **WHEN** a review completes on a repo with uncommitted changes
- **THEN** `git status` and the working-tree content are byte-identical to
  before the review

#### Scenario: Report file only on explicit request

- **WHEN** the user passes `--out <path>`
- **THEN** the report is written to exactly that path, and to no path
  otherwise (terminal output is the default sink)

### Requirement: Findings are line-anchored and complete

Every reported finding SHALL include: file and line anchor, severity, a
concrete failure scenario (inputs/state → wrong outcome), a suggested fix or
rewrite, and a confidence score. Findings SHALL be ranked most-severe-first
and consolidated (related nits merged into one comment).

#### Scenario: Finding rendering

- **WHEN** the pipeline reports a confirmed finding
- **THEN** the report entry shows `file:line`, severity, failure scenario,
  suggested fix, and confidence — none absent

#### Scenario: Clean review

- **WHEN** no finding survives the confidence gate
- **THEN** the report states that no issues were found and which dimensions
  were checked, and nothing else

### Requirement: The single-pass review applies the duplication lens identically

`/reviso:review`'s inline anti-slop lens SHALL include the duplication
item exactly as specified for the pipeline's anti-slop finder (same bar,
same helper-naming fix requirement, same below-bar silence, same search
protocol before clearing an added block) — the two surfaces SHALL NOT
drift in the item's definition or thresholds.

#### Scenario: Same bar in the inner loop

- **WHEN** `/reviso:review` reviews a diff containing the same predicate
  added at five call sites
- **THEN** it ships the same single consolidated duplication finding the
  audit pipeline would, with every occurrence cited and the helper named

#### Scenario: Below-bar stays silent

- **WHEN** `/reviso:review` encounters a two-instance duplication with no
  prior copies
- **THEN** the report ships no duplication finding and makes no mention of
  the duplication
