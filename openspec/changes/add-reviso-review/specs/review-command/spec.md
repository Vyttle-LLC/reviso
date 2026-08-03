# review-command

## ADDED Requirements

### Requirement: /reviso:review reviews base..HEAD plus uncommitted changes

The plugin SHALL provide a `/reviso:review` command that reviews the full
`base..HEAD` diff plus uncommitted (working tree and index) changes. The
default base SHALL be the repository's default branch (via `origin/HEAD`),
overridable with `--base <branch-or-sha>`.

#### Scenario: Default invocation on a feature branch

- **WHEN** `/reviso:review` runs on a branch with commits ahead of the
  default branch and uncommitted edits
- **THEN** the review covers every change in `base..HEAD` and the
  uncommitted edits, not just the working-tree diff

#### Scenario: Base override

- **WHEN** `/reviso:review --base develop` runs
- **THEN** the diff is computed against `develop` instead of the default
  branch

### Requirement: Report-only — the command never mutates the working tree

The command and every subagent it spawns SHALL be restricted to read-only
tools. No file in the user's repository is created, edited, or deleted by a
review. The command's `allowed-tools` frontmatter MUST NOT include Edit,
Write, or NotebookEdit, and MUST NOT include Bash patterns that permit
writes.

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
