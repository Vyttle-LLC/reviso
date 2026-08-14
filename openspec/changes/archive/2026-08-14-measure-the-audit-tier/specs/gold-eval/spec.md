# gold-eval

## MODIFIED Requirements

### Requirement: Gold mode evaluates the candidate against labels without baseline runs

The harness SHALL provide a gold-mode runner that, for a gold-labeled
corpus case, runs **the Reviso review tier named by the invocation**
(`/reviso:review` or `/reviso:audit`) against the case's pinned checkout
(identically to parity mode's candidate leg) and judges the resulting
findings against the case's labels file — invoking no upstream review at
any point. The tier SHALL be named explicitly at every invocation and
SHALL NOT be inferred from a default, so a recorded run always states which
product it measured. Matching SHALL use the same matcher and the same
tiering as parity mode, from one shared definition. The runner SHALL fail
loudly and by name when its corpus file is missing, when a requested case
is absent from it, when a case carries no labels path, or when no tier was
named — a gold run without labels is an error, never a silently skipped
case.

#### Scenario: No upstream invocations

- **WHEN** a gold-mode run completes
- **THEN** no `/code-review` (or other upstream review) invocation was
  made; the only model costs are the candidate run and the judge's
  matching calls

#### Scenario: Same matcher, same calibration

- **WHEN** gold mode matches candidate findings to gold labels
- **THEN** it uses the parity harness's matcher and the shared tier
  definition, so one calibration covers both modes

#### Scenario: Missing labels fail by name

- **WHEN** a gold run names a case whose corpus entry has no labels path
- **THEN** the run exits with an error naming the case and the corpus file
  it was read from

#### Scenario: Either review tier can be the candidate

- **WHEN** a gold run names `/reviso:audit` as the tier under test
- **THEN** the deep multi-agent pipeline is the candidate leg, judged
  against the same labels by the same matcher as a `/reviso:review` run

#### Scenario: An unnamed tier is an error

- **WHEN** a gold run is invoked without naming a review tier
- **THEN** the run exits with an error rather than selecting one by
  default

## ADDED Requirements

### Requirement: Recorded gold runs carry the review tier that produced them

Every gold run's recorded metadata SHALL name the Reviso review tier that
produced its findings, alongside the CLI version and resolved model IDs it
already records. Aggregate metrics SHALL be reported per tier and SHALL
NOT pool runs from different tiers into one figure, because the two tiers
are different products with different pipelines and costs.

#### Scenario: Tier is recorded

- **WHEN** a gold run completes
- **THEN** its metadata names the review tier under test, and a run
  lacking that field is treated as non-comparable rather than assumed to
  be any particular tier

#### Scenario: Sweep metrics do not pool tiers

- **WHEN** a sweep aggregates completed cases into a summary
- **THEN** recall, precision-proxy, and clean-case figures are reported
  per tier, so no single number can describe two pipelines at once
