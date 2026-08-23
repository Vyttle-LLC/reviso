# Gold labels provenance

The `crb-*.json` labels in this directory are derived from
[withmartian/code-review-benchmark](https://github.com/withmartian/code-review-benchmark)
(MIT — vendored verbatim as `LICENSE-code-review-benchmark`; © the
benchmark's authors), via the reviso-api eval fixtures (import date and
per-case source PR recorded inside each labels file). Transformation
applied: category normalization to the harness vocabulary (`bug` →
`correctness`, `security` → `security`, `error-handling` → `robustness`,
`performance` → `efficiency`; the original is kept as `crb_category`),
`file: "*"` → null, missing lines → 0, title = description truncated to
120 chars. No upstream diff or code content is included — corpus entries
are pointers (repo, PR, SHAs).

Hand-authored labels (origin `"hand"`) may be added beside imported ones;
the `origin` field distinguishes them.

## Hand-authored labels

- `termic-162.json` — [simion/termic#162](https://github.com/simion/termic/pull/162),
  authored 2026-08-08 from the upstream reviewer's own public review of the
  PR. Upstream is **AGPL-3.0**; nothing from it is vendored here. The corpus
  entry is a pointer (repo, PR, SHAs) and the label is our own description of
  the duplication, so no upstream code is copied or redistributed — the same
  pointer-only posture the imported cases use. It is the corpus's only
  `duplication`-category label.
- `slop-*.json` (10 files) — authored 2026-08-19 in this repo for the
  slop-detection expansion, alongside their fixtures under `synthetic/`.
  All content (code, labels, PR framing) is original to this repo —
  nothing imported, nothing vendored. Five true-positive / expected-clean
  pairs, one per new style lens (over-engineering, dead weight, comments,
  test slop, AI tells); all findings carry category `slop`. Style-tier
  gold cases: run them with `REVISO_TIER=style`.
- `slop-derivedstate-*.json`, `slop-naming-*.json`,
  `slop-errorhandling-*.json`, `slop-multilens-001.json` (7 files) —
  authored 2026-08-22 in this repo for the reader lenses, same posture:
  all content original, nothing imported. Three true-positive /
  expected-clean pairs (derived state, naming, error handling) and one
  multi-lens case whose label is the expected *consolidated* set — eight
  findings from ten planted, ordered most-severe-first. Category `slop`;
  `REVISO_TIER=style`.
- `slop-staledocs-*.json`, `slop-surfacearea-*.json`,
  `slop-typeslop-*.json` (6 files) — authored 2026-08-22 in this repo
  for the surface lenses, same posture: all content original, nothing
  imported. Three true-positive / expected-clean pairs (stale docs,
  surface area, type slop). The stale-docs pair is the first to carry a
  `context` file re-listed as `added` — the change modifies an existing
  file, and the README it contradicts stays untouched. Category `slop`;
  `REVISO_TIER=style`.
