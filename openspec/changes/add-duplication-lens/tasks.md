# Tasks — add-duplication-lens

## 1. Lens

- [x] 1.1 `agents/reviso-finder-slop.md`: add slop item 5 (duplication,
      both directions) with the bar, occurrence citations, helper-naming
      `suggested_fix`, drift-risk failure scenario, P2 cap (P1 only for
      already-drifted copies), and the distinctive-identifier search
      protocol
- [x] 1.2 `commands/review.md` (and `commands/audit.md` lens summary):
      mirror the item word-for-word compatible with the agent's
      definition; below-bar is silent (notes tier dropped — design D1)
- [x] 1.3 Sharpen existing item 3 with the same search protocol (the #9
      fix)

## 2. Calibration

- [x] 2.1 Calibrate against the three cases: termic-162 (must ship,
      occurrences cited, helper named), watchos-202 (type-alias copy must
      ship), sagechat-15 (dups must stay silent); pass/fail recorded in
      design.md. Done as a text-level pass over the labels rather than
      live `/reviso:review` runs — it corrected the bar (design D1) before
      any spend.
- [x] 2.3 Recall measured. `gold.sh termic-162` (2026-08-08): the lens
      matched its gold label **1/1**, finding all seven occurrences,
      citing each, and naming a helper with signature and home. Artifacts
      in `eval/runs/2026-08-08-gold-termic-162/`; published in
      `docs/evals.md`. The above/below-bar exemplars stay unmeasured until
      4.3 lands.
- [x] 2.2 Evaluated the deterministic duplicate-run assist (design D4) by
      prototyping it against the termic-162 diff: it misses the seed
      exemplar and emits only test-scaffolding noise, so it fails its own
      gate. **Dropped** — not shipped; decision and evidence recorded in
      design D4 and `detectors/DISCOVERY.md`.

## 4. Public regression coverage

- [x] 4.1 Add `termic-162` to `eval/corpus/public.jsonl` with a
      hand-authored label (`labels/termic-162.json`, origin `hand`,
      category `duplication`) — the corpus's first and only duplication
      label. Upstream is AGPL-3.0, so the entry stays a pointer and the
      label is our own prose; recorded in `labels/PROVENANCE.md` and the
      corpus README. Resolution verified end to end: entry selects,
      labels file resolves, shape matches the CRB labels.
- [x] 4.2 Update corpus counts in `docs/evals.md` (63 → 64 labeled) and
      the CHANGELOG. The dated 2026-08-07 sweep row keeps its 63 — it is a
      historical result, not a description of the corpus.
- [ ] 4.3 **Not done — the private cases remain unreachable.** `gold.sh`
      and `sweep.sh` hardcode `CORPUS_FILE` to `public.jsonl` and resolve
      labels against `eval/corpus/`, and no private entry carries a
      `labels` field, so `REVISO_EVAL_PRIVATE_CORPUS` is documented but
      wired to nothing. watchos-202 and sagechat-15 — the above/below-bar
      exemplars — therefore cannot be swept. Needs: a `labels` field on
      each private entry, label resolution relative to the corpus file's
      own directory, and `sweep.sh` honoring the env var.
- [ ] 4.4 **Not done — a duplication miss is informational, not loud.**
      `judge.sh`'s `CLEANUP_RE` lists `duplication`, so a miss on
      termic-162 lands in `missed_informational_cleanup` rather than
      counting against `gold_recall_correctness`. That tiering predates
      Reviso shipping duplication findings; now that the lens is in-lane,
      a miss on a shipped lens should fail loudly. Confirmed empirically
      by the 2026-08-08 run: `gold_correctness_count: 0` and
      `gold_recall_correctness: null` on a case the lens passed — the
      headline metric cannot see this lane at all.

## 3. Release (0.3.0)

- [x] 3.1 `.claude-plugin/plugin.json` → 0.3.0; roll CHANGELOG
      [Unreleased] into a 0.3.0 heading with this lens as the headline
- [x] 3.2 Commented on #9 with the shipped lens, the bar correction, and
      the calibration results. **Left open deliberately**: #9 reports two
      recall gaps and this change fixes only the verbatim-duplicate half —
      redundant derived state is a different shape with one labeled
      instance and no calibrated bar. Close it when that half is done, or
      split it out.
