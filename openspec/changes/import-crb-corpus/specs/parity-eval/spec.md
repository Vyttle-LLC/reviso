# parity-eval (delta)

## MODIFIED Requirements

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

#### Scenario: Private tier stays private

- **WHEN** the harness runs against the Vyttle (private) corpus
- **THEN** no corpus entry, diff content, or finding text from it lands in
  the repository

#### Scenario: Imported labels carry provenance

- **WHEN** a public case's labels were imported from an external benchmark
- **THEN** the labels file names its origin and the vendored upstream
  license covers it

#### Scenario: Published metrics are not conflated

- **WHEN** docs/evals.md publishes results
- **THEN** gold-mode numbers and parity numbers are reported as distinct
  metrics, each naming the corpus slice it covers

## ADDED Requirements

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
cases) spanning the corpus's languages and repos, including at least two
expected-clean cases.

#### Scenario: Parity run filters on the marker

- **WHEN** a parity sweep is launched over the public corpus
- **THEN** only `active_parity: true` entries incur baseline runs

#### Scenario: Gold sweep covers everything

- **WHEN** a gold-mode sweep is launched
- **THEN** every gold-labeled entry runs, regardless of `active_parity`
