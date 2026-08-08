## Reviso review — HEAD vs b004587262 (26 commits, 15 files)

Found 7 issues:

1. **[P1][conf 92] Adding guests bypasses the "seats disable guests" invariant and inflates seat counts** — `packages/trpc/server/routers/viewer/bookings/addGuests.handler.ts:95`
   Failure: `EventAdvancedTab.tsx:468` states "Enabling seats will disable guests and requiring confirmation until fully supported", and `toggleGuests` hides the `guests` booking field for seated event types. The new endpoint has no `seatsPerTimeSlot` guard, so an attendee on a 2-seat booking can `createMany` 5 attendee rows. `getCurrentSeats` (`packages/core/getUserAvailability.ts:157-172`) counts `booking.attendees` directly, so the slot immediately reports over-capacity. The new rows also have no `BookingSeat`, so those guests can never cancel their seat.
   Fix: reject when `booking.eventType?.seatsPerTimeSlot` is set (`BAD_REQUEST`), and hide the menu item in `BookingListItem.tsx:193` for seated bookings.
   (bugs, comments, history)

2. **[P1][conf 92] Guest-email blacklist is case-sensitive here, so it can be bypassed** — `packages/trpc/server/routers/viewer/bookings/addGuests.handler.ts:71,77`
   Failure: the env list is lowercased (`.map((email) => email.toLowerCase())`) but the candidate is compared raw: `!blacklistedGuestEmails.includes(guest)`. With `BLACKLISTED_GUEST_EMAILS=spam@evil.com`, submitting `Spam@Evil.com` passes the filter and the address is added as an attendee and emailed. The established pattern at `packages/features/bookings/lib/handleNewBooking.ts:742-743` normalizes both sides *and* strips plus-aliases.
   Fix: mirror that code — `const baseGuestEmail = extractBaseEmail(guest).toLowerCase(); blacklistedGuestEmails.some((e) => e === baseGuestEmail)`.
   (bugs, conventions)

3. **[P2][conf 90] `isTeamAdminOrOwner` uses `&&`, which reduces to owner-only** — `packages/trpc/server/routers/viewer/bookings/addGuests.handler.ts:46-48`
   Failure: `isTeamAdmin` (`packages/lib/server/queries/teams/index.ts:264`) already matches `role IN (ADMIN, OWNER)`; ANDing it with `isTeamOwner` (OWNER only) narrows the result to OWNER. A team ADMIN who is neither the booking's host nor an attendee gets `FORBIDDEN`, contradicting the variable's name. It also fires two queries where one suffices.
   Fix: `const isTeamAdminOrOwner = !!(await isTeamAdmin(user.id, booking.eventType?.teamId ?? 0));`
   (bugs)

4. **[P2][conf 88] Server schema doesn't enforce the uniqueness its error message claims** — `packages/trpc/server/routers/viewer/bookings/addGuests.schema.ts:5`
   Failure: uniqueness is validated only client-side (`AddGuestsDialog.tsx:26-29`). `uniqueGuests` filters against *existing* attendees but not against duplicates within `guests`, so a direct tRPC call with `guests: ["a@x.com", "a@x.com"]` passes both to `createMany`, creating two identical attendee rows (no unique constraint on booking+email) and sending two invites — while the handler's own error key is `emails_must_be_unique_valid`.
   Fix: move the client's refine onto the server schema — `guests: z.array(z.string().email()).refine((e) => new Set(e).size === e.length)` — and delete the duplicated local schema in the dialog.
   (bugs, slop)

5. **[P2][conf 88] `you_do_not_have_permission` has no translation, so the raw key is shown** — `packages/trpc/server/routers/viewer/bookings/addGuests.handler.ts:55`
   Failure: the dialog renders `` `${err.data?.code}: ${t(err.message)}` `` (`AddGuestsDialog.tsx:43`). The key was not added to `apps/web/public/static/locales/en/common.json` (the diff adds the other five new keys), so an unauthorized user sees the toast `FORBIDDEN: you_do_not_have_permission`.
   Fix: reuse the existing `dont_have_permission` key (common.json:1628) or add the new one.
   (bugs, conventions)

6. **[P2][conf 85] Existing attendees get a fresh "scheduled" invite instead of the add-guests notice** — `packages/emails/email-manager.ts:541`, `packages/trpc/server/routers/viewer/bookings/addGuests.handler.ts:168`
   Failure: the handler passes the raw `guests` input, not the filtered `uniqueGuests`. `newGuests.includes(attendee.email)` therefore matches attendees that were filtered out as already-existing, so submitting a new guest alongside an already-invited address re-sends that person a full `AttendeeScheduledEmail` with a REQUEST ICS rather than `AttendeeAddGuestsEmail`.
   Fix: `await sendAddGuestsEmails(evt, uniqueGuests);`
   (bugs)

7. **[P2][conf 85] `isInvalidEmail` is never cleared except on Cancel, so the error persists** — `apps/web/components/dialog/AddGuestsDialog.tsx:33,36-41`
   Failure: after one failed validation, correcting the emails and submitting successfully closes the dialog but leaves `isInvalidEmail === true` (`onSuccess` resets `multiEmailValue` but not this flag). Reopening the dialog shows "Emails must be unique and valid" over an empty, valid form. Dismissing via Esc/overlay (`onOpenChange`) leaves both states stale the same way.
   Fix: add `setIsInvalidEmail(false)` to `onSuccess` and at the top of `handleAdd`, or reset both states from `onOpenChange` instead of only the Cancel button.
   (bugs)

Checked: bugs, conventions, history, comments, slop. No root `CLAUDE.md`/`AGENTS.md` in this repo.
Skipped: `apps/web/public/static/locales/en/common.json` (data-only, cross-checked for key coverage). The deterministic detector suite was not approved to run, so no `deterministic` findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
