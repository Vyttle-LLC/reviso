# parity-eval

## RENAMED Requirements

- FROM: `### Requirement: Replay harness compares /reviso:review to /review on real PRs`
- TO: `### Requirement: Replay harness compares the Reviso tier under test to /review on real PRs`

## MODIFIED Requirements

### Requirement: Replay harness compares the Reviso tier under test to /review on real PRs

The eval harness SHALL, for each corpus entry (repo, PR, base SHA, head
SHA): capture a baseline from the built-in `/code-review` skill **pinned to
the medium level** with subagent fan-out enabled, as the findings appearing
in at least 2 of 3 runs on the PR; run **the Reviso review tier named by
the invocation** (`/reviso:review` or `/reviso:audit`) locally against the
identical `base..head` range; and store both raw outputs and parsed
findings as run artifacts under `eval/runs/`. Both the upstream review
level and the Reviso tier SHALL be pinned explicitly in the invocation,
never inherited from ambient session effort or from a default. When the
baseline output contains the skill's JSON findings contract, the harness
SHALL parse it directly (preserving each finding's `category` and
`verdict`); prose extraction is the fallback.

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

#### Scenario: Ambient default cannot swap the candidate

- **WHEN** the candidate runner is invoked without an explicit tier
- **THEN** the run exits with an error rather than selecting a tier by
  default

## ADDED Requirements

### Requirement: Comparisons require matching review tiers

The judge SHALL refuse to compare a baseline and a candidate whose
recorded review tiers differ, and SHALL refuse a candidate whose recorded
tier is absent — on the same footing as its existing refusals across
differing CLI versions and resolved model IDs. A tier roll is a
re-baseline event, not a comparison.

#### Scenario: Cross-tier comparison is refused

- **WHEN** a judge run is given a candidate recorded under one Reviso tier
  and a comparison recorded under another
- **THEN** it refuses the comparison and names the mismatch, rather than
  reporting a parity figure across two different pipelines

#### Scenario: Missing tier is refused

- **WHEN** a candidate artifact carries no recorded tier
- **THEN** the judge refuses it as non-comparable rather than assuming the
  tier
