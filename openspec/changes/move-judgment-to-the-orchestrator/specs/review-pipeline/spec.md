# review-pipeline

## MODIFIED Requirements

### Requirement: Parallel blind dimension finders, forked from the reference recipe

Stage 3 SHALL launch parallel finder agents, blind to each other, covering
the reference recipe's dimensions (conventions compliance, shallow-bug scan,
git-history context, prior-review guidance, code-comment guidance) plus an
anti-slop dimension. Each finder SHALL return structured candidates, each
with a concrete failure scenario and a suggested fix or rewrite.

Finders SHALL report every candidate they can evidence and SHALL NOT gate
their own output. In particular a finder SHALL NOT apply the false-positive
exclusion list, SHALL NOT withhold a candidate for being minor, uncertain,
or likely to be rejected, and SHALL NOT cap the number of candidates it
returns. Judgment about what ships belongs to the stage that can see the
whole change; a finder's obligation is evidence, not selection.

The evidence obligation is unchanged and is not a filter: every candidate
carries a `file:line`, a concrete failure scenario, and a suggested fix,
because those are what let a later stage adjudicate it.

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

#### Scenario: Finder does not pre-gate

- **WHEN** a finder identifies a candidate it believes is minor, or that it
  suspects matches a known false-positive class
- **THEN** it returns the candidate with its evidence rather than
  withholding it, and the orchestrator decides

#### Scenario: No candidate cap

- **WHEN** a finder evidences more candidates than any previous cap allowed
- **THEN** all of them are returned, and none is dropped for ordinal
  position

### Requirement: Per-finding verification with a confidence gate

Stage 4 SHALL re-examine every LLM candidate against the code with an
independent agent, and that agent SHALL return **findings of fact only**:
whether the cited lines are part of the change under review, what guards,
callers, or tests bear on the claimed failure scenario, and whether that
scenario reproduces against the real code. It SHALL NOT return a
confidence score, SHALL NOT return a drop reason, and SHALL NOT withhold or
gate a candidate. Deterministic findings bypass this stage.

The confidence gate SHALL be applied once, by the orchestrator, after
verification evidence is in hand. The orchestrator SHALL apply the
false-positive exclusion list and score each candidate on the 0–100
confidence rubric, drop candidates scoring below 80, and say nothing about
a dropped candidate in the default report. Because the orchestrator holds
every candidate at once, it — and only it — SHALL judge the rubric's
comparative bands, which ask how a candidate ranks relative to the rest of
the change.

The orchestrator SHALL record, per candidate, the score it assigned and the
reason for any drop, drawn from the closed set `exclusion-list`,
`pre-existing`, `rubric-score`, or `none` for a candidate that cleared the
gate. That record is what `--explain` reports; without the flag it is not
surfaced. The gate's threshold and its default silence about dropped
candidates SHALL be unchanged by this requirement.

The rubric and the false-positive exclusion list SHALL be inputs to the
orchestrator and SHALL NOT be required reading for any subagent, so no
stage can gate a candidate against a reference it failed to load.

#### Scenario: Low-confidence finding dropped

- **WHEN** the orchestrator scores a finding at 60
- **THEN** the finding does not appear in the report and no mention of it
  is made

#### Scenario: Known false-positive class dropped

- **WHEN** a finder flags a pre-existing issue on lines the change did not
  modify
- **THEN** the orchestrator scores it as a false positive per the exclusion
  list and it is gated out

#### Scenario: Verification returns evidence, not a verdict

- **WHEN** a Stage 4 agent examines a candidate it judges to be wrong
- **THEN** it returns what it found against the code — the guard that
  already handles the case, the caller that cannot reach it — and returns
  no score and no drop reason

#### Scenario: Comparative scoring uses the whole change

- **WHEN** the orchestrator scores a candidate against the rubric band that
  asks how important it is relative to the rest of the change
- **THEN** it judges with every candidate from every lens in hand, rather
  than delegating that comparison to an agent holding one candidate

#### Scenario: Drop record survives for diagnostics

- **WHEN** the orchestrator gates a candidate because it matches the
  false-positive exclusion list
- **THEN** it records the drop reason `exclusion-list` for `--explain`, and
  the default report still says nothing about the candidate

#### Scenario: References are not subagent inputs

- **WHEN** the pipeline runs in an environment where a subagent cannot read
  files at the plugin root
- **THEN** no candidate is gated against an unread rubric or exclusion
  list, because gating happens only in the orchestrator
