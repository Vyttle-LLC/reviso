# style-command

## Purpose

The `/reviso:style` verb: a single-pass, style-only review — AI slop, drift from the repo's own norms, comment and method length, duplication, over-engineering, dead weight, test slop, AI tells, derived state, naming, error-handling shape — calibrated against the codebase itself, never against absolute thresholds, with exactly two named exceptions (the comments lens's earn-its-place bar and placeholder text).
## Requirements
### Requirement: `/reviso:style` is a single-pass, style-only review

The plugin SHALL provide `/reviso:style`, a review performed entirely by
the command's own session (no subagents), pinned to the `opus` tier alias
(D1), assembling its mock PR by the same deterministic sequence the other
verbs use (see mock-pr-assembly). Scope (`base..HEAD` plus uncommitted
changes, `--base`), the report-only contract (`--out`), and `--explain`
diagnostics are the every-command obligations of review-command, which
bind this verb identically.

#### Scenario: Style spawns no agents

- **WHEN** `/reviso:style` runs
- **THEN** no subagent is launched; the session performs assembly,
  detection, review, self-verification, and reporting itself

### Requirement: Sixteen style lenses, and no bug hunting

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

### Requirement: Style severity is capped below blocking

Style findings SHALL be P2 by default and P1 only when the finding
actively misleads: a wrong comment, a shadowed utility with different
behavior, duplicated copies that have already diverged in behavior, or a
test that appears to cover behavior but cannot fail. The style lenses
SHALL NOT emit P0. Deterministic detector findings keep their own
severities.

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

### Requirement: The style command reuses the shared harness unchanged

`/reviso:style` SHALL run the deterministic detector suite before its own
pass, record candidates in the shared finding schema, self-verify every
candidate against the false-positive exclusion list and the confidence
rubric, and silently drop candidates scoring below 80. Its reporting
policy SHALL match `/reviso:review`: no finding below P2 ships, related
findings are consolidated, at most 8 findings ship most-severe-first, and
`--explain` carries the ledger and gated candidates per the shared
diagnostics requirement.

#### Scenario: Detectors run first and free

- **WHEN** a style review starts
- **THEN** the deterministic detectors complete against the diff before
  the lens pass, consuming no model tokens

#### Scenario: Confidence gate applies

- **WHEN** a style candidate scores 79 against the rubric
- **THEN** it is silently dropped, appearing only in `--explain`
  diagnostics when that flag was passed

### Requirement: The comments lens applies an absolute earn-its-place bar

A changed comment SHALL be judged against an absolute bar, not the repo's
demonstrated habits: a comment earns its place only when the code cannot
be made to say the same thing — through naming, extraction, or types —
and even then it SHALL be as short as the point allows. Comments that
restate the code, narrate control flow, or pad a necessary point with
generated filler are findings, with the tightened rewrite (or deletion)
in `suggested_fix`. The only override is a written convention: CLAUDE.md
/ AGENTS.md guidance or a lint rule governing the changed paths that
demands the comment shape in question (e.g. mandatory doc comments).
Demonstrated verbosity in the repo's existing comments SHALL NOT clear a
candidate. This override SHALL be enforced as a style-command-local gate;
the shared false-positive exclusion list is unchanged and other surfaces
keep their convention-relative comment judgment.

#### Scenario: Verbose repo does not clear a bloated comment

- **WHEN** a changed comment restates its function's behavior, and the
  repo's existing comments are similarly verbose but no written
  convention demands it
- **THEN** the finding ships, with the tightened rewrite or deletion in
  `suggested_fix`

#### Scenario: Written convention overrides the bar

- **WHEN** a changed doc comment matches a shape that a CLAUDE.md rule or
  a configured lint rule (e.g. require-jsdoc) governing the changed paths
  explicitly demands
- **THEN** no comments finding ships

#### Scenario: Genuinely complex code earns a tight comment

- **WHEN** a changed comment states a constraint the code cannot express
  and is as short as that point allows
- **THEN** no comments finding ships

### Requirement: Dead weight is flagged only beyond linter coverage

The dead-weight lens SHALL flag only unused code that linters,
typecheckers, and compilers cannot see, and SHALL read the lint configs
governing the changed paths to know what is already covered. In scope:
added helpers or exports with no caller anywhere in the repo, parameters
accepted but never read, flags or config keys never consumed, and
branches whose condition the surrounding code makes impossible. Out of
scope regardless of lint config: unused imports and unused locals — the
exclusion list's linter-territory rule stands. Evidence MUST state the
search performed (the identifiers grepped) and its empty result; a
dead-weight candidate without that recorded search SHALL be dropped at
self-verification.

#### Scenario: Unused import stays excluded

- **WHEN** the change adds an import nothing references
- **THEN** no dead-weight finding ships; that is linter territory

#### Scenario: Exported helper with no caller

- **WHEN** the change adds an exported helper, and a repo-wide search for
  its identifier finds no consumer
- **THEN** a dead-weight finding ships, with the search and its empty
  result stated in evidence

#### Scenario: Candidate without a recorded search

- **WHEN** a dead-weight candidate's evidence does not state what was
  searched and that it came back empty
- **THEN** the candidate scores 0 at self-verification and does not ship

### Requirement: AI-tell and test-slop findings quote their evidence

An **AI tells** finding SHALL quote the tell verbatim. Placeholder text
("In a real implementation…", "In production you would…") is a finding
absolutely. Every other tell — temporal/comparative naming,
changelog-style comments, emoji, tonal flourishes — is judged against the
repo's own text: a repo that demonstrably uses the pattern (two existing
examples) keeps it. A **test slop** finding SHALL quote the assertion (or
wait) and state concretely why it cannot fail or what it actually
exercises instead of the subject; `suggested_fix` sketches the test as it
should be written, or its deletion.

#### Scenario: Placeholder text is absolute

- **WHEN** the change commits a comment reading "in a real
  implementation, this would validate the token"
- **THEN** the finding ships regardless of the repo's own comment style

#### Scenario: Emoji in an emoji codebase

- **WHEN** the change adds an emoji-decorated log line, and two existing
  files log the same way
- **THEN** no AI-tells finding ships

#### Scenario: Asserting the mock

- **WHEN** a changed test configures a mock to return a value and then
  asserts the subject returned that value without exercising any logic of
  the subject itself
- **THEN** a test-slop finding ships, quoting the assertion and naming
  what the test actually exercises

