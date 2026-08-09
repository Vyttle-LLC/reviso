# gold-eval

## Purpose

Candidate-only evaluation against gold-labeled corpus cases — absolute recall/precision and clean-case discipline, cheap enough to run on every meaningful pipeline change (no upstream review invocations).

## Requirements

### Requirement: Gold mode evaluates the candidate against labels without baseline runs

The harness SHALL provide a gold-mode runner that, for a gold-labeled
corpus case, runs `/reviso:review` against the case's pinned checkout
(identically to parity mode's candidate leg) and judges the resulting
findings against the case's labels file — invoking no upstream review at
any point. Matching SHALL use the same matcher and the same tiering as
parity mode, from one shared definition. The runner SHALL fail loudly and
by name when its corpus file is missing, when a requested case is absent
from it, or when a case carries no labels path — a gold run without labels
is an error, never a silently skipped case.

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

### Requirement: A recorded run can be re-judged without re-running the review

Gold-mode judging (tiering, bucketing, metrics) SHALL be invocable
independently of the candidate leg, against a run's recorded outputs.
When calibration moves — a category entering or leaving the cleanup
family — every archived run's verdict is stale until re-derived, and
re-deriving it SHALL NOT require paying for the review again. A re-judge
SHALL reuse the run's recorded matcher verdicts rather than recomputing
them, so it changes only how matches are tiered, never which findings
matched. The live path and the re-judge path SHALL be the same code.

#### Scenario: Re-judge after a tiering change

- **WHEN** a category leaves the cleanup family and a recorded gold run is
  re-judged
- **THEN** the run's metrics are recomputed from its recorded candidate
  output and recorded matches, with no review invocation and no new
  matcher calls

#### Scenario: Published run states that it was re-judged

- **WHEN** a published result changes because of a re-judge rather than a
  new run
- **THEN** the publication says so, so the number is not read as a fresh
  measurement

### Requirement: Gold metrics separate recall, proxy precision, and clean-case discipline

Gold-mode output SHALL report per-case and aggregate:
`gold_recall_correctness` (matched correctness-tier gold issues ÷ total
correctness-tier gold issues), a precision proxy (candidate findings
matching any gold issue ÷ all candidate findings) explicitly labeled as a
proxy, and — for cases marked expected-clean — the count of candidate
findings, each of which is a false positive. Cleanup-tier gold issues the
candidate does not match SHALL be reported informationally and SHALL NOT
reduce gold recall.

#### Scenario: Expected-clean case with findings

- **WHEN** the candidate reports any finding on an expected-clean case
- **THEN** each such finding is counted and listed as a false positive
  for that case, with no judge call required

#### Scenario: Unmatched candidate finding is not auto-penalized

- **WHEN** a candidate finding matches no gold issue
- **THEN** it lowers only the proxy-precision number and is listed for
  potential promotion into the labels (real-but-unlabeled), mirroring
  parity mode's claimed-wins handling

#### Scenario: Cleanup-tier gold issue missed

- **WHEN** a gold issue tiered cleanup has no candidate match
- **THEN** it appears in an informational bucket and does not change
  `gold_recall_correctness`

### Requirement: Synthetic cases run against materialized throwaway repos

For corpus cases marked synthetic (no upstream repo), gold mode SHALL
materialize the case's diff into a freshly initialized throwaway git
repository (base content committed, diff applied as the change under
review) so the candidate reviews a real checkout; such cases SHALL be
skipped by parity tooling.

#### Scenario: Synthetic case reviewed

- **WHEN** gold mode runs a synthetic case
- **THEN** the candidate reviews a git checkout whose working diff equals
  the fixture's diff, and the run is judged against the case's labels
  like any other

#### Scenario: Parity tooling skips synthetics

- **WHEN** the parity baseline runner is pointed at a synthetic case
- **THEN** it refuses the case, identifying it as gold-mode-only
