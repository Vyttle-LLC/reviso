## Reviso style — HEAD (detached) vs `776dbd4` (0 commits, 2 files)

No style issues found.

Checked: slop, duplication, length, over-engineering, dead weight, test slop, AI tells, deterministic.
Not checked: comments (skipped — the change adds no comments); conventions (skipped — no CLAUDE.md/AGENTS.md and no lint config in the repo); drift (skipped — base `776dbd4` is an empty tree, so there is no existing code to cite as an established norm).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on the run: the whole change is two untracked files (`src/reminder.ts`, `tests/reminder.test.ts`), nothing committed on the branch and no commit messages to read for intent. The deterministic detector suite ran and returned `[]`. Dead-weight search: grepped `sendOverdueReminder`, `Mailer`, `daysOverdue`, and the literal `"Final notice: invoice overdue"` across `src/` and `tests/` — both exports have a consumer in the test, all three parameters are read, so nothing unused.
