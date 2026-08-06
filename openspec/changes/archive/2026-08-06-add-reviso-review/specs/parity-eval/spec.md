# parity-eval

## ADDED Requirements

### Requirement: Replay harness compares /reviso:review to /review on real PRs

The eval harness SHALL, for each corpus entry (repo, PR, base SHA, head
SHA): capture a `/review` baseline as the findings appearing in at least 2
of 3 runs on the PR; run `/reviso:review` locally against the identical
`base..head` range; and store both raw outputs and parsed findings as run
artifacts under `eval/runs/`.

#### Scenario: Baseline is majority-of-three

- **WHEN** a finding appears in only 1 of 3 `/review` runs
- **THEN** it is excluded from the parity baseline

#### Scenario: Identical diff under review

- **WHEN** the candidate run executes
- **THEN** it reviews exactly the PR's base..head range at the recorded
  SHAs, so both tools saw the same change

#### Scenario: Parse failure is loud

- **WHEN** a baseline run's output cannot be parsed into findings
- **THEN** the run fails with an error; the baseline is never silently
  reduced

### Requirement: Judge buckets findings as matched, missed, or claimed-win

An LLM judge SHALL compare baseline and candidate findings on underlying
root cause, matching conservatively (same defect, not similar wording), and
emit three buckets: matched (both found), missed (baseline-only), and
claimed-win (candidate-only). Claimed-wins SHALL NOT count as wins until
verified real. The judge SHALL be calibrated against a hand-labeled sample
before its parity numbers are trusted.

#### Scenario: Same bug, different words

- **WHEN** both tools flag the same off-by-one under different descriptions
  and nearby but unequal line anchors
- **THEN** the judge buckets it as matched

#### Scenario: Unverified extra finding

- **WHEN** the candidate reports a finding absent from the baseline
- **THEN** it is bucketed claimed-win and excluded from win metrics until a
  verification pass confirms it is real

### Requirement: Metrics treat misses as failures

The harness SHALL report per-run and aggregate: parity percentage
(matched / baseline findings), the explicit list of misses (each a P0
regression per the PRD), verified wins, and dismissal rate. Target values:
parity ~100%, dismissal rate <10%.

#### Scenario: Miss surfaces as regression

- **WHEN** a baseline finding has no candidate match
- **THEN** the run output lists it individually as a P0 regression, not
  only as a percentage

### Requirement: Two corpus tiers, only the public one committed

The corpus format SHALL support a public tier committed under
`eval/corpus/` and a private tier referenced by local path and never
committed. Published eval runs (docs/evals.md) SHALL come from the public
tier only.

#### Scenario: Private tier stays private

- **WHEN** the harness runs against the Vyttle (private) corpus
- **THEN** no corpus entry, diff content, or finding text from it lands in
  the repository
