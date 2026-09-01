Detectors ran clean (`[]`). Working through the lenses now.

## Reviso style — HEAD (detached) vs ed632ff (0 commits, 1 file)

Found 1 style issue:

```
1. [P1][conf 95] README usage line still documents the removed --output flag — src/cli.ts:8
   Failure: The flag was renamed `output` → `out`, so README.md:7 now
   documents a flag that no longer parses. A reader following the README
   runs `reviso-sync --output ./m.json`, node:util parseArgs rejects the
   unknown option, and the documented path is unreachable. Contradicted
   sentence, verbatim, README.md:7:
     "Run `reviso-sync --output <path>` to write the merged manifest to a file"
   Fix: Update README.md:7 to `Run `reviso-sync --out <path>` …`.
   (stale docs)
```

Checked: reuse, deterministic, drift, length, over-engineering, surface area, AI tells, naming, stale docs.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in the repo), error handling (skipped: the change adds or alters no error handling), comments (skipped: no comments in the changed hunks), test slop (skipped: no test files in the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
