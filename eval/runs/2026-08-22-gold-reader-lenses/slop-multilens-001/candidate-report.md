## Reviso style — HEAD (detached) vs `d7d9c43` (0 commits, 4 files)

Found 8 style issues:

**1. [P1][conf 100] Test assertion is tautological and cannot fail** — `src/services/summary-manager.test.ts:9`
Failure: `expect(total).toBe(total)` compares the value to itself, so it passes for any `total()` implementation — including one that returns `0`. The file reads as coverage for `total()` and provides none.
Fix: assert the expected sum: `expect(manager.total()).toBe(15);`
(test slop)

**2. [P1][conf 100] Placeholder text committed — unimplemented code presented as implemented** — `src/format/period.ts:8`
Failure: `// In a real implementation, this would use the account's locale` admits the code is a stand-in; the locale handling it describes never happens, and the next reader can't tell whether the gap is tracked.
Fix: implement locale-aware formatting, or drop the comment and track the gap explicitly.
(deterministic)

**3. [P1][conf 95] `persist` swallows and logs where this repo wraps and rethrows** — `src/services/summary-manager.ts:31`
Baseline: both existing storage writers surface the failure with a keyed message — `src/storage/read-blob.ts:8` (``throw new StorageError(`failed to read blob ${key}`, { cause })``) and `src/storage/delete-blob.ts:7` (``throw new StorageError(`failed to delete blob ${key}`, { cause })``). The new catch does `console.warn("persist failed")` with no key and no `cause`. The file already imports `StorageError` at line 2 and never uses it.
Fix: ``catch (cause) { throw new StorageError(`failed to persist summary ${key}`, { cause }); }``
(error handling)

**4. [P2][conf 92] `count` is a stored projection of `invoices.length`** — `src/services/summary-manager.ts:6`
Failure: every write is lockstep with the source — `src/services/summary-manager.ts:9-10` (`this.invoices = invoices; this.count = invoices.length;`) and `src/services/summary-manager.ts:14-15` (identical pair in `replace`). The single reader is `src/services/summary-manager.ts:42` (`${manager.count} invoices`). The field can never say anything `invoices.length` doesn't, but every future mutator has to remember to update it.
Fix: delete the field and read the source at the one call site: `` `${manager.invoices.length} invoices, ${manager.total()} total` ``.
(derived state)

**5. [P2][conf 92] Comparative name and changelog comment in `period.ts`** — `src/format/period.ts:5`
Failure: `formatPeriodEnhanced` (line 6) says only that it is newer than `formatPeriod`, not what it does differently; `// Fixed bug where the end date was off by one day` (line 5) documents a commit, not the code, and goes stale the moment history moves on. No existing name in the repo carries an `Enhanced`/`New`/`2` qualifier.
Fix: name the behavior — `formatInclusivePeriod` — and replace the changelog line with nothing (the `inclusiveEnd` local already says it), or fold the inclusive-end adjustment into `formatPeriod` itself.
(AI tells)

**6. [P2][conf 90] Comments in `total()` restate the code** — `src/services/summary-manager.ts:18`
Failure: `// Sum the totals of all invoices` above a method named `total` and `// Loop over each invoice and add its total to the sum` (line 20) above `for (const invoice of this.invoices) { sum += invoice.total; }` narrate what the code already says. They cost the reader two lines to learn nothing and will not be updated when the body changes.
Fix: delete both. No `CLAUDE.md`, `AGENTS.md`, or lint config in this repo requires a doc comment here.
(comments)

**7. [P2][conf 88] `toCsvRow` and `replace` are added with no caller** — `src/services/summary-manager.ts:37`
Failure: `grep -rn 'toCsvRow' src/` returns only the definition at line 37; `grep -rn 'replace' src/` returns only the definition at line 13. A repo-wide grep for dynamic access (`Reflect`, `Object.keys`, `require(`, string-keyed indexing, DI registration) returns nothing, so neither is reachable indirectly. Both are exported surface a maintainer must keep working with nothing exercising them.
Fix: delete both; re-add when a caller exists. (CSV emission already lives in `ExportService.exportCsv`, `src/services/export-service.ts:6`.)
(dead weight)

**8. [P2][conf 85] `Manager` suffix diverges from this repo's `Service` naming** — `src/services/summary-manager.ts:4`
Baseline: every other class in `src/services/` is a `Service` — `InvoiceService` (`src/services/invoice-service.ts:3`) and `ExportService` (`src/services/export-service.ts:3`). `Manager` names the class after nothing in particular.
Fix: rename to `SummaryService` in `src/services/summary-service.ts`, following the two cited files.
(naming)

Checked: deterministic, slop, comments, duplication, drift, length, over-engineering, dead weight, test slop, AI tells, derived state, naming, error handling.
Not checked: conventions (skipped — no `CLAUDE.md`, `AGENTS.md`, or lint config exists anywhere in the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: slop 1, comments 1, duplication 0, conventions skipped, drift 2,
length 0, over-engineering 1, dead-weight 1, test-slop 1, ai-tells 2,
derived-state 1, naming 1, error-handling 1, deterministic 1.
Candidates before the gate (13):
  [test-slop]   summary-manager.test.ts:9   score 100  reported
  [determin.]   period.ts:8                 score 100  reported
  [error-hand]  summary-manager.ts:31       score  95  reported
  [derived]     summary-manager.ts:6        score  92  reported
  [ai-tells]    period.ts:6                 score  92  reported (consolidated, finding 5)
  [ai-tells]    period.ts:5                 score  92  reported (consolidated, finding 5)
  [comments]    summary-manager.ts:18       score  90  reported (2 anchors)
  [dead-weight] summary-manager.ts:37       score  88  reported (2 anchors)
  [naming]      summary-manager.ts:4        score  85  reported
  [over-eng]    period.ts:1                 score  72  dropped: rubric-score
  [drift]       summary-manager.ts:41       score  70  dropped: rubric-score
  [drift]       summary-manager.ts:4        score  65  dropped: rubric-score
  [slop]        summary-manager.ts:19       score  40  dropped: rubric-score
Below-bar, not raised: BASE_URL const duplicated across src/app.ts:4 and
src/cli/summary.ts:5 — 2 occurrences, under the duplication lens's bar.
```

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
