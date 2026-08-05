# review-pipeline

This capability specifies the multi-agent pipeline behind **`/reviso:audit`**
(per D10; `/reviso:review` is the single-pass tier specified in
review-command — it applies the same lenses, exclusion list, and <80
self-gate inline, without subagents).

## ADDED Requirements

### Requirement: Triage tags hunks and skips non-reviewable content

Stage 2 SHALL run one low-cost model pass that tags each hunk with risk
categories (auth, money, concurrency, external input, public API, migration,
deleted tests) and marks skip-tier content (lockfiles, generated code,
pure formatting). Skip-tier hunks SHALL NOT be sent to finder agents; risk
tags SHALL be passed into finder prompts.

#### Scenario: Lockfile skipped

- **WHEN** the diff includes a lockfile change and a source change
- **THEN** finder agents receive only the source change, with the lockfile
  noted as skipped in the report's coverage summary

### Requirement: Parallel blind dimension finders, forked from the reference recipe

Stage 3 SHALL launch parallel finder agents, blind to each other, covering
the reference recipe's dimensions (conventions compliance, shallow-bug scan,
git-history context, prior-review guidance, code-comment guidance) plus an
anti-slop dimension. Each finder SHALL return structured candidates, each
with a concrete failure scenario and a suggested fix or rewrite.

#### Scenario: Finder fan-out

- **WHEN** Stage 3 runs on a non-trivial diff
- **THEN** all finder dimensions run in parallel, and each returned
  candidate carries a failure scenario and suggested fix

#### Scenario: Anti-slop finder scope

- **WHEN** the anti-slop finder reviews a hunk
- **THEN** it flags only the P0 slop set relative to the codebase's own
  norms (drift from existing patterns, verbosity, reinvented utilities,
  borderline comment slop) — deliberate repo style is not flagged

### Requirement: Per-finding verification with a confidence gate

Stage 4 SHALL score every LLM finding with an independent verifier using the
reference recipe's 0–100 confidence rubric (given verbatim) and
false-positive exclusion list. Findings scoring below 80 SHALL be silently
dropped. Deterministic findings bypass this stage.

#### Scenario: Low-confidence finding dropped

- **WHEN** a verifier scores a finding at 60
- **THEN** the finding does not appear in the report and no mention of it
  is made

#### Scenario: Known false-positive class dropped

- **WHEN** a finder flags a pre-existing issue on lines the change did not
  modify
- **THEN** the verifier scores it as a false positive per the exclusion
  list and it is gated out

### Requirement: Consolidated, severity-ranked report

The report stage SHALL dedupe overlapping findings, consolidate related
minor findings into single comments, and order the report
most-severe-first. The pipeline SHALL prefer silence over uncertain
findings: an uncertain finding does not ship.

#### Scenario: Duplicate findings merged

- **WHEN** two finders flag the same underlying defect
- **THEN** the report contains one finding citing the strongest evidence
