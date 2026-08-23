## Reviso style — HEAD (detached) vs d0eb9e1 (0 commits, 1 file)

Found 1 style issue:

1. [P1][conf 95] README documents the removed `--output` flag — src/cli.ts:8
   Failure: `README.md:7` still reads: "Run `reviso-sync --output <path>` to write the merged manifest to a file instead of stdout." Renaming the option to `out` makes that sentence false — a reader following the README passes a flag `parseArgs` no longer defines, and the only usage documentation in the repo now describes an interface that does not exist. `src/cli.ts:17` (`values.out`) is the second anchor.
   Fix: update `README.md:7` to `` Run `reviso-sync --out <path>` ``.
   (stale docs)

Checked: reuse, drift, length, over-engineering, surface area, AI tells, naming, stale docs, deterministic.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config governs the changed path), error handling (skipped: the change touches no error paths), comments (skipped: no comments added or changed), test slop (skipped: no test files in the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
