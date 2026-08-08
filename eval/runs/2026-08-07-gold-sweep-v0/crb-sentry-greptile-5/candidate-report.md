## Reviso review — HEAD vs 49a2758 (32 commits, 106 files)

Found 3 issues:

1. **[P1][conf 90] `drain_mailbox_parallel`'s processing deadline (120s) is shorter than the runtime the task budgets for itself (180s)** — `src/sentry/hybridcloud/tasks/deliver_webhooks.py:239`
   Failure: Both drain tasks self-limit their loop at `deadline = timezone.now() + BATCH_SCHEDULE_OFFSET`, and `BATCH_SCHEDULE_OFFSET = timedelta(minutes=BACKOFF_INTERVAL)` with `BACKOFF_INTERVAL = 3` → 180s (`deliver_webhooks.py:44`, `webhookpayload.py:18`, loop check at `deliver_webhooks.py:301`). With a deep mailbox backlog, taskworker hard-kills `drain_mailbox_parallel` at 120s before the loop can reach 180s, so the graceful break never runs: the `deliver_webhook_parallel.delivery_deadline` log and `outcome: delivery_deadline` metric are never emitted, and the in-flight thread-pool batch is aborted mid-delivery. Note `drain_mailbox` in the same commit got 300s (headroom over 180s), so the two are inconsistent.
   Fix: Raise `processing_deadline_duration` for `drain_mailbox_parallel` above `BATCH_SCHEDULE_OFFSET` (match `drain_mailbox`'s 300, or derive both from `BATCH_SCHEDULE_OFFSET.total_seconds()` plus slack so the relationship can't drift again).
   (bugs)

2. **[P1][conf 90] Replay summary interleaves error timestamps (epoch seconds) with rrweb timestamps (epoch ms), so every error is emitted before every breadcrumb** — `src/sentry/replays/endpoints/project_replay_summarize_breadcrumbs.py:153`
   Failure: `ErrorEvent["timestamp"]` comes from the nodestore event payload, which is epoch **seconds** (`fetch_error_details`, line 646 — the new test stores `now.timestamp() - 1`). `event.get("timestamp", 0)` is the top-level rrweb timestamp, which is epoch **milliseconds** (`src/sentry/replays/testutils.py:326`, `:398` — "rrweb timestamps are in ms"; the sentry payload nested inside is the seconds one). Since ~1.75e9 < ~1.75e12 for every pair, the `while` guard is always true and all error messages are flushed before the first breadcrumb, defeating `gen_request_data`'s "in chronological order" docstring — Seer receives a mis-ordered log and produces summaries with wrong causality. The new `test_get_request_data` uses 1.5/2.0 for rrweb timestamps, so it can't catch this.
   Fix: Normalize to one unit before comparing, e.g. store `timestamp=data.get("timestamp", 0.0) * 1000` in `fetch_error_details` (and format the log message from the same normalized value), or convert the rrweb timestamp to seconds at the comparison site.
   (bugs)

3. **[P2][conf 85] New dashboard table path renders hardcoded empty data, discarding `result`** — `static/app/views/dashboards/widgetCard/chart.tsx:165`
   Failure: The `use-table-widget-visualization` branch passes `columns={[]}` and `tableData={{data: [], meta: {fields: {}, units: {}}}}` instead of `result.data` / `result.meta`, while the `else` branch passes real data. `columns={[]}` is not nullish, so `TableWidgetVisualization`'s `columns ?? …fallback` never fires and `GridEditable` gets zero columns — any org with the flag on sees a blank table for every table widget. The flag isn't registered in `src/sentry/features/`, so this is currently unreachable, but it breaks the moment someone registers it, and nothing marks it as a placeholder.
   Fix: Pass the real result (`tableData={{data: result.data, meta: result.meta}}` with columns derived from `fields`/`fieldAliases`), or add an explicit TODO stating the wiring is deliberately deferred.
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (the `detectors/run.sh` call was not approved, so that pass did not run — rerun `/reviso:review` and approve it for the free detector findings). Content review skipped for pure Flex-primitive style swaps (`row.tsx`, `teamMisery.tsx`, `auditLogList.tsx`, `codeOwnerFileTable.tsx`, codecov selectors, `eventAttachments.tsx`, `newTraceDetailsHeader.tsx`) and for test-only churn mirroring the source renames.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
