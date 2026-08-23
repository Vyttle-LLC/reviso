# style-command (delta)

## MODIFIED Requirements

### Requirement: Thirteen style lenses, and no bug hunting

`/reviso:style` SHALL apply exactly sixteen lenses:

1. **Anti-slop** — drift from codebase patterns, ~3× verbosity, and
   reimplementing an existing utility (cited, or it is not a finding),
   as specified for the pipeline's anti-slop finder. Comment slop is no
   longer this lens's concern — it moved to the comments lens below.
2. **Comments** — every changed comment measured against the absolute
   earn-its-place bar (see the dedicated requirement below), with the
   tightened rewrite or deletion in `suggested_fix`.
3. **Duplication** — the same 4-or-more / exactly-3 / 2-or-fewer bar,
   helper-naming fix requirement, and search protocol as the pipeline's
   anti-slop finder and `/reviso:review`, with `/reviso:review`'s
   below-bar silence at reporting time; the three surfaces SHALL NOT
   drift in the item's definition or thresholds, while severity and
   gating remain each surface's own.
4. **Conventions** — compliance with CLAUDE.md / AGENTS.md guidance and
   lint configs governing changed paths, code-shaped rules only.
5. **Repo-style drift** — the change writes this kind of code differently
   from how the repo demonstrably writes it (module layout, test
   structure, control-flow shape). Naming and error-handling shape are
   the dedicated lenses below, not drift's.
6. **Outlier length** — a method/function or comment far outside the size
   of comparable units in this repo.
7. **Over-engineering** — machinery the change builds that nothing needs:
   abstractions with a single consumer (an interface, factory, or config
   knob serving one caller), defensive handling of states the types or
   call sites make impossible, backwards-compatibility shims with no
   second consumer.
8. **Dead weight** — code the change adds that nothing uses, scoped to
   what linters cannot see (see the dedicated requirement below).
9. **Test slop** — tests that cannot fail (tautological assertions,
   asserting the value a mock was just configured to return), mocking the
   subject under test, and sleep-based waits where the repo demonstrates
   a deterministic waiting idiom.
10. **AI tells** — text artifacts of machine generation: temporal or
    comparative naming (`newHelper`, `enhancedFoo`, `utils2`),
    changelog-style comments ("// Fixed bug where…"), placeholder text
    ("In a real implementation…"), and emoji or tonal flourishes foreign
    to the repo's own text.
11. **Derived state** — a stored value the change adds or writes that is
    always a projection of another stored value, kept in lockstep at
    every write site; also a cached or memoized value with a single
    reader. The fix is the projection computed at the read site, or a
    computed property/getter in the repo's idiom when there are several.
12. **Naming** — a name the change introduces that hedges, lies, or
    diverges from how this repo names the same kind of thing: generic
    nouns (`data`, `result`, `info`), verb-less handlers, suffixes the
    repo does not use (`Manager`, `Helper`, `Util`), booleans not phrased
    as predicates, and names asserting behavior the code does not have.
13. **Error handling** — the change handles errors in a shape the repo
    does not: swallow-and-log where the repo surfaces, an empty catch,
    a rethrow that adds no context where the repo wraps, a generic
    message where the repo's are specific, or a try/catch around code
    that cannot throw. Shape only — an error that a swallow actually
    hides is a bug and belongs to `/reviso:review`.
14. **Stale docs** — existing prose the change made false: README,
    CLAUDE.md / AGENTS.md, CHANGELOG entries, ADRs, and doc comments on
    a signature the change altered. The finding anchors on the changed
    line that falsified the prose and quotes the contradicted sentence
    verbatim in `evidence`. A missing doc update is never a finding;
    only a contradiction is. Changed comments stay with the comments
    lens.
15. **Surface area** — exposure without a consumer: a new `export` /
    `public` member with callers only inside its own module, a widened
    signature (added parameter, new optional) nothing passes, a return
    type broadened beyond what any caller reads. The dead-weight
    recorded-search protocol applies, searching for external consumers.
16. **Type slop** — a loosened type where the repo types the same kind
    of value precisely: `any` / `Any` / `interface{}`, a force-unwrap
    or cast the surrounding code makes unnecessary, a stringly-typed
    enum, an optional that is never absent. Convention-relative; a
    configured lint rule already covering the case, or an inline
    suppression, clears it.

The command SHALL NOT report bugs, and SHALL NOT apply the bugs, history,
or code-comment-compliance lenses. Its report SHALL point users to
`/reviso:review` and `/reviso:audit` for bug-finding coverage. Each lens
SHALL get a coverage-ledger row recorded as it resolves, exactly as the
sibling verbs keep theirs. The default report's coverage block SHALL
render lenses by family — shape (drift, length, over-engineering,
conventions, error handling, surface area), text (comments, AI tells,
naming, stale docs), reuse (anti-slop, duplication, dead weight, derived
state), tests (test slop) — plus the deterministic row, naming an
individual lens only when its outcome differs from its family's;
`--explain` SHALL keep per-lens counts.

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

#### Scenario: Swallowed error that masks a failure

- **WHEN** the change adds a catch that logs and continues, and the
  swallowed error would leave the caller with a wrong result
- **THEN** the error-handling lens reports only the shape divergence
  (with the repo's surfacing idiom cited), never the masked failure

#### Scenario: One lens in a family did not resolve

- **WHEN** every text-family lens returned except stale docs, which has
  a `no result` row
- **THEN** `Checked:` names the text family's other lenses individually
  and `Not checked:` names "stale docs (no result)"

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
