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

### Requirement: Consolidated, severity-ranked report

The report stage SHALL dedupe overlapping findings, consolidate related
minor findings into single comments, and order the report
most-severe-first. The pipeline SHALL prefer silence over uncertain
findings: an uncertain finding does not ship.

#### Scenario: Duplicate findings merged

- **WHEN** two finders flag the same underlying defect
- **THEN** the report contains one finding citing the strongest evidence

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

### Requirement: Finder history access is bounded by the change under review

A finder that reads git history SHALL treat as inadmissible any evidence
reachable only through commits that are not ancestors of the change's head
— sibling branches, later commits on the same branch, and anything else
visible to `git log --all` but not to the change itself. A finding SHALL
NOT cite such a commit as evidence, and a finder that discovers one SHALL
proceed as though it were absent.

The change under review defines the world a reviewer can see. On a user's
real branch the constraint is inert, because there is no future to reach.
In evaluation it is load-bearing: every corpus case drawn from this
repository sits in an object store that also contains the commits which
later fixed the very issues under review, and a lens that reads them
reports a recall it did not earn.

#### Scenario: Future commits are inadmissible

- **WHEN** a history or prior-review finder encounters a commit that is
  not an ancestor of the change's head
- **THEN** it does not cite that commit as evidence, and any candidate
  resting solely on it is not returned

#### Scenario: Real-branch behaviour is unchanged

- **WHEN** a finder runs against a user's working branch, where no commit
  after the change's head exists
- **THEN** the bound excludes nothing and the lens behaves exactly as
  before

#### Scenario: Evaluation runs are not contaminated

- **WHEN** a corpus case is drawn from a repository whose object store
  contains the case's own future
- **THEN** the recorded candidate findings cite only evidence reachable
  from the case's head, so the measured recall reflects what the lens
  could see at review time
