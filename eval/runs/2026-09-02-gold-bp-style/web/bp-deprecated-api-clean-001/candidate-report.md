## Reviso style — HEAD (detached) vs 32b9133 (0 commits, 1 file)
Base: `32b9133` via flag — merge-base `32b9133`

The whole change is one untracked file, `auditlog/events.py` (17 lines added).

No style issues found.

Checked: reuse, length, over-engineering, surface area, AI tells, naming, best practices, deterministic.
Not checked: comments (skipped: the change adds no comments), drift (skipped: repo contains no other Python source, so no same-language baseline exists), conventions (skipped: no CLAUDE.md/AGENTS.md and no lint config — `pyproject.toml` has no `[tool.*]` section), error handling (skipped: the change contains no raise/try/except), stale docs (skipped: repo contains no doc or prose files), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

One note on the `--web` lens, since it is the reason the run touched the network: `datetime.now(timezone.utc)` at `auditlog/events.py:6` is the form the Python 3.12 docs themselves recommend ("the recommended way to create an object representing the current time in UTC is by calling `datetime.now(timezone.utc)`"), and `timezone.utc` carries no deprecation — only `utcnow()` and `utcfromtimestamp()` do, and neither appears here. `datetime.UTC` is a shorter alias with no stated consequence for the older spelling, so it does not meet the superseded-idiom bar. Nothing shipped from the lens.
