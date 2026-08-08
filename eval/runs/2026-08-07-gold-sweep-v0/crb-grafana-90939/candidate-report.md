## Reviso review — HEAD (detached) vs 3ce1a5b0ca (1 commit, 1 file)

No issues found.

The change adds an `RWMutex` around the `entryPointAssetsCache` global. I verified the fix actually holds:

- The published `*dtos.EntryPointAssets` is fully built (including `SetContentDeliveryURL` mutation at `webassets.go:64`) *before* the pointer is assigned under the write lock, so readers never observe a partially-mutated struct.
- All three callers (`pkg/api/index.go:82`, `pkg/api/frontendsettings.go:62`, `pkg/middleware/recovery.go:141`) only read the returned struct — no post-publish mutation, so no residual race on the pointee.
- `cfg.GetContentDeliveryURL` (`pkg/setting/setting.go:1934`) is read-only, so calling it under the lock introduces no new shared-state write.

Two things I looked at and deliberately did not report: the write lock is acquired without re-checking `entryPointAssetsCache != nil` (classic double-checked-locking omission), and the error path still assigns `nil` to the cache at `webassets.go:69`. Neither changes observable behavior — the first only costs a few redundant manifest parses during a cold-start burst, and the cache-wipe-on-error is unchanged from before this commit.

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. No `CLAUDE.md`/`AGENTS.md` exists in this repo or under `pkg/api/webassets/`. The deterministic detector suite did not run — the `sh .../detectors/run.sh` call was not approved, so no `deterministic`-tagged findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
