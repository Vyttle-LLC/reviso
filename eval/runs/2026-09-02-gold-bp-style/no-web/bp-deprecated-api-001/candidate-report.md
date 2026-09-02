## Reviso style — HEAD (detached) vs 32b9133 (0 commits, 1 file)
Base: `32b9133eeb03b690c16503c0f9182d4675f71707` via flag — merge-base `32b9133`

No style issues found.

Checked: reuse, drift, length, over-engineering, surface area, AI tells, naming, stale docs, deterministic.
Not checked: comments (skipped: no comments in the change), conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in the repo), error handling (skipped: no error handling in the change), test slop (skipped: no test files changed), best practices (no `--web`).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Two notes on how that zero was reached, so you can calibrate it:

- `auditlog/events.py` is the repo's only Python file, so the convention-relative lenses (drift, naming, error handling, type slop, over-engineering) had no same-language baseline to cite. They returned clean, but on a 17-line change in a repo with nothing to compare against — that is a weaker clean than it would be in an established codebase.
- The change is almost entirely stdlib `datetime` usage, which is exactly the territory the best-practices lens covers, and it's off unless you pass `--web`. Re-running as `/reviso:style --base 32b9133 --web` would check the changed lines against Python's own documentation for deprecations and documented misuse.
