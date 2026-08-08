## Reviso review — HEAD (detached) vs 50f4e78a (5 commits, 11 files)

Found 4 issues:

1. **[P0][conf 95] Device limit is bypassed on every request after the first rejection** — pkg/services/anonymous/anonimpl/impl.go:147
   Failure: `tagDeviceUI` writes the cache entry *before* the store call (impl.go:87), so when `CreateOrUpdateDevice` returns `ErrDeviceLimitReached` the device is already cached as tagged. The first request from a new device over the limit gets a 401; every subsequent request from that same `X-Grafana-Device-Id` for the next 29 minutes hits the cache short-circuit at impl.go:83, returns `nil`, and authenticates normally — while never being written to `anon_device`, so it never counts toward the limit either. The stated intent ("break auth if limit reached") holds for one request per device per 29 min.
   Fix: only populate the cache after a successful write — move `a.localCache.SetDefault(key, struct{}{})` below the `CreateOrUpdateDevice` call, or `a.localCache.Delete(key)` in the error branch.
   (bugs; enforcement doesn't match the claim)

2. **[P1][conf 85] Store is no longer injectable; wire registration is now dead and unbuildable** — pkg/services/anonymous/anonimpl/impl.go:43
   Failure: `ProvideAnonymousDeviceService` now takes `db.DB` and constructs `anonstore.ProvideAnonDBStore(...)` itself instead of receiving `anonstore.AnonStore`. `pkg/server/wire.go:374-375` still registers the provider plus `wire.Bind(new(anonstore.AnonStore), ...)`, but nothing consumes it anymore — and the new `deviceLimit int64` parameter has no provider in the graph, so the moment anything does ask for `anonstore.AnonStore`, wire fails with "no provider found for int64". Tests also lose the ability to substitute a fake store (impl_test.go now has to reach into `anonService.anonStore`).
   Fix: keep `anonStore anonstore.AnonStore` as the injected parameter and give the store its limit from `cfg` inside `ProvideAnonDBStore` (take `*setting.Cfg`, not a bare `int64`), so wire can still build it; otherwise drop the now-dead lines from `pkg/server/wire.go`.
   (conventions)

3. **[P2][conf 95] New `device_limit` ini option is undocumented** — pkg/setting/setting.go:1654
   Failure: `contribute/create-pull-request.md:136-140` states that a PR with configuration changes **must** correspondingly change `conf/defaults.ini`, `conf/sample.ini`, and the configuration docs. None were touched, and `[auth.anonymous]` in `conf/defaults.ini:581` and `docs/sources/setup-grafana/configure-grafana/_index.md:1057` lists every other key in the section. An operator reading the docs has no way to discover the limit exists or that `0` means unlimited.
   Fix: add a commented `device_limit` entry to both ini files and a description under `## [auth.anonymous]` in the configuration docs.
   (conventions)

4. **[P2][conf 85] `anonymousDeviceLimit` is typed `undefined`, not `number | undefined`** — packages/grafana-runtime/src/config.ts:97
   Failure: with `strict: true` (tsconfig.json:8), an un-annotated class field initialized to `undefined` infers the type `undefined`. `GrafanaBootConfig` compiles against the interface, but any consumer writing `config.anonymousDeviceLimit > 0` gets a type error and reads the field as permanently undefined — even though `getFrontendSettings` always sends an `int64`. The file's own norm for this shape is `loginError: string | undefined = undefined;` (config.ts:85).
   Fix: `anonymousDeviceLimit: number | undefined = undefined;` — or, since the DTO always emits a number (0 = unlimited), drop the `| undefined` in `packages/grafana-data/src/types/config.ts:200` and use `anonymousDeviceLimit = 0;`.
   (slop; convention drift)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detector suite (the `run.sh` invocation was not approved, so it did not run); no generated or lockfile content in this diff.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
