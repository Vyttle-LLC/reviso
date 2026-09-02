# style-command (delta)

## ADDED Requirements

### Requirement: The best-practices lens runs opt-in under `--web`

When the user passed `--web`, `/reviso:style` SHALL apply a
best-practices lens **in addition to the sixteen always-on lenses**,
inline in the same single pass — no subagent. The lens SHALL identify
the change's ecosystem from manifests and changed-line imports, query
the web within the web-lookup contract, and record candidates only in
four classes: a deprecated or removed API used on a changed line; a
call pattern the maintainer's documentation warns against, naming a
consequence; a published advisory against a version the change pins,
where changed code reaches the affected surface; and an idiom the
official documentation supersedes with a named replacement and a stated
consequence of the old form. Every candidate SHALL carry the fetched
source URL, a quoted passage of at most two sentences, and the version
range the claim applies to.

The lens is ecosystem-relative: it SHALL be a named exception to the
cardinal rule, measured against the ecosystem's own documentation and
never against the repository's norms. Its `dimension` is
`best-practices`, and the feedback mapping SHALL carry it as its own
lens value.

When `--web` was not passed, or no web tool is available in the
environment, the lens SHALL NOT run, its ledger row SHALL be `skipped`
with that reason, and the coverage block SHALL name it under the
not-checked line. It SHALL NOT be recorded as `returned` with zero
candidates.

#### Scenario: Deprecated API on a changed line

- **WHEN** a changed line calls an API whose official documentation
  marks it deprecated in a version the manifest allows, and `--web` was
  passed
- **THEN** the report carries a best-practices finding citing the
  fetched documentation URL on a `Source:` line, the deprecation
  passage, and the version range

#### Scenario: Taste is not a class

- **WHEN** a fetched page recommends a different idiom without stating
  a consequence of the one on the changed line
- **THEN** no candidate is recorded, because no class admits a
  replacement without a documented consequence

#### Scenario: Lens skipped without the flag

- **WHEN** the user runs `/reviso:style` without `--web`
- **THEN** the ledger records the lens `skipped (no --web)`, the
  sixteen always-on lenses run unchanged, and the coverage block names
  the lens as not checked with that reason

#### Scenario: Ledger family of its own

- **WHEN** the coverage block renders lens families
- **THEN** best practices is its own family (`ecosystem`), always named
  as itself, like deterministic

### Requirement: Best-practices candidates are gated on source and version applicability

At the Step 4 gate, a best-practices candidate with no fetched URL or
no quoted passage SHALL score 0 with the drop reason `no-source`,
recorded beside the lane's other protocol reasons. A candidate whose
claim does not apply to the version the manifests pin or allow, and a
superseded-idiom candidate whose source states no consequence of the
old form, SHALL score 0 as exclusion-list matches. Surviving candidates
SHALL be scored on the style rubric as evidence quality: source
fetched, passage exact, version applicable, changed line really calls
the cited symbol. The web SHALL NOT be re-consulted at the gate.

#### Scenario: Unfetched citation drops

- **WHEN** a candidate cites a URL that appears in no recorded fetch of
  this run
- **THEN** it scores 0 with reason `no-source` and the default report
  says nothing about it

#### Scenario: Version mismatch drops

- **WHEN** a candidate claims an API was removed in a major version the
  manifests exclude
- **THEN** it scores 0 as an exclusion-list match

## MODIFIED Requirements

### Requirement: Style severity is capped below blocking

Style findings SHALL be P2 by default and P1 only when the finding
actively misleads: a wrong comment, a shadowed utility with different
behavior, duplicated copies that have already diverged in behavior, or a
test that appears to cover behavior but cannot fail. The style lenses
SHALL NOT emit P0, with one exception: best-practices findings keep
their own class band — a removed API at P1 and a deprecated one at P2; a
documented misuse by its stated consequence; an advisory at P1, and P0
only when rated critical and the changed code takes external input; a
superseded idiom at P2 and never higher — the way deterministic
detector findings keep their own severities, because both report
documented facts rather than style judgment.

#### Scenario: Ordinary slop finding

- **WHEN** a verbose-but-correct block is flagged
- **THEN** it ships at P2

#### Scenario: Comment that misleads

- **WHEN** a changed comment asserts behavior the code does not have
- **THEN** the finding may ship at P1

#### Scenario: Test that cannot fail

- **WHEN** a changed test asserts only the value its own mock was
  configured to return
- **THEN** the finding may ship at P1, because the apparent coverage is
  itself misleading

#### Scenario: Critical advisory outranks the style cap

- **WHEN** `--web` was passed and a manifest change pins a version with
  a critical advisory whose affected surface the changed code exposes
  to external input
- **THEN** the finding may ship at P0 with its advisory URL, the class
  band having precedence over the style cap
