# review-pipeline (delta)

## ADDED Requirements

### Requirement: Stage 3 records a per-finder return ledger

Stage 3 SHALL record, for each finder it launches, one ledger row
capturing the lens name, the finder's outcome, and its candidate count.
The outcome SHALL be exactly one of: `returned` (the finder produced a
findings array, of any length including zero), `no result` (the finder
did not return, errored, or returned output that is not a findings
array), or `skipped` (the lens had nothing in scope). A finder for which
no row was recorded SHALL be treated as `no result` and MUST NOT be
treated as clean. An empty findings array SHALL be recorded as
`returned`, never as `no result`. The ledger SHALL be recorded as each
finder returns, before Stage 4 begins, and SHALL be available to the
report stage.

#### Scenario: Finder returns an empty array

- **WHEN** `reviso-finder-comments` returns `[]` on a diff with no
  comment-guidance violations
- **THEN** its ledger row records `returned` with a candidate count of
  zero, and the lens counts as checked

#### Scenario: Finder never returns

- **WHEN** one of the six finder Tasks fails to launch or returns
  unparseable output
- **THEN** its ledger row records `no result`, and the run does not treat
  that lens as clean

#### Scenario: Detector suite declined

- **WHEN** the user declines the permission prompt for the deterministic
  detector script, so no detector output is produced
- **THEN** the deterministic lens is recorded as `no result` rather than
  as a lens that ran and found nothing

### Requirement: Reported coverage is derived from recorded outcomes

The report stage SHALL derive its coverage claim from the Stage 3 ledger
and the deterministic-detector outcome, and SHALL NOT emit a fixed list of
lens names. Lenses recorded as `returned` SHALL be named as checked.
Lenses recorded as `no result` or `skipped` SHALL be named separately from
the checked lenses, each with its reason, and SHALL NOT be named as
checked. A lens with no ledger row SHALL NOT appear as checked. The
default report SHALL NOT print per-lens candidate counts; the separate
line naming failed or out-of-scope lenses SHALL be emitted only when at
least one lens is in those states.

#### Scenario: A finder fails on an otherwise clean run

- **WHEN** five finders return empty arrays, one finder returns `no
  result`, and no finding survives the gate
- **THEN** the report states that no issues were found, names the five
  lenses that ran as checked, and names the sixth as not checked with its
  reason — so the report is distinguishable from a run where all six ran
  clean

#### Scenario: Every lens ran

- **WHEN** all lenses are recorded as `returned` and nothing was skipped
- **THEN** the report emits the checked line naming those lenses and no
  not-checked line

#### Scenario: Lens out of scope

- **WHEN** the repository has no GitHub remote, so the prior-reviews lens
  has nothing in scope
- **THEN** the report names prior reviews as not checked, with that
  reason, rather than including it among the checked lenses

## MODIFIED Requirements

### Requirement: Per-finding verification with a confidence gate

Stage 4 SHALL score every LLM finding with an independent verifier using the
reference recipe's 0–100 confidence rubric (given verbatim) and
false-positive exclusion list. Findings scoring below 80 SHALL be silently
dropped. Deterministic findings bypass this stage.

The verifier SHALL additionally return a structured drop reason alongside
its score, drawn from a closed set corresponding to the checks it already
performs: `exclusion-list`, `pre-existing`, `rubric-score`, or `none` for a
candidate that cleared the gate. The reason SHALL be machine-readable and
SHALL NOT replace the one-sentence verdict. A verifier return that omits
the reason SHALL be treated as `rubric-score` below 80 and `none` at or
above 80, so the pipeline degrades rather than stalls. The gate's threshold
and its default silence about dropped candidates SHALL be unchanged by this
requirement.

#### Scenario: Low-confidence finding dropped

- **WHEN** a verifier scores a finding at 60
- **THEN** the finding does not appear in the report and no mention of it
  is made

#### Scenario: Known false-positive class dropped

- **WHEN** a finder flags a pre-existing issue on lines the change did not
  modify
- **THEN** the verifier scores it as a false positive per the exclusion
  list and it is gated out

#### Scenario: Drop reason is structured

- **WHEN** a verifier gates a candidate because it matches the
  false-positive exclusion list
- **THEN** its return carries the drop reason `exclusion-list`, and the
  default report still says nothing about the candidate

#### Scenario: Verifier omits the drop reason

- **WHEN** a verifier returns a score of 45 with no drop reason
- **THEN** the pipeline treats the reason as `rubric-score` and continues
