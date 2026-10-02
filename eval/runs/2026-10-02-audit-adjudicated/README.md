# Audit comparison attempt — 2026-10-02

**Blocked, zero scored cases.** This is diagnostic evidence for issue #18,
not a recall result. The planned ten cases are recorded in
`eval/corpus/subsets/audit-adjudicated.json` and cover all nine eligible
findings from the adjudicated zero-recall cluster, two previously matched
controls, and one entirely excluded Ruby case.

The candidate and matcher used Codex `gpt-6.1-sol`, medium effort,
CLI 0.160.0; the plugin was 0.14.0 at the revision in each `meta.json`.
Claude was unavailable. These results cannot establish historical Claude
performance or compare providers.

The initial Grafana run lacked diff blobs in a partial clone. The adapter
now hydrates the merge-base diff and objects between the pinned revisions
before entering the read-only sandbox. Subsequent Keycloak runs could
inspect current source but some historical blame still required missing
promisor objects. Full history is not promised by this preparation.

The audit could start several independent finders, then hit the host
agent-thread limit. Comments, anti-slop, prior-reviews, and independent
verification could not all complete. The workflow correctly recorded
missing coverage instead of treating fallback work as a full audit.
The sweeps were stopped after these repeat failures. Completed diagnostic
outputs and metadata are preserved here; interrupted attempts and raw
host event streams remain in the ignored cache.

Both tiers reported the repository unchanged. No matcher judgments or
gold metrics were produced for incomplete candidates. The comparison
needs a host with sufficient releasable audit agent capacity and prepared
historical objects before issue #18 can be resolved.

## Reproduction after resolving the blockers

Install `jsonschema` in the Python environment used by `REVISO_PYTHON`.
Generate a JSONL file in `eval/.cache/` by selecting the subset IDs from
`eval/corpus/public.jsonl` and prefixing each labels/fixture path with
`../corpus/`. Use a fresh output directory for each tier, and these env vars:

```sh
REVISO_TIER=audit
CANDIDATE_HOST=codex
CANDIDATE_CODEX_MODEL=gpt-6.1-sol
CANDIDATE_CODEX_EFFORT=medium
MATCH_HOST=codex
MATCH_CODEX_MODEL=gpt-6.1-sol
MATCH_CODEX_EFFORT=medium
REVISO_SWEEP_SUBSET=audit-adjudicated
CORPUS_FILE=/absolute/path/to/subset.jsonl
REVISO_PYTHON=/absolute/path/to/python-with-jsonschema
```

Export them, then run `sh eval/runners/sweep.sh gold <fresh-output-dir>`.
Repeat with `REVISO_TIER=review`. Only complete coverage can be scored.
Do not retry into an existing candidate directory: preserve the failed
attempt and use a fresh output path.
