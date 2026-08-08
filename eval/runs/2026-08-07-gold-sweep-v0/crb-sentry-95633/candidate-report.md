## Reviso review — HEAD (detached) vs `fd358e8a3` (8 commits, 7 files)

Found 4 issues:

**1. [P0][conf 90] Strategy `close()` destroys the factory-owned queue pool — consumer silently drops every message after a rebalance** — `src/sentry/remote_subscriptions/consumers/queue_consumer.py:338`

Failure: `FixedQueuePool` is created once in `ResultsStrategyFactory.__init__` (`result_consumer.py:133`) and reused for the process lifetime, but `SimpleQueueProcessingStrategy.close()`, `terminate()` (:342) and `join()` (:344) all call `queue_pool.shutdown()`. Arroyo's `StreamProcessor` closes/joins the strategy on every partition revocation and then calls `create_with_partitions` again on reassignment. After the first rebalance (deploy, scale-up, broker hiccup) the pool's worker threads have exited and its queues are `shutdown()`. The new strategy asserts `queue_pool is not None` and passes, then every `submit()` hits `work_queue.put()` → `queue.ShutDown` → caught by the blanket `except Exception` at :317, which logs and calls `add_offset` + `complete_offset`. The commit loop then commits those offsets. Result: silent, permanent data loss with a healthy-looking consumer. This diverges from the established pattern in this file — `parallel_executor` and `MultiprocessingPool` are process-lifetime resources torn down only in `ResultsStrategyFactory.shutdown()` (`result_consumer.py:180`), never by a strategy (same in `monitors/consumers/monitor_consumer.py:1150`).

Fix: don't tear down the shared pool from the strategy. `close()`/`join()` should stop the commit thread, drain outstanding work, and do a final commit; leave `queue_pool.shutdown()` to `ResultsStrategyFactory.shutdown()` (which already does it, :183-185). Alternatively make the pool per-strategy — created in `create_thread_queue_parallel_worker` rather than in `__init__`.

(bugs, history)

**2. [P1][conf 85] "Natural backpressure" is claimed but the queues are unbounded and `submit()` never rejects** — `src/sentry/remote_subscriptions/consumers/queue_consumer.py:253`

Failure: the class docstring guarantees "Natural backpressure when queues fill up", but `queue.Queue()` at :185 has no `maxsize`, `submit()` never raises `MessageRejected`, and `poll()` (:327) only emits a gauge. Arroyo will feed messages as fast as the broker delivers them. On a consumer restart against a large uptime-results backlog, or when one group's `result_processor` stalls, its queue grows without bound — every `WorkItem` also pins a full `Message[KafkaPayload]` (see finding 4) — until the pod OOMs. `OffsetTracker.all_offsets` grows alongside it since nothing can be committed past the stalled offset.

Fix: give each queue a bounded `maxsize` and raise `arroyo.processing.strategies.abstract.MessageRejected` from `submit()` when the target queue is full (arroyo will re-deliver the message), or drop the backpressure claim from the docstring and add an explicit total-depth cap.

(bugs)

**3. [P2][conf 85] `shutdown()` sets the worker stop flag before `q.shutdown(immediate=False)`, so queued items are abandoned** — `src/sentry/remote_subscriptions/consumers/queue_consumer.py:231`

Failure: `shutdown()` sets `worker.shutdown = True` for all workers (:233-234) *before* calling `q.shutdown(immediate=False)` (:238). `immediate=False` exists to let workers drain what's already queued, but each worker's loop re-checks `while not self.shutdown` after finishing its current item and exits immediately — so with, say, 200 items queued across 20 workers, at most 20 are processed and ~180 are dropped. The docstring says "Gracefully shutdown all workers"; the `immediate=False` argument is dead. Offsets aren't committed for the dropped items so there's no data loss, but every restart re-does that work, and combined with finding 1 the abandoned items' offsets stay `outstanding` forever in the shared tracker.

Fix: call `q.shutdown(immediate=False)` first and let `queue.ShutDown` from `get()` be the sole exit signal; drop the `self.shutdown` flag (or only set it in a `terminate`-style immediate path that also passes `immediate=True`).

(bugs, comments)

**4. [P2][conf 80] Unused `WorkItem.message` field and unused `wait_until_empty` helper** — `src/sentry/remote_subscriptions/consumers/queue_consumer.py:31`

Failure: `WorkItem.message` is documented as "the original message for offset tracking", but offset tracking uses the sibling `partition`/`offset` fields exclusively — `grep` over `src/sentry/remote_subscriptions/` and the tests shows the field is written at :312 and never read. It keeps the decoded `KafkaPayload` alive for the entire time an item sits in a queue, roughly doubling queue memory and worsening finding 2. `FixedQueuePool.wait_until_empty` (:222-229) is likewise never called from source or tests — the tests poll `get_stats()` directly.

Fix: drop the `message` field from `WorkItem` (and the `message=message` kwarg at :312) and delete `wait_until_empty`.

(slop)

---

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (the `detectors/run.sh` invocation was not approved, so that lens did not run); `tests/sentry/remote_subscriptions/{,consumers/}__init__.py` (empty files).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
