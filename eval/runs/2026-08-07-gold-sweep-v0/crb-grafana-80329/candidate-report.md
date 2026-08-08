## Reviso review — HEAD (detached) vs a886bd3c79 (16 commits, 3 files)

Found 3 issues:

1. **[P0][conf 100] Debug logging left in at Error level, dumping every row ID each batch** — `pkg/services/annotations/annotationsimpl/xorm_store.go:534`
   Also at `:537`, `:554`, `:557`, `:576`, `:579`.
   Failure: `CleanAnnotations` and `CleanOrphanedAnnotationTags` now emit two `log.Error` lines per batch on the *success* path, each carrying the full `ids` slice. With the default `cleanupjob_batchsize = 100` (`pkg/setting/setting.go:710`), an instance cleaning 1M stale annotations emits 20,000 ERROR lines per cycle, each with 100 IDs — log flooding plus false pages for any alert keyed on error-level logs. The `"err", y` field logs an error that is nil on every success, and `y` is returned as the batch error anyway.
   Fix: delete all six `r.log.Error` calls. If batch visibility is wanted, keep one `r.log.Debug` with `"count", len(ids)` and no `ids`/`cond`. While there, rename `x, y` to `affected, err` — they are the function's return values, not scratch vars.
   (bugs)

2. **[P0][conf 95] Cleanup ticker cut from 10 minutes to 1 minute, unrelated to the change** — `pkg/services/cleanup/cleanup.go:77`
   Failure: this line is bundled into commit `4ecfade258 "Iterate in batches"`, which otherwise only touches annotation batching; no commit message mentions it. It changes the cadence of *every* cleanup job — temp files, expired snapshots, dashboard versions, expired images, temp users, annotations — to 10× more often. `clean` runs under a 9-minute timeout (`cleanup.go:89`), so on a large instance each run now effectively restarts as soon as it finishes, holding continuous delete pressure on the DB. This reads as a leftover from shortening the local test loop.
   Fix: restore `time.NewTicker(time.Minute * 10)`.
   (history)

3. **[P2][conf 85] Quadratic string building for the SQLite inline-ID path** — `pkg/services/annotations/annotationsimpl/xorm_store.go:609`
   Failure: `values = fmt.Sprintf("%s, %d", values, v)` reallocates and copies the whole accumulated string on every iteration. The new test at `cleanup_test.go:101` runs this with `annotationCleanupJobBatchSize: 32767`, so each batch builds a ~230 KB string via ~32k copies — roughly 3.8 GB of memcpy per batch, repeated for every batch of a 40k-row cleanup. The `else` branch two lines down already shows the codebase's idiom for this shape.
   Fix:
   ```go
   parts := make([]string, len(ids))
   for i, v := range ids {
       parts[i] = strconv.FormatInt(v, 10)
   }
   sql = fmt.Sprintf(`DELETE FROM %s WHERE id IN (%s)`, table, strings.Join(parts, ","))
   ```
   Separately, the comment at `:605` says "SQLite has a parameter limit of 999" while the test name correctly cites 32766 for SQLite ≥ 3.32.0 — the 999 threshold is safely conservative, but the comment should say why.
   (slop)

Checked: bugs, conventions, history, comments, slop. The integration-test rename in `cleanup_test.go` correctly follows `contribute/backend/style-guide.md:36` (`TestIntegration` prefix + `testing.Short()` skip).
Skipped: nothing. Deterministic detectors did not run — the `detectors/run.sh` invocation was denied at the permission prompt, so those findings are absent from this report.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
