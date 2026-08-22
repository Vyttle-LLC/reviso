# review-pipeline (delta)

## MODIFIED Requirements

### Requirement: Parallel blind dimension finders, forked from the reference recipe

Stage 3 SHALL launch parallel finder agents, blind to each other, covering
the reference recipe's dimensions (conventions compliance, shallow-bug scan,
git-history context, prior-review guidance, code-comment guidance) plus an
anti-slop dimension. Each finder SHALL return structured candidates, each
with a concrete failure scenario and a suggested fix or rewrite.

The anti-slop finder SHALL cover the P0 slop set (drift from existing
patterns, verbosity, reinvented utilities, duplication per the
duplication requirement below) plus every **admitted style lens**. A
style lens is admitted when it has shipped in `/reviso:style` for at
least one minor release, its gold true-positive / expected-clean pair
holds, and no false-positive report against it has been adjudicated
genuine; the admitted set SHALL be recorded in the repo and each
admitted lens SHALL keep the definition and evidence protocol the
style-command capability gives it — the two surfaces SHALL NOT drift.
`/reviso:review` is unchanged and keeps the P0 set.

Finders SHALL report every candidate they can evidence and SHALL NOT gate
their own output. In particular a finder SHALL NOT apply the false-positive
exclusion list, SHALL NOT withhold a candidate for being minor, uncertain,
or likely to be rejected, and SHALL NOT cap the number of candidates it
returns. Judgment about what ships belongs to the stage that can see the
whole change; a finder's obligation is evidence, not selection. The
style-local gates — the comments lens's absolute bar and its
written-convention override, the placeholder-text item, and the
no-baseline / no-search drops — are applied by the orchestrator at the
confidence gate, never by the finder; the shared exclusion list is
unchanged.

The evidence obligation is unchanged and is not a filter: every candidate
carries a `file:line`, a concrete failure scenario, and a suggested fix,
because those are what let a later stage adjudicate it.

#### Scenario: Finder fan-out

- **WHEN** Stage 3 runs on a non-trivial diff
- **THEN** all finder dimensions run in parallel, and each returned
  candidate carries a failure scenario and suggested fix

#### Scenario: Anti-slop finder scope

- **WHEN** the anti-slop finder reviews a hunk
- **THEN** it flags the P0 slop set and every admitted style lens
  relative to the codebase's own norms, each candidate carrying that
  lens's evidence protocol — deliberate repo style is not flagged

#### Scenario: Finder does not pre-gate

- **WHEN** a finder identifies a candidate it believes is minor, or that it
  suspects matches a known false-positive class
- **THEN** it returns the candidate with its evidence rather than
  withholding it, and the orchestrator decides

#### Scenario: No candidate cap

- **WHEN** a finder evidences more candidates than any previous cap allowed
- **THEN** all of them are returned, and none is dropped for ordinal
  position

#### Scenario: Style-local gate applied by the orchestrator

- **WHEN** the anti-slop finder returns a dead-weight candidate whose
  evidence records no search
- **THEN** the orchestrator scores it 0 with reason `no-search`, and the
  finder is not faulted for returning it

#### Scenario: Unadmitted lens stays out

- **WHEN** a style lens shipped in the most recent minor release only
- **THEN** the anti-slop finder does not apply it, and the audit's
  coverage block does not name it

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

For the anti-slop finder, Stage 3 SHALL additionally record one sub-row
per admitted style lens carrying that lens's candidate count and the
finder's outcome: an empty array yields `returned` with count zero for
every sub-row; a finder that never returns yields `no result` for every
sub-row. The report's coverage block names admitted lenses from these
sub-rows.

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

#### Scenario: Ported lens appears in coverage

- **WHEN** the anti-slop finder returns and the dead-weight lens is
  admitted
- **THEN** `Checked:` names dead weight alongside the finder's other
  lenses, from its sub-row

#### Scenario: Slop finder never returns

- **WHEN** the anti-slop finder's Task errors
- **THEN** its row and every admitted-lens sub-row read `no result`, and
  `Not checked:` names each
