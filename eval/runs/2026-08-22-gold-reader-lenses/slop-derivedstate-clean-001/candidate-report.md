## Reviso style — HEAD vs 67b055c (0 commits, 4 files)

No style issues found.

Checked: slop, duplication, length, over-engineering, dead weight, AI tells, derived state, naming, deterministic.
Not checked: comments (skipped — the change adds no comments), conventions (skipped — no CLAUDE.md/AGENTS.md or lint config in the repo), drift (skipped — the base commit is empty, so there is no pre-existing code to establish a baseline from), test slop (skipped — the change adds no tests), error handling (skipped — the change has no error paths).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

```
--- explain: pipeline diagnostics (not review findings) ---
Lenses: slop 0, comments skipped, duplication 0, conventions skipped,
drift skipped, length 0, over-engineering 0, dead-weight 1, test-slop skipped,
ai-tells 0, derived-state 0, naming 0, error-handling 0, deterministic 0.
Candidates before the gate (1):
  [dead-weight] src/session.ts:17  score 20  dropped: exclusion-list
```

Notes on the two lenses that did real work here:

- **derived-state** — `Session.messages` (`src/session.ts:6`) looked like a projection of `manifest.platform.messages`, but it has two write sites that don't come from that source: the constructor writes `tenant.messageOverrides ?? manifest.platform?.messages ?? []` (`src/session.ts:10`, tenant override wins), and `setMessages` writes an arbitrary caller value (`src/session.ts:18`). One independent write disqualifies it — not derived, no finding.
- **dead-weight** — `setMessages`, `apply`, and `bannerText` have no callers (grepped `setMessages`, `bannerText`, `new Session`, `.apply(` across the repo; only definitions came back). Dropped: the whole change is a greenfield module with no entry point, so *every* added symbol is uncalled — that's the shape of a new module seam, not dead code.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
