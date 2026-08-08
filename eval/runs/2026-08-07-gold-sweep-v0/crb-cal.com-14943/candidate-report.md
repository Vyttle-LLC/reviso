## Reviso review — HEAD (detached) vs 917c7b0764 (7 commits, 3 files)

Found 2 issues:

1. **[P1][conf 90] Retry-count bump inside `catch` can throw and abort the whole cron run** — packages/features/ee/workflows/api/scheduleSMSReminders.ts:190
   Failure: `deleteScheduledSMSReminder` (packages/features/ee/workflows/lib/reminders/smsReminderManager.ts:251) deletes `WorkflowReminder` rows when a booking is cancelled/rescheduled. The loop awaits a slow Twilio call per reminder, so a row fetched at line 48 can be gone by the time it is processed. Then the success `update` at :169 throws Prisma `P2025`, control enters the `catch`, and the new `update` at :190 throws `P2025` again — a throw inside a `catch` is not caught by its own `try`, so it escapes the loop. Every remaining reminder in the batch is silently skipped and the endpoint 500s. The same applies to any transient DB error, which is exactly the class of error most likely to have triggered the `catch` in the first place. Before this change the `catch` only logged, so per-reminder failures were isolated.
   Fix: make the increment non-throwing — `await prisma.workflowReminder.updateMany({ where: { id: reminder.id }, data: { retryCount: reminder.retryCount + 1 } })` (a no-op when the row is gone), or wrap it in its own `try/catch`. Same for the `else` branch at :179.
   (bugs, history)

2. **[P1][conf 88] SMS-lock is counted as a retryable failure, permanently deleting pending reminders** — packages/features/ee/workflows/api/scheduleSMSReminders.ts:178
   Failure: `twilio.scheduleSMS` returns `undefined` when the user's/team's `smsLockState` is `LOCKED` (packages/features/ee/workflows/lib/reminders/providers/twilioProvider.ts:92-95) — a deliberate policy state, not a transient error. The new `else` branch increments `retryCount` for it, and the new delete branch at :38-42 hard-deletes any reminder with `retryCount > 1`. The cron runs every 15 minutes (.github/workflows/cron-scheduleSMSReminders.yml:8), so a team that is SMS-locked for ~45 minutes loses **every** pending SMS reminder in the next 7-day window, irrecoverably and with no log line. Unlocking the team does not bring them back; before this change they were simply picked up on the next run after the unlock.
   Fix: don't treat the lock as a retry — have `scheduleSMS` distinguish "locked" from "failed" (e.g. return a discriminated result), or check `isLockedForSMSSending` and `continue` before the increment. Also log the reminder id when a reminder is dropped for exhausted retries, so the deletion isn't silent.
   (bugs)

Checked: bugs, conventions, history, comments, slop. No `CLAUDE.md`/`AGENTS.md` governs the changed paths. The schema change and migration match the existing `WebhookScheduledTriggers.retryCount` pattern and the migration timestamp orders correctly after `20240502213807`.
Skipped: nothing. Note: the deterministic detector suite was not approved to run, so its findings are absent from this pass; `--base` was the only flag used.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
