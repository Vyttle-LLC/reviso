# review-pipeline

## Purpose

The multi-agent pipeline behind `/reviso:audit`: staged triage, blind dimension finders, per-finding verification, and consolidated reporting.

This capability specifies the multi-agent pipeline behind **`/reviso:audit`**
(per D10; `/reviso:review` is the single-pass tier specified in
review-command — it applies the same lenses, exclusion list, and <80
self-gate inline, without subagents).

## Requirements

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
  borderline comment slop, and duplication per the duplication
  requirement below) — deliberate repo style is not flagged

### Requirement: The duplication lens ships helper extractions above a calibrated bar

The anti-slop dimension SHALL flag duplication in both directions —
new code reimplementing something the repository already has, and code
duplicated within the change itself — only when the diff reaches the bar.
The unit is a rule-encoding expression or predicate, a declaration or
definition, or a verbatim or near-verbatim block, and new occurrences
SHALL be counted together with any pre-existing copies. Four or more
occurrences SHALL ship. Exactly three occurrences SHALL ship only when
the duplicated unit encodes a rule that can change — a predicate, a
policy constant, a shared type or contract — and SHALL stay silent when
the similarity is incidental, such as setup or assertion scaffolding. Two
or fewer occurrences SHALL NOT ship regardless of how long the copied
block is. Every shipped duplication finding SHALL cite each occurrence by
`file:line`, state the drift-risk failure scenario concretely, and give a
`suggested_fix` naming the helper (name, signature, proposed location
consistent with the repository's layout) plus the rewrite of one call
site. Below-bar duplication SHALL NOT be reported at all. Before clearing
any added block as non-duplicative, the finder SHALL search the
repository for that block's distinctive identifiers.

#### Scenario: Rule expression repeated across call sites

- **WHEN** the diff adds the same collision predicate at five call sites
  plus a closure
- **THEN** one duplication finding ships, citing every occurrence, with a
  named shared helper and the drift-risk scenario

#### Scenario: Third verbatim copy of an existing utility

- **WHEN** the diff adds a verbatim copy of a shared type declaration
  already present in two other files
- **THEN** a duplication finding ships naming the existing copies and the
  shared home the three should adopt

#### Scenario: Three incidental look-alikes stay below the bar

- **WHEN** three added lines coincide only as setup or assertion
  scaffolding, encoding no rule that a future edit would have to change in
  every copy
- **THEN** no duplication finding ships — at exactly three occurrences the
  duplicated unit must encode a changeable rule

#### Scenario: Two-instance duplication stays below the bar

- **WHEN** the diff contains a helper duplicated exactly twice with no
  prior copies
- **THEN** no duplication finding ships and the report says nothing about
  it

#### Scenario: A long block duplicated only once stays below the bar

- **WHEN** the diff contains a line-for-line copy of a sixteen-line
  function or view skeleton, giving two occurrences in total
- **THEN** no duplication finding ships — block length is not a route
  past the occurrence bar

#### Scenario: Severity cap

- **WHEN** a duplication finding ships and the copies have not yet
  diverged in behavior
- **THEN** its severity is P2 (P1 is reserved for copies that have
  already drifted)

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
