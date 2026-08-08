Detector suite: the `run.sh` invocation wasn't approved, so deterministic findings are absent from this pass — everything below is from the manual review.

```text
## Reviso review — HEAD (detached) vs bdd229e3f22 (2 commits, 4 files)

Found 2 issues:

1. [P1][conf 82] MetricAlertDetectorHandler is now abstract but still registered as a handler — src/sentry/incidents/grouptype.py:11
   Failure: `StatefulDetectorHandler` has four abstract members (`counter_names`,
   `get_dedupe_value`, `get_group_key_values`, and the newly added
   `build_occurrence_and_event_data`). `MetricAlertDetectorHandler` implements none
   of them, so it cannot be instantiated. It is still wired up as
   `MetricAlertFire.detector_handler` (grouptype.py:27), and
   `Detector.detector_handler` calls `group_type.detector_handler(self)`
   (src/sentry/workflow_engine/models/detector.py:86) with no abstract-class guard.
   The first `process_detectors` call that sees a `metric_alert_fire` detector raises
   `TypeError: Can't instantiate abstract class MetricAlertDetectorHandler`. Before
   this change the class was concrete (`evaluate` returned `[]`), so the handler
   degraded to a no-op instead of blowing up. Latent today only because
   `process_detectors` has no production caller yet.
   Fix: either keep it on `DetectorHandler` with a stub `evaluate` returning `{}`
   until the real implementation lands, or give it stub implementations of the four
   abstract members. Also drop the now-wrong TODO on grouptype.py:10 ("This will be
   a stateful detector when we build that abstraction") — it is one now.
   (bugs; anchors: src/sentry/incidents/grouptype.py:10, :12, :27)

2. [P2][conf 80] `evaluate` docstring still describes the old list return — src/sentry/workflow_engine/processors/detector.py:230
   Failure: the signature one line above now returns
   `dict[DetectorGroupKey, DetectorEvaluationResult]`, but the docstring says
   "returns a list of `DetectorEvaluationResult`". Since the dict-keying is the whole
   point of the change (it replaces the duplicate-group-key error path deleted from
   `process_detectors`), the stale wording actively misleads the next implementer of
   a stateful detector.
   Fix: "Evaluates a given data packet and returns a dict of
   `DetectorEvaluationResult` keyed by group key."
   (conventions/comments)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (run.sh not approved). No CLAUDE.md/AGENTS.md found at repo root or in any changed directory.
```

Notes on things I checked and cleared: `PriorityLevel(new_status)` on processors/detector.py:300 is safe — `DataCondition.evaluate_value` only ever returns a valid `DetectorPriorityLevel`, and the `OK`/0 case is handled by the sibling branch, so the remaining values (25/50/75) all exist in `PriorityLevel`. Removing the duplicate-group-key error log is a strict improvement, not a regression — the dict return makes duplicates structurally impossible — and the deleted `test_state_results_multi_group_dupe` matches the stated intent in the commit message.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
