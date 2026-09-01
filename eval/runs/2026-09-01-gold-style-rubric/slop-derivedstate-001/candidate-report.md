## Reviso style — HEAD (detached) vs 50b14db (0 commits, 3 files)

Found 1 style issue:

1. **[P2][conf 92] `Session.messages` is a stored projection of `Session.platform`** — src/session.ts:5
   Failure: `messages` is written in lockstep with `platform` from the same source at every write site, so it can never hold anything `platform.messages` doesn't already say — yet every future write path (a new `apply`-like setter, a partial manifest update) has to remember to write both, and the second one that forgets makes the banner silently stale.
   Evidence — every write site of `messages`, each assigned from `manifest.platform` immediately beside `this.platform`:
   - `src/session.ts:8-9` — `this.platform = manifest.platform;` / `this.messages = manifest.platform?.messages ?? [];`
   - `src/session.ts:13-14` — `this.platform = manifest.platform;` / `this.messages = manifest.platform?.messages ?? [];`

   No write of `messages` comes from anywhere but `manifest.platform`. Every read site (`grep -rn "messages" src/`): `src/banner.ts:4` — `session.messages.join(" · ")` — one reader.
   Fix: with a single reader, inline the projection at the read site and drop the field. Delete `messages: string[];` (src/session.ts:5) and both assignments (src/session.ts:9, src/session.ts:14); `src/banner.ts:4` becomes `return (session.platform?.messages ?? []).join(" · ");`
   (derived state)

Checked: reuse, deterministic, length, over-engineering, surface area, AI tells, naming.
Not checked: drift (skipped: base commit `50b14db` contains no files — no demonstrated repo pattern to compare against), conventions (skipped: no CLAUDE.md / AGENTS.md or lint config anywhere in the repo), error handling (skipped: the change handles no errors), comments (skipped: the change contains no comments), stale docs (skipped: repo has no README, docs, or prose to falsify), test slop (skipped: no test files).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
