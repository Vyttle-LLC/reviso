## Reviso review — HEAD (detached) vs b8c1cd41 (1 commit, 10 files)

Found 4 issues:

1. **[P0][conf 90] A permission scoped to a single client grants realm-wide client management** — `services/src/main/java/org/keycloak/services/resources/admin/permissions/ClientPermissionsV2.java:237`
   Failure: `hasPermission(String scope)` evaluates the `Clients` resource-type ("all-clients") resource with no check that the granting policy is actually associated with that resource. `DefaultPolicyEvaluator` (`DefaultPolicyEvaluator.java:74`) pulls in **every** policy with `resourceType = "Clients"` via `findByResourceType`, including per-client permissions, and `DecisionPermissionCollector` grants their scopes onto the all-clients permission. So: grant `myadmin` a Clients permission with `resources={myclient}, scopes={manage}` (exactly what the new `testManageOnlyOneClient` does) → `canManage()` at line 72 returns `true` → `ClientsResource.createClient` (`ClientsResource.java:186`, `auth.clients().requireManage()`) lets that admin create arbitrary new clients, and `canManageClientScopes()` (line 106) lets them create/delete realm client scopes. Same shape with `{view}` for a single client: `canView()` (line 86) returns `true`, so `canView(ClientModel)` short-circuits and every client in the realm becomes visible. The sibling overload `hasPermission(ClientModel, String)` at line 219 does gate the all-clients fallback on `policyStore.findByResource(...).isEmpty()` — this one has no gate at all. This is the same class of bug as #36838, fixed for `Users` in c2acddc7ca three days earlier.
   Fix: restrict the decision to policies bound to the all-clients resource — e.g. evaluate only `policyStore.findByResource(server, resource)` for the requested scope, rather than accepting any granted scope from the resource-type-wide evaluation. Add tests asserting that a single-client `manage` permission does *not* satisfy `requireManage()`/`requireManageClientScopes()`, and that a single-client `view` permission does not list all clients.
   (bugs / history)

2. **[P2][conf 90] Dead code and unused imports in the new ClientPermissionsV2** — `services/src/main/java/org/keycloak/services/resources/admin/permissions/ClientPermissionsV2.java:262`
   Failure: `getEvaluationContext(ClientModel, AccessToken)` (lines 262–272) is private and never called — the only method that would have used it, `canExchangeTo`, throws `UnsupportedOperationException` at line 148. `logger` (line 51) is never used. The imports `org.keycloak.authorization.model.Scope` (27) and the static `AdminPermissionManagement.TOKEN_EXCHANGE` (46) are unused, and `ClientModelIdentity`/`DefaultEvaluationContext`/`EvaluationContext` (22, 23, 29) exist only for the dead method. `UserPermissionsV2`, the file this was modelled on, carries none of this.
   Fix: delete `getEvaluationContext`, `logger`, and the six now-unused imports. Separately, `hasPermission(ClientModel, String)` and `hasPermission(String)` are ~20 duplicated lines apart from resource lookup — collapse them into one method taking the resolved `Resource`.
   (slop)

3. **[P2][conf 85] New javadoc describes two void methods as returning a boolean** — `services/src/main/java/org/keycloak/services/resources/admin/permissions/ClientPermissionEvaluator.java:96`
   Failure: `requireView()` (line 98) is documented as "Returns `true` if `canView()` returns `true`" and `requireViewClientScopes()` (line 103) as "Returns `true` if `canViewClientScopes()` returns `true`". Both are `void` and throw `ForbiddenException` — every other `require*` in the same batch of javadoc correctly says "Throws ForbiddenException if …". A caller reading these expects a boolean return and will not guard for the exception.
   Fix: change both to "Throws ForbiddenException if `canView()` / `canViewClientScopes()` returns `false`."
   (comments)

4. **[P2][conf 80] Clients resources have no display name in the permission UI** — `server-spi-private/src/main/java/org/keycloak/authorization/AdminPermissionsSchema.java:304`
   Failure: `getResourceName(session, policy, resource)` was extended for `USERS` only — it maps the all-users resource to "All users" and per-user resources to the username. The new `CLIENTS` type falls through to `resource.getDisplayName()`, which is never set for resources created by `getOrCreateResource` (line 104) or by `init` (line 249). `PolicyResourceService.getResources` (`PolicyResourceService.java:218`) feeds that straight into `ResourceRepresentation.displayName`, so a Clients scope permission shows a blank display name and a raw client UUID in the admin console, where a Users permission shows the username.
   Fix: add a `CLIENTS.getType()` branch mirroring the `USERS` one — return "All clients" for the resource-type resource and `client.getClientId()` for per-client resources, resolved via `session.clients().getClientById(...)`.
   (conventions)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. Note: the deterministic detector suite was not approved to run, so its findings are absent from this pass — re-run `/reviso:review` and approve the `detectors/run.sh` prompt to include them.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
