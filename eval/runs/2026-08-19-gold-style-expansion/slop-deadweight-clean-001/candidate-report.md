Detectors returned `[]` (clean). Base commit is empty — the entire change is one new 19-line file, `src/events.ts`, with no pre-existing code, no conventions files, and no lint configs in the repo.

One candidate reached the gate and did not survive it: `dispatch` (src/events.ts:16) is exported with no caller anywhere — I grepped the repo for `dispatch`, `Handler`, `user.created`, `user.deleted`, and both log strings, and every hit is inside `src/events.ts` itself, with no dynamic dispatch or DI registration nearby. But this is the repo's first source file and `dispatch` is its sole public export, i.e. the intended entry point for consumers that don't exist yet. That's an exclusion-list match, not a finding.

```text
## Reviso style — HEAD vs 776dbd4 (0 commits, 1 file)

No style issues found.

Checked: deterministic, slop, duplication, length, over-engineering, dead weight, AI tells.
Not checked: comments (skipped — the change contains no comments); conventions (skipped — no CLAUDE.md/AGENTS.md or lint config in the repo); drift (skipped — base commit is empty, so there is no existing code to establish a demonstrated norm); test slop (skipped — the change adds no tests).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Note on the zero: four of the ten lenses could not run because this branch has no baseline to measure against — an empty base commit means drift and conventions have nothing to cite, and the change itself contributes no comments or tests. The six lenses that are judgeable on a standalone file all ran and came back clean.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
