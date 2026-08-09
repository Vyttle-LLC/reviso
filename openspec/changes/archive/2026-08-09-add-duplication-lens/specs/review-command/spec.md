# review-command (delta)

## ADDED Requirements

### Requirement: The single-pass review applies the duplication lens identically

`/reviso:review`'s inline anti-slop lens SHALL include the duplication
item exactly as specified for the pipeline's anti-slop finder (same bar,
same helper-naming fix requirement, same below-bar silence, same search
protocol before clearing an added block) — the two surfaces SHALL NOT
drift in the item's definition or thresholds.

#### Scenario: Same bar in the inner loop

- **WHEN** `/reviso:review` reviews a diff containing the same predicate
  added at five call sites
- **THEN** it ships the same single consolidated duplication finding the
  audit pipeline would, with every occurrence cited and the helper named

#### Scenario: Below-bar stays silent

- **WHEN** `/reviso:review` encounters a two-instance duplication with no
  prior copies
- **THEN** the report ships no duplication finding and makes no mention of
  the duplication
