Detector suite needed approval that wasn't granted, so I completed the review manually. Both changed files are untracked new files; I read them in full.

## Reviso review — HEAD (detached) vs af74c29 (0 commits, 2 files)

Found 1 issue:

1. **[P0][conf 100] `updateUserRole` is called with its arguments swapped — every role update fails** — `src/routes/user-roles.ts:25`
   Failure: the route calls `updateUserRole(userId, role)` (`src/routes/user-roles.ts:25`) but the service signature is `updateUserRole(role: string, userId: string)` (`src/services/user-service.ts:11-14`). `PUT /api/users/u_123/role` with `{"role":"admin"}` validates `VALID_ROLES.includes("u_123")` → throws `Invalid role: u_123` → 400 for every request. Worse, if a user id ever equals a role literal (`"admin"`), validation passes and it runs `UPDATE users SET role='u_123' WHERE id='admin'` — writing a garbage role onto the wrong row.
   Fix: change the call site to `updateUserRole(role, userId)`, or reorder the service signature to `(userId, role)` to match the route's natural ordering and the endpoint path. Both params are `string`, so neither the compiler nor tsc will catch this — consider a branded/union type (`type Role = "viewer" | "editor" | "admin" | "owner"`) on the service parameter so the swap is a compile error.
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (`detectors/run.sh` not approved); no CLAUDE.md/AGENTS.md or lint config present in this repo.

Notes that did not meet the reporting bar: the endpoint has no visible authn/authz for a privilege-escalation operation, but the router is exported for mounting elsewhere and no app entry point exists in this repo, so I could not verify whether middleware guards it — worth confirming at the mount site. The read-then-write on `users` is also non-transactional, so `previousRole` can be stale under concurrent updates.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
