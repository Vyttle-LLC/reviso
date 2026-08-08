Detectors couldn't run (the `sh` invocation wasn't approved), so this is a model-only pass. Review of the single new file:

## Reviso review — HEAD (detached) vs 5efa077 (0 commits, 1 file)

Found 4 issues:

1. **[P0][conf 85] Admin user-search endpoint has no authentication or authorization check** — `src/main/java/com/example/admin/UserSearchServlet.java:26`
   Failure: `GET /api/admin/users/search?username=a` is served to any unauthenticated caller. `doGet` goes straight from `getParameter` to the query and returns `id, username, email` for every match. There is no `HttpSession` check, no role check, no `@ServletSecurity`, and no `web.xml` or filter anywhere in the repo that could be covering it. The `/api/admin/` path prefix asserts a privilege boundary that the code does not enforce, so the result is an unauthenticated PII (email) dump.
   Fix: gate the handler before querying — reject with 401/403 unless the session principal holds the admin role, e.g. `if (!request.isUserInRole("admin")) { response.setStatus(403); return; }`, or register a security filter/`@ServletSecurity(@HttpConstraint(rolesAllowed = "admin"))` on the servlet.
   (bugs)

2. **[P1][conf 90] Database credentials hardcoded in source** — `src/main/java/com/example/admin/UserSearchServlet.java:39`
   Failure: `DriverManager.getConnection(DB_URL, "app_user", "app_pass")` embeds the DB password as a string literal. It lands in version control, in the compiled `.class` bytes of any deployed artifact, and is readable by anyone with repo or JAR access; rotating it requires a code change and redeploy.
   Fix: obtain the connection from a container-managed `DataSource` via JNDI (`InitialContext.lookup("java:comp/env/jdbc/appdb")`) so credentials live in server config, or at minimum read them from environment/config rather than literals. This also gives you connection pooling instead of a fresh TCP+auth handshake per request.
   (bugs)

3. **[P2][conf 85] LIKE wildcards in user input are not escaped, allowing full-table enumeration** — `src/main/java/com/example/admin/UserSearchServlet.java:41`
   Failure: the statement is correctly parameterized, but `"%" + username + "%"` interpolates raw input into the *pattern*. A request with `username=%` produces `LIKE '%%%'` and `username=_` produces `LIKE '%_%'` — both match every row, returning the entire users table with emails in one unbounded response (`while (rs.next())` at :44 has no limit).
   Fix: escape pattern metacharacters before wrapping, and bound the result set:
   ```java
   String pattern = "%" + username.replace("!", "!!").replace("%", "!%").replace("_", "!_") + "%";
   // SELECT ... WHERE username LIKE ? ESCAPE '!' LIMIT ?
   ```
   (bugs)

4. **[P2][conf 80] Database failures are swallowed with no logging** — `src/main/java/com/example/admin/UserSearchServlet.java:51`
   Failure: `catch (Exception e)` discards `e` entirely and returns a generic 500 body. When the query fails in production — driver missing, auth rejected, schema drift, timeout — nothing reaches the logs, so the outage is undiagnosable from the server side. The broad `Exception` catch also absorbs `RuntimeException`s from `gson`/servlet code that were never meant to be handled here.
   Fix: log before responding (`log("user search failed", e)` or a logger) and narrow the catch to `SQLException`.
   (bugs)

Not flagged: `pstmt`/`rs` are outside try-with-resources, but the enclosing `Connection` is closed on every path and closing a connection releases its statements, so there is no leak here — worth tidying if you move to a pooled `DataSource` (see finding 2), where it would become one.

Checked: bugs, conventions (no CLAUDE.md/AGENTS.md or lint config present), history (single new untracked file, no prior blame), comments, slop.
Skipped: nothing. Deterministic detectors: not run — the detector script needs Bash approval; re-run `/reviso:review` and approve it for that layer.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
