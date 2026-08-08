## Reviso review — HEAD vs 28e3db2520 (2 commits, 9 files)

Found 5 issues:

1. **[P0][conf 90] `organization_context.member` dereferenced without a None guard — 500s every audit-log request for token auth** — `src/sentry/api/endpoints/organization_auditlogs.py:71`
   Failure: `enable_advanced` is computed unconditionally, before the `use_optimized` branch, so it runs on *every* GET regardless of query params. `RpcUserOrganizationContext.member` is documented as nullable (`src/sentry/organizations/services/organization/model.py:344`) and is None whenever the caller isn't an org member of that org — org auth tokens and internal-integration tokens resolve to `AnonymousUser`/a sentry-app proxy user, so `convert_args` calls `get_organization_by_id(user_id=None or proxy_id)` and gets `member=None`. `AnonymousUser.is_superuser` is False, so the `or` doesn't short-circuit → `AttributeError: 'NoneType' object has no attribute 'has_global_access'` → 500. Every other consumer of this field in the codebase guards it (`src/sentry/auth/access.py:435,448,464,476,495,509`).
   Fix: compute it only inside the branch that needs it, and guard: `enable_advanced = is_active_superuser(request) or bool(organization_context.member and organization_context.member.has_global_access)`.
   (bugs)

2. **[P0][conf 92] `OptimizedCursorPaginator` uses integer-key semantics against a `datetime` column** — `src/sentry/api/paginator.py:838`
   Failure: `get_item_key` / `value_from_cursor` are copied verbatim from `Paginator` (`paginator.py:222-227`), which assumes a numeric key. The endpoint passes `order_by="-datetime"`, so `getattr(item, "datetime")` is a `datetime`, and `int(math.ceil(value))` raises `TypeError: must be real number, not datetime` as soon as `build_cursor` → `_build_next_values` calls `key(results[0])` (`src/sentry/utils/cursors.py:122`). Any request with `?optimized_pagination=true` that returns at least one row 500s. Second-order: with a cursor present, `value_from_cursor` returns the raw int, which `build_queryset` splices into `WHERE "datetime" <= %s` — comparing timestamptz to an integer, a Postgres error. `DateTimePaginator` exists precisely to handle this (`paginator.py:230-241`); nothing in the change reuses it, and there is no test exercising the new class.
   Fix: subclass `DateTimePaginator` instead of `BasePaginator` and drop the two overrides, or delete the class — the only stated benefit (negative offsets) is broken anyway (see #3).
   (bugs, slop)

3. **[P1][conf 90] Negative-offset branch is guaranteed to raise; its comment claims the opposite** — `src/sentry/api/paginator.py:876`
   Failure: the comment states "The underlying Django ORM properly handles negative slicing automatically" and "This is safe because permissions are checked at the queryset level." Django's `QuerySet.__getitem__` raises `ValueError("Negative indexing is not supported.")` for any slice with a negative `start`. Offsets come straight from the user-controlled `cursor` query param (`Cursor.from_string` accepts `int(bits[1])` unbounded, `src/sentry/utils/cursors.py:56`), so `?optimized_pagination=true&cursor=0:-1:0` is an unauthenticated-input path to a 500. Note the sibling comment added at `cursors.py:26` advertises negative offsets as a supported "performance optimization" — no code was added to support them.
   Fix: remove the branch and the two comments; if reverse paging is genuinely needed, use the existing `is_prev` cursor path rather than negative slicing.
   (bugs, comments)

4. **[P1][conf 85] Superuser gate bypasses superuser elevation, and `has_global_access` gates nothing** — `src/sentry/api/endpoints/organization_auditlogs.py:71`
   Failure: `request.user.is_superuser` is the raw User flag, not Sentry's elevated-session check. This endpoint's own permission class uses the correct helper (`is_active_superuser(request)`, `src/sentry/api/bases/organization.py:124`), so the new line silently opts out of the elevation requirement the same file enforces two frames earlier. Separately, `OrganizationMember.has_global_access` defaults to `True` (`src/sentry/models/organizationmember.py:216`), so the comment's "Enable advanced pagination for admins" / "authorized administrators" describes a gate that admits every org member reaching this endpoint. The check reads as an authorization boundary while being a no-op — a pattern that will get copied to endpoints where it does matter.
   Fix: use `is_active_superuser(request)`, and if the intent really is admin-only, check a role/scope (`request.access.has_scope("org:admin")`) rather than `has_global_access`.
   (bugs, conventions)

5. **[P1][conf 82] Redis key type changed set→zset with no key migration — WRONGTYPE crash-loop across a rolling deploy** — `src/sentry/spans/buffer.py:197`, `src/sentry/scripts/spans/add-buffer.lua:46`
   Failure: `span-buf:s:{...}` keys keep the same name but switch from `sadd`/`scard`/`sunionstore` to `zadd`/`zcard`/`zunionstore`. Buffered keys live up to `redis_ttl` (3600s), so during a rolling deploy new pods hit keys the old pods created as plain sets: `p.zadd(set_key, ...)` and `redis.call("zcard", span_key)` both raise `WRONGTYPE Operation against a key holding the wrong kind of value`. The Lua script aborts, the pipeline raises, and the consumer crash-loops until every stale key expires — the same happens in reverse on rollback.
   Fix: bump the key prefix (e.g. `span-buf:s2:`) so old and new schemas coexist, or `unlink` on WRONGTYPE and retry.
   (bugs, history)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. The deterministic detector suite (`detectors/run.sh`) was not run — the command was declined, so no `deterministic` findings are included above.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
