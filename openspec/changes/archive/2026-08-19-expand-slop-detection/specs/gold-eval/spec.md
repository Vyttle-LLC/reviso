# gold-eval (delta)

## MODIFIED Requirements

### Requirement: Gold mode evaluates the candidate against labels without baseline runs

The harness SHALL provide a gold-mode runner that, for a gold-labeled
corpus case, runs **the Reviso review tier named by the invocation**
(`/reviso:review`, `/reviso:audit`, or `/reviso:style`) against the
case's pinned checkout (identically to parity mode's candidate leg) and
judges the resulting findings against the case's labels file — invoking
no upstream review at any point. The tier SHALL be named explicitly at
every invocation and SHALL NOT be inferred from a default, so a recorded
run always states which product it measured. Matching SHALL use the same
matcher and the same tiering as parity mode, from one shared definition.
The runner SHALL fail loudly and by name when its corpus file is missing,
when a requested case is absent from it, when a case carries no labels
path, or when no tier was named — a gold run without labels is an error,
never a silently skipped case.

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

#### Scenario: The style tier can be the candidate

- **WHEN** a gold run names `/reviso:style` as the tier under test
- **THEN** the single-pass style lane is the candidate leg, judged
  against the same labels by the same matcher as the other tiers, and the
  run's recorded metadata names `style` as the tier

#### Scenario: An unnamed tier is an error

- **WHEN** a gold run is invoked without naming a review tier
- **THEN** the run exits with an error rather than selecting one by
  default
