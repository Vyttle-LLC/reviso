## Reviso review — HEAD (detached, `feat/sync-app-credentials`) vs `bc89fe00ea` (25 commits, 39 files)

Found 5 issues:

1. **[P0][conf 95] Google Calendar credential key is overwritten with the zod result wrapper, not the parsed key** — `packages/app-store/googlecalendar/lib/CalendarService.ts:97`
   Failure: `parseRefreshTokenResponse` returns the `safeParse` **result** (`{ success: true, data: {...} }`), but the old code assigned the parsed object (`googleCredentialSchema.parse(...)`). So `prisma.credential.update({ data: { key } })` now writes `{"success":true,"data":{...}}` into `Credential.key`. On the next load, `googleCredentialSchema.parse(credential.key)` (line 75) throws — Google Calendar breaks permanently for every user the moment their token first refreshes. This fires with credential sharing **off** too, so it hits all deployments. It typechecks because the inferred return type is `SafeParseSuccess<any>` and `data: any` satisfies Prisma's `InputJsonValue`.
   Fix: `const key = parseRefreshTokenResponse(googleCredentials, googleCredentialSchema).data;` — or better, have `parseRefreshTokenResponse` return `refreshTokenResponse.data` since it already throws on failure, and drop the now-dead `if (!parsed.success)` branches in the zoom/salesforce callers.
   (bugs)

2. **[P1][conf 95] `minimumTokenResponseSchema`'s computed keys collapse to a single literal key; the expiry claim is never enforced** — `packages/app-store/_utils/oauth/parseRefreshTokenResponse.ts:7`
   Failure: `[z.string().toString()]` and `[z.string().optional().toString()]` both stringify a ZodType instance to the literal `"[object Object]"`, so the shape is `{ access_token, "[object Object]" }` — the second entry overwrites the first and `z.number()` is discarded entirely. The comment "Assume that any property with a number is the expiry" describes behaviour the schema cannot have (a fixed key can never match a dynamic one). With sharing enabled zod then strips every other field: zoom computes `expiry_date = Math.round(Date.now() + undefined * 1000)` → `NaN` (`zoomvideo/lib/VideoApiAdapter.ts:122`), and office365 never updates `expires_in` (`office365calendar/lib/CalendarService.ts:265`) — both treat the token as permanently expired and re-refresh on every call.
   Fix: use `z.object({ access_token: z.string() }).catchall(z.unknown())`, or explicitly model the expiry (`expires_in: z.number().optional(), expiry_date: z.number().optional()`); drop the computed-key trick.
   (bugs / enforcement-vs-claim)

3. **[P1][conf 90] `refreshOAuthTokens` returns a raw `fetch` Response in the sharing branch, but four callers expect an SDK/axios shape** — `packages/app-store/_utils/oauth/refreshOAuthTokens.ts:12`
   Failure: with `CALCOM_CREDENTIAL_SYNC_ENDPOINT` set, the helper returns a `Response`, never a parsed body. Fetch-based callers (office365, zoom, webex, lark) are fine; the others are not: `googlecalendar/lib/CalendarService.ts:94` does `res?.data` → `undefined` → `token.access_token` throws, caught by the `catch`, which returns stale credentials silently; `hubspot/lib/CalendarService.ts:192` reads `.expiresIn`/`.accessToken` off a `Response` and persists `NaN`/`undefined`; `zohocrm/lib/CalendarService.ts:213` and `zoho-bigin/lib/CalendarService.ts:95` read `.data.error` off a `Response` → `TypeError`. Credential sync is therefore broken for exactly the apps it was wired into. The helper also never checks `response.ok`.
   Fix: make the sharing branch parse and normalise (`if (!response.ok) throw ...; return await response.json()`), and give each caller an adapter so both branches return the same shape — or type the helper's return so the mismatch is a compile error instead of a runtime one.
   (bugs)

4. **[P1][conf 90] Zoho Bigin passes `credentialId` where `refreshOAuthTokens` expects `userId`** — `packages/app-store/zoho-bigin/lib/CalendarService.ts:93`
   Failure: `refreshAccessToken(credentialId, credentialKey)` only has the credential id in scope, and it is handed to the `userId` parameter. The sync request then POSTs `calcomUserId: <credential.id>` to the self-hoster's endpoint, which resolves to the wrong user (or no user) — returning another account's access token, or none. Every other app passes `credential.userId`.
   Fix: thread `credential.userId` into `refreshAccessToken` (change the signature to take the `CredentialPayload`, as the other services do) and pass it here.
   (bugs)

5. **[P1][conf 88] Salesforce refreshes the token on every instantiation, then builds the connection with the stale one** — `packages/app-store/salesforce/lib/CalendarService.ts:106`
   Failure: the new block at lines 75–99 unconditionally hits Salesforce's token endpoint on every `SalesforceCalendarService` construction (no expiry check — the other services all gate on `isTokenValid`/`isExpired`), persists the refreshed key, and then constructs `jsforce.Connection` with `accessToken: credentialKey.access_token` / `instanceUrl: credentialKey.instance_url` — the *old* values read before the refresh. The refresh has no effect on the request being served, and if the stored token had actually expired the connection still fails. It also adds a network round-trip to every booking. The `if (!accessTokenParsed.success) return Promise.reject(...)` guard at line 91 is dead: `parseRefreshTokenResponse` throws rather than returning a failure.
   Fix: use `accessTokenParsed.data.access_token` / `.instance_url` for the connection, and gate the refresh on the stored token's expiry instead of running it every time.
   (bugs / conventions)

Checked: bugs, conventions (no CLAUDE.md or AGENTS.md in this repo), history, comments, slop.
Skipped: nothing. Note: the deterministic detector suite was not run — the permission prompt for `detectors/run.sh` was declined, so this pass is model-only.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
