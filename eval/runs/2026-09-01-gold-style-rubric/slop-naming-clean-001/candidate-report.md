## Reviso style — HEAD (detached) vs 0b179e0 (0 commits, 1 file)

No style issues found.

Checked: reuse, deterministic, drift, length, over-engineering, surface area, AI tells, naming.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md, or lint config in repo), error handling (skipped: change contains no error handling), comments (skipped: no comments added or changed), stale docs (skipped: repo contains no docs or prose files), test slop (skipped: no test files in repo or change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

The change is one untracked file, `src/services/session-manager.ts` (15 lines). It matches its two siblings closely: `Manager` suffix (`token-manager.ts:1`, `cache-manager.ts:1`), `current()` accessor (`token-manager.ts:4`), one exported class per kebab-case file under `src/services/`, `string | null` for the nullable field (`token-manager.ts:2`), 1–3 line methods throughout. The `Manager` suffix and the uncalled export both read as the repo's established norm rather than drift — two same-language examples each.
