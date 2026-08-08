No `CLAUDE.md`/`AGENTS.md` in the repo. The detector suite required approval and was declined, so Step 2 is unavailable — findings below are all from my own read.

## Reviso review — HEAD (detached) vs 43c7253 (0 commits, 1 file)

Found 3 issues:

1. **[P0][conf 100] SQL injection: request parameter concatenated into the query string** — `src/main/java/com/example/admin/UserSearchServlet.java:40`
   Failure: `username` comes straight from `request.getParameter` (line 29) and is spliced into a `Statement` query with no escaping or validation. `GET /api/admin/users/search?username=%25'%20UNION%20SELECT%20id,password,email,created_at%20FROM%20credentials--` breaks out of the `LIKE '%…%'` literal and returns arbitrary table contents in the JSON response; `?username='%20OR%20'1'='1` dumps every user. On PostgreSQL with `Statement` this also permits stacked-statement variants depending on driver config.
   Fix: use a `PreparedStatement` and bind the wildcards as data, never as SQL text:
   ```java
   String query = "SELECT id, username, email, created_at FROM users WHERE username LIKE ?";
   try (PreparedStatement stmt = conn.prepareStatement(query)) {
       stmt.setString(1, "%" + username + "%");
       try (ResultSet rs = stmt.executeQuery()) { ... }
   }
   ```
   (bugs)

2. **[P1][conf 85] Database credentials hardcoded in source** — `src/main/java/com/example/admin/UserSearchServlet.java:38` (also the URL at line 21)
   Failure: `"app_user", "app_pass"` are literals compiled into the artifact and committed to git. Anyone with repo read access or the built WAR has the production DB login, and rotating it requires a code change and redeploy. History rewriting is the only way to un-leak it once pushed.
   Fix: resolve the connection from a container-managed `DataSource` via JNDI (`java:comp/env/jdbc/appdb`), or read URL/user/password from environment variables with no in-code defaults.
   (bugs)

3. **[P1][conf 80] Admin endpoint performs no authorization check** — `src/main/java/com/example/admin/UserSearchServlet.java:17`
   Failure: the servlet is mapped at `/api/admin/users/search` and returns user IDs and email addresses, but `doGet` never inspects the session, a role, or a token — it goes straight from parameter validation to the query. Any unauthenticated caller who can reach the port enumerates the full user table (`?username=a`), which also amplifies finding 1 into an unauthenticated injection. There is no filter, `web.xml`, or other security infrastructure anywhere in the repository to cover it.
   Fix: gate the handler on an authenticated admin principal (`request.isUserInRole("ADMIN")` → 403 otherwise), or register a security constraint / filter covering `/api/admin/*`. If such a filter exists outside this repo, disregard.
   (bugs)

Checked: bugs, conventions, history, comments, slop. Deterministic detectors: not run (command declined).
Skipped: nothing.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
