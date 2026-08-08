No conventions files (`CLAUDE.md`/`AGENTS.md`) exist in this repo. The detector suite command was not approved, so Step 2 is skipped — noted in the coverage line.

## Reviso review — HEAD vs 30f804af (2 commits, 9 files)

Found 2 issues:

1. **[P0][conf 100] Build break: `UsernameForm` calls the removed no-arg `isConditionalPasskeysEnabled()`** — `services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernameForm.java:47`
   Failure: commit `3214b188de` renamed `UsernamePasswordForm.isConditionalPasskeysEnabled()` to `isConditionalPasskeysEnabled(UserModel)` without updating the caller in the subclass. `UsernameForm.authenticate()` still invokes the zero-arg form; a repo-wide grep confirms no zero-arg overload exists anywhere. `services` fails to compile: `method isConditionalPasskeysEnabled in class UsernamePasswordForm cannot be applied to given types`.
   Fix: update the call site to `!isConditionalPasskeysEnabled(context.getUser())` (the guard already establishes `context.getUser() != null` on that line), or keep the zero-arg overload.
   (bugs)

2. **[P0][conf 95] `user != null` in `isConditionalPasskeysEnabled` disables passkeys on the anonymous login page** — `services/src/main/java/org/keycloak/authentication/authenticators/browser/UsernamePasswordForm.java:161`
   Failure: the base commit's intent was to make the conditional-UI passkey form render in *both* first-login (`user == null`) and re-authentication (`user != null`); it did that by dropping the user condition entirely. Adding `&& user != null` back inverts that into "re-auth only". At `UsernamePasswordForm.java:115` and `:137`, `context.getUser()` is null on a normal first login, so `webauthnAuth.fillContextForm(context)` never runs, the `webauthn`/`challenge` form attributes are never set, and the conditional-UI passkey autofill flow — the primary passkeys login path — disappears from the login page. `action()` at `:59-60` still accepts WebAuthn submissions, but the fields to produce them are never rendered. This contradicts tests in this same branch: `PasskeysUsernamePasswordFormTest.webauthnLoginWithExternalKey` and `webauthnLoginWithExternalKey_reauthentication` both assert `//form[@id='webauth']` is present on the *initial* anonymous login page (`PasskeysUsernamePasswordFormTest.java:443`, `:485`), as does `PasskeysUsernameFormTest`.
   Fix: revert to `return webauthnAuth != null && webauthnAuth.isPasskeysEnabled();`. If a per-user check is genuinely wanted, it must not gate the identifier-less flow — the whole point of conditional UI is that no user is selected yet. Note the commit message claims "proper user context validation" but the predicate is a bare null check, not validation.
   (bugs, history)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (command not approved); no generated files or lockfiles in the diff.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
