# review-command (delta)

## ADDED Requirements

### Requirement: Opt-in pre-gate diagnostics via `--explain`

Both commands SHALL accept an `--explain` flag, default off. When passed,
the report SHALL additionally carry one clearly-labelled diagnostic
section containing the per-lens ledger with candidate counts and every
candidate considered before the confidence gate, each with its score and
its disposition (reported, or dropped with the structured drop reason).
The diagnostic section SHALL be labelled as diagnostics rather than
findings and SHALL appear after the findings.

When `--explain` is absent, the report SHALL be exactly what it would be
without the feature: no candidate below the gate is mentioned, no score of
a dropped candidate is shown. Passing `--explain` SHALL NOT change the
findings section — with and without the flag, the findings and their order
are identical.

The diagnostic section SHALL follow the report to the same sink: the
terminal, plus the `--out` path when the user gave one. It SHALL NOT
introduce any other write, and neither command's `allowed-tools` SHALL
gain an entry for it.

#### Scenario: Default run is unchanged

- **WHEN** a review runs without `--explain`
- **THEN** no dropped candidate, score, or drop reason appears anywhere in
  the report

#### Scenario: Diagnostics on a zero-finding run

- **WHEN** `/reviso:audit --explain` runs on a change where every
  candidate was gated
- **THEN** the report says no issues were found and the diagnostic section
  lists each gated candidate with its score and drop reason, labelled as
  diagnostics

#### Scenario: Findings section is flag-independent

- **WHEN** the same change is reviewed with and without `--explain`
- **THEN** the findings section is identical in both reports, and only the
  appended diagnostic section differs

#### Scenario: Diagnostics respect the report-only contract

- **WHEN** `--explain` is passed without `--out`
- **THEN** the diagnostics are printed to the terminal only, and no file is
  written

## MODIFIED Requirements

### Requirement: Findings are line-anchored and complete

Every reported finding SHALL include: file and line anchor, severity, a
concrete failure scenario (inputs/state → wrong outcome), a suggested fix or
rewrite, and a confidence score. Findings SHALL be ranked most-severe-first
and consolidated (related nits merged into one comment).

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
