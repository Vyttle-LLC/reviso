# Tasks — expand-slop-detection

## 1. Expand the style command

- [x] 1.1 Rewrite `commands/style.md` Step 3 to the ten-lens set (D1):
      pull comment slop out of the slop lens; add comments,
      over-engineering, dead-weight, test-slop, and AI-tells lenses with
      the evidence protocols the delta spec defines (recorded search for
      dead weight, absence citation for over-engineering, verbatim quotes
      for tells/test slop, two-example repo override where
      convention-relative).
- [x] 1.2 State the comments lens's absolute earn-its-place bar and its
      written-convention-only override in the lens text, and carve the
      cardinal-rule paragraph so it names its two absolute exceptions
      (comments bar, placeholder text).
- [x] 1.3 Update Step 4: add the comments-lens carve-out from the
      deliberate-style exclusion (D2), and add the dead-weight
      no-recorded-search → 0 gate alongside the existing no-baseline gate;
      extend the drop-reason vocabulary (`no-search`) for `--explain`.
- [x] 1.4 Update the ledger and report sections: ten lens rows plus
      deterministic; Step 6 feedback mapping sends the new lenses to the
      `slop` dimension; severity paragraph adds the can't-fail-test P1
      case.
- [x] 1.5 Re-read the finished command end-to-end for internal
      contradictions (cardinal rule vs absolute bars, exclusion list vs
      Step 4 carve-out) — the file is the product; it must not disagree
      with itself.

## 2. Detector discovery

- [x] 2.1 Run the DISCOVERY.md process on the D5 candidates (placeholder
      phrases, changelog comments, temporal naming, emoji): define each
      candidate's FP-free construction, then sweep recent history of the
      Vyttle repos and this repo (`git log -p -U0 -n 300 --no-merges |
      awk -f detect.awk` pattern) for false positives.
- [x] 2.2 Implement whatever cleared the bar in
      `skills/reviso/detectors/detect.awk` (expected: `placeholder`
      with a curated phrase list, markdown-suppressed); extend the
      synthetic true-positive fixture checks.
- [x] 2.3 Update both DISCOVERY.md tables (shipped + rejected-with-where-
      the-concern-went) with every candidate evaluated, including the
      sweep evidence line.

## 3. Eval harness — style tier

- [x] 3.1 Add `style` to `eval/runners/review-tier.sh`
      (`REVISO_TIER=style` → `/reviso:style`); audit its callers
      (`candidate.sh`, `gold.sh`, `sweep.sh`, `gold-judge.sh`) for
      two-tier assumptions and fix any found.
- [x] 3.2 Verify recorded-run metadata carries `style` as the tier and
      that per-tier aggregation treats it as its own bucket (no pooling).

## 4. Synthetic corpus cases

- [x] 4.1 Author fixture pairs per new category under `eval/corpus/synthetic/`
      following the existing synthetic-case format: over-engineering
      (defended-impossible-state TP / genuinely-reachable-state clean),
      dead weight (no-caller-export TP / dynamically-dispatched clean),
      comments (bloated-restating TP / earned-constraint clean), test
      slop (mock-asserting TP / real-assertion clean), AI tells
      (placeholder + temporal-naming TP / repo-with-the-idiom clean).
- [x] 4.2 Write gold labels (category `slop`) for the TP fixtures and
      mark the look-alikes expected-clean; add the `public.jsonl` entries
      (`synthetic: true`, gold-only) and update `labels/PROVENANCE.md`.
- [x] 4.3 Note in `eval/corpus/README.md` that style-tier gold runs are
      meaningful only against style-labeled or expected-clean cases (D6).

## 5. Prove it

- [x] 5.1 Run gold mode with `REVISO_TIER=style` over the new synthetic
      cases: every TP fixture's labeled finding matched, zero findings on
      every clean look-alike. Iterate lens prompts until both hold.
- [x] 5.2 Run `/reviso:style` against a real recent branch in a Vyttle
      repo as a field smoke test; check the ledger reports all ten lens
      rows and the report stays within the 8-finding/P2-band contract.

## 6. Docs and release

- [x] 6.1 Update the style-command and gold-eval sections of any docs
      that enumerate the lenses or tiers (`README.md`, `docs/evals.md`
      if touched), and record the eval results per the docs/evals.md
      publication convention.
- [x] 6.2 CHANGELOG entry (0.7.0) and version bump in
      `.claude-plugin/plugin.json`; note the future-work item (lane
      restructure) where the repo tracks it.
