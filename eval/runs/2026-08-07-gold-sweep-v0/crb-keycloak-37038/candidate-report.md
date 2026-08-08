I could not run the deterministic detector suite (permission denied), so this is the LLM pass only.

## Reviso review — HEAD (detached) vs 7ea067aae9 (1 commit, 19 files)

Found 2 issues:

1. **[P0][conf 90] `getGroupIdsWithViewPermission()` returns authz resource UUIDs, not group IDs** — services/src/main/java/org/keycloak/services/resources/admin/permissions/GroupPermissionsV2.java:123 (also :122)
   Failure: the returned set is stored as `session.setAttribute(UserModel.GROUPS, …)` and matched against `UserGroupMembershipEntity.groupId` in `JpaUserProvider.groupsWithPermissionsSubquery` (model/jpa/…/JpaUserProvider.java:1070), so an admin granted `view-members`/`manage-members` on *all groups* gets a non-empty set of bogus IDs and `GET /admin/realms/{realm}/users` returns zero users; with a per-group grant the set comes back empty and `GET /users/count` reports 0 while `GET /users` still lists members.
   Fix: use the resource **name** in both places — `hasPermission(groupResource.getName(), …)` and `granted.add(groupResource.getName())`. A group resource's name is the group ID (`AdminPermissionsSchema.resolveGroup` returns `group.getId()`, server-spi-private/…/AdminPermissionsSchema.java:185); `Resource.getId()` is a freshly generated UUID (`JPAResourceStore.create` line 66), so `findByName(server, resource.getId())` always misses and silently falls through to the all-groups resource. Both siblings do this correctly: V1 uses `resource.getName().substring(RESOURCE_NAME_PREFIX.length())` (GroupPermissions.java:315) and `ClientPermissionsV2.getClientsWithPermission` uses `resource.getName()` (ClientPermissionsV2.java:140).
   (bugs)

2. **[P0][conf 85] `GroupPermissionsV2.canManage()` grants group creation on a `view`-only permission** — services/src/main/java/org/keycloak/services/resources/admin/permissions/GroupPermissionsV2.java:70
   Failure: an admin holding only an all-groups `view` scope permission passes `auth.groups().requireManage()` in `GroupsResource.addTopLevelGroup` (GroupsResource.java:181) and can create top-level groups — a read-only grant becomes a write grant. This is the only caller of the no-arg `canManage()`, and no test covers it (`testViewGroups` grants all-groups `VIEW` but never attempts a create).
   Fix: `return hasPermission(null, AdminPermissionsSchema.MANAGE);` and drop the `VIEW` clause from the `canManage()` javadoc in GroupPermissionEvaluator.java. The scope list looks copy-pasted from `canView()` two methods above; the per-group `canManage(GroupModel)` at line 79 correctly checks `MANAGE` only, as does `ClientPermissionsV2.canManage()`.
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (`detectors/run.sh` not approved to run); no CLAUDE.md/AGENTS.md exists in this repo, so the conventions lens fell back to in-repo sibling patterns.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
