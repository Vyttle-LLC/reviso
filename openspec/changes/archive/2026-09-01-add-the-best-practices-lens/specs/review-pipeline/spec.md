# review-pipeline (delta)

## ADDED Requirements

### Requirement: The best-practices finder is opt-in and source-anchored

When the user passed `--web`, Stage 3 SHALL launch a seventh blind
finder with the `best-practices` dimension, in the same parallel
fan-out as the others. It SHALL identify the change's ecosystem from
manifests and changed-line imports, query the web within the
web-lookup contract, and return candidates only in four classes: a
deprecated or removed API used on a changed line; a call pattern the
maintainer's documentation warns against, naming a consequence; a
published advisory against a version the change pins, where changed
code reaches the affected surface; and an idiom the official
documentation supersedes with a named replacement and a stated
consequence of the old form. Every candidate SHALL carry the fetched
source URL, a quoted passage of at most two sentences, and the version
range the claim applies to. The finder SHALL NOT gate its own output
and SHALL NOT cap its candidates, and the evidence obligation of the
other finders applies unchanged.

When `--web` was not passed, or the web tools are unavailable in the
environment, the finder SHALL NOT be launched and its ledger row SHALL
be `skipped` with that reason; the report SHALL name it under the
not-checked line. It SHALL NOT be recorded as `returned` with zero
candidates.

#### Scenario: Deprecated API on a changed line

- **WHEN** a changed line calls an API whose official documentation
  marks it deprecated in a version the manifest allows, and `--web` was
  passed
- **THEN** the finder returns a candidate citing the fetched
  documentation URL, the deprecation passage, and the version range

#### Scenario: Taste is not a class

- **WHEN** a fetched page recommends a different idiom without stating
  a consequence of the one on the changed line
- **THEN** the finder returns no candidate for it, because no class
  admits a replacement without a documented consequence

#### Scenario: Lens skipped without the flag

- **WHEN** the user runs `/reviso:audit` without `--web`
- **THEN** the ledger records `best-practices` as `skipped (no --web)`,
  the fan-out is six finders, and the coverage block names the lens as
  not checked with that reason

#### Scenario: Web tools unavailable

- **WHEN** `--web` was passed but the environment offers no web tool
- **THEN** the ledger records `skipped (web tools unavailable)` and the
  run does not treat the lens as clean

### Requirement: Best-practices candidates are gated on source and version applicability

The orchestrator SHALL treat as false-positive exclusion-list matches,
scored 0 with reason `exclusion-list`: a best-practices candidate with
no fetched URL or no quoted passage; a candidate whose claim does not
apply to the version the manifests pin or allow; and a superseded-idiom
candidate whose source states no consequence of the old form. Stage 4
evidence agents SHALL verify the changed line and the manifest version
against the code without web tools; the web is not re-consulted after
Stage 3. Severity SHALL follow the class: a removed API at P1 and a
deprecated one at P2; a documented misuse by its stated consequence; an
advisory at P1, P0 only when rated critical and the hunk carries the
external-input risk tag; a superseded idiom at P2 and never higher. A
shipped finding SHALL print `Source: <url>` after its fix line. The
existing "general code quality" exclusion SHALL remain unchanged.

#### Scenario: Version mismatch drops

- **WHEN** a candidate claims an API was removed in a major version the
  manifest excludes
- **THEN** the orchestrator scores it 0 with reason `exclusion-list`
  and the default report says nothing about it

#### Scenario: Unfetched citation drops

- **WHEN** a candidate's evidence carries a URL the finder's recorded
  fetch list does not contain
- **THEN** the orchestrator scores it 0 with reason `exclusion-list`

#### Scenario: Advisory severity follows reachability and input

- **WHEN** a manifest change pins a version with a critical advisory
  and the hunk calling the affected surface is tagged external-input
- **THEN** the finding ships at P0 with the advisory URL as its source

#### Scenario: Reported with its source

- **WHEN** a deprecated-API finding survives the gate
- **THEN** the report entry reads P2, cites `file:line`, and carries a
  `Source:` line naming the fetched documentation URL
