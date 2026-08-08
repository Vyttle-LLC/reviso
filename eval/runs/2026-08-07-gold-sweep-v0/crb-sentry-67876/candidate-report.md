## Reviso review — HEAD (detached) vs 344aa102 (5 commits, 3 files)

Found 4 issues:

1. **[P0][conf 88] OAuth `state` is `pipeline.signature`, a global constant — the CSRF check is decorative** — `src/sentry/integrations/github/integration.py:402`
   Failure: `Pipeline.signature` is `md5_text(*pipe_ids).hexdigest()` over the pipeline view class names (`src/sentry/pipeline/base.py:132-133`) — identical for every user and every install, and stable across deploys (the new test hardcodes it as `9cae5e88803f35ed7970fc131e6e65d3`). So the `state != pipeline.signature` check at :412 is satisfiable by any attacker. Attacker installs the GitHub App on an org they control (webhook stores `sender: attacker`), then lures a Sentry admin mid-pipeline to `/extensions/github/setup/?code=<attacker_code>&state=<constant>`; the victim's pipeline binds `github_authenticated_user = attacker`, the new sender check at :503 then matches, and the attacker's GitHub installation is connected to the victim's org — defeating the exact control this branch adds.
   Fix: follow the codebase's own pattern in `sentry/identity/oauth2.py:245-252` — `state = secrets.token_hex()`, `pipeline.bind_state("state", state)` before redirecting, then compare `request.GET.get("state") != pipeline.fetch_state("state")` on the callback (as `OAuth2CallbackView` does at :325). The two `# similar to OAuth2CallbackView...` comments already declare that intent; the state handling is the one part that wasn't copied.
   (bugs / conventions)

2. **[P1][conf 85] `integration.metadata["sender"]` raises `KeyError` for pipeline-created integrations** — `src/sentry/integrations/github/integration.py:503`
   Failure: `metadata["sender"]` only exists when the integration was created by the `installation` webhook (`webhook.py:203-207`); `build_integration` receives `self.state.data` (`integrations/pipeline.py:93`), and no view ever calls `bind_state("sender", ...)`, so integrations created by the install pipeline have no `sender` key. On any deployment where the webhook doesn't land first (self-hosted / firewalled), the first install succeeds via the `Integration.DoesNotExist` branch at :481, and every later re-install of that same `installation_id` after the org disconnects hits :503 with an unhandled `KeyError` → 500 instead of the failure dialog. `installation.py:44` guards this exact case with `if "sender" not in integration.metadata`, confirming the key is not guaranteed.
   Fix: `if pipeline.fetch_state("github_authenticated_user") != integration.metadata.get("sender", {}).get("login"): return error(...)`, and decide deliberately whether a missing `sender` should fail closed (error) or fall through — a bare subscript picks neither.
   (bugs)

3. **[P2][conf 85] `test_installation_not_found` no longer tests installation-not-found** — `tests/sentry/integrations/github/test_integration.py:379`
   Failure: the test passes `state="ddd023d87a913d5226e2a882c4c4cc05"`, which does not match `pipeline.signature` (`9cae5e88...`, per line 234), so the request errors out at the state check in `OAuthLoginView` and never reaches `build_integration`. The `responses.replace(..., status=404)` stub at :381 is never called and the `ApiError` 404 → `IntegrationError("The GitHub installation could not be found.")` path at `integration.py:355-356` is now uncovered — the deleted assertion was the only test for it.
   Fix: use the correct state so the pipeline advances, and restore `assert b"The GitHub installation could not be found." in resp.content`. If a wrong-state case is also wanted, add it as a separate `test_invalid_state` rather than repurposing this one.
   (bugs / history)

4. **[P2][conf 80] `Integration` fetched twice for the same `external_id`** — `src/sentry/integrations/github/integration.py:494`
   Failure: :478 already does `Integration.objects.get(external_id=installation_id)`; :494 immediately re-queries the same row with an added `status=ObjectStatus.ACTIVE` filter. Two round-trips for one row, and the status condition is split across two blocks so a non-`ACTIVE` integration silently takes the "Invalid installation request." path at :498 rather than any of the specific error messages above it.
   Fix: hoist one lookup above the `installations_exist` check and reuse it:
   ```python
   try:
       integration = Integration.objects.get(external_id=installation_id, status=ObjectStatus.ACTIVE)
   except Integration.DoesNotExist:
       return pipeline.next_step()
   if OrganizationIntegration.objects.filter(integration=integration).exists():
       return error(request, self.active_organization, ...)
   ```
   (slop)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing — all 3 files reviewed. The deterministic detector suite was not run (permission for `detectors/run.sh` was declined), so no `deterministic` findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
