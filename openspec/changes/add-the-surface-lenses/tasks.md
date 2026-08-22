# Tasks — add-the-surface-lenses

## 1. Expand the style command

- [ ] 1.1 Add stale-docs, surface-area, and type-slop lens bullets to
      `commands/style.md` Step 3 with the evidence protocols in the
      delta spec (quoted contradicted sentence; recorded external-
      consumer search; two same-language precise-type examples).
- [ ] 1.2 Step 4: add the stale-docs anchoring rule (D1) beside the
      pre-existing gate; extend `no-search` to surface area; note the
      lint-suppression clearance for type slop (D3).
- [ ] 1.3 Ledger 16 rows plus deterministic; render the coverage block
      by family (D4) with the differing-lens rule; `--explain` example
      extended; feedback mapping (new lenses → `slop`).
- [ ] 1.4 Re-read the command end-to-end; confirm the comments lens and
      stale docs do not both claim a changed doc comment (changed →
      comments; unchanged-but-falsified → stale docs).

## 2. Synthetic corpus cases

- [ ] 2.1 Fixture pairs: stale docs (README sentence contradicted by a
      renamed flag TP / README still accurate clean), surface area (new
      export with one internal caller TP / export consumed by a sibling
      package clean), type slop (`any` where the repo types the same
      payload TP / `any`-heavy repo clean).
- [ ] 2.2 Labels (`slop`), `public.jsonl`, PROVENANCE, README note →
      sixteen lenses and the family rendering.

## 3. Prove it

- [ ] 3.1 `REVISO_TIER=style` gold run over the 6 new cases plus the
      0.8.0 multi-lens case: all TPs matched, clean look-alikes silent,
      multi-lens ordering unchanged.
- [ ] 3.2 Field smoke test on a real branch; check the family coverage
      block reads correctly with one lens forced to `no result`.

## 4. Docs and release

- [ ] 4.1 Update lens enumerations and the example report's coverage
      block in `README.md` / `docs/`; record eval results.
- [ ] 4.2 CHANGELOG 0.9.0, `plugin.json` bump; resolve the open question
      (changelog scope) in the CHANGELOG entry's wording.
- [ ] 4.3 Sync the delta spec and archive this change on the feature PR.
