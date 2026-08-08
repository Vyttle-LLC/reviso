## Reviso review — HEAD (detached) vs de11fb0166a (24 commits, 6 files)

Note: the deterministic detector suite (`detectors/run.sh`) could not run — the sandbox refused the command outside the working directory. Findings below are from manual review only.

Found 4 issues:

1. **[P0][conf 90] Hung flusher processes are never killed — the new `isinstance` guard is always false** — `src/sentry/spans/consumers/process/flusher.py:254`
   Failure: `self.mp_context = multiprocessing.get_context("spawn")`, so `mp_context.Process` produces `multiprocessing.context.SpawnProcess`, which subclasses `process.BaseProcess` — **not** `multiprocessing.Process` (which is `context.Process`). So `isinstance(process, multiprocessing.Process)` is `False` for every real flusher process and `process.kill()` never executes. Previously the kill was unconditional. On the `cause = "hang"` path the process is still alive: it is not killed, and `_create_process_for_shards()` immediately spawns a second process for the *same* shards. Both call `buffer.flush_segments()` against the same Redis queue keys, so segments get read and produced to `buffered-segments` twice. This repeats up to `MAX_PROCESS_RESTARTS`, accumulating up to 10 live orphan flushers per process index, each with its own Redis connections. `git log -S "self.process.kill()"` points at #92920 ("We now apply the same behavior for hangs of the flusher process") — this change silently reverts that fix. The same always-false guard is at `flusher.py:346`, making `join()`'s `terminate()` dead too.
   Fix: gate on the type you actually want to exclude, not on `multiprocessing.Process`:
   ```python
   if not isinstance(process, threading.Thread):
       process.kill()
   ```
   (bugs, history)

2. **[P2][conf 100] Dead method and comments that describe logic the code doesn't have** — `src/sentry/spans/consumers/process/flusher.py:127`
   Failure: `_create_process_for_shard(self, shard)` (singular) has no callers anywhere in `src/` or `tests/` — the restart path calls `_create_process_for_shards(process_index, shards)` directly. Additional anchors: `flusher.py:222` `if not process: continue` can never fire (`self.processes` is typed non-optional and neither `SpawnProcess` nor `Thread` defines `__bool__`); `flusher.py:235` `# Check if any shard handled by this process is unhealthy` sits on a branch that checks one per-process `Value`, not per-shard anything; `flusher.py:178` `# Update healthy_since for all shards handled by this process` restates `healthy_since.value = system_now`. The branch has three separate "remove dead code" commits, so this is drift from the author's own intent.
   Fix: delete `_create_process_for_shard`, the `if not process` guard, and the three comments.
   (slop)

3. **[P2][conf 90] Class docstring claims one process per shard; the shipped default is one process for all shards** — `src/sentry/spans/consumers/process/flusher.py:32`
   Failure: the docstring says "Creates one process per shard for parallel processing", but `--flusher-processes` defaults to `1` (`src/sentry/consumers/__init__.py:434`), so `num_processes = min(1, len(assigned_shards)) == 1` and a single process handles every shard. Anyone reading the class to reason about flush parallelism or Redis connection count gets the wrong model.
   Fix: `Creates up to ``max_processes`` processes, with assigned shards distributed round-robin across them. Defaults to a single process handling all shards.`
   (comments)

4. **[P2][conf 95] The sleep added to `test_basic` is a no-op** — `tests/sentry/spans/consumers/process/test_consumer.py:62`
   Failure: line 15 does `monkeypatch.setattr("time.sleep", lambda _: None)`, which patches the `time` module attribute the test itself resolves at line 62. So `time.sleep(0.1)` returns immediately and the comment "Give flusher threads time to process after drift change" is false — the added `import time`, `step.poll()`, and sleep buy the flusher thread nothing. If `test_basic` was flaky before, this does not fix it.
   Fix: drop lines 60–62 and the `import time`, or poll for the condition instead — e.g. spin on `while not messages and time.monotonic() < deadline:` using `time.monotonic`, which the monkeypatch does not touch.
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: `CLAUDE.md` (docs-only addition, unrelated to the span-buffer change); deterministic detectors (blocked by sandbox).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
