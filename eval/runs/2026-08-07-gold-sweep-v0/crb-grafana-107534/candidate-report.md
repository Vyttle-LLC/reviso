## Reviso review — HEAD (detached) vs d9a8253 (6 commits, 4 files)

Found 1 issue:

1. **[P1][conf 85] Ad hoc filters are now applied twice (three times under shard splitting), duplicating label filters — `public/app/plugins/datasource/loki/querySplitting.ts:299`** (also `public/app/plugins/datasource/loki/shardQuerySplitting.ts:52`)

   Failure: `applyTemplateVariables` is not idempotent when `request.filters` is non-empty, and it was already being applied downstream. `runSplitQuery` → `runSplitGroupedQueries` → `datasource.runQuery` (`datasource.ts:350`) → `super.query()` → `DataSourceWithBackend.ts:185`, which applies `applyTemplateVariables(q, request.scopedVars, request.filters)` again for same-datasource targets. `applyTemplateVariables` calls `addAdHocFilters` (`datasource.ts:1127`) → `addLabelToQuery`, and the parser branch `addFilterAsLabelFilter` (`modifyQuery.ts:511`) appends unconditionally — unlike the stream-selector branch, which dedupes via `labelExists` (`modifyQuery.ts:494`).

   Concrete: `lokiQuerySplitting` is GA and on by default (`registry.go:158`). Dashboard with ad hoc filter `level=error`, query `{app="foo"} | logfmt` → the request sent to Loki becomes `{app="foo"} | logfmt | level=\`error\` | level=\`error\``. With `lokiShardSplitting` on, `runShardSplitQuery` interpolates, `runSplitQuery` interpolates the sharded target again, and `super.query` a third time → three copies. Before this change the plain split path interpolated exactly once. The updated assertion `expect(datasource.applyTemplateVariables).toHaveBeenCalledTimes(5)` (`shardQuerySplitting.test.ts:112`, was `toHaveBeenCalledTimes(1)`) records this: the test previously encoded "interpolate once" as the invariant.

   Fix: interpolate for split decisions without shipping the interpolated targets through a layer that re-interpolates. Either derive the split metadata (`expr` for `isLogsQuery`/`querySupportsSplitting`, `step` for `calculateStep`) from a local interpolated copy and keep `request.targets` raw, or pass `{ ...subRequest, filters: undefined }` / a `skipTemplateVariables`-style marker into `runQuery` so the ad hoc pass runs exactly once. Same treatment needed in `runShardSplitQuery`, whose result is fed to `runSplitQuery`.

   (bugs; confirmed against `DataSourceWithBackend.ts:185`, `modifyQuery.ts:494` vs `:511`)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors were **not** run — `detectors/run.sh` needs approval and the prompt was declined, so that lens is missing from this pass.
Skipped: nothing (all 4 changed files reviewed; no repo `CLAUDE.md`/`AGENTS.md` exists at root or under `public/app/plugins/datasource/loki/`).

Note: `--base d9a8253640464014aa3662c91131278990cfb828` is also the merge base, so the review covers all 6 branch commits.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
