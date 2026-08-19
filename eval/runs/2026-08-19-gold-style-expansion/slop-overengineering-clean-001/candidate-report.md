## Reviso style — HEAD (detached, at `776dbd4`) vs `776dbd46` (0 commits, 1 file)

No style issues found.

Checked: slop, duplication, over-engineering, dead weight, AI tells, deterministic.
Not checked: comments (skipped — the change adds no comments), conventions (skipped — no CLAUDE.md/AGENTS.md or lint config in the repo), drift (skipped — `src/notify.ts` is the repo's only source file, so the two-example baseline bar cannot be met), length (skipped — no comparable units in the repo to measure against), test slop (skipped — the change adds no tests).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on scope: the change is one untracked file, `src/notify.ts` (34 lines), reviewed in full as added lines. The `Notifier` interface plus `notifierFor` factory was examined under the over-engineering lens — it has two real implementations, both reachable from the `"email" | "sms"` union, so it is not single-consumer machinery. The two `send` bodies are 2 occurrences of a near-verbatim block, which is below the duplication bar and does not ship. All non-exported symbols have callers; the exports are a new module's public API in a repo with no other files.
