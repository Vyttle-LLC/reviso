Detectors were not run — the `run.sh` invocation required approval and was declined. Everything below is from manual review.

## Reviso review — HEAD (detached) vs 5634ca44f7 (7 commits, 4 files)

Found 3 issues:

1. **[P1][conf 90] Denial cache key omits identity type — `anonymous:0` and `render:0` collide** — `pkg/services/authz/rbac/cache.go:30`, set/read at `pkg/services/authz/rbac/service.go:116` and `:154`
   Failure: `userPermDenialCacheKey` is keyed on `(namespace, userUID, action, name, parent)` with no identity type, and it is now used for *all four* supported identity types. `pkg/services/user/identity.go:296-298` gives both anonymous users and the render service the identifier `"0"`. So: anonymous is denied `dashboards:read` on a restricted dashboard → `org-1.perm_0_dashboards:read_dash5_fold1` is cached → the render service (which `getRendererPermissions` grants wildcard read to, `service.go:446`) checks the same dashboard within 30s and is wrongly denied, breaking image rendering for exactly the restricted dashboards. The reverse also holds: a renderer denied `dashboards:write` poisons an anonymous Editor's write check. The pre-existing key functions avoided this by construction — `userPermCacheKey` is only reached for user/service-account, anonymous has its own `anonymousPermCacheKey`, and the renderer has none.
   Fix: include the identity type in the key, e.g. `func userPermDenialCacheKey(namespace string, idType types.IdentityType, userUID, action, name, parent string) string { return namespace + ".perm_denial_" + string(idType) + "_" + userUID + "_" + action + "_" + name + "_" + parent }`. The distinct `perm_denial_` prefix also keeps `bool` denial entries out of the `perm_` keyspace that `map[string]bool` permission entries share in the same underlying `cache.Cache`.
   (bugs)

2. **[P2][conf 90] `Should deny on explicit cache deny entry` passes with the denial cache removed** — `pkg/services/authz/rbac/service_test.go:982`
   Failure: the comment says "Allow access to the dashboard to prove this is not checked", but the seeded scope map is `{"dashboards:uid:dash1": false}` — a `false` value grants nothing. `checkPermission` falls through to `checkInheritedPermissions`, which denies on the empty fake folder tree, then the fallback DB fetch returns the default empty `fakeStore` permissions and denies again. Delete the `permDenialCache.Set` at line 979 and `assert.False` still holds, so the only new short-circuit in `Check` is untested.
   Fix: `s.permCache.Set(ctx, userPermCacheKey("org-12", "test-uid", "dashboards:read"), map[string]bool{"dashboards:uid:dash1": true})` — with `true` the test fails unless the denial cache short-circuits at `service.go:117`.
   (bugs; comment claims a guarantee the code doesn't enforce)

3. **[P2][conf 85] Dead `cacheHit` scaffolding left in `TestService_getUserPermissions`** — `pkg/services/authz/rbac/service_test.go:337`
   Failure: removing the "should return permissions from cache if available" case leaves `cacheHit` `false` in both remaining cases, so the seeding block at lines 367-369 and the `require.Equal(t, 1, store.calls)` assertion at 388-390 are unreachable. Future readers will assume the cached path is still covered here; it isn't (`getUserPermissions` no longer reads `permCache` at all).
   Fix: drop the `cacheHit` field and both `if tc.cacheHit` branches, keeping only the `require.Equal(t, 3, store.calls)` assertion.
   (slop)

Checked: bugs, conventions (no CLAUDE.md/AGENTS.md in repo root or `pkg/services/authz/`), history, comments, slop.
Skipped: nothing. Deterministic detectors: not run (permission declined).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
