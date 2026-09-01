I have the full picture. Working through the lenses now.

**Ledger recorded per lens** — deterministic (returned, 1), slop (returned, 0), comments (returned, 1), duplication (returned, 0), conventions (skipped), drift (returned, 0), length (returned, 0), over-engineering (returned, 0), dead weight (returned, 1), test slop (returned, 1), AI tells (returned, 1), derived state (returned, 1), naming (returned, 1), error handling (returned, 1), stale docs (skipped), surface area (returned, 1).

```text
## Reviso style — HEAD (detached) vs ea3e074 (0 commits, 4 files)

Found 8 style issues:

1. [P1][conf 100] Placeholder text committed — unimplemented code presented as implemented — src/format/period.ts:8
   Failure: `// In a real implementation, this would use the account's locale` — the
   comment admits locale handling is a stand-in; the next reader assumes it exists.
   Fix: implement the locale-aware formatting, or drop the comment and track the gap explicitly.
   (deterministic)

2. [P1][conf 95] Test assertion cannot fail — src/services/summary-manager.test.ts:9
   Failure: `expect(total).toBe(total);` compares the value to itself, so it passes for
   any `total()` implementation — including one that returns 0 or throws away invoices.
   The test's name claims coverage of summing that no assertion exercises.
   Fix: `expect(manager.total()).toBe(15);`
   (test slop)

3. [P1][conf 92] `persist` swallows errors where the repo wraps and surfaces them — src/services/summary-manager.ts:31
   Baseline: src/storage/read-blob.ts:7-9 and src/storage/delete-blob.ts:6-8 both catch
   as `cause` and `throw new StorageError(\`failed to … blob ${key}\`, { cause })` — a
   keyed message plus the cause chain. `persist` instead logs the generic
   `console.warn("persist failed")`, discards `err`, and resolves normally. The file
   already imports `StorageError` (line 2) without using it.
   Fix: `} catch (cause) { throw new StorageError(\`failed to write blob ${key}\`, { cause }); }`
   (error handling)

4. [P2][conf 92] Changelog comment and comparative name on `formatPeriodEnhanced` — src/format/period.ts:6
   Failure: `// Fixed bug where the end date was off by one day` (line 5) narrates a
   past edit rather than the code, and `Enhanced` dates the function against its
   neighbour instead of naming what it does — the next variant has nowhere to go.
   No repo name uses a comparative or temporal qualifier (`formatPeriod`, `readBlob`,
   `deleteBlob`, `InvoiceService`, `ExportService`).
   Fix: delete the comment; rename to `formatInclusivePeriod`, which states the actual
   difference from `formatPeriod`.
   (AI tells; additional anchor src/format/period.ts:5)

5. [P2][conf 90] `count` is a stored projection of `invoices.length` — src/services/summary-manager.ts:6
   Failure: every write site sets it from the source in the same breath —
   constructor `this.invoices = invoices; this.count = invoices.length;` (lines 9-10)
   and `replace` `this.invoices = invoices; this.count = invoices.length;` (lines 14-15).
   The single read is `manager.count` at line 42. The field can never say anything
   `invoices.length` doesn't, but every future mutator must remember the second line.
   Fix: delete the `count` field and both assignments; `summaryLine` reads
   `manager.invoices.length`.
   (derived state)

6. [P2][conf 90] Comments restate the code they sit above — src/services/summary-manager.ts:18
   Failure: `// Sum the totals of all invoices` repeats the signature `total(): number`
   over an invoice list, and `// Loop over each invoice and add its total to the sum`
   (line 20) narrates the `for` loop directly beneath it. A reader pays for two lines
   that carry nothing the four lines of code don't already say.
   Fix: delete both comments.
   (comments; additional anchor src/services/summary-manager.ts:20)

7. [P2][conf 88] Added members with no caller anywhere in the repo — src/services/summary-manager.ts:37
   Failure: grepped `toCsvRow` and `.replace(` across `src` — `toCsvRow` appears only at
   its definition (line 37), `replace` only at its definition (line 13); no dynamic
   access (no reflection, string-keyed dispatch, or DI registration exists in this repo).
   `ExportService.exportCsv` already posts invoices to the server for CSV, so `toCsvRow`
   is a second, unreachable CSV encoding a future reader must reconcile.
   Fix: delete `toCsvRow` and `replace`.
   (dead weight; additional anchor src/services/summary-manager.ts:13)

8. [P2][conf 85] `SummaryManager` uses a suffix the repo doesn't — src/services/summary-manager.ts:4
   Baseline: the repo's only other classes are `InvoiceService` (src/services/invoice-service.ts:3)
   and `ExportService` (src/services/export-service.ts:3), both `*Service` in
   `src/services/*-service.ts`. `Manager` names no responsibility the `Service` suffix
   doesn't already carry here.
   Fix: rename to `SummaryService`, file `src/services/summary-service.ts`.
   (naming)

Checked: reuse, tests, deterministic, drift, length, over-engineering, error handling, surface area, comments, AI tells, naming.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md, or lint config governing the changed paths), stale docs (skipped: repo has no README, docs, or doc comments on a changed signature).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Two notes on what did **not** ship: the duplicated `BASE_URL` line (`src/app.ts:4`, `src/cli/summary.ts:5`) sits at two occurrences, below the duplication bar; and a ninth finding (surface area on `formatPeriod`, exported at `src/format/period.ts:1` with its only caller at line 9 inside its own module, conf 82) was cut by the 8-finding cap.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
