Detectors returned `[]`. Here is the report.

```text
## Reviso style — HEAD vs dda7edb (0 commits, 1 file)

No style issues found.

Checked: reuse, deterministic, comments, AI tells, naming, length,
over-engineering, surface area.
Not checked: conventions (skipped: no CLAUDE.md / AGENTS.md or lint config
governing the changed path), drift (skipped: base commit is empty — no
existing TypeScript to cite as a baseline), error handling (skipped: the
change contains no error handling), stale docs (skipped: no docs in the
repo for the change to contradict), test slop (skipped: no test files
changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Notes on the two lenses that had the most to chew on here:

- **Comments** (absolute bar, not repo-relative): both comments in `src/retry.ts` clear it. `retry.ts:2-3` names the jitter variant chosen, the one rejected, and why — none of which naming or types can carry. `retry.ts:9` explains that the regex literal is an en-dash, visually indistinguishable from the hyphen it maps to, plus the domain constraint that forces it. Neither restates the code or narrates control flow.
- **Dead weight / surface area**: `retryDelayMs` and `normalizeSku` are exported with no caller anywhere (grepped both identifiers plus `jitter`/`Sku` across the repo; only self-hits in `src/retry.ts`, and `git ls-files` is empty — this file is the repo's entire content). Both candidates were dropped at the gate: with an empty base commit there is no baseline showing that an export without an in-repo caller is anomalous rather than the premise of the change.

The change is 11 lines with no baseline to measure against, so five lenses had nothing in scope — that is what the `Not checked:` line records, not a clean pass on them.
