## Reviso review — HEAD (detached) vs `a308075bc3` (14 commits, 22 files)

Found 9 issues:

1. **[P0][conf 95] Google Meet fallback crashes when there is no destination calendar** — `packages/core/EventManager.ts:119`
   Failure: `const [mainHostDestinationCalendar] = evt.destinationCalendar ?? []` yields `undefined` whenever `destinationCalendar` is `null`/`[]` (handleNewBooking sets `null` when neither the event type nor the organizer has one; `confirm.handler.ts`, `webhook.ts`, `bookingReminder.ts` all pass `[]`). The next line dereferences `.integration` unguarded, so a Google Meet booking by a user without a Google Calendar throws `TypeError: Cannot read properties of undefined` — exactly the case the fallback was written to handle. TS won't catch it: array destructuring is typed non-optional without `noUncheckedIndexedAccess`.
   Fix: `if (evt.location === MeetLocationType && mainHostDestinationCalendar?.integration !== "google_calendar")`.
   (bugs)

2. **[P0][conf 90] Organization `slug` / `requestedSlug` logic inverted** — `packages/trpc/server/routers/viewer/organizations/create.handler.ts:151`
   Failure: `db92960dc4` ("fix change from main spread operator") rewrote `...(!IS_TEAM_BILLING_ENABLED && { slug })` as `...(IS_TEAM_BILLING_ENABLED ? { slug } : {})`, flipping the condition. With billing enabled the org is now created with a live `slug` *and* a `requestedSlug` (bypassing the pending-payment gate); with billing disabled the org is created with no slug at all. Unrelated to this branch's destination-calendar concern.
   Fix: `...(IS_TEAM_BILLING_ENABLED ? {} : { slug })` — only the `&&`→ternary shape needed to change, not the polarity.
   (history)

3. **[P1][conf 90] Google `updateEvent`/`deleteEvent` fallback compares `externalCalendarId` to itself** — `packages/app-store/googlecalendar/lib/CalendarService.ts:256`, also `:317`
   Failure: the `find` only runs when `externalCalendarId` is falsy, so `cal.externalId === externalCalendarId` is `cal.externalId === undefined` and always misses. `updateEvent` then passes `calendarId: undefined` to `calendar.events.update` (request fails); `deleteEvent` falls through to `"primary"` and deletes from the wrong calendar — and Google's 404 is swallowed as a resolve, so the stale event silently survives. Previously both fell back to `destinationCalendar.externalId`.
   Fix: fall back to the main host destination calendar, e.g. `event.destinationCalendar?.[0]?.externalId`, or match on `credentialId` as `createEvent` does.
   (bugs)

4. **[P1][conf 90] Video booking references lose their `credentialId` — silent revert of #9281** — `packages/core/EventManager.ts:170`
   Failure: `credentialId: isCalendarType ? result.credentialId : undefined` drops the non-calendar branch. Commit `d0707422b9` ("fix: Credential of type video wrong id on bookingReference", PR #9281) deliberately introduced `: result.credentialId` there so video references store the right credential. Every new `*_video` booking reference now persists `credentialId: undefined`, reintroducing the bug that fix closed.
   Fix: `credentialId: isCalendarType ? result.credentialId : result.credentialId ?? undefined` — i.e. keep `result.credentialId` on both branches.
   (history)

5. **[P1][conf 85] New booking references lose `externalCalendarId` for destinations without a `credentialId`** — `packages/core/EventManager.ts:380`
   Failure: `referencesToCreate` now reads `externalCalendarId` from `result.externalId`, which `createEvent` only sets when the caller passes it. In the `else` branch (destination calendar with no `credentialId`) `createEvent(c, event)` is called without `destination.externalId`, so the reference is written with `externalCalendarId: undefined` — previously it got `evt.destinationCalendar?.externalId`. Those bookings then hit finding 3's broken fallback on update/delete.
   Fix: pass it through — `createEvent(c, event, destination.externalId)`.
   (bugs)

6. **[P2][conf 85] `updateAllCalendarEvents` catch block no longer logs anything** — `packages/core/EventManager.ts:592`
   Failure: `console.error(message)` was removed but `message` is still built, so calendar-update failures are now swallowed entirely — no log line, only `success: false` results. `message` is dead code.
   Fix: restore `console.error(message)` (or `logger.error`) before the `return`.
   (history)

7. **[P2][conf 85] Recurring-cancellation deletes are re-run once per calendar reference** — `packages/features/bookings/lib/handleCancelBooking.ts:445`
   Failure: the recurring branch iterates *all* user calendar credentials × *all* updated bookings' references and ignores the loop variable `reference`. Now that it sits inside `for (const reference of bookingCalendarReference)`, a collective booking with N calendar references issues N identical passes of `deleteEvent` calls — N× the Google API traffic for the same events.
   Fix: hoist the `recurringEvent && recurringEventId && allRemainingBookings` block out of the per-reference loop and run it once.
   (bugs)

8. **[P2][conf 80] Team destination calendars silently dropped when the organizer has none** — `packages/features/bookings/lib/handleNewBooking.ts:1078`
   Failure: `evt.destinationCalendar?.push(...teamDestinationCalendars)` is a no-op when `destinationCalendar` is `null`, which is exactly the case when neither the event type nor the organizer has a destination calendar. For a COLLECTIVE event, every member's calendar is then discarded and the feature this branch adds doesn't apply.
   Fix: build the array first — `const destinationCalendars = [...(eventType.destinationCalendar ? [eventType.destinationCalendar] : organizerUser.destinationCalendar ? [organizerUser.destinationCalendar] : []), ...teamDestinationCalendars]` and assign that.
   (bugs)

9. **[P2][conf 80] 22-line credential-from-DB block duplicated verbatim** — `packages/core/EventManager.ts:343`, also `:516`
   Failure: the identical `prisma.credential.findUnique` + manual field-by-field remap appears twice in the same class (`createAllCalendarEvents` and `updateAllCalendarEvents`). Any change to the credential shape has to be made in both, and the second copy leaves `credential` possibly `undefined` before `updateEvent(credential, ...)`.
   Fix: extract one `private async getCredentialById(id: number)` helper returning `CredentialWithAppName | undefined`, and skip the reference when it returns nothing.
   (slop)

Checked: bugs, conventions (no CLAUDE.md/AGENTS.md in this repo), history, comments, slop.
Skipped: `apps/web/playwright/webhook.e2e.ts` (snapshot value follows the type change); the deterministic detector suite did not run — permission for `detectors/run.sh` was declined, so no `deterministic` findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
