I reviewed the change (one untracked file, `src/metrics/record-scroll.ts`) against base `03699cf`, read `src/log.ts` and both sibling metric modules as the baseline, and ran the deterministic detector suite (clean, `[]`).

```text
## Reviso style — HEAD vs 03699cf (0 commits, 1 file)

No style issues found.

Checked: deterministic, drift, length, over-engineering, error handling,
surface area, slop, duplication, dead weight, AI tells, naming.
Not checked: conventions (skipped: no CLAUDE.md / AGENTS.md / lint config
in the repo), comments (skipped: the change adds no comments), stale docs
(skipped: no README, ADR, changelog, or doc comments in the repo), derived
state (skipped: the change adds no stored value), test slop (skipped: no
test files in the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

The change tracks the repo's demonstrated shape closely enough that the convention-relative lenses had nothing to bite on: module path and named export follow `record-click.ts:3` / `record-view.ts:3`, the `async … Promise<void>` signature and `try { await fetch(…) } catch (err) { log.warn(…) }` error shape are identical to both, and the log message and context fields follow the same `"metrics: <thing> not recorded"` form. Types are precise (`string`, `number`, no `any`, no casts). The export has no in-repo caller, but neither do `recordClick` or `recordView` — an uncalled export is this repo's surface, not dead weight.

Two candidates came up and were gated before reporting: the three-way repetition of the fetch/catch/warn block (exactly 3 occurrences of what reads as incidental boilerplate, and the shape is the repo's deliberate established style — below the duplication bar), and the singular `/metrics/scroll/` path segment against plural `clicks`/`views`. The second is worth a word since it isn't a style question either way: either the server route is genuinely singular and there's nothing to fix, or the path is wrong — which is a correctness matter this lane doesn't report. Worth a glance against the server's routes.
