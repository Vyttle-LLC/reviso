# Tasks — add-the-reader-lenses

## 1. Expand the style command

- [x] 1.1 Add the derived-state, naming, and error-handling lens bullets
      to `commands/style.md` Step 3 with the evidence protocols the delta
      spec defines (D2, D3); strip "naming, error-handling shape" from
      the drift bullet so the lenses do not overlap.
- [x] 1.2 Add the same-language clause to the drift/baseline text (D4).
- [x] 1.3 Update Step 4: extend the `no-baseline` gate to the three new
      lenses (no lockstep citation / no two same-language examples → 0).
- [x] 1.4 Update the ledger (13 rows plus deterministic), the `--explain`
      example, the severity paragraph (D5), and the Step 6 feedback
      mapping (new lenses → `slop`).
- [x] 1.5 Re-read the finished command end-to-end for contradictions
      (drift vs the new lenses, no-bug-hunting vs error handling).

## 2. Synthetic corpus cases

- [x] 2.1 Author fixture pairs under `eval/corpus/synthetic/`: derived
      state (lockstep copy TP / independently-written field clean),
      naming (hedged name against a named repo idiom TP / repo that
      names it that way clean), error handling (swallow-and-log against
      a surfacing repo TP / repo whose idiom is log-and-continue clean).
- [x] 2.2 Author the multi-lens fixture (D6): ≥10 plantable findings
      across ≥4 lenses; label the expected consolidated set and order.
- [x] 2.3 Gold labels (category `slop`), `public.jsonl` entries
      (`synthetic: true`), `labels/PROVENANCE.md`, and the corpus README
      note extended to thirteen lenses.

## 3. Prove it

- [x] 3.1 `REVISO_TIER=style` gold run over the 7 new cases: every TP
      matched, zero findings on every clean look-alike, multi-lens case
      ships ≤8 findings in the labeled order. Iterate lens text until
      all hold.
- [x] 3.2 Field smoke test on a real recent Vyttle or Sage Haven branch;
      confirm the ledger carries all thirteen rows and note pass duration
      against a 0.7.0 run on the same branch.

## 4. Docs and release

- [x] 4.1 Update any doc that enumerates the lenses (`README.md`,
      `docs/evals.md`); record the eval results per the docs/evals.md
      convention.
- [x] 4.2 CHANGELOG 0.8.0, `plugin.json` bump; close issue #9 with a
      comment naming which lens covers each pattern.
- [x] 4.3 Sync the delta spec into `openspec/specs/style-command/spec.md`
      and archive this change on the feature PR.
