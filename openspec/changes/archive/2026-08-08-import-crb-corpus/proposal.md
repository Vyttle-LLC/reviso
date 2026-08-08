# Import the CRB corpus and add a gold-mode eval

## Why

The re-aimed parity harness has two structural gaps: the public corpus has
one case (published numbers rest on n=1), and every case costs three
headless `/code-review` baseline runs, so the corpus can't grow into a
regression suite anyone actually runs. Meanwhile the retired reviso-api
repo already holds the answer: 50 fixtures imported from
`withmartian/code-review-benchmark` (MIT) — real PRs in public OSS repos
(cal.com, grafana, discourse, keycloak, sentry; 5 languages) with 165
gold-labeled issues — plus 24 expected-clean cases that test the silence
discipline. Those PRs still resolve to pinnable SHAs. And with upstream
medium's precision measured at high variance across our two labeled cases
(1/6 vs 3/3), a gold-label metric is a steadier primary quality signal
than parity against a noisy baseline.

## What Changes

- **CRB importer**: convert reviso-api's CRB fixtures into public-tier
  corpus entries — re-resolve each PR to pinned base/head SHAs via `gh`,
  emit `eval/corpus/public.jsonl` entries plus per-case labels files
  (`gold_issues` → the harness label schema, with a correctness/cleanup
  tiering pass). Cases whose PR or SHAs no longer resolve are skipped
  loudly, never silently.
- **Gold-mode runner**: a candidate-only eval path — run `/reviso:review`
  against a pinned checkout and judge findings against the case's gold
  labels (no baseline runs). Reports per-case and aggregate recall on
  correctness-tier gold issues, precision (findings matched to any gold
  issue or verified real), and false-positive count on expected-clean
  cases. Roughly 10× cheaper per case than parity mode.
- **Parity subset**: an `active_parity` marker on corpus entries selects
  ~10–15 cases (spanning languages/repos) for full parity runs; gold mode
  covers the whole corpus. Parity-vs-medium remains the market-position
  check; gold recall/precision becomes the tracked-per-release number.
- **Synthetic fixtures**: import reviso-api's 13 synthetic cases
  (bug-*/clean-*/security-*) as diff-only gold cases where SHA-pinning
  doesn't apply. The 39 OWASP fixtures are explicitly not imported
  (single-file Java security benchmark; wrong shape for a PR reviewer).
- Attribution: CRB's MIT license and provenance recorded alongside the
  imported labels.

## Capabilities

### New Capabilities

- `gold-eval`: candidate-only evaluation against gold-labeled corpus
  cases — recall/precision/clean-case metrics, the cheap always-run mode.

### Modified Capabilities

- `parity-eval`: corpus schema gains labels files and the `active_parity`
  subset marker; public tier grows from 1 to ~50 entries; published
  metrics distinguish gold-mode numbers (whole corpus) from parity numbers
  (active subset).

## Impact

- New: `eval/runners/gold.sh`, `eval/corpus/import-crb.sh` (or .ts port),
  `eval/corpus/labels/` (public labels, MIT-attributed), corpus README
  updates.
- Modified: `eval/corpus/public.jsonl`, `eval/corpus/README.md`,
  `eval/README.md`, `docs/evals.md` (metric definitions),
  `eval/runners/judge.sh` (gold-mode judging path reuses match.sh +
  tiering).
- Reused as-is: `report-findings.sh`, `extract.sh`, `candidate.sh`,
  calibration conventions.
- Source material: `~/dev/vyttle/reviso-api/eval/fixtures/` (read-only;
  reviso-api itself is untouched).
