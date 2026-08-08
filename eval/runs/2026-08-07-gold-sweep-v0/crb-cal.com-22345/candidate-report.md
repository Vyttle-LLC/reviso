## Reviso review — HEAD vs c9a47dd0 (9 commits, 2 files)

Found 4 issues:

1. **[P1][conf 85] `getBaseConditions()` can return an unparenthesized top-level `OR`** — packages/lib/server/service/insightsBooking.ts:68
   Failure: for `scope: "org"`/`"team"` with no filters, the returned SQL is `(A AND B) OR (C AND D)` with no outer parens (built by the reducers at insightsBooking.ts:171-174 and :204-207, returned verbatim by the `else if (authConditions)` branch at :74). This method exists to be composed into a larger `WHERE` — it replaced `findMany(findManyArgs)`, which let callers pass their own `where`. A caller writing ``$queryRaw`... WHERE ${base} AND "startTime" >= ${from}` `` gets `A AND B OR (C AND D AND startTime>=from)` by SQL precedence, so the team-booking branch ignores the date filter entirely and returns rows outside the requested range. The one integration test that actually executes SQL (insightsBooking.integration-test.ts:481) uses `scope: "user"`, whose condition is `AND`-only, so it never hits this.
   Fix: wrap once at the boundary — `return Prisma.sql\`(${authConditions})\`` in the auth-only branch, or better, have both reducers and `getBaseConditions` return `Prisma.sql\`(${result})\`` so every public condition getter is self-contained.
   (bugs)

2. **[P2][conf 85] Three unreachable branches in `getBaseConditions()`** — packages/lib/server/service/insightsBooking.ts:74
   Failure: `getAuthorizationConditions()` is typed `Promise<Prisma.Sql>` and `buildAuthorizationConditions()` returns `NOTHING_CONDITION` rather than null on every early exit, so `authConditions` is always a truthy object. Lines 76-80 (`else if (filterConditions)` and the `else` fallback) can never execute; the code reads as if auth conditions are optional, which invites a future reader to assume a missing-auth path exists.
   Fix:
   ```ts
   async getBaseConditions(): Promise<Prisma.Sql> {
     const authConditions = await this.getAuthorizationConditions();
     const filterConditions = await this.getFilterConditions();
     if (!filterConditions) return authConditions;
     return Prisma.sql`(${authConditions}) AND (${filterConditions})`;
   }
   ```
   (slop)

3. **[P2][conf 82] Org and team auth SQL lost all execution coverage** — packages/lib/server/service/__tests__/insightsBooking.integration-test.ts:292
   Failure: the org (:292) and team (:329) tests now assert `toEqual` against a hand-written `Prisma.sql` literal that mirrors the implementation, and nothing runs it. Before this change those paths went through `findMany`, which hit the database. `"teamId" = ANY(${teamIds})` with an array bind is a pattern that appears nowhere else in this repo — existing raw queries use `IN (${Prisma.join(ids)})` (packages/trpc/server/routers/viewer/availability/team/listTeamAvailability.handler.ts:174) or `unnest(ARRAY[${Prisma.join(...)}])` (packages/features/insights/server/routing-events.ts:830). If the `ANY(...)` binding is wrong for this driver, both authorization scopes fail at runtime with a green test suite.
   Fix: mirror the `getBaseConditions` test — run `prisma.$queryRaw` with the org- and team-scope conditions against seeded bookings and assert on returned ids, instead of on the `Prisma.Sql` object.
   (bugs)

4. **[P2][conf 80] `InsightsBookingServicePublicOptions` drops the discriminant, turning a compile error into silent no-data** — packages/lib/server/service/insightsBooking.ts:29
   Failure: the constructor's public type widens `scope` to a bare union and makes `teamId` optional, replacing the discriminated union it validates against (:21-26). `new InsightsBookingService({ prisma, options: { scope: "team", userId, orgId } })` now typechecks, `safeParse` fails at :62, `this.options` becomes `null`, and every query silently resolves to `1=0` — an authorization misconfiguration surfaces as an empty insights dashboard with no error. Previously TypeScript rejected it. The sibling service keeps the union in its constructor signature (packages/lib/server/service/insightsRouting.ts:52).
   Fix: use `options: InsightsBookingServiceOptions` in the constructor signature and delete the widened type; if a widened entry point is genuinely needed, throw on `!validation.success` instead of falling through to `null`.
   (conventions)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. The deterministic detector suite was not run — the command needs approval and was declined, so no `deterministic` findings are included above.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
