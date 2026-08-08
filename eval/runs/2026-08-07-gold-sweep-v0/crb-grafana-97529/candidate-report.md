Detector suite required approval and was declined, so Step 2 was skipped — this report is the model pass only.

## Reviso review — HEAD vs 871af07203 (16 commits, 5 files)

Found 2 issues:

1. **[P1][conf 82] Unsynchronized read of the bleve index cache** — `pkg/storage/unified/resource/search.go:216`
   `TotalDocs()` (`pkg/storage/unified/search/bleve.go:144-154`) ranges over `b.cache` without taking `cacheMu.RLock()`, while `BuildIndex` now writes `b.cache[key] = idx` under a narrow lock at `bleve.go:137-139`.
   Failure: the new log line calls `s.search.TotalDocs()` nine lines after the watch goroutine is launched at `search.go:207`. If a write event for an unindexed `NamespacedResource` arrives in that window, `handleEvent` → `getOrCreateIndex` → `build` → `BuildIndex` writes the map while `TotalDocs` iterates it → Go runtime `fatal error: concurrent map read and map write`, which is not recoverable and kills the process. The same unguarded read is reachable from `BleveIndexMetrics.Collect` (`bleve_index_metrics.go:96`) on every `/metrics` scrape, and this PR greatly widens that window by building every index during startup.
   Fix: since this commit is specifically about cache locking, guard the reader too:
   ```go
   func (b *bleveBackend) TotalDocs() int64 {
       b.cacheMu.RLock()
       defer b.cacheMu.RUnlock()
       var totalDocs int64
       for _, v := range b.cache { ... }
       return totalDocs
   }
   ```
   (bugs; the finer-grained locking in `bleve.go` is correct on the write side — only the reader was missed)

2. **[P2][conf 80] Postgres skip papers over a startup-latency regression this PR introduces** — `pkg/server/module_server_test.go:36`
   Failure: `NewResourceServer` now runs `s.Init(ctx)` synchronously (`server.go:258`), so `lifecycle.Init` (DB connect + ping) and `initWatcher` → `WatchWriteEvents` → `listLatestRVs` all execute inside `sql/service.go:start` before the module reports running. The test waits a fixed `time.Sleep(500 * time.Millisecond)` (line 56) before `GET /metrics` on :3001. On postgres in Drone that DB work exceeds 500ms, so the endpoint isn't listening yet. The branch history confirms the diagnosis path — `29db0d39b0 wait 1 second`, `1095580dce try with big timeout`, `45e0089891 put delay back to 500 ms`, then `6f4d70876a skips postgres` — i.e. a timing failure that was disabled rather than fixed, on the exact code path this PR changes. "Works locally" is expected: a local postgres is fast.
   Fix: replace the fixed sleep with a poll — retry `client.Get` against `/metrics` until it succeeds or a ~10s deadline elapses (`require.Eventually`) — and drop the postgres skip. That makes the test robust for every backend instead of hiding the readiness change.
   (history; conventions — the skip's stated reason doesn't match what the branch changed)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors: not run (permission declined).
Skipped: nothing — all 5 changed files reviewed. `pkg/storage/unified/sql/backend.go` and the trace-context fixes in `search.go` are correct as written.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
