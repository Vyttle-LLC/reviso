## Reviso style — HEAD vs `90c37b3` (0 commits, 2 files)

No style issues found.

Checked: tests, deterministic, slop, duplication, dead weight, over-engineering, surface area, AI tells.
Not checked: drift (skipped: base commit is an empty tree — no existing same-language files to cite as baseline); naming (skipped: same, no baseline); error handling (skipped: no error handling in the change, and no baseline); length (skipped: no comparable units in the repo to measure against); type slop (skipped: no loosened types in the change, and no baseline); conventions (skipped: no CLAUDE.md / AGENTS.md / lint config in the repo); comments (skipped: the change adds no comments); derived state (skipped: no stored state added); stale docs (skipped: no prose or doc files in the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on the two candidates I considered and dropped:

- The two `it` blocks in `tests/reminder.test.ts:6` and `:15` are near-identical scaffolding, but that is 2 occurrences of incidental assertion setup — below the duplication bar (2-or-fewer never ships), and test-only with no written convention demanding shared helpers.
- The `Mailer` interface (`src/reminder.ts:1`) has one production consumer, but it is the injection seam the test substitutes at (`tests/reminder.test.ts:4`), so it is not single-consumer machinery.

Both `sendOverdueReminder` and `Mailer` are imported from outside their module by the test file (grep for `sendOverdueReminder`, `Mailer`, `daysOverdue`, and the literals `Final notice` / `settle the outstanding` returned only those two files), so neither dead weight nor surface area applies.
