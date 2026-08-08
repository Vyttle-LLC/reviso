## Reviso review — HEAD vs 66c4dff17e (11 commits, 5 files)

Found 6 issues:

**1. [P0][conf 92] Async legacy writes are cancelled as soon as the HTTP handler returns — `pkg/apiserver/rest/dualwriter_mode3.go:51`**
Failure: each `go func()` derives its timeout from the inbound request `ctx` (`context.WithTimeoutCause(ctx, ...)`), then the parent returns immediately. `net/http` cancels `Request.Context()` on handler return, so the derived context is cancelled before or during `d.Legacy.Create/Update/Delete/DeleteCollection`. Any legacy store that honours context (SQL driver, `bus`, HTTP) aborts with `context.Canceled`, so in mode 3 legacy silently stops receiving writes while unified storage accepts them — exactly the divergence mode 3 exists to prevent. The 10s timeout is dead code. Also anchors: `:110`, `:135`, `:163`.
Fix: detach first, then bound: `ctx := context.WithoutCancel(ctx)` (Go 1.21+) before `context.WithTimeoutCause`, so only the 10s budget applies.
(bugs)

**2. [P1][conf 90] Panics in the detached goroutines kill the Grafana process — `pkg/apiserver/rest/dualwriter_mode3.go:50`**
Failure: previously the legacy call ran inline in the request path, where the apiserver's panic filter turned a nil-pointer in a legacy store into a 500. In a bare goroutine there is no recover on the stack, so the same panic terminates the whole process. Anchors: `:50`, `:108`, `:134`, `:161`.
Fix: add `defer func() { if r := recover(); r != nil { log.Error(nil, "panic in legacy write", "recover", r) } }()` as the first statement of each goroutine (or a small shared `d.goLegacy(ctx, fn)` helper, since the four bodies are identical).
(bugs)

**3. [P1][conf 95] Storage/legacy duration metrics are recorded against the wrong series — `pkg/apiserver/rest/dualwriter_mode3.go:45`**
Failure: `Create`'s storage-error path calls `recordLegacyDuration(true, ...)` even though `d.Storage.Create` failed, and `Update`'s storage-error path does the same at `:129`. Conversely `DeleteCollection`'s goroutine records the *legacy* call via `recordStorageDuration` at `:166`. Net effect: `dual_writer_legacy_duration_seconds{is_error="true"}` fires for unified-storage failures with no legacy call at all, storage errors never appear on the storage histogram, and legacy delete-collection latency is invisible — the metrics can't be used to gate the mode-3 rollout they were added for.
Fix: `:45` and `:129` → `recordStorageDuration(true, ...)`; `:166` → `recordLegacyDuration(err != nil, ...)`.
(bugs)

**4. [P1][conf 90] Delete's success path writes the object name into the `kind` metric label — `pkg/apiserver/rest/dualwriter_mode3.go:106`**
Failure: `d.recordStorageDuration(false, mode3Str, name, method, startStorage)` passes the per-object `name`, while `metrics.go:23` declares that position as the `kind` label. Every deleted playlist/dashboard mints a new `dual_writer_storage_duration_seconds` child series that is never reclaimed — unbounded cardinality growth in the Grafana process itself, and the series is unaggregatable. Every other call site in this file and in `dualwriter_mode2.go` passes `options.Kind`.
Fix: `d.recordStorageDuration(false, mode3Str, options.Kind, method, startStorage)`.
(bugs)

**5. [P1][conf 88] The new mode-3 integration tests actually run in mode 1 — `pkg/tests/apis/playlist/playlist_test.go:132`**
Failure: `DualWriterDesiredModes` is written to the `unified_storage_mode` ini section (`testinfra.go:389`) and resolved through `SetDualWritingMode` (`dualwriter.go:151`). With no stored kv value, `currentMode` defaults to `Mode1`, and the only transitions implemented are `Mode1↔Mode2` — `desiredMode == Mode3` matches no branch, so it returns `Mode1` and `helper.go:184` builds a `DualWriterMode3`… no, a `DualWriterMode1`. All three new subtests pass while exercising mode 1, so this branch's mode-3 code has no integration coverage. Anchors: `:191`, `:287`.
Fix: add the `Mode2 → Mode3` gate in `SetDualWritingMode` (this branch's stated goal), or have the tests seed the kv store with `"3"` for the group-resource key so the desired mode is reachable.
(bugs, history)

**6. [P2][conf 95] Delete puts the wrong logger into the context — `pkg/apiserver/rest/dualwriter_mode3.go:97`**
Failure: `ctx = klog.NewContext(ctx, d.Log)` stores the bare receiver logger instead of the `log` built one line above, so everything downstream (including the legacy store) logs without `name`, `kind`, and `method`. Every other method in the file passes `log`.
Fix: `ctx = klog.NewContext(ctx, log)`.
(bugs, conventions)

Checked: bugs, conventions, history, comments, slop.
Skipped: `go.work.sum` (dependency checksums); deterministic detectors did not run — the detector script was not approved, so those checks are not reflected above.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
