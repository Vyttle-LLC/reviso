# Tasks — import-crb-corpus

## 1. Importer

- [x] 1.1 Spot-audit 8–10 CRB fixtures across repos/languages: confirm
      gold-label quality, category vocabulary, and that their PRs resolve
      to SHAs; record the category → tier mapping the importer will use
- [x] 1.2 Write the importer (sh + jq preferred; see design OQ): fixture →
      resolved SHAs via `gh` → `public.jsonl` entry + labels file; loud
      skip report for unresolvables; no diff content copied
- [x] 1.3 Vendor CRB's MIT license + provenance note beside
      `eval/corpus/labels/`
- [x] 1.4 Run the import; commit entries + labels; record the skip report
      in the change
- [x] 1.5 Mark the `active_parity` subset (~12: per-language/repo spread,
      ≥2 expected-clean); document the selection rationale in
      `eval/corpus/README.md`
- [x] 1.6 Import the 13 synthetic fixtures as `synthetic: true` diff-only
      cases with labels

## 2. Gold-mode runner

- [x] 2.1 `gold.sh <workdir> <case-id> <outdir>`: pinned checkout (clone
      cache under `eval/.cache/`), candidate leg via `candidate.sh`,
      judge against the labels file
- [x] 2.2 Judge gold path: `gold_recall_correctness`, proxy precision
      (labeled as proxy), informational cleanup bucket, unmatched-finding
      promotion list
- [x] 2.3 Expected-clean handling: findings counted as FPs with no judge
      call
- [x] 2.4 Synthetic materialization: init throwaway repo, apply diff,
      run candidate; parity tooling refuses synthetics
- [x] 2.5 Smoke: one gold-issue case, one expected-clean case, one
      synthetic — verify metrics and artifacts end-to-end

## 3. Docs and metrics

- [x] 3.1 `eval/README.md`: gold mode section (what it measures, cost,
      when to run which mode)
- [x] 3.2 `eval/corpus/README.md`: labels dir, provenance, active_parity,
      synthetic cases
- [x] 3.3 `docs/evals.md`: metrics glossary (gold vs parity), placeholder
      for the first full gold sweep

## 4. First sweep

- [x] 4.1 Full gold sweep over the imported corpus; publish aggregate
      numbers in docs/evals.md and file eval-candidate issues for any
      systematic gaps the sweep exposes (cross-check against #9)
