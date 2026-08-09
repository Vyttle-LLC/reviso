# parity-eval (delta)

## MODIFIED Requirements

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
