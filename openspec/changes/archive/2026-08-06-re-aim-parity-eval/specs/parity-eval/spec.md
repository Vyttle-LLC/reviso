# parity-eval (delta)

## MODIFIED Requirements

### Requirement: Replay harness compares /reviso:review to /review on real PRs

The eval harness SHALL, for each corpus entry (repo, PR, base SHA, head
SHA): capture a baseline from the built-in `/code-review` skill **pinned to
the medium level** with subagent fan-out enabled, as the findings appearing
in at least 2 of 3 runs on the PR; run `/reviso:review` locally against the
identical `base..head` range; and store both raw outputs and parsed
findings as run artifacts under `eval/runs/`. The review level SHALL be
pinned explicitly in the invocation, never inherited from ambient session
effort. When the baseline output contains the skill's JSON findings
contract, the harness SHALL parse it directly (preserving each finding's
`category` and `verdict`); prose extraction is the fallback.

#### Scenario: Baseline is majority-of-three

- **WHEN** a finding appears in only 1 of 3 baseline runs
- **THEN** it is excluded from the parity baseline

#### Scenario: Identical diff under review

- **WHEN** the candidate run executes
- **THEN** it reviews exactly the PR's base..head range at the recorded
  SHAs, so both tools saw the same change

#### Scenario: Parse failure is loud

- **WHEN** a baseline run's output cannot be parsed into findings
- **THEN** the run fails with an error; the baseline is never silently
  reduced

#### Scenario: Fallback-mode baseline is rejected

- **WHEN** a baseline run's output self-reports the skill's single-pass
  inline fallback (fan-out did not run)
- **THEN** the run fails with an error; a degraded pipeline is never
  recorded as the baseline

#### Scenario: Ambient effort cannot swap the target

- **WHEN** the baseline runner is invoked without an explicit level override
- **THEN** the executed review command names the medium level explicitly

### Requirement: Metrics treat misses as failures

The harness SHALL report per-run and aggregate: parity percentage
(matched / correctness-tier baseline findings), the explicit list of
correctness-tier misses (each a P0 regression per the PRD), verified wins,
and dismissal rate. Only baseline findings in the correctness tier SHALL
count toward parity and P0 misses; cleanup-tier baseline findings
(simplification, efficiency, reuse, altitude, conventions, test-coverage
and similar) SHALL be bucketed and reported informationally. A baseline
finding with no category SHALL be classified by the judge, resolving
ambiguity to the correctness tier. Target values: parity ~100% on the
correctness tier, dismissal rate <10%.

#### Scenario: Correctness miss surfaces as regression

- **WHEN** a correctness-tier baseline finding has no candidate match
- **THEN** the run output lists it individually as a P0 regression, not
  only as a percentage

#### Scenario: Cleanup-tier miss is informational

- **WHEN** a cleanup-tier baseline finding (e.g. category `simplification`)
  has no candidate match
- **THEN** it appears in an informational bucket and does not reduce the
  parity percentage or produce a P0 regression

#### Scenario: Uncategorized finding fails toward P0 scope

- **WHEN** a baseline finding carries no category and the judge cannot
  clearly place it in the cleanup tier
- **THEN** it is treated as correctness-tier

## ADDED Requirements

### Requirement: Baseline runs record comparability metadata

Each baseline run SHALL record, in a metadata artifact beside its outputs:
the Claude Code CLI version, the pinned review level, and the resolved
model ID. The harness SHALL treat two runs as comparable only when all
three match, and SHALL treat a CLI version roll as a re-baseline event
(corpus re-run, diff, re-tune), extending the existing model-tier-roll
rule.

#### Scenario: Version roll invalidates comparison

- **WHEN** a judge invocation is given a baseline and prior runs whose
  recorded CLI versions differ
- **THEN** the harness refuses the comparison (or labels it
  non-comparable) rather than reporting parity numbers across versions

#### Scenario: Metadata is complete or the run fails

- **WHEN** a baseline run finishes without a recorded CLI version, level,
  or resolved model
- **THEN** the run fails rather than producing an artifact with unknown
  identity

### Requirement: Upstream drift detection is behavioral, and proprietary text stays out of the repo

The harness SHALL detect upstream `/code-review` drift by re-running corpus
baselines on a new CLI version and diffing against recorded runs — not by
hashing any plugin file. The repository SHALL carry the extraction method
for the CLI-embedded skill text, a content hash of the extracted text per
inspected CLI version, and a factual structural summary (levels, angle
names, caps, stances); verbatim extracted text SHALL NOT be committed. The
2026-08-03 marketplace snapshot SHALL be marked superseded and retained as
history.

#### Scenario: Drift is caught by re-baselining

- **WHEN** a new CLI version changes the built-in review's behavior
- **THEN** the next corpus baseline run on that version, diffed against
  prior recorded runs, surfaces the change — without reference to the
  marketplace plugin file

#### Scenario: No verbatim skill text in-repo

- **WHEN** a new CLI version's skill text is extracted for inspection
- **THEN** only its hash and structural summary are committed; the
  extracted text itself stays local, like the private corpus

### Requirement: A labeled multi-run calibration case seeds the re-aimed judge

The private corpus tier SHALL include a calibration entry consisting of one
change reviewed by all three of: `/reviso:review`, built-in `/code-review`
medium, and built-in `/code-review` xhigh — with a labels file recording,
per finding: source run, category, and a hand verdict (real, not-real, or
out-of-lane). The judge's category bucketing and matching SHALL be checked
against these labels before its parity numbers are trusted.

#### Scenario: Judge disagrees with labels

- **WHEN** the judge's bucketing of the calibration entry's findings
  disagrees with the hand labels beyond the documented tolerance
- **THEN** parity numbers from that judge configuration are not published

#### Scenario: Calibration entry stays private

- **WHEN** the calibration entry is added
- **THEN** no diff content, finding text, or repository identity from it
  lands in this repository
