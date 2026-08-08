Detector suite: the run was declined at the permission prompt, so Step 2 did not execute — the findings below are all from my own review pass.

## Reviso review — HEAD vs 91d5682 (0 commits, 1 file)

Found 3 issues:

**1. [P0][conf 95] `RateLimiter` has no synchronization — concurrent use crashes the process — `pkg/ratelimit/limiter.go:31`**
Failure: `Allow` reads and writes `rl.clients` (lines 34, 36) and mutates `state.Count`/`state.WindowStart` (43–53) with no lock, and `Reset` (59) swaps the map out from under it. A rate limiter is by definition called from concurrent request handlers; two goroutines calling `Allow` with new client keys trip Go's map-write detector and abort with `fatal error: concurrent map writes`, which `recover()` cannot catch. Even without the crash, concurrent `state.Count++` loses updates, so a client exceeds `maxPerWindow`. Nothing in the doc comments declares the type single-goroutine-only.
Fix: embed a `sync.Mutex` and take it for the whole of `Allow` and `Reset`:
```go
type RateLimiter struct {
	mu             sync.Mutex
	clients        map[string]*ClientState
	maxPerWindow   int
	windowDuration time.Duration
}

func (rl *RateLimiter) Allow(clientKey string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	// ...existing body...
}
```
A plain `Mutex` (not `RWMutex`) is right here — every path writes.
(bugs; concurrency)

**2. [P1][conf 85] `clients` map grows without bound — `pkg/ratelimit/limiter.go:36`**
Failure: entries are only ever added, never evicted. Client keys normally come from external input (IP, API key, token), so an attacker rotating keys — or just ordinary long-tail traffic — grows the map forever; expired windows keep their entries alive indefinitely. The only relief is `Reset()`, which also wipes every live limit, so it can't be used as a reaper.
Fix: sweep expired entries — either opportunistically inside `Allow` (delete entries whose `WindowStart` is older than `windowDuration` on every Nth call) or via a background janitor goroutine started in `New`. Deleting the current key's entry instead of resetting it in place at line 43 also helps.
(bugs; external input)

**3. [P2][conf 90] Doc comment claims a sliding window; the code implements a fixed window — `pkg/ratelimit/limiter.go:13`**
Failure: line 13 says "within a sliding time window", but lines 43–46 reset the counter wholesale once `windowDuration` elapses — a textbook fixed window. Callers trusting the comment get up to `2*maxPerWindow` requests in a single `windowDuration`: `maxPerWindow` at the end of one window, `maxPerWindow` immediately after the boundary. For an abuse-prevention limiter that doubled burst ceiling is the number that matters.
Fix: either correct the comment to "fixed time window" and document the 2× boundary burst, or implement the claimed behavior (keep per-client request timestamps, or a two-bucket weighted sliding-window counter).
(comments; enforcement-vs-claim)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors: not run (permission declined).
Skipped: nothing. No `CLAUDE.md`/`AGENTS.md` or lint config exists in this repo, so the conventions lens had no repo rules to check against; `pkg/ratelimit/limiter.go` is the repo's only file, and it is untracked, so there is no history to blame.

Dropped below the confidence gate: struct field alignment (gofmt territory), `>` vs `>=` at line 43, and the `maxPerWindow <= 0` misconfiguration path.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
