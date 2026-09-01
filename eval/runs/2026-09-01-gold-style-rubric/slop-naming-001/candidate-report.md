## Reviso style — HEAD vs af10d97 (0 commits, 1 file)

Found 2 style issues:

1. **[P1][conf 92]** `validateReport` asserts validation it does not perform — src/services/report-manager.ts:15
   Baseline: every other method in this repo names exactly what it does — `isOverdue` returns the overdue predicate (src/services/invoice-service.ts:11), `hasRows` returns the row predicate (src/services/export-service.ts:14), `exportCsv` posts and returns the CSV (src/services/export-service.ts:6). `validateReport` performs no validation: its whole body is `return report.title;`, and its return type is `string`, not a validation result.
   Fix: drop the method and read `report.title` at the call site, or, if an accessor is wanted, name it for what it returns — `reportTitle(report: Report): string`.
   (naming)

2. **[P2][conf 90]** New class and its methods diverge from the repo's naming idiom — src/services/report-manager.ts:3
   Baseline: this repo names services `<Noun>Service` in `<noun>-service.ts` — `InvoiceService` (src/services/invoice-service.ts:3), `ExportService` (src/services/export-service.ts:3); no `Manager` suffix exists anywhere in `src/`. Fetch methods are verb phrases — `fetchInvoices` (src/services/invoice-service.ts:6), `exportCsv` (src/services/export-service.ts:6). Booleans are predicates — `isOverdue` (src/services/invoice-service.ts:11), `hasRows` (src/services/export-service.ts:14).
   Fix: `ReportManager` → `ReportService` in `src/services/report-service.ts`; `data(accountId, month)` (src/services/report-manager.ts:6) → `fetchReport(accountId, month)`; `empty(report)` (src/services/report-manager.ts:11) → `isEmpty(report)`, or invert to `hasInvoices(report)` to mirror `hasRows`.
   (naming)

Checked: shape, text, reuse, tests, deterministic.
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
