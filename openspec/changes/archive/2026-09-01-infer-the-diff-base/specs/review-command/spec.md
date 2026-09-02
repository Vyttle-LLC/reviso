# review-command

## MODIFIED Requirements

### Requirement: Every command reviews base..HEAD plus uncommitted changes

Each review command SHALL review the full `base..HEAD` diff plus
uncommitted (working tree and index) changes. The base SHALL be the first
of these signals that yields a ref, in this order: `--base <ref>`; the
open pull request's target branch; the branch's tracking branch, unless
that is only the remote copy of the current branch; the repository's
default branch, preferring the remote ref over a local one. The command
SHALL NOT infer a base from commit history. Every report SHALL name the
base, the signal that chose it, and the merge-base.

#### Scenario: Default invocation on a feature branch

- **WHEN** any review command runs on a branch with commits ahead of the
  default branch and uncommitted edits
- **THEN** the review covers every change in `base..HEAD` and the
  uncommitted edits, not just the working-tree diff

#### Scenario: Base override

- **WHEN** a review command runs with `--base develop`
- **THEN** the diff is computed against `develop` instead of any inferred
  base, and the report names `develop` via the flag

#### Scenario: Stacked branch with a tracking parent

- **WHEN** a review command runs on a branch whose tracking branch is its
  local parent and no pull request is open
- **THEN** the diff is computed against the parent, and the report names
  the parent via upstream

#### Scenario: Pushed branch tracks itself

- **WHEN** a branch's tracking branch is `origin/<same name>` and no pull
  request is open
- **THEN** the tracking branch is ignored and the default branch is used

#### Scenario: Open pull request

- **WHEN** a pull request is open for the branch with a non-default target
- **THEN** the diff is computed against that target, ahead of the tracking
  branch and the default branch
