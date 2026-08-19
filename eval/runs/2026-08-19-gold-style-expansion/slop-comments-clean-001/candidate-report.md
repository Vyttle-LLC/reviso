## Reviso style — HEAD (detached) vs 776dbd4 (0 commits, 1 file)

No style issues found.

Checked: slop, comments, duplication, over-engineering, dead weight, AI tells, deterministic.
Not checked: conventions (skipped — no CLAUDE.md/AGENTS.md or lint config anywhere in the repo); drift (skipped — the base commit is empty, so there is no existing code to establish a demonstrated norm against); length (skipped — no comparable units in the repo to measure against); test slop (skipped — the change adds no test files).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on the two lenses most likely to fire here: both comments in `src/retry.ts` clear the earn-its-place bar — `src/retry.ts:2` records why full jitter was chosen over equal jitter, and `src/retry.ts:9` records the external warehouse-API constraint behind the en-dash replacement. Neither restates the code, and neither rationale is expressible through naming, extraction, or types. The exported-but-uncalled functions were considered under dead weight and dropped: in a repo whose only file is this one, an empty caller search carries no signal about a new module's public API.
