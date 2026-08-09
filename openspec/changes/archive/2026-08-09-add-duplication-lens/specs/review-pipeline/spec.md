# review-pipeline (delta)

## MODIFIED Requirements

### Requirement: Parallel blind dimension finders, forked from the reference recipe

Stage 3 SHALL launch parallel finder agents, blind to each other, covering
the reference recipe's dimensions (conventions compliance, shallow-bug scan,
git-history context, prior-review guidance, code-comment guidance) plus an
anti-slop dimension. Each finder SHALL return structured candidates, each
with a concrete failure scenario and a suggested fix or rewrite.

#### Scenario: Finder fan-out

- **WHEN** Stage 3 runs on a non-trivial diff
- **THEN** all finder dimensions run in parallel, and each returned
  candidate carries a failure scenario and suggested fix

#### Scenario: Anti-slop finder scope

- **WHEN** the anti-slop finder reviews a hunk
- **THEN** it flags only the P0 slop set relative to the codebase's own
  norms (drift from existing patterns, verbosity, reinvented utilities,
  borderline comment slop, and duplication per the duplication
  requirement below) — deliberate repo style is not flagged

## ADDED Requirements

### Requirement: The duplication lens ships helper extractions above a calibrated bar

The anti-slop dimension SHALL flag duplication in both directions —
new code reimplementing something the repository already has, and code
duplicated within the change itself — only when the diff reaches the bar.
The unit is a rule-encoding expression or predicate, a declaration or
definition, or a verbatim or near-verbatim block, and new occurrences
SHALL be counted together with any pre-existing copies. Four or more
occurrences SHALL ship. Exactly three occurrences SHALL ship only when
the duplicated unit encodes a rule that can change — a predicate, a
policy constant, a shared type or contract — and SHALL stay silent when
the similarity is incidental, such as setup or assertion scaffolding. Two
or fewer occurrences SHALL NOT ship regardless of how long the copied
block is. Every shipped duplication finding SHALL cite each occurrence by
`file:line`, state the drift-risk failure scenario concretely, and give a
`suggested_fix` naming the helper (name, signature, proposed location
consistent with the repository's layout) plus the rewrite of one call
site. Below-bar duplication SHALL NOT be reported at all. Before clearing
any added block as non-duplicative, the finder SHALL search the
repository for that block's distinctive identifiers.

#### Scenario: Rule expression repeated across call sites

- **WHEN** the diff adds the same collision predicate at five call sites
  plus a closure
- **THEN** one duplication finding ships, citing every occurrence, with a
  named shared helper and the drift-risk scenario

#### Scenario: Third verbatim copy of an existing utility

- **WHEN** the diff adds a verbatim copy of a shared type declaration
  already present in two other files
- **THEN** a duplication finding ships naming the existing copies and the
  shared home the three should adopt

#### Scenario: Three incidental look-alikes stay below the bar

- **WHEN** three added lines coincide only as setup or assertion
  scaffolding, encoding no rule that a future edit would have to change in
  every copy
- **THEN** no duplication finding ships — at exactly three occurrences the
  duplicated unit must encode a changeable rule

#### Scenario: Two-instance duplication stays below the bar

- **WHEN** the diff contains a helper duplicated exactly twice with no
  prior copies
- **THEN** no duplication finding ships and the report says nothing about
  it

#### Scenario: A long block duplicated only once stays below the bar

- **WHEN** the diff contains a line-for-line copy of a sixteen-line
  function or view skeleton, giving two occurrences in total
- **THEN** no duplication finding ships — block length is not a route
  past the occurrence bar

#### Scenario: Severity cap

- **WHEN** a duplication finding ships and the copies have not yet
  diverged in behavior
- **THEN** its severity is P2 (P1 is reserved for copies that have
  already drifted)
