Stage 5 complete. Report:

```text
## Reviso audit — master (detached at 60d8020) vs 60d8020 (0 commits, 1 file)

Found 1 issue:

1. [P2][conf 95] datetime.utcnow() is deprecated on every Python version this project supports — auditlog/events.py:6
   Failure: _stamp() is the default_factory for AuditEvent.created_at, so every AuditEvent construction calls
   datetime.utcnow() unconditionally. pyproject.toml:4 declares requires-python = ">=3.12", and 3.12 is exactly
   the version where utcnow() was deprecated — so the deprecation applies across the project's entire declared
   support range, with no version in it where the call is clean. It also returns a naive datetime, so
   age_seconds(now) raises TypeError: can't subtract offset-naive and offset-aware datetimes the first time a
   caller passes the modern datetime.now(timezone.utc).
   Fix: return datetime.now(timezone.utc) from _stamp() (import timezone from datetime), making created_at
   timezone-aware; age_seconds then works correctly with aware inputs.
   Source: https://docs.python.org/3/library/datetime.html#datetime.datetime.utcnow — "Deprecated since version
   3.12: Use datetime.now() with UTC instead"
   (best-practices)

Checked: deterministic detectors, conventions, bugs, history, comments, slop, best-practices.
Not checked: prior reviews (no git remote configured, and the repo's single commit contains no prior version of the changed file — no admissible review history).
Skipped: nothing.
```

Notes on the run: the bugs and history lenses independently flagged the same line; per reconcile, they merged into the source-cited finding above. The detector suite ran clean, and the best-practices lens made 2 searches and 2 fetches, well under its bound.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
