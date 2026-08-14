# parity-eval

## MODIFIED Requirements

### Requirement: A labeled multi-run calibration case seeds the re-aimed judge

The private corpus tier SHALL include a calibration entry consisting of one
change reviewed by all three of: `/reviso:review`, built-in `/code-review`
medium, and built-in `/code-review` xhigh — with a labels file recording,
per finding: source run, category, and a hand verdict (real, not-real, or
out-of-lane). The judge's category bucketing and matching SHALL be checked
against these labels before its parity numbers are trusted.

A change to the confidence rubric's bands SHALL invalidate the existing
calibration. Recorded runs SHALL carry the rubric revision under which they
were judged, and the judge SHALL NOT compare runs across differing rubric
revisions — on the same footing as its refusals across CLI versions,
resolved model IDs, and review tiers. Recalibration against the labels
SHALL be re-established before parity numbers are published under the new
bands.

#### Scenario: Judge disagrees with labels

- **WHEN** the judge's bucketing of the calibration entry's findings
  disagrees with the hand labels beyond the documented tolerance
- **THEN** parity numbers from that judge configuration are not published

#### Scenario: Calibration entry stays private

- **WHEN** the calibration entry is added
- **THEN** no diff content, finding text, or repository identity from it
  lands in this repository

#### Scenario: Rubric change invalidates calibration

- **WHEN** the confidence rubric's bands change
- **THEN** the existing calibration is marked stale, and parity numbers are
  not published until the judge is re-checked against the labels under the
  new bands

#### Scenario: Cross-revision comparison is refused

- **WHEN** a judge run is given runs recorded under different rubric
  revisions
- **THEN** it refuses the comparison and names the mismatch, rather than
  reporting a figure across two calibrations
