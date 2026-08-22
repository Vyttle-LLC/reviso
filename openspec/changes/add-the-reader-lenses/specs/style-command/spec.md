# style-command (delta)

## MODIFIED Requirements

### Requirement: Ten style lenses, and no bug hunting

`/reviso:style` SHALL apply exactly thirteen lenses:

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

The command SHALL NOT report bugs, and SHALL NOT apply the bugs, history,
or code-comment-compliance lenses. Its report SHALL point users to
`/reviso:review` and `/reviso:audit` for bug-finding coverage. Each lens
SHALL get a coverage-ledger row recorded as it resolves, exactly as the
sibling verbs keep theirs.

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
- **THEN** the ledger holds one row per lens — thirteen lens rows plus
  the deterministic row — and the report's coverage block is derived
  from them

#### Scenario: Swallowed error that masks a failure

- **WHEN** the change adds a catch that logs and continues, and the
  swallowed error would leave the caller with a wrong result
- **THEN** the error-handling lens reports only the shape divergence
  (with the repo's surfacing idiom cited), never the masked failure

### Requirement: Every style finding cites the repo baseline it was measured against

Style judgments SHALL be calibrated against the repository's own norms,
never against absolute thresholds or general taste, with exactly two
carve-outs: the comments lens's earn-its-place bar and the AI-tells
lens's placeholder-text item are absolute (their own requirements below
define the override). For every other lens:

- A **repo-style drift**, **naming**, or **error-handling** finding MUST
  cite at least two existing examples of the established pattern by
  `file:line` in its evidence; with no cited baseline there is no
  finding.
- Cited examples MUST be in the same language as the changed code. A
  norm demonstrated in one language of a polyglot repo SHALL NOT be
  cited against code in another.
- An **outlier length** finding MUST name the comparable functions or
  comments in this repo it was measured against and their approximate
  sizes; fixed numeric thresholds (e.g. "functions over N lines") SHALL
  NOT be used as evidence.
- An **over-engineering** finding MUST cite the evidence of absence by
  `file:line`: the abstraction's only consumer, the type or call sites
  that make the defended state impossible, or the shim's missing second
  consumer. When the repo demonstrably builds this kind of code the same
  defensive way (two existing examples), it is the repo's norm and not a
  finding.
- A **derived state** finding MUST cite every write site of the copy,
  quoting the lockstep assignment that makes it a projection of its
  source, and every read site; a candidate without the lockstep
  citation SHALL be dropped at self-verification.
- A deliberate, established style in this repo is never a finding: when
  the repo itself is verbose, verbose new code matches its norms.

#### Scenario: Drift finding without a cited baseline

- **WHEN** a candidate claims the change drifts from repo style but no
  existing `file:line` examples of the established pattern are cited
- **THEN** the candidate is dropped and does not ship

#### Scenario: Long method in a long-method codebase

- **WHEN** a changed function is long, and comparable functions in the
  repo run about the same length
- **THEN** no outlier-length finding ships

#### Scenario: Defensive repo keeps its defenses

- **WHEN** the change adds a null check the types make redundant, and two
  existing files handle the same shape with the same redundant check
- **THEN** no over-engineering finding ships

#### Scenario: Cross-language baseline is rejected

- **WHEN** a naming candidate against a TypeScript file cites two Swift
  files as the repo's naming norm
- **THEN** the candidate scores 0 at self-verification and does not ship

#### Scenario: Manager suffix in a Manager codebase

- **WHEN** the change adds `SessionManager`, and two existing
  same-language files name the same kind of service `*Manager`
- **THEN** no naming finding ships

#### Scenario: Lockstep copy with one reader

- **WHEN** the change adds a stored `messages` field assigned
  `platform?.messages` at every site that assigns `platform`, and one
  site reads it
- **THEN** a derived-state finding ships citing each lockstep write and
  the read, with the inline projection in `suggested_fix`

#### Scenario: Independently written field is not derived

- **WHEN** two stored fields are usually equal but at least one write
  site sets them from different sources
- **THEN** no derived-state finding ships
