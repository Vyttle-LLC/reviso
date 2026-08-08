Detectors (Step 2) required a permission approval that wasn't granted, so the deterministic suite did not run — findings below are all from manual review.

## Reviso review — HEAD (detached) vs 93cb21f5 (11 commits, 4 files)

Found 3 issues:

**1. [P0][conf 95] New working-hours guard rejects every slot for split or UTC-midnight-crossing schedules — packages/trpc/server/routers/viewer/slots.ts:139**
   Failure: `workingHours.find(wh => slot is outside wh)` returns truthy if *any* range excludes the slot, but a user routinely has several `WorkingHours` entries covering the same weekday. (a) Split shift 09:00–12:00 + 13:00–17:00: the 10:00 slot is rejected by the 13:00–17:00 entry and the 14:00 slot by the 09:00–12:00 entry — the day returns zero slots. (b) `getWorkingHours` (packages/lib/availability.ts:100-119) emits a second overflow entry whenever local hours cross UTC midnight, so an Australia/Sydney organizer with Mon–Fri 09:00–17:00 gets `{days:[1..5], 0–360}` plus `{days:[0..4], 1320–1439}`; Monday 02:00 UTC passes the first and is rejected by the second. `isFixed` defaults to true for any event type without a `schedulingType` (slots.ts:369), so this hits ordinary single-user booking pages, not just round robin. Existing tests only use Asia/Kolkata (04:00–12:30 UTC, single range), so nothing catches it.
   Same pattern at slots.ts:106 for date overrides: a date with two ranges (09:00–12:00 and 14:00–17:00) rejects the 15:00 slot because the first range excludes it.
   Fix: invert to "must be inside at least one range", and use the slot's *end* for the end bound — `end` is currently a copy-paste of `start` (line 142), so slots that overrun `endTime` also slip through:
   ```ts
   const daysWorkingHours = workingHours.filter((wh) => wh.days.includes(slotStartTime.day()));
   const start = slotStartTime.hour() * 60 + slotStartTime.minute();
   const end = slotEndTime.hour() * 60 + slotEndTime.minute();
   if (daysWorkingHours.length && !daysWorkingHours.some((wh) => start >= wh.startTime && end <= wh.endTime))
     return false;
   ```
   Apply the same `.some(insideRange)` shape to the date-override block.
   (bugs)

**2. [P0][conf 92] Busy times are skipped entirely on any day that has a date override — packages/trpc/server/routers/viewer/slots.ts:133**
   Failure: when a date override exists for the slot's day and the slot falls inside it, the `.find` returns falsy, `dateOverrideExist` is true, and the function returns `true` before ever reaching `busy.every(...)`. A user who sets a date override for next Tuesday 09:00–17:00 and already has a booking (or a synced calendar event) Tuesday 10:00–11:00 will have the 10:00 slot offered again — double booking. The later `selectedSlots` pass only re-checks reserved slots, not real busy times, so nothing recovers it.
   Fix: drop the early `return true` and let control fall through to the busy check; the date-override block should only ever return `false`.
   (bugs)

**3. [P1][conf 85] Override day comparison mixes server-local and UTC calendar days — packages/trpc/server/routers/viewer/slots.ts:110**
   Failure: `dayjs(date.start).add(utcOffset, "minutes").format("YYYY MM DD")` formats in the *server's* local timezone, while `slotStartTime.format("YYYY MM DD")` is UTC (`time.utc()` at line 100). On any deployment whose process TZ is not UTC, the day strings disagree near the local-midnight boundary, so overrides are matched to the wrong day or missed entirely — the override guard silently stops applying. The `.isBefore`/`.isAfter` comparisons in the same block are instant-based and unaffected, which is why the bug is invisible in a UTC test runner.
   Fix: use `dayjs.utc(date.start).add(utcOffset, "minutes")` (and likewise for `date.end`) so both sides format in UTC.
   (bugs)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors: not run (permission not granted).
Skipped: nothing — all 4 changed files reviewed. No CLAUDE.md/AGENTS.md found at root or in the changed directories.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
