## Reviso style — HEAD (detached) vs 776dbd4 (0 commits, 3 files)

No style issues found.

Checked: slop, duplication, length, over-engineering, dead weight, AI tells, deterministic.
Not checked: comments (skipped — the change adds no comments); conventions (skipped — no CLAUDE.md / AGENTS.md / lint config governing `src/`); drift (skipped — base commit `776dbd4` tracks no files, so there is no pre-existing code to cite a two-example baseline against); test slop (skipped — no test files in the change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on what was examined, since three lenses had no baseline to work from:

- The change is three untracked files (`src/app.ts`, `src/routes.ts`, `src/users.ts`, 60 lines total) on top of an empty base commit — every line is added.
- Deterministic detector suite ran clean (`[]`).
- Dead-weight search: grepped `registerRoutes`, `listUsers`, `createUser`, `UserInput`, `App`, `Request`, `Response` across the repo. All are consumed except `registerRoutes` (`src/routes.ts:4`), which is the module's top-level entry point in a repo with no bootstrap file yet — not a finding.
- `V1`/`V2` suffixes (`src/routes.ts:10,14,20`) track the real route versions `/api/v1/users` and `/api/v2/users`, so they are not the temporal/comparative naming the AI-tells lens looks for.
