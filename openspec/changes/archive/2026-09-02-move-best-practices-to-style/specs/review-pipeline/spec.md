# review-pipeline (delta)

## REMOVED Requirements

### Requirement: The best-practices finder is opt-in and source-anchored

**Reason**: The lens moved to `/reviso:style --web` (Michael's call —
the ecosystem check belongs in the style lane, which is also
single-pass and cheaper). The audit returns to six finders.
**Migration**: Run `/reviso:style --web`; the audit's `--web` flag is
gone and reports the unknown-flag note pointing there. The contract
(`web-lookup-contract`) and the four classes are unchanged.

### Requirement: Best-practices candidates are gated on source and version applicability

**Reason**: Gating moved with the lens; it now lives in the
style-command capability's gate requirement.
**Migration**: Same gates, applied at `/reviso:style` Step 4
(`no-source` protocol reason; version and consequence as
exclusion-list matches).
