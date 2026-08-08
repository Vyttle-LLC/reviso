## Reviso review — HEAD (detached, f3317b329b) vs cbe1e7d63f (2 commits, 7 files)

Found 3 issues:

1. **[P1][conf 90] `enableSqlExpressions` can never return true — the feature-flag read is dead and inverted** — `pkg/expr/reader.go:194`
   Failure: `enabled := !h.features.IsEnabledGlobally(FlagSqlExpressions)` is assigned, then *both* branches return `false`, so the toggle lookup is computed and discarded. The helper's name and body claim to gate on `sqlExpressions`, but the toggle has zero effect — an operator who turns it on still gets `"sqlExpressions is not implemented"`, and a future maintainer reading the helper will believe the flag is the switch. The condition is also inverted relative to the name (`enabled` holds *not* enabled), so a "fix" that just changes `return false` → `return true` would enable SQL exactly when the flag is *off*. golangci-lint (gocritic/staticcheck identical-branches) is likely to fail on this too.
   Fix: if the disable is intended to be unconditional, delete the helper and inline it at the case:
   ```go
   case QueryTypeSQL:
       return eq, fmt.Errorf("sqlExpressions is not implemented")
   ```
   If it should honour the toggle: `if !h.features.IsEnabledGlobally(featuremgmt.FlagSqlExpressions) { return eq, fmt.Errorf("sqlExpressions is not enabled") }`.
   (bugs / slop — enforcement doesn't match its claim)

2. **[P2][conf 85] Default (non-`expressionParser`) path isn't gated and reports valid SQL as malformed** — `pkg/expr/nodes.go:160`, `pkg/expr/sql_command.go:30`
   Failure: the new guard lives only in `ReadQuery`, which `buildCMDNode` reaches only when `expressionParser` is enabled (`pkg/expr/nodes.go:123`). Both flags are experimental/off by default, so the ordinary path still runs `UnmarshalSQLCommand` → `NewSQLCommand` → `sql.TablesList` → the new stub `RunCommands`, which returns `errors.New("not implemented")`. `NewSQLCommand` swallows that into `errutil.BadRequest("sql-invalid-sql", "error reading SQL command")` — so existing dashboards and provisioned alert rules with perfectly valid SQL expressions now fail with a 400 telling the user their SQL is wrong, with no hint the feature was turned off. Before this change that path worked with the real DuckDB backend.
   Fix: gate `UnmarshalSQLCommand` (or the `case TypeSQL` in `buildCMDNode`) with the same explicit error so both paths surface "sqlExpressions is not implemented".
   (bugs)

3. **[P2][conf 82] Flag description, docs, and frontend still advertise working DuckDB SQL expressions** — `pkg/services/featuremgmt/registry.go:1084`
   Failure: the `go-duck` dependency is gone and the flag is inert, but the registry still says "Enables using SQL and DuckDB functions as Expressions", `docs/sources/setup-grafana/configure-grafana/feature-toggles/index.md:187` repeats it verbatim, and `public/app/features/expressions/types.ts:73` still offers the SQL expression type in the query editor whenever `sqlExpressions` is on. An operator follows the docs, flips the toggle, sees SQL in the picker, and every query errors.
   Fix: mark the toggle as non-functional in `registry.go` (regenerate `toggles_gen.*` and the docs table), or hide the editor option so the UI matches the backend.
   (conventions — doc staleness)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors did not run — `detectors/run.sh` was not approved for execution, so no detector-tagged findings are included.
Skipped: `go.mod`, `go.sum`, `go.work.sum` (dependency manifests — verified only that the `go-duck` removal and the transitive drops are consistent; the residual `go.work.sum` `go-duck v0.3.1` hashes are normal workspace-sum accumulation, not a finding).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
