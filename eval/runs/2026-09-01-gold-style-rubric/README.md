# 2026-09-01 — style gold sweep under the style rubric (0.10.0)

Acceptance run for `give-style-its-own-confidence-rubric`: every style
gold case (12 true-positive + 11 expected-clean, the union of the 0.7.0,
0.8.0, and 0.9.0 case sets) through `REVISO_TIER=style gold.sh`, plugin
at the change's working tree, `claude-opus-5`, CLI 2.1.252.

| | |
| --- | --- |
| clean cases | **11/11 silent** — the precision tripwire for admitting an importance-free gate |
| matched (matcher) | 21/24 first pass; 22/24 with the multi-lens re-run |
| report content | every labeled finding is in a report (see the two notes) |
| candidate findings | 23, all matching a label or a label's other half — no false positive |
| cost | $0.41–$0.85 per case, $13.35 total incl. the re-run |

Two cases need reading past the matcher's number:

- **`slop-aitells-001` (1/3 by matcher).** The report covers all three
  labels: the placeholder detector (matched), and one consolidated
  finding anchored on `:14` (also `:13`, `:15`) carrying the comparative
  name and the changelog comment — both labels — as one root cause. The
  matcher pairs each candidate at most once, so the second label counts
  as missed. The "extra" is the over-engineering half (a delegating
  wrapper with one caller, search recorded), which the 0.7.0 run had
  merged into its AI-tells finding. Same substance, different split;
  nothing false.
- **`slop-multilens-001` (7/8, then 8/8 on `-rerun/`).** The first pass
  cleared the planted dead weight (`toCsvRow`, `replace`) because the
  fixture repo already ships four uncalled exports and the pass read
  that as the repo's norm — the lens is not convention-relative, and the
  0.9.0 run reported it at 88. A fresh run reported all eight, the same
  three P1s first, dead weight at 88. Lens-level variance, not the
  gate: the candidate never reached scoring. Worth watching: the
  cardinal rule pulls the model toward relativity on a lens that does
  not ask for it.

What the sweep can and cannot show: seeded cases score 85–100 under
either rubric, so this run establishes that precision held (clean cases
silent, no candidate outside the labels' substance) and that reporting
policy still bounds volume (multi-lens shipped exactly eight). It cannot
show the field yield moved — that is the `--explain` funnel on real
branches, tasks 4.2–4.4 of the change.
