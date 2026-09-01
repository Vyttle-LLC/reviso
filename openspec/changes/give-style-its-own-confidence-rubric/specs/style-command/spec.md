# style-command

## ADDED Requirements

### Requirement: Style confidence measures evidence quality, not importance

`/reviso:style` SHALL score every candidate at self-verification on the
style confidence rubric
(`skills/reviso/references/style-confidence-rubric.md`), whose bands
measure evidence quality alone: whether the candidate satisfied its
lens's evidence protocol, whether it holds against the real code on
re-examination, whether the cited baseline is unambiguous, and whether
the suggested fix is concrete. The rubric SHALL NOT take importance,
frequency of occurrence, impact on functionality, a senior engineer's
willingness to mention it, or the candidate's rank relative to the rest
of the change as scoring inputs — the lens protocols decide what is
callable and the severity band decides how much a finding misleads.

The rubric SHALL express its bands as ranges with the ship threshold on a
stated boundary: 80–89 for a candidate whose protocol is satisfied,
which holds against the code, whose baseline is unambiguous, and whose
fix is concrete; 90–100 when the evidence is text the reader can check
without judgment — a written convention or lint rule, an existing helper
cited by `file:line`, a verbatim quote of the tell; 50–79 when verified
but the baseline is thin or the fix is arguable; 1–49 when the protocol
is met on paper but the evidence does not survive re-examination; and 0
for the existing gates (exclusion list, pre-existing, protocol unmet).
The rubric SHALL carry a revision identifier and state in its header
which command scores on it.

In the style lane, the shared exclusion list's importance-shaped entries
— pedantic nitpicks a senior engineer would not call out, and general
code quality or documentation concerns not required by CLAUDE.md — SHALL
match a candidate only when it fails its lens's evidence protocol. A
candidate that satisfies the protocol SHALL NOT be scored down under
either entry. The shared exclusion list file is unchanged; this is a
style-command-local reading, like the comments lens's deliberate-style
carve-out.

The 80 gate, the silent drop, the `--explain` record, and the feedback
payload's confidence buckets (`80s`, `90s`, `100`) SHALL be unchanged;
the bands SHALL produce no shipping score outside those buckets.

#### Scenario: Verified, minor, and concrete ships

- **WHEN** a naming candidate cites two same-language `file:line`
  examples of the repo's `*Service` suffix, the change introduces a
  `*Manager`, re-examination confirms both, and the fix names the
  replacement
- **THEN** it scores in the 80–89 band and ships at P2, regardless of
  how little the name affects functionality

#### Scenario: Importance is not a scoring input

- **WHEN** a comments candidate satisfies the earn-its-place bar with a
  concrete rewrite and the scorer judges it unlikely to matter much in
  practice
- **THEN** that judgment changes nothing: the candidate is scored on its
  evidence alone, and a drop recorded as `rubric-score` on importance
  grounds is a defect in the run

#### Scenario: Written rule scores in the top band

- **WHEN** a conventions candidate quotes the CLAUDE.md sentence the
  change violates with its `file:line`
- **THEN** it scores 90–100

#### Scenario: Thin baseline stays below the gate

- **WHEN** a drift candidate cites exactly two examples of the
  established pattern and re-examination finds a third same-language
  file doing it the change's way
- **THEN** it scores 50–79 and does not ship

#### Scenario: Protocol unmet still scores 0

- **WHEN** a dead-weight candidate's evidence does not state the search
  performed
- **THEN** it scores 0 with reason `no-search`, exactly as before

#### Scenario: Nitpick entry does not drop a protocol-satisfying candidate

- **WHEN** a surface-area candidate records its search, cites the sole
  internal caller, and gives the narrowed visibility, and it matches the
  shape of "a pedantic nitpick a senior engineer wouldn't call out"
- **THEN** the exclusion-list entry does not apply; the candidate is
  scored on its evidence

#### Scenario: Shipping scores fit the feedback buckets

- **WHEN** a user names a style finding for false-positive feedback
- **THEN** its confidence falls in `80s`, `90s`, or `100`, and
  `build-payload.sh` accepts the bucket

## RENAMED Requirements

- FROM: `### Requirement: The style command reuses the shared harness unchanged`
- TO: `### Requirement: The style command reuses the shared harness, scoring on its own rubric`

## MODIFIED Requirements

### Requirement: The style command reuses the shared harness, scoring on its own rubric

`/reviso:style` SHALL run the deterministic detector suite before its own
pass, record candidates in the shared finding schema, self-verify every
candidate against the false-positive exclusion list (read as the style
rubric requirement above directs) and the **style confidence rubric**,
and silently drop candidates scoring below 80. It SHALL NOT score on the
shared `confidence-rubric.md`, which serves `/reviso:review` and
`/reviso:audit`. Its reporting policy SHALL match `/reviso:review`: no
finding below P2 ships, related findings are consolidated, at most 8
findings ship most-severe-first, and `--explain` carries the ledger and
gated candidates per the shared diagnostics requirement.

#### Scenario: Detectors run first and free

- **WHEN** a style review starts
- **THEN** the deterministic detectors complete against the diff before
  the lens pass, consuming no model tokens

#### Scenario: Confidence gate applies

- **WHEN** a style candidate scores 79 against the style rubric
- **THEN** it is silently dropped, appearing only in `--explain`
  diagnostics when that flag was passed

#### Scenario: Style scores on its own rubric

- **WHEN** Step 4 reads its references
- **THEN** it reads the style confidence rubric and the exclusion list,
  and does not apply the shared rubric's bands
