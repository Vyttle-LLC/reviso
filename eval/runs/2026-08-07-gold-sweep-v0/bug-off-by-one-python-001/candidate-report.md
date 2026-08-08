Detector suite step was declined at the permission prompt, so this is a model-only pass.

## Reviso review — HEAD (detached) vs 58e3616 (0 commits, 1 file)

Found 1 issue:

1. [P0][conf 100] Sliding window loop drops the final window — off-by-one in `range` — src/analytics/smoothing.py:25
   Failure: The docstring (line 15) promises `N - W + 1` averages, but `range(len(readings) - self.window_size)` yields only `N - W`. `smooth([1,2,3,4,5,6,7])` with `window_size=5` returns 2 values instead of 3 — the last window `[3,4,5,6,7]` is never averaged. Worse, when `len(readings) == window_size` the guard on line 21 is False and the loop becomes `range(0)`, so the exact-window-size case returns `[]` instead of the single average it documents. `detect_anomalies` inherits this: the trailing readings are never checked against a baseline, so a late-arriving anomaly is silently missed.
   Fix: `for i in range(len(readings) - self.window_size + 1):`
   (bugs; enforcement does not match the docstring's stated contract)

Checked: bugs, conventions (no CLAUDE.md/AGENTS.md or lint config present), history (single untracked file, no prior blame), comments, slop.
Skipped: nothing. Deterministic detectors: not run (permission declined).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
