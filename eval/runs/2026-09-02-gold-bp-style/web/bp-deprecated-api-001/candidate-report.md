## Reviso style — HEAD (detached) vs 32b9133 (1 file, 0 commits, 1 untracked)
Base: `32b9133eeb03b690c16503c0f9182d4675f71707` via flag — merge-base `32b9133`

Found 1 style issue:

1. [P2][conf 95] `datetime.utcnow()` is deprecated in every Python version this project allows — auditlog/events.py:6
   Failure: `utcnow()` returns a naive datetime with no `tzinfo`, which the docs warn "many `datetime` methods treat as local times"; `pyproject.toml:4` pins `requires-python = ">=3.12"`, so the deprecation applies to the entire allowed range (removed in 3.14).
   Fix: `return datetime.now(UTC)` (import `UTC` from `datetime`), per the replacement the docs name.
   Source: https://docs.python.org/3/library/datetime.html — "the recommended way to create an object representing the current time in UTC is by calling `datetime.now(timezone.utc)`. Deprecated since version 3.12: Use `datetime.now()` with `UTC` instead."
   (best practices)

Checked: reuse, tests, AI tells, naming, best practices, deterministic.
Not checked: comments (skipped: no comments in the change), conventions (skipped: no CLAUDE.md/AGENTS.md and no lint config in the repo), drift (skipped: no other Python source to establish a baseline), length (skipped: no comparable units in the repo), over-engineering — returned; error handling (skipped: no error handling in the change), stale docs (skipped: no prose docs in the repo), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
