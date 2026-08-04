# mock-pr-assembly

## ADDED Requirements

### Requirement: Assemble PR-grade context from local git state

Stage 0 SHALL assemble, using only deterministic read-only git operations:
the complete `base..HEAD` diff plus uncommitted changes, all commit messages
on the branch, the changed-file list with full-file content available to
finders on demand (the orchestrator does not buffer file contents — cost
measurement showed buffering pays for every byte once per agent prompt), a
ticket reference inferred from branch name or commit trailers when present,
and repo conventions (root and path-relevant CLAUDE.md / AGENTS.md, lint
configuration for changed paths).

#### Scenario: Full context assembled

- **WHEN** Stage 0 runs on a branch with three commits and one staged edit
- **THEN** the assembled context contains the three commit messages, the
  combined diff including the staged edit, and the changed-file list —
  with finders able to Read any changed file in full on demand

#### Scenario: Conventions included

- **WHEN** a changed file lives under a directory with its own CLAUDE.md
- **THEN** both the root CLAUDE.md (if present) and that directory's
  CLAUDE.md are part of the assembled context

#### Scenario: Ticket inference

- **WHEN** the branch is named `feat/VYT-123-thing` or a commit carries a
  ticket trailer
- **THEN** the ticket identifier appears in the assembled context; absence
  of a ticket is not an error

### Requirement: Assembly is deterministic and reproducible

Given identical git state and flags, Stage 0 SHALL produce identical
assembled context (no LLM calls, no time- or environment-dependent content).

#### Scenario: Repeat run

- **WHEN** Stage 0 runs twice on the same commit and working tree
- **THEN** the two assembled contexts are identical
