## Reviso review — HEAD (detached, base `24584e6`) — 0 commits, 1 file

Found 2 issues:

1. **[P0][conf 95] JWT signing secret hardcoded in source with no environment override — src/middleware/jwt-auth.ts:4**
   Failure: `JWT_SECRET` is a source-code literal (`sk_live_…`) used as the HMAC key at line 24, so the key lives in git history and is readable by anyone with repo access, CI logs, or a built bundle. Anyone holding it can mint a token with an arbitrary `sub` and `role` that this middleware accepts as authentic — full authentication bypass and privilege escalation. Every deployment also shares one key, so rotation requires a code change and redeploy.
   Fix: read it from the environment and fail closed at startup:
   ```ts
   const JWT_SECRET = process.env.JWT_SECRET;
   if (!JWT_SECRET) throw new Error("JWT_SECRET is not set");
   ```
   Treat the committed value as compromised: rotate it and purge it from history (`git filter-repo` / BFG) rather than only deleting the line. The `TESTONLYFAKE` marker inside the literal suggests a placeholder — that makes it worse, not better: a placeholder that ships is a guessable production key.
   (bugs/security)

2. **[P1][conf 85] Expiry check fails open for tokens with no `exp` claim — src/middleware/jwt-auth.ts:26**
   Failure: the guard is `if (payload.exp && …)`, so a token whose payload omits `exp` (or has `exp: 0`) skips the comparison entirely and is accepted forever — despite `JwtPayload` at line 8 declaring `exp: number` as required. `hono/jwt`'s `verify` applies the same present-only rule, so nothing upstream catches it either; a single leaked or stolen token never stops working.
   Fix: require the claim instead of tolerating its absence:
   ```ts
   if (typeof payload.exp !== "number" || payload.exp < Math.floor(Date.now() / 1000)) {
     return c.json({ error: "Token expired" }, 401);
   }
   ```
   (bugs; enforcement doesn't match the declared contract)

Checked: bugs, conventions, history, comments, slop, deterministic (suite returned no matches).
Skipped: nothing.

Notes: no `CLAUDE.md`/`AGENTS.md` or lint config exists in this repo, so the conventions lens had no rules to apply; `var` over `const` is left to the linter. No ticket ID inferable from the detached HEAD.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
