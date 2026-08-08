## Reviso review — HEAD (detached) vs 30a92a4d66 (27 commits, 17 files)

Found 7 issues:

**1. [P1][conf 88] "Delete cached data" is exposed on surfaces that explicitly disable connection modification — packages/features/apps/components/CredentialActionsDropdown.tsx:71**
Failure: `hasCache` (line 69) is computed independently of `disableConnectionModification`, and the render gate at line 71 returns null only when *both* `canDisconnect` and `hasCache` are false. `EventAdvancedTab.tsx:375` renders `SelectedCalendarsSettingsWebWrapper` with `disableConnectionModification={true}` — previously no action element rendered there at all. Now any Google Calendar with a cache row shows the dropdown with a destructive, credential-wide "Delete cached data" action on the event-type Advanced tab. That surface also passes no `onChanged`, so `onSuccess` is undefined and the stale timestamp stays on screen after deletion (`deleteCacheMutation` has no `onSettled` invalidation, unlike `disconnectMutation` at line 60).
Fix: gate cache actions on the same flag — `const hasCache = isGoogleCalendar && cacheUpdatedAt && !disableConnectionModification;` — or split "show status" from "allow delete" and gate only the delete item. Separately, mirror the disconnect mutation's `onSettled` invalidation on `deleteCacheMutation`.
(bugs)

**2. [P1][conf 85] Cache reads/deletes bypass the `CalendarCache.init()` feature-flag factory, making the mock added in this PR dead code — packages/trpc/server/routers/viewer/calendars/connectedCalendars.handler.ts:28**
Failure: `new CalendarCacheRepository()` is the only direct instantiation outside `calendar-cache.ts` itself; every other consumer (`api/cron.ts:80`, `CalendarService.ts:463/616/981`, `apps/web/app/api/availability/calendar/route.ts:95`) goes through `CalendarCache.init`/`initFromCredentialId`, which returns `CalendarCacheRepositoryMock` when the global `calendar-cache` feature flag is off. This PR adds `getCacheStatusByCredentialIds` to the mock with the log line "Skipping … due to calendar-cache being disabled" — an explicit claim that the disabled path is handled — but that branch is unreachable from the only caller. With the flag off, the UI still renders "Cache Status / Last updated" and offers cache deletion driven by stale rows. `deleteCache.handler.ts:28` bypasses the same factory with a raw `prisma.calendarCache.deleteMany`, contradicting commit c615a404c7's stated "Replace direct Prisma calls with CalendarCacheRepository pattern".
Fix: `const cacheRepository = await CalendarCache.init(null);` in the handler, and route the delete through the repository interface too (add a `deleteManyByCredentialId` member to `ICalendarCacheRepository` alongside the existing mock-only `deleteManyByCredential`).
(bugs; enforcement-vs-claim)

**3. [P2][conf 82] Dead `SelectedCalendar.updatedAt` plumbing writes on every webhook-driven cache refresh — packages/app-store/googlecalendar/lib/CalendarService.ts:1024**
Failure: `updateManyByCredentialId(this.credential.id, {})` issues an unconditional `UPDATE` across *every* `SelectedCalendar` row for the credential on each `fetchAvailabilityAndSetCache` call (i.e. each Google webhook), relying on an implicit Prisma `@updatedAt` bump from an empty `data` object. Nothing reads the result: the UI's timestamp comes from `cacheUpdatedAt` (`CalendarCache._max.updatedAt`), and `updatedAt`/`googleChannelId` — added to `UserWithCalendars` (getConnectedDestinationCalendars.ts:23,27) and to the per-request session-user select (`user.ts:899-900`, `findUnlockedUserForSession`) — are never referenced anywhere. It is also semantically wrong for its stated purpose: it bumps rows for calendars that were not in the refreshed `selectedCalendars` set.
Fix: drop the `updateManyByCredentialId` call, the `updateManyByCredentialId` repository method, the two `UserWithCalendars` field additions, and the two extra fields in the session-user select — leftovers from commit 14dfef842c's design, superseded by credential-level `cacheUpdatedAt`.
(slop; history)

**4. [P2][conf 82] Dev script writes `.env` outside the repo and exits 0 on failure — scripts/test-gcal-webhooks.sh:5**
Failure: `ENV_FILE="../.env"` resolves against the caller's CWD. The repo's `.env` is at the repo root (`.gitignore:4`); run as `sh scripts/test-gcal-webhooks.sh` from the root it targets the *parent directory of the repo*, and line 64 silently `touch`es a new file there, then line 73 prints "✅ Updated GOOGLE_WEBHOOK_URL" — the developer believes webhooks are configured when nothing in the repo changed. Additionally, the rate-limit and "failed to extract URL" paths call `cleanup`, which ends in `exit 0`, so hard failures report success to any caller. `sed -i ''` (line 68) is also BSD-only and fails on Linux.
Fix: resolve the path from the script location — `ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"` — and give `cleanup` an exit-code argument so failure paths exit non-zero.
(bugs)

**5. [P2][conf 82] Cache timestamp is hardcoded to `en-US` inside a localized component — packages/features/apps/components/CredentialActionsDropdown.tsx:89**
Failure: `new Intl.DateTimeFormat("en-US", …)` renders US month/day ordering and 12-hour time for every user, while the surrounding labels come from `useLocale()` two lines up. A German or Japanese user sees a fully translated dropdown with `7/15/25, 4:06 PM`. The `interpolation: { escapeValue: false }` workaround on line 93 exists only because that hardcoded format emits `/`.
Fix: pull the active locale off `useLocale()` and pass it in (`const { t, i18n } = useLocale(); … new Intl.DateTimeFormat(i18n.language, …)`), or use the repo's existing date-formatting helpers.
(bugs; conventions)

**6. [P2][conf 80] Authorization denial in `deleteCache` throws a bare `Error`, surfacing as a 500 — packages/trpc/server/routers/viewer/calendars/deleteCache.handler.ts:25**
Failure: a plain `Error` from a tRPC procedure is coerced to `INTERNAL_SERVER_ERROR`, so a routine "not your credential" denial is reported as a server fault (and the message is masked in production). The sibling handler in the same directory uses `TRPCError` for exactly this (`setDestinationCalendar.handler.ts:77,97`). Error monitoring will page on ordinary authz rejections.
Fix: `throw new TRPCError({ code: "NOT_FOUND", message: "Credential not found or access denied" });`
(conventions)

**7. [P2][conf 80] Raw Tailwind gray classes instead of the codebase's semantic tokens, flattening dark-mode hierarchy — packages/features/apps/components/CredentialActionsDropdown.tsx:86**
Failure: `packages/features` uses semantic tokens (`text-emphasis`/`text-subtle`) in 357 places versus 12 raw `text-gray-900`/`text-gray-500`. Beyond the drift, both lines 86 and 87 use `dark:text-white`, so in dark mode the secondary "Last updated" line renders the same pure white as the "Cache Status" heading, erasing the intended contrast between them.
Fix: `<div className="text-emphasis text-sm font-medium">` and `<div className="text-subtle text-xs">`, dropping both `dark:` overrides.
(slop; conventions)

Checked: bugs, conventions, history, comments, slop.
Skipped: `apps/web/public/static/locales/en/common.json` (data only — all 12 keys referenced by the new component resolve), `packages/prisma/migrations/…/migration.sql` (matches the schema change; the stale auto-generated "without a default value" warning comment is cosmetic), deterministic detector suite (`detectors/run.sh` was not approved to run, so no `deterministic`-tagged findings are included).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
