## Reviso review — HEAD (detached) vs bb5a6837 (8 commits, 7 files)

Found 2 issues:

1. `[P1][conf 95]` `AssignmentSource.queued` default is evaluated once at import time — src/sentry/integrations/services/assignment_source.py:18
   Failure: `queued: datetime = timezone.now()` is a dataclass field default, so `timezone.now()` runs once when the module is first imported (worker/web boot), not per instance. Every `AssignmentSource` built anywhere in the process — including all `from_integration()` calls in `sync_group_assignee_inbound` — carries the identical process-start timestamp, and that stale value is what gets serialized into `assignment_source_dict` and shipped to the task. The field is meaningless as a "when was this queued" marker, and any future staleness/TTL check built on it (the obvious next step for cycle-breaking) would silently never expire. No linter catches this: flake8-bugbear's B008 only inspects function-argument defaults, and this repo uses flake8, not ruff (RUF009). It also reads Django settings at module import.
   Fix: `from dataclasses import field` and `queued: datetime = field(default_factory=timezone.now)`. Note that `tests/sentry/integrations/services/test_assignment_source.py:37` (`assert result.get("queued") is not None`) passes either way, so it does not cover this.
   (bugs)

2. `[P2][conf 80]` `assignment_source` added to abstract `sync_status_outbound` is unreachable — src/sentry/integrations/mixins/issues.py:411
   Failure: the abstract signature now advertises `assignment_source: AssignmentSource | None = None`, but the only caller (`src/sentry/integrations/tasks/sync_status_outbound.py:46`) never passes it and calls `should_sync("outbound_status")` with no source, so status sync cycles are not broken. None of the four implementations accept the parameter — jira:990, jira_server:1090 and vsts:266 would swallow it into `**kwargs`, and `src/sentry/integrations/example/integration.py:161` (`def sync_status_outbound(self, external_issue, is_resolved, project_id)`) has no `**kwargs` and would raise `TypeError` the moment someone does wire it up. mypy won't catch the override mismatch — all four modules are in the `override`-disabled list in pyproject.toml:119-410.
   Fix: either drop the parameter until the status path is actually threaded, or complete it — thread a source through `sync_status_inbound` → `sync_status_outbound.apply_async` → `should_sync("outbound_status", source)` and add `**kwargs` to the example integration's override.
   (bugs; enforcement-vs-claim)

Checked: bugs, conventions, history, comments, slop. The deterministic detector suite did not run — the `sh .../detectors/run.sh` invocation was not approved, so no `deterministic` findings are included.
Skipped: nothing.

Notes on what I looked at and cleared: all four `sync_assignee_outbound` implementations accept `**kwargs`, so the new `assignment_source=` kwarg is safe; `CELERY_TASK_SERIALIZER` is `pickle` (src/sentry/conf/server.py:739), so the `datetime` inside `assignment_source_dict` survives the queue; `RpcOrganizationIntegration.integration_id` exists, so the new guard in `should_sync` is well-formed; all inbound assignment entry points (jira, jira_server, vsts) funnel through `sync_group_assignee_inbound`, so the source is threaded on every inbound path. A two-integration A↔B ping-pong is still possible in principle but terminates, because a repeat assignment to the same user leaves `affected` false in `GroupAssigneeManager.assign` and never re-fires outbound.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
