## Reviso review — HEAD (detached, `4def149a50`) vs `c834e7473c` (1 commit, 4 files)

Found 2 issues:

1. **[P1][conf 90] Regression test asserts before joining the reader thread, so it can miss the very NPE it guards** — `tests/base/src/test/java/org/keycloak/tests/admin/group/GroupTest.java:155`
   Failure: the reader thread's last `groups(...)` call — the one most likely to race the final `remove()` and hit the 500/NPE — is still in flight (network + server round-trip, milliseconds) when the main thread executes `deletedAll.set(true); assertThat(caughtExceptions, empty())` microseconds later. `caughtExceptions.add(e)` lands after the assertion has already read an empty list, so the test passes green against the unfixed `GroupAdapter`. The thread is also never joined, so it outlives the test method and keeps issuing admin requests during teardown.
   Fix: hold the `Thread` in a local, and `t.join()` (with a timeout) after `deletedAll.set(true)` and before the assertion. Also assert the reader actually performed at least one read (an `AtomicInteger` iteration counter) so a fast delete loop can't silently make the test vacuous, and include the exception in the failure message (`assertThat(caughtExceptions.toString(), caughtExceptions, empty())`).
   (bugs)

2. **[P2][conf 80] `getSubGroupsCount()` now returns `null`, contradicting the interface's documented "Never returns `null`"** — `model/infinispan/src/main/java/org/keycloak/models/cache/infinispan/GroupAdapter.java:275`
   Failure: `GroupModel.getSubGroupsCount()` (`server-spi/src/main/java/org/keycloak/models/GroupModel.java:296`) documents `@return The number of groups beneath this group. Never returns {@code null}.` — a contract added deliberately in `69497382d8` and relied on by every other implementation (`model/jpa/.../GroupAdapter.java:190`, the SPI default). The new branch returns `null` for a concurrently-deleted group; `GroupUtils.populateSubGroupCount` (`services/src/main/java/org/keycloak/utils/GroupUtils.java:90`) passes it straight into the representation, so the admin REST response omits `subGroupCount`, and the admin UI's `group.subGroupCount !== 0` checks (`js/apps/admin-ui/src/components/group/GroupPickerDialog.tsx:324`, `:379`) then render the vanished group as expandable. Nothing in the change updates the contract, so the next implementer still reads "never null".
   Fix: either return `0L` here (the group has no reachable subgroups once it's gone) or keep `null` and update the `@return` javadoc on `GroupModel.getSubGroupsCount()` to state that cache-backed implementations may return `null` when the group was concurrently removed, so callers know to null-check.
   (comments; contract vs. enforcement)

Checked: bugs, conventions, history, comments, slop. No `CLAUDE.md`/`AGENTS.md` exists in this repo, so the conventions lens ran against repo norms only.
Skipped: nothing. The deterministic detector suite did not run — the `sh .../detectors/run.sh` invocation was not approved, so no `deterministic` findings are included.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
