Detector suite ran clean (`[]`). Here is the review.

```text
## Reviso style — HEAD (detached) vs cfc35b8 (0 commits, 3 files)

No style issues found.

Checked: reuse, deterministic, length, over-engineering, surface area, comments, AI tells.
Not checked: drift (skipped: base commit cfc35b8 is empty — no pre-existing
same-language code to cite as a baseline); naming (skipped: same, no baseline);
error handling (skipped: the change contains no error handling, and no baseline
exists); type slop (skipped: no baseline); conventions (skipped: no CLAUDE.md,
AGENTS.md, or lint config governing src/); stale docs (skipped: repo contains no
README, docs, or prose); test slop (skipped: no test files in the change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

One thing worth stating plainly about this run: the base commit is empty and the change *is* the entire repository — `src/app.ts`, `src/routes.ts`, `src/users.ts`, three untracked files, 60 lines total. Every convention-relative lens measures against how this repo already writes this kind of code, and there is no already. That is why five lenses are on the `Not checked` line rather than reporting zero: they could not have produced a finding regardless of what the code looked like, and recording them as clean would be a false pass.

The lenses that do work without a baseline — slop, duplication, comments, length, derived state, dead weight, surface area, over-engineering, AI tells — were applied and returned nothing above the gate.
