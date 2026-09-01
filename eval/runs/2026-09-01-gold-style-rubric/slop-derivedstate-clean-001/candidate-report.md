## Reviso style — HEAD vs 85514a8 (0 commits, 4 files)

No style issues found.

Checked: reuse (slop, duplication, dead weight, derived state), deterministic, length, over-engineering, surface area, AI tells, type slop.
Not checked: drift (skipped: base commit is empty — no pre-existing code to cite as a baseline), naming (skipped: same), conventions (skipped: no CLAUDE.md/AGENTS.md or lint config governing the changed paths), error handling (skipped: the change contains no error handling), comments (skipped: the change contains no comments), stale docs (skipped: the repo contains no prose docs), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Two candidates were examined and gated:

- **Derived state** on `Session.messages` (`src/session.ts:6`) — it sits beside `this.platform = manifest.platform` in the constructor, which is the lockstep shape this lens hunts, but it is not a projection. Write sites are `src/session.ts:10` (`this.messages = tenant.messageOverrides ?? manifest.platform?.messages ?? []` — the tenant override wins over the manifest) and `src/session.ts:18` (`this.messages = messages` — caller-supplied). Two writes that don't come from `manifest.platform`, so the field can hold values the source doesn't; the lens's own carve-out clears it.
- **Dead weight / surface area** on `setMessages` and `bannerText` — `grep -rn` over `src/` returns no callers, but it returns no callers for `Session`, `Manifest`, or `TenantConfig` either. The base commit is empty, so every symbol here is new API with no consumer code in the repo; the empty search result carries no signal about these two specifically.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
