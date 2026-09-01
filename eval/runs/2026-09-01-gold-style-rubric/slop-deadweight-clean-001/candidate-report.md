Detector suite ran clean (`[]`). The change is a single untracked file, `src/events.ts` (18 lines); the base commit `dd729bd` is empty, so the repo has no pre-existing code.

```text
## Reviso style — HEAD (detached) vs dd729bd (0 commits, 1 file)

No style issues found.

Checked: slop, duplication, dead weight, drift, length, over-engineering,
surface area, naming, AI tells, deterministic.
Not checked: comments (skipped: change adds no comments), conventions
(skipped: no CLAUDE.md / AGENTS.md or lint config in the repo), error handling
(skipped: change contains no error handling), derived state (skipped: change
stores no state), stale docs (skipped: repo has no prose docs), test slop
(skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

One thing worth knowing about that zero: the base commit is empty, so the convention-relative lenses (drift, naming, type slop, over-engineering) had no pre-existing same-language code to cite as a baseline. They returned nothing because nothing in the change could have cleared their two-example citation bar, not because a baseline was checked and matched. `dispatch` (`src/events.ts:16`) is exported with no caller anywhere — a repo-wide grep for `dispatch` hits only its own definition — but in a one-file repo that is a new module's public API, not dead weight, so it does not ship.
