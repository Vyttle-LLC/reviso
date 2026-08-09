# parity-eval

## Purpose

The acceptance harness for the north star: on the same changes, `/reviso:review` catches every correctness-tier finding the built-in `/code-review` at medium catches, at comparable cost.

## Requirements

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
(matched / correctness-tier baseline findings), the explicit list of
correctness-tier misses (each a P0 regression per the PRD), verified wins,
and dismissal rate. Only baseline findings in the correctness tier SHALL
count toward parity and P0 misses; cleanup-tier baseline findings SHALL be
bucketed and reported informationally. A baseline finding with no category
SHALL be classified by the judge, resolving ambiguity to the correctness
tier. Target values: parity ~100% on the correctness tier, dismissal rate
<10%.

The tier split SHALL encode whether Reviso claims the lane, not the
literal correctness of the finding: a category belongs to the cleanup
family only while Reviso deliberately gates it. Consequently a category
SHALL leave the cleanup family when a lens ships that reports it, and the
list SHALL have exactly one definition shared by every mode, so parity and
gold cannot disagree about what counts as a regression.

#### Scenario: Correctness miss surfaces as regression

- **WHEN** a correctness-tier baseline finding has no candidate match
- **THEN** the run output lists it individually as a P0 regression, not
  only as a percentage

#### Scenario: Cleanup-tier miss is informational

- **WHEN** a cleanup-tier baseline finding (e.g. category `simplification`)
  has no candidate match
- **THEN** it appears in an informational bucket and does not reduce the
  parity percentage or produce a P0 regression

#### Scenario: A newly shipped lens leaves the cleanup family

- **WHEN** a lens ships that reports a category previously gated (as the
  duplication lens did in 0.3.0)
- **THEN** that category is removed from the shared cleanup list, and a
  baseline finding in it that the candidate misses becomes a listed
  regression rather than an informational miss

#### Scenario: Uncategorized finding fails toward P0 scope

- **WHEN** a baseline finding carries no category and the judge cannot
  clearly place it in the cleanup tier
- **THEN** it is treated as correctness-tier

### Requirement: Two corpus tiers, only the public one committed

The corpus format SHALL support a public tier committed under
`eval/corpus/` and a private tier referenced by local path and never
committed. Public-tier cases MAY carry a committed labels file under
`eval/corpus/labels/<case-id>.json` in the shared label schema, with
imported labels attributed to their source (origin, upstream license
vendored beside the labels, import date); private-tier labels stay
outside the repo in the same schema. Published eval runs (docs/evals.md)
SHALL come from the public tier only, and SHALL distinguish gold-mode
metrics (whole corpus, per release) from parity metrics (active subset,
re-baseline cadence).

The runners SHALL make the private tier actually runnable, not merely
describable: the corpus file SHALL be selectable, and paths inside a
corpus entry (labels, fixtures) SHALL resolve against that corpus file's
own directory, so a corpus living outside the repository carries its
labels beside it. A sweep SHALL pass its corpus selection down to the
per-case runners, so a loop cannot iterate one corpus while the runner
resolves ids against another.

#### Scenario: Private tier stays private

- **WHEN** the harness runs against the Vyttle (private) corpus
- **THEN** no corpus entry, diff content, or finding text from it lands in
  the repository

#### Scenario: Private-tier case resolves its labels

- **WHEN** a gold run is pointed at a corpus file outside the repository
  and the entry names a relative labels path
- **THEN** the labels resolve beside that corpus file, not under
  `eval/corpus/`

#### Scenario: Sweep and per-case runner agree on the corpus

- **WHEN** a sweep runs against a non-default corpus file
- **THEN** each per-case runner it invokes reads that same corpus file

#### Scenario: Imported labels carry provenance

- **WHEN** a public case's labels were imported from an external benchmark
- **THEN** the labels file names its origin and the vendored upstream
  license covers it

#### Scenario: Published metrics are not conflated

- **WHEN** docs/evals.md publishes results
- **THEN** gold-mode numbers and parity numbers are reported as distinct
  metrics, each naming the corpus slice it covers

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

### Requirement: CRB import re-pins real PRs and skips unresolvable ones loudly

The CRB importer SHALL derive each public corpus entry from the fixture's
source repo and PR number by resolving current base/head SHAs via the
GitHub API, and SHALL convert the fixture's gold issues into the shared
label schema. A fixture whose PR or SHAs cannot be resolved SHALL be
skipped with an explicit report line; the import SHALL never emit an
entry with unpinned or guessed SHAs, and SHALL NOT copy upstream diff
content into the repository.

#### Scenario: Resolvable PR becomes a pinned entry

- **WHEN** the importer processes a fixture whose PR still resolves
- **THEN** the emitted entry carries the resolved base/head SHAs and a
  labels file derived from the fixture's gold issues

#### Scenario: Unresolvable PR is skipped loudly

- **WHEN** a fixture's PR no longer resolves to SHAs
- **THEN** the importer reports the skip by name and emits no entry for it

### Requirement: The active parity subset is corpus data

Corpus entries SHALL support an optional `active_parity` boolean; parity
baseline tooling SHALL run only entries marked true, while gold mode
ignores the marker. The imported corpus SHALL mark a subset (~10–15
cases) spanning the corpus's languages and repos. (No CRB case is
expected-clean — the task-1.1 audit found all 50 carry gold issues —
so clean-case discipline is covered by gold mode's synthetic cases, not
the parity subset.)

#### Scenario: Parity run filters on the marker

- **WHEN** a parity sweep is launched over the public corpus
- **THEN** only `active_parity: true` entries incur baseline runs

#### Scenario: Gold sweep covers everything

- **WHEN** a gold-mode sweep is launched
- **THEN** every gold-labeled entry runs, regardless of `active_parity`
