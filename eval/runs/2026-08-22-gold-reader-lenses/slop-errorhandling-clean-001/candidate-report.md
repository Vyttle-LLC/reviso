## Reviso style — HEAD (detached) vs 7dbf08e (0 commits, 1 file)

No style issues found.

Checked: slop, duplication, drift, length, over-engineering, dead weight, AI tells, derived state, naming, error handling, deterministic.
Not checked: comments (skipped — the change adds no comments), conventions (skipped — no CLAUDE.md / AGENTS.md / lint config anywhere in the repo), test slop (skipped — no test files in the change or the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: slop 0, comments skipped, duplication 1, conventions skipped,
drift 0, length 0, over-engineering 0, dead-weight 1, test-slop skipped,
ai-tells 0, derived-state 0, naming 0, error-handling 0, deterministic 0.
Candidates before the gate (2):
  [duplication]  src/metrics/record-scroll.ts:4   score 0  dropped: exclusion-list
  [dead-weight]  src/metrics/record-scroll.ts:3   score 0  dropped: exclusion-list
```

Notes on the two dropped candidates:

- **duplication** — the try/catch + `fetch` + `log.warn("metrics: … not recorded", {…, err})` shape now appears 3×, alongside `src/metrics/record-click.ts:4` and `src/metrics/record-view.ts:4`. At exactly 3 the lens ships only if the duplicated unit encodes a rule that can change; here the endpoint, payload, and log fields all differ per call, leaving incidental boilerplate over an established one-function-per-metric layout. Dropped as deliberate style.
- **dead weight** — `recordScroll` has no caller (grepped `recordScroll` and `record-scroll` repo-wide; only the definition). But `recordView` and `recordClick` are equally uncalled — this module is a library of exports with no in-repo consumer, which is the repo's demonstrated norm, not something the change introduced.

The new file matches both siblings on naming (`record<Event>` / `record-<event>.ts`), error-handling shape, function length, and log-message phrasing.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
