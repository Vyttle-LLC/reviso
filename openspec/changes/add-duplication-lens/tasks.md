# Tasks — add-duplication-lens

## 1. Lens

- [ ] 1.1 `agents/reviso-finder-slop.md`: add slop item 5 (duplication,
      both directions) with the bar, occurrence citations, helper-naming
      `suggested_fix`, drift-risk failure scenario, P2 cap (P1 only for
      already-drifted copies), and the distinctive-identifier search
      protocol
- [ ] 1.2 `commands/review.md` (and `commands/audit.md` lens summary):
      mirror the item word-for-word compatible with the agent's
      definition; below-bar routes to the notes tier
- [ ] 1.3 Sharpen existing item 3 with the same search protocol (the #9
      fix)

## 2. Calibration

- [ ] 2.1 Run `/reviso:review` against the three calibration cases:
      termic-162 (must ship, occurrences cited, helper named),
      watchos-202 (Transport copy must ship), sagechat-15 (dups must stay
      notes/silent); record pass/fail per case in the design doc
- [ ] 2.2 Evaluate the deterministic duplicate-run assist (design D4) on
      the same cases; ship under `skills/reviso/detectors/` as a
      finder-hint channel only if it changes recall, else record the
      decision and drop

## 3. Release (0.3.0)

- [ ] 3.1 `.claude-plugin/plugin.json` → 0.3.0; roll CHANGELOG
      [Unreleased] into a 0.3.0 heading with this lens as the headline
- [ ] 3.2 Close #9 with a pointer to the shipped lens and the calibration
      results
