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
