All four files read, detectors run, greps done. Here's the report.

```text
## Reviso style — HEAD vs 7c31cf7 (0 commits, 1 file)

Found 2 style issues:

1. [P1][conf 92] `validateReport` asserts validation but only returns a field — src/services/report-manager.ts:15
   Baseline: this repo's method names describe exactly what the body does —
   `hasRows` returns `invoices.length > 0` (src/services/export-service.ts:14),
   `isOverdue` computes exactly that predicate (src/services/invoice-service.ts:11).
   `validateReport` validates nothing: it returns `report.title`, and its
   `string` return type is a title, not a validation result.
   Fix: if it is an accessor, name it `reportTitle` (or drop it and read
   `report.title` at the call site). If validation is intended, the name should
   wait for the code that does it.
   (naming)

2. [P2][conf 88] New service's class, file, and method names diverge from the sibling services — src/services/report-manager.ts:3
   Baseline: both existing services in `src/services/` use the `*Service` suffix
   in `*-service.ts` — `ExportService` (src/services/export-service.ts:3),
   `InvoiceService` (src/services/invoice-service.ts:3); their fetchers are
   verb-prefixed — `fetchInvoices` (src/services/invoice-service.ts:6),
   `exportCsv` (src/services/export-service.ts:6); their booleans are phrased as
   predicates — `isOverdue` (src/services/invoice-service.ts:11), `hasRows`
   (src/services/export-service.ts:14). The new file uses a `Manager` suffix no
   other file uses, and names a fetcher `data` (src/services/report-manager.ts:6)
   and a predicate `empty` (src/services/report-manager.ts:11).
   Fix: `ReportService` in `src/services/report-service.ts`; `data` →
   `fetchReport`; `empty` → `isEmpty`.
   (naming)

Checked: slop, duplication, drift, length, over-engineering, dead weight, AI tells, derived state, naming, error handling, deterministic.
Not checked: comments (skipped — the change adds no comments), conventions (skipped — no CLAUDE.md, AGENTS.md, or lint config in the repo), test slop (skipped — the repo has no tests and the change adds none).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: slop 0, comments skipped, duplication 1, conventions skipped, drift 0,
length 0, over-engineering 0, dead-weight 1, test-slop skipped, ai-tells 0,
derived-state 0, naming 3, error-handling 0, deterministic 0.
Candidates before the gate (5):
  [naming]      report-manager.ts:15  score 92  reported
  [naming]      report-manager.ts:3   score 90  reported (merged into #2)
  [naming]      report-manager.ts:6   score 88  reported (merged into #2)
  [duplication] report-manager.ts:4   score 20  dropped: exclusion-list
  [dead-weight] report-manager.ts:3   score 15  dropped: exclusion-list
```

Notes on the two dropped candidates, since you asked for `--explain`:

- **duplication** — `constructor(private readonly baseUrl: string) {}` now appears 3 times (export-service.ts:4, invoice-service.ts:4, report-manager.ts:4). Exactly-3 ships only when the unit encodes a rule a future edit must change everywhere at once; a constructor-injection declaration is incidental boilerplate, so it stays silent.
- **dead weight** — `grep -rn "ReportManager\|validateReport\|report-manager"` across `*.ts`/`*.js`/`*.json` returns only the definitions, no callers. But the same grep shows `InvoiceService` and `ExportService` have no callers either, so an uncalled service export is this repo's established state, not something the change introduced.

Error handling was checked and came back clean: the new `data()` does bare `fetch` → `res.json()` with no `res.ok` check and no try/catch, which is exactly the shape at invoice-service.ts:7-8 and export-service.ts:7-11. Whether that unchecked response is an actual failure is a bug question, not this lane's.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
