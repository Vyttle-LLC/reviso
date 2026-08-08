## Reviso review — HEAD (giuseppe/rename-instrumentation-middleware) vs 58ba11ecbd (9 commits, 8 files)

Found 1 issue:

1. [P2][conf 80] Middleware-ordering invariant was deleted, not carried over — pkg/services/pluginsintegration/clientmiddleware/contextual_logger_middleware.go:12
   Failure: `metrics_middleware.go` dropped the note "It also enriches the [context.Context] with a contextual logger containing plugin and request details. For those reasons, this middleware should live at the top of the middleware stack." The constraint is now *stronger*, not gone: `LoggerMiddleware.logRequest` no longer takes `pluginCtx`/`endpoint` at all (logger_middleware.go:36) and gets `pluginId`, `endpoint`, `dsName`, `dsUID`, `uname` only via `m.logger.FromContext(ctx)` (logger_middleware.go:57). If someone reorders `CreateMiddlewares` (pluginsintegration.go:158-162) so `NewContextualLoggerMiddleware()` lands below `NewLoggerMiddleware`, every `grafana-data-egress` log line silently loses all five fields — no compile error, no test, and no comment warning them.
   Fix: Put the ordering requirement on `NewContextualLoggerMiddleware` — e.g. "This middleware must be registered above any middleware that logs (notably LoggerMiddleware), since those rely on the attributes it puts on the context." Optionally mirror it on `LoggerMiddleware`.
   (comments/history)

Notes on things checked and cleared, since they look like regressions but aren't:
- `traceID` removal from `logParams` is covered — `tracing.ProvideService` registers a contextual log provider that re-adds it (pkg/infra/tracing/tracing.go:91).
- The other five removed fields are restored by the default provider reading `logParamsContextKey` (pkg/infra/log/log.go:55) fed by `WithContextualAttributes`.
- Middleware composition reverses the slice (`clientFromMiddlewares`, decorator.go:106), so the contextual middleware is correctly outside `LoggerMiddleware`.
- No stale references to `InstrumentationMiddleware` / `newInstrumentationMiddleware` remain outside the renamed test's function name.

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. Deterministic detectors did not run — the `run.sh` invocation needed approval and wasn't granted, so that lens is uncovered; re-run with approval if you want it.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
