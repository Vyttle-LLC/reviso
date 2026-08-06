# deterministic-detectors

## Purpose

The zero-token detector suite that runs before any LLM stage and ships only checks that cannot false-positive.

## Requirements

### Requirement: Zero-token deterministic pass runs on every review

Stage 1 SHALL run deterministic detectors on the assembled diff before any
LLM stage, at zero token cost, using only POSIX tools, git, and ripgrep —
no runtime dependencies requiring installation.

#### Scenario: Detectors run first and free

- **WHEN** a review starts
- **THEN** deterministic detectors complete against the diff before any
  finder agent is launched, consuming no model tokens

### Requirement: A detector ships only if it cannot false-positive

Every shipped detector MUST be FP-free by construction: it flags only
conditions that are mechanically verifiable from the diff and repository
content. A candidate detector that can misfire SHALL be excluded and its
concern routed to the anti-slop LLM finder instead.

#### Scenario: Borderline candidate excluded

- **WHEN** a candidate detector's condition requires judgment (e.g.
  "comment is unnecessarily verbose")
- **THEN** it is not shipped as a deterministic detector; the concern is
  covered by the anti-slop finder

#### Scenario: Scope limited to the change

- **WHEN** a detector condition also holds on lines the change did not
  touch
- **THEN** only occurrences introduced or modified by the change are
  flagged

### Requirement: Deterministic findings join the pipeline unverified

Detector findings SHALL use the same finding schema as LLM finders, tagged
`deterministic`, and SHALL bypass Stage 4 verification and the confidence
gate (they report at full confidence).

#### Scenario: Deterministic finding in the report

- **WHEN** a detector flags a diff-introduced unused import
- **THEN** the finding appears in the final report with full confidence
  without consuming a verifier run
