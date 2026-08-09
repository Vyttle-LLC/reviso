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
- [x] 4.3 Private tier made runnable. Entry-relative paths (labels,
      fixtures) now resolve against the corpus file's own directory, so a
      corpus outside the repo carries its labels beside it; `sweep.sh`
      exports its corpus selection so the loop and the per-case runner
      cannot disagree; `gold.sh` fails by name on a missing corpus file,
      an unknown case, or an entry with no `labels`. The four private
      entries gained `labels` fields (that file lives outside the repo).
      Verified: guards fire, and a private-corpus case resolves its labels
      beside the corpus file rather than under `eval/corpus/`.
- [x] 4.4 Duplication is in-lane. The tier list moved to one shared
      definition (`eval/runners/tiers.sh`, sourced by both `judge.sh` and
      `gold.sh` — it had been copy-pasted between them, a calibration
      decision living in two places) and `duplication` left it, since the
      split encodes what Reviso ships rather than literal correctness.
      Judging was extracted to `gold-judge.sh` so a recorded run can be
      re-judged when calibration moves; the 2026-08-08 run was re-judged
      from its recorded output and recorded matches — no review, no new
      matcher calls — taking `gold_recall_correctness` from `null` to
      **100%**. `docs/evals.md` says it was a re-judge.

## 3. Release (0.3.0)

- [x] 3.1 `.claude-plugin/plugin.json` → 0.3.0; roll CHANGELOG
      [Unreleased] into a 0.3.0 heading with this lens as the headline
- [x] 3.2 Commented on #9 with the shipped lens, the bar correction, and
      the calibration results. **Left open deliberately**: #9 reports two
      recall gaps and this change fixes only the verbatim-duplicate half —
      redundant derived state is a different shape with one labeled
      instance and no calibrated bar. Close it when that half is done, or
      split it out.
