## Reviso style — detached HEAD vs c745879 (0 commits, 1 file)

No style issues found.

The change is a single new file, `src/notify.ts` (34 lines, untracked). The repo contains no other files at this base — no existing TypeScript, no `CLAUDE.md`/`AGENTS.md`, no lint config — so the convention-relative lenses have no baseline to measure against and could not have produced a shippable finding. Two things I looked at and cleared rather than dropped silently:

- The two `send` bodies (`src/notify.ts:7`, `src/notify.ts:13`) are near-verbatim, differing only in path. Two occurrences is below the duplication bar (4+ ships; exactly 3 ships only for a changeable rule), so it is not a finding however it reads.
- Every export (`Notifier`, `EmailNotifier`, `SmsNotifier`, `notifierFor`, `remindUser`) has no caller outside the file — grep across the whole repo for those identifiers and `postJson` returns only `src/notify.ts` itself. For a brand-new standalone module with no consumers yet, that is the module's intended API surface, not dead weight or over-exposure. `notifierFor` serves two implementations, so it is not a single-consumer abstraction either.

Checked: over-engineering, error handling, surface area, AI tells, naming, slop, duplication, dead weight, deterministic.
Not checked: drift (skipped: no pre-existing code to establish a demonstrated norm), length (skipped: no comparable units in repo to measure against), conventions (skipped: no CLAUDE.md/AGENTS.md or lint config governing changed paths), comments (skipped: change adds no comments), stale docs (skipped: no README, changelog, ADRs, or doc comments in repo), derived state (skipped: change stores no state), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
