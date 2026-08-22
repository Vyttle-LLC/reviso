# review-command

## MODIFIED Requirements

### Requirement: Findings are line-anchored and complete

Every reported finding SHALL include: file and line anchor, severity, a
concrete failure scenario (inputs/state → wrong outcome), a suggested fix or
rewrite, and a confidence score. Findings SHALL be ranked most-severe-first
and consolidated (related nits merged into one comment).

Reporting policy SHALL be an obligation of the command that produces the
report, not of the shared finding schema. Each command SHALL state the
severity floor it applies (no finding ranking below P2 ships), the
consolidation it performs, and any limit on how many findings it reports.
The shared schema defines the wire format every stage speaks and SHALL NOT
carry policy, so that a stage which merely serializes a candidate cannot
thereby suppress it.

A report with no findings SHALL state that no issues were found and SHALL
report which lenses were checked, derived from the lenses that actually
ran rather than from a fixed list, naming separately any lens that
produced no result or was out of scope. A clean report and a report from a
run whose lenses failed SHALL NOT be identical.

#### Scenario: Finding rendering

- **WHEN** the pipeline reports a confirmed finding
- **THEN** the report entry shows `file:line`, severity, failure scenario,
  suggested fix, and confidence — none absent

#### Scenario: Clean review

- **WHEN** no finding survives the confidence gate and every lens ran
- **THEN** the report states that no issues were found and names the lenses
  that ran, and nothing else

#### Scenario: Clean review with a broken lens

- **WHEN** no finding survives the confidence gate and one lens produced no
  result
- **THEN** the report states that no issues were found, names the lenses
  that ran, and names the failed lens with its reason — the report differs
  from the fully-clean report above

#### Scenario: Severity floor is applied by the reporting command

- **WHEN** the single-pass review holds a candidate that ranks below P2
- **THEN** the command drops it under its own stated policy, and the
  behaviour is identical to the previous schema-carried rule

#### Scenario: Schema carries no policy

- **WHEN** a finder serializes a candidate per the shared finding schema
- **THEN** the schema constrains only the format, and imposes no severity
  floor and no count limit on what the finder may return
