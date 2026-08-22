# style-command (delta)

## MODIFIED Requirements

### Requirement: Ten style lenses, and no bug hunting

`/reviso:style` SHALL apply exactly sixteen lenses: the thirteen defined
by `add-the-reader-lenses` (anti-slop, comments, duplication,
conventions, repo-style drift, outlier length, over-engineering, dead
weight, test slop, AI tells, derived state, naming, error handling),
unchanged in definition, plus three further lenses (numbered
fourteen to sixteen in the command):

1. **Stale docs** — existing prose the change made false: README,
    CLAUDE.md / AGENTS.md, CHANGELOG entries, ADRs, and doc comments on
    a signature the change altered. The finding anchors on the changed
    line that falsified the prose and quotes the contradicted sentence
    verbatim in `evidence`. A missing doc update is never a finding;
    only a contradiction is. Changed comments stay with the comments
    lens.
2. **Surface area** — exposure without a consumer: a new `export` /
    `public` member with callers only inside its own module, a widened
    signature (added parameter, new optional) nothing passes, a return
    type broadened beyond what any caller reads. The dead-weight
    recorded-search protocol applies, searching for external consumers.
3. **Type slop** — a loosened type where the repo types the same kind of
    value precisely: `any` / `Any` / `interface{}`, a force-unwrap or
    cast the surrounding code makes unnecessary, a stringly-typed enum,
    an optional that is never absent. Convention-relative; a configured
    lint rule already covering the case, or an inline suppression, clears
    it.

The command SHALL NOT report bugs, and SHALL NOT apply the bugs, history,
or code-comment-compliance lenses. Its report SHALL point users to
`/reviso:review` and `/reviso:audit` for bug-finding coverage. Each lens
SHALL get a coverage-ledger row recorded as it resolves, exactly as the
sibling verbs keep theirs. The default report's coverage block SHALL
render lenses by family — shape (drift, length, over-engineering,
surface area), text (comments, AI tells, naming, stale docs), reuse
(anti-slop, duplication, dead weight, derived state), tests (test
slop) — plus the deterministic row, naming an individual lens only when
its outcome differs from its family's; `--explain` SHALL keep per-lens
counts.

#### Scenario: A bug is noticed mid-review

- **WHEN** the style pass happens to notice a likely bug in a changed hunk
- **THEN** no bug finding ships; the report's scope note directs the user
  to `/reviso:review` or `/reviso:audit`

#### Scenario: Duplication bar matches the sibling surfaces

- **WHEN** `/reviso:style` reviews a diff containing the same predicate
  added at five call sites
- **THEN** it ships the same single consolidated duplication finding the
  audit pipeline would, with every occurrence cited and the helper named

#### Scenario: Every lens has a ledger row

- **WHEN** a style review completes
- **THEN** the ledger holds one row per lens — sixteen lens rows plus
  the deterministic row — and the report's coverage block is derived
  from them, rendered by family

#### Scenario: One lens in a family did not resolve

- **WHEN** every text-family lens returned except stale docs, which has
  a `no result` row
- **THEN** `Checked:` names the text family and `Not checked:` names
  "stale docs (no result)" individually

#### Scenario: Contradicted README sentence

- **WHEN** the change renames a CLI flag and the README still documents
  the old name
- **THEN** a stale-docs finding ships anchored on the renaming line,
  quoting the README sentence, at P1

#### Scenario: Missing changelog entry is not a finding

- **WHEN** the change adds a feature and CHANGELOG.md has no entry for it
- **THEN** no stale-docs finding ships

#### Scenario: Export with only an internal caller

- **WHEN** the change exports a function whose only callers, by recorded
  search, are in the same module
- **THEN** a surface-area finding ships with the search stated in
  evidence and the narrowed visibility in `suggested_fix`

#### Scenario: any in a typed repo

- **WHEN** the change types a payload `any`, two same-language files
  type the same payload with a named interface, and no lint rule covers
  `any`
- **THEN** a type-slop finding ships citing both

#### Scenario: Suppressed any is silenced

- **WHEN** the change types a value `any` under an inline lint disable
- **THEN** no type-slop finding ships; the exclusion list's explicitly-
  silenced rule holds
