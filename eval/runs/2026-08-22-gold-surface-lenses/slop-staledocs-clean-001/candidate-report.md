## Reviso style — HEAD (detached) vs 78ed3c6 (0 commits, 1 file)

No style issues found.

Checked: reuse, drift, length, over-engineering, surface area, AI tells, naming, stale docs, deterministic.
Not checked: comments (skipped: no comments added or changed), conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in repo), error handling (skipped: no error handling in the change), test slop (skipped: no test files in repo or change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Two things I considered and did not ship as findings, since neither is style: `README.md:8` and `CHANGELOG.md` never mention the new `--quiet` flag, but a missing doc update is process, not a contradicted sentence; and the flag's scope within `main` is a behavioral question for `/reviso:review`.
