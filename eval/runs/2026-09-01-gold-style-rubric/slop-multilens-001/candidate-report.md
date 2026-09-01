## Reviso style — HEAD (detached) vs c486e70 (0 commits, 4 files)

Found 7 style issues:

1. **[P1][conf 100] Placeholder text committed — unimplemented behavior presented as implemented** — src/format/period.ts:8
   Failure: `// In a real implementation, this would use the account's locale` — the code admits it is a stand-in, so the locale handling a reader assumes is there never happens.
   Fix: implement the locale lookup, or drop the comment and the pretense with it.
   (deterministic)

2. **[P1][conf 96] Test cannot fail — asserts a value against itself** — src/services/summary-manager.test.ts:9
   Failure: `const total = manager.total(); expect(total).toBe(total);` passes for every possible return value, including `NaN` or `0`. The test named "total sums invoice totals" exercises nothing but that `total()` does not throw.
   Fix: `expect(manager.total()).toBe(15);`
   (test slop)

3. **[P1][conf 92] `persist` swallows and logs where this repo wraps and rethrows** — src/services/summary-manager.ts:31
   Baseline: src/storage/read-blob.ts:7-9 and src/storage/delete-blob.ts:6-8 both `catch (cause) { throw new StorageError(\`failed to ... ${key}\`, { cause }); }` — specific message, cause preserved, surfaced to the caller. `persist` instead does `catch (err) { console.warn("persist failed"); }`: generic message, cause dropped, nothing surfaced. The file already imports `StorageError` (line 2) and never uses it.
   Fix: `catch (cause) { throw new StorageError(\`failed to persist summary ${key}\`, { cause }); }`
   (error handling)

4. **[P2][conf 90] Changelog comment and comparative name on a new function** — src/format/period.ts:5-6
   Failure: `// Fixed bug where the end date was off by one day` describes a repo history event, not the code — and this function is new, so no such fix happened here. `formatPeriodEnhanced` names itself only in relation to `formatPeriod`; a reader six months out cannot tell which one to call or why.
   Fix: delete the comment (git history carries that), and name the function for what it does — `formatInclusivePeriod` — or fold the inclusive-end behavior into `formatPeriod` and keep one entry point.
   (AI tells)

5. **[P2][conf 90] Comments restate the code they sit on** — src/services/summary-manager.ts:18, :20
   Failure: `// Sum the totals of all invoices` says what `total()` already says; `// Loop over each invoice and add its total to the sum` narrates the `for` loop verbatim. Neither carries information the code cannot; both are lines a maintainer must keep true for no return.
   Fix: delete both.
   (comments)

6. **[P2][conf 88] `count` is a stored projection of `invoices.length`** — src/services/summary-manager.ts:6
   Failure: every write is a lockstep copy of the source — constructor `this.invoices = invoices;` / `this.count = invoices.length;` (:9-10) and `replace` `this.invoices = invoices;` / `this.count = invoices.length;` (:14-15). There is exactly one reader, `${manager.count}` at :42. The field can never say anything `invoices.length` doesn't, but every future write path has to remember to update it.
   Fix: drop the `count` field and both its assignments; read `manager.invoices.length` at :42.
   (derived state)

7. **[P2][conf 84] `Manager` suffix in a directory that names its classes `Service`** — src/services/summary-manager.ts:4
   Baseline: src/services/invoice-service.ts:3 `export class InvoiceService` and src/services/export-service.ts:3 `export class ExportService` are the only two precedents in `src/services/`, and both use `<Noun>Service`.
   Fix: rename to `SummaryService` in `src/services/summary-service.ts`, following the two cited files.
   (naming)

Checked: reuse, tests, drift, length, over-engineering, error handling, surface area, comments, AI tells, naming, deterministic.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md, or lint config anywhere in the repo), stale docs (skipped: no README, docs, ADRs, or changelog exist, so no prose the change could falsify).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Two things I looked at and deliberately did not report: the duplicated `BASE_URL` declaration (src/app.ts:4, src/cli/summary.ts:5) sits at two occurrences, below the duplication bar; and the uncalled `toCsvRow` (:37) and `replace` (:13) clear the dead-weight lens because this repo already ships uncalled exports and public methods — `readBlob`, `deleteBlob`, `InvoiceService.isOverdue` (invoice-service.ts:11), `ExportService.hasRows` (export-service.ts:14) all have zero callers.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
