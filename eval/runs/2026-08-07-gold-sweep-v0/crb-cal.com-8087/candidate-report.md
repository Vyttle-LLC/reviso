Detector suite (Step 2) needs a permission grant I didn't get, so that step was skipped — everything below is from my own pass.

## Reviso review — HEAD vs ba9688a04a (1 commit, 12 files)

Found 2 issues:

1. **[P1][conf 90] `import()` in the object literal runs eagerly — nothing is actually deferred** — `packages/app-store/index.ts:3`
   Failure: `import("./applecalendar")` etc. are *invoked* when `packages/app-store/index.ts` is evaluated, not when a key is read. Any request path that touches the barrel (`handlePayment`, `getCalendar`, `videoClient`, `handleCancelBooking`) still pulls in all 28 app packages — googleapis, stripe, exchange, etc. — so the commit's stated goal ("Async import of the appStore packages") isn't achieved, while every call site now pays `await` plumbing for no benefit. Secondary: the 28 promises sit at module scope with no handler attached until first use, so a single app module that throws at load time surfaces as an `unhandledRejection` (fatal on Node ≥15) instead of a synchronous import error.
   Fix: store thunks and call at the use site — the pattern this repo already uses (`packages/app-store/apps.browser.generated.tsx:8`, `packages/app-store-cli/src/build.ts:193`):
   ```ts
   applecalendar: () => import("./applecalendar"),
   ```
   and at each consumer `const app = await appStore[key]?.();`
   (bugs; also conventions — drift from the repo's own `() => import(...)` idiom)

2. **[P1][conf 85] `forEach(async …)` leaves the calendar/video deletions floating and kills the surrounding error handling** — `packages/trpc/server/routers/viewer/bookings.tsx:553`
   Also at `packages/app-store/vital/lib/reschedule.ts:125` and `packages/app-store/wipemycalother/lib/reschedule.ts:125`.
   Failure: `forEach` discards the returned promise, so on a request-reschedule the handler now returns while `getCalendar()`'s dynamic import is still pending — the `deleteEvent`/`deleteMeeting` calls are no longer even *initiated* before the response is sent (previously `getCalendar` was synchronous, so the delete request was in flight before return). On a serverless runtime that freezes after the response, the stale calendar event is never removed. In the two `reschedule.ts` copies the enclosing `try/catch` at line 124 is also now dead: a rejection inside the async callback escapes as an unhandled rejection rather than hitting `logger.error`.
   Fix: use the same `for…of` + `await` shape this PR correctly applied at `packages/features/bookings/lib/handleCancelBooking.ts:480`:
   ```ts
   for (const bookingRef of bookingRefsFiltered) {
     if (!bookingRef.uid) continue;
     if (bookingRef.type.endsWith("_calendar")) {
       const calendar = await getCalendar(credentialsMap.get(bookingRef.type));
       await calendar?.deleteEvent(bookingRef.uid, builder.calendarEvent, bookingRef.externalCalendarId);
     } else if (bookingRef.type.endsWith("_video")) {
       await deleteMeeting(credentialsMap.get(bookingRef.type), bookingRef.uid);
     }
   }
   ```
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (permission not granted); no files skipped.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
