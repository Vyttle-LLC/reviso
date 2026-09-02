## Reviso audit — HEAD (detached) vs 60d8020 (0 commits, 1 file)

All changes are uncommitted: `auditlog/events.py` is a new untracked file.

Found 1 issue:

1. [P2][conf 85] Naive UTC timestamp makes `age_seconds` crash on an aware `now` — auditlog/events.py:6
   Failure: `_stamp()` returns `datetime.utcnow()`, which is naive, so `created_at` is always naive. `age_seconds(now: datetime)` is public and takes any `datetime`; a caller passing the standard modern value — `AuditEvent("u", "login").age_seconds(datetime.now(timezone.utc))` — hits `now - self.created_at` at line 16 and raises `TypeError: can't subtract offset-naive and offset-aware datetimes`. Separately, `pyproject.toml` sets `requires-python = ">=3.12"`, where `datetime.utcnow()` itself emits a `DeprecationWarning` on every call.
   Fix: `return datetime.now(timezone.utc)` in `_stamp()` (importing `timezone`), and either document that `age_seconds` requires an aware `now` or normalize it there before subtracting.
   (bugs; root cause shared with the line-16 subtraction, merged into this finding)

Checked: deterministic detectors, conventions, bugs, history, comments, slop.
Not checked: prior reviews (no GitHub remote, and no commit reachable from HEAD touches this path), best-practices (no `--web`).
Skipped: nothing.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
