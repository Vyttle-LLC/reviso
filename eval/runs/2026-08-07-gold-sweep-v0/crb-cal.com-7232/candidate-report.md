Detector suite could not run — the `sh .../detectors/run.sh` invocation was not approved, so this pass is model-review only.

## Reviso review — HEAD (detached) vs d1440bb5d2 (8 commits, 10 files)

Found 2 issues:

1. **[P1][conf 88] One SendGrid failure aborts every remaining cancellation, and no row is ever deleted** — `packages/features/ee/workflows/api/scheduleEmailReminders.ts:53`
   Failure: the whole `for` loop over `remindersToCancel` sits in a single `try`. If any `client.request` rejects (network blip, 4xx on an unknown/already-cancelled `batch_id`), the loop exits to the outer `catch` and every reminder after it keeps its scheduled SendGrid send — reminder emails go out for cancelled/rescheduled bookings, which is exactly what this branch sets out to prevent. Worse, `workflowRemindersToDelete` holds lazy `PrismaPromise`s that are only executed by the `await Promise.all` on line 74; the throw skips it, so not even the reminders already cancelled at SendGrid get their rows deleted. The same failing row is re-fetched on every cron run and re-aborts the loop — a permanent poison pill that silently disables cancellation for all users.
   Fix: move the `try`/`catch` inside the loop, one iteration per reminder, and `await` each `prisma.workflowReminder.delete` immediately after its cancel succeeds — the same per-item error handling the scheduling loop below already uses (`scheduleEmailReminders.ts:105-224`).
   (bugs)

2. **[P1][conf 82] Reminder cancellation is now fire-and-forget; the awaits that guaranteed it were removed** — `packages/trpc/server/routers/viewer/bookings.tsx:486`
   Failure: `await Promise.all(remindersToDelete)` was deleted here, and in `handleCancelBooking.ts:495` the reminder promises were dropped from `prismaPromises`. The replacement `deleteScheduledEmailReminder(...)` / `deleteScheduledSMSReminder(...)` calls are `async` but unawaited inside a `forEach`, so the handler can return before the `cancelled: true` update, the row delete, or `twilio.cancelSMS` completes. On Vercel the function is frozen once the response is sent, so the cancel is lost and the reminder still fires for a cancelled booking. Same pattern at `handleCancelBooking.ts:485`, `handleNewBooking.ts:964`, `workflows.tsx:374`.
   Relatedly, the `try`/`catch` added at `handleNewBooking.ts:964` is dead: `forEach` discards the returned promises, so the `catch` can never observe a rejection (and both helpers already swallow their own errors), yet it reads as error handling that exists.
   Fix: collect the calls and await them — e.g. `await Promise.all(booking.workflowReminders.map((reminder) => reminder.method === WorkflowMethods.EMAIL ? deleteScheduledEmailReminder(...) : deleteScheduledSMSReminder(...)))` — before the handler returns, and drop the no-op `try`/`catch`.
   (bugs, comments)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (not approved); `packages/prisma/migrations/.../migration.sql` and the `schema.prisma` hunk (reviewed, consistent nullable `Boolean`, no finding); the reindented commented-out block at `workflows.tsx:901-963` (dead commented code, pure whitespace churn).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
