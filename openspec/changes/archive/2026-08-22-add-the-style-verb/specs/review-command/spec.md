# review-command (delta)

## ADDED Requirements

### Requirement: Three verbs — review and style single-pass, audit multi-agent

The plugin SHALL provide three review commands: `/reviso:review`, a
single-pass general review performed entirely by the command's own session
(no subagents), pinned to the `opus` tier alias (D11) — the tier `/review`
typically runs on, keeping comparisons same-tier and cost predictable;
`/reviso:audit`, the multi-agent pipeline (triage, blind finders,
per-finding verification) intended as the pre-PR deep pass; and
`/reviso:style`, a single-pass style-only review (see style-command).

Each command's report SHALL point users to the sibling verb that covers
concerns outside its own scope: the style report names the review/audit
verbs for bug finding, and the review and audit reports remain the
general-purpose surfaces.

#### Scenario: Review spawns no agents

- **WHEN** `/reviso:review` runs
- **THEN** no subagent is launched; the session performs assembly,
  detection, review, self-verification, and reporting itself

#### Scenario: Audit runs the pipeline

- **WHEN** `/reviso:audit` runs
- **THEN** the staged multi-agent pipeline executes (see review-pipeline)

#### Scenario: Style is the dedicated style lane

- **WHEN** `/reviso:style` runs
- **THEN** the single-pass style-only review executes (see style-command)
  and its report directs bug-finding concerns to the sibling verbs

### Requirement: Every command reviews base..HEAD plus uncommitted changes

Each review command SHALL review the full `base..HEAD` diff plus
uncommitted (working tree and index) changes. The default base SHALL be
the repository's default branch (via `origin/HEAD`), overridable with
`--base <branch-or-sha>`.

#### Scenario: Default invocation on a feature branch

- **WHEN** any review command runs on a branch with commits ahead of the
  default branch and uncommitted edits
- **THEN** the review covers every change in `base..HEAD` and the
  uncommitted edits, not just the working-tree diff

#### Scenario: Base override

- **WHEN** a review command runs with `--base develop`
- **THEN** the diff is computed against `develop` instead of the default
  branch

### Requirement: Report-only — no command mutates the working tree

Every review command and every subagent it spawns SHALL be restricted to
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

## MODIFIED Requirements

### Requirement: Opt-in pre-gate diagnostics via `--explain`

Every review command SHALL accept an `--explain` flag, default off. When
passed, the report SHALL additionally carry one clearly-labelled
diagnostic section containing the per-lens ledger with candidate counts
and every candidate considered before the confidence gate, each with its
score and its disposition (reported, or dropped with the structured drop
reason). The diagnostic section SHALL be labelled as diagnostics rather
than findings and SHALL appear after the findings.

When `--explain` is absent, the report SHALL be exactly what it would be
without the feature: no candidate below the gate is mentioned, no score of
a dropped candidate is shown. Passing `--explain` SHALL NOT change the
findings section — with and without the flag, the findings and their order
are identical.

The diagnostic section SHALL follow the report to the same sink: the
terminal, plus the `--out` path when the user gave one. It SHALL NOT
introduce any other write, and no command's `allowed-tools` SHALL gain an
entry for it.

#### Scenario: Default run is unchanged

- **WHEN** a review runs without `--explain`
- **THEN** no dropped candidate, score, or drop reason appears anywhere in
  the report

#### Scenario: Diagnostics on a zero-finding run

- **WHEN** `/reviso:audit --explain` runs on a change where every
  candidate was gated
- **THEN** the report says no issues were found and the diagnostic section
  lists each gated candidate with its score and drop reason, labelled as
  diagnostics

#### Scenario: Findings section is flag-independent

- **WHEN** the same change is reviewed with and without `--explain`
- **THEN** the findings section is identical in both reports, and only the
  appended diagnostic section differs

#### Scenario: Diagnostics respect the report-only contract

- **WHEN** `--explain` is passed without `--out`
- **THEN** the diagnostics are printed to the terminal only, and no file is
  written

## REMOVED Requirements

### Requirement: Two tiers — single-pass review, multi-agent audit

**Reason**: The command roster grew from two verbs to three; superseded by
"Three verbs — review and style single-pass, audit multi-agent", which
carries the original review and audit obligations unchanged.

**Migration**: None for users — `/reviso:review` and `/reviso:audit`
behave exactly as before; `/reviso:style` is additive.

### Requirement: Both commands review base..HEAD plus uncommitted changes

**Reason**: "Both" no longer names the roster; superseded by "Every
command reviews base..HEAD plus uncommitted changes", identical in
substance and now covering `/reviso:style` too.

**Migration**: None — behavior unchanged.

### Requirement: Report-only — neither command mutates the working tree

**Reason**: "Neither" no longer names the roster; superseded by
"Report-only — no command mutates the working tree", identical in
substance and now covering `/reviso:style` too.

**Migration**: None — behavior unchanged.
