## Reviso style — HEAD (detached) vs cfa8818 (0 commits, 1 file)

No style issues found.

Checked: reuse (slop, duplication, dead weight, derived state), deterministic, drift, length, over-engineering, surface area, AI tells, naming, stale docs.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md, or lint config in the repo), comments (skipped: the change adds no comments and touches none), error handling (skipped: no error handling in the changed hunk), test slop (skipped: no test files in the repo or the change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on the two lenses that had something to look at:

- **Dead weight** — grepped `quiet` repo-wide: two hits, the declaration at `src/cli.ts:10` and the read at `src/cli.ts:15`. The flag is consumed; no finding.
- **Stale docs** — grepped `dry-run` and `plan` across `README.md` and `CHANGELOG.md`. `README.md:8` ("Pass `--dry-run` to print the plan without writing.") is still true — `--dry-run` alone prints. `--quiet` being undocumented is a missing doc update, which is process, not a contradiction, so it does not ship here.

The added `--quiet` option mirrors the existing `dry-run` declaration shape exactly (`{ type: "boolean", default: false }`), so drift, naming, and type slop had no divergence to measure.
