## Reviso style — HEAD vs 29d705f (0 commits, 4 files)

Found 8 style issues:

1. **[P1][conf 100] Placeholder text committed — unimplemented code presented as implemented** — src/format/period.ts:8
   Failure: `// In a real implementation, this would use the account's locale` tells the next reader the locale handling exists somewhere; it does not, and nothing tracks the gap.
   Fix: implement the locale-aware formatting or delete the comment and the pretense with it.
   (deterministic)

2. **[P1][conf 95] Tautological assertion — the test cannot fail** — src/services/summary-manager.test.ts:9
   Failure: `expect(total).toBe(total)` compares a value to itself, so `total()` could return `0`, `NaN`, or throw off-by-one sums and the suite stays green while reading as coverage of "total sums invoice totals".
   Fix: `expect(total).toBe(15);` — the fixture's two invoices are `total: 10` and `total: 5`.
   (test slop)

3. **[P1][conf 92] `persist` swallows and logs where this repo wraps and rethrows** — src/services/summary-manager.ts:31
   Baseline: src/storage/read-blob.ts:7-9 and src/storage/delete-blob.ts:6-8 both do `catch (cause) { throw new StorageError(\`failed to … ${key}\`, { cause }); }` — key-specific message, cause preserved, surfaced to the caller. This file already imports `StorageError` (src/services/summary-manager.ts:2) and then never uses it.
   Fix: `catch (cause) { throw new StorageError(\`failed to persist summary ${key}\`, { cause }); }` and drop the `console.warn("persist failed")`.
   (error handling)

4. **[P2][conf 92] Comments restate the code they sit above** — src/services/summary-manager.ts:18
   Failure: `// Sum the totals of all invoices` says what `total()` says; `// Loop over each invoice and add its total to the sum` (line 20) narrates the `for` beneath it. Neither survives a rename, so both become the reader's second thing to verify.
   Fix: delete both lines. There is no CLAUDE.md, AGENTS.md, or lint config in this repo requiring them.
   (comments)

5. **[P2][conf 90] `count` is a stored projection of `invoices.length`** — src/services/summary-manager.ts:6
   Failure: every write of `count` comes from `invoices` in the same breath — `this.invoices = invoices; this.count = invoices.length;` at lines 9-10 and again at lines 14-15 — so the field can never say anything `invoices.length` doesn't, but every future mutation path has to remember the lockstep.
   Fix: one reader (`manager.count` at line 42) — delete the field and write `` `${manager.invoices.length} invoices, …` ``.
   (derived state)

6. **[P2][conf 88] Comparative name and changelog comment** — src/format/period.ts:6
   Failure: `formatPeriodEnhanced` names itself relative to `formatPeriod` rather than by what it does, so the pair gives a caller no way to choose; `// Fixed bug where the end date was off by one day` (line 5) is commit-message text in source, and it goes stale the moment the next edit lands. No existing file in this repo uses either pattern.
   Fix: name it for the behavior — `formatInclusivePeriod` — and delete the changelog comment.
   (AI tells)

7. **[P2][conf 88] Two added exports with no caller** — src/services/summary-manager.ts:37
   Failure: `toCsvRow` (line 37) and `replace` (line 13) are dead on arrival — a reader has to work out what they were for, and both will be maintained against a contract nothing exercises.
   Fix: delete both. Searched `toCsvRow` and `replace(` across `src/`: only the definitions came back. Grepped `Reflect`, `require(`, `import(` across `src/`: no matches, so no dynamic access, and the repo has no package.json or barrel file making these a published surface.
   (dead weight)

8. **[P2][conf 85] `Manager` suffix diverges from this repo's service naming** — src/services/summary-manager.ts:4
   Baseline: `InvoiceService` (src/services/invoice-service.ts:3) and `ExportService` (src/services/export-service.ts:3) — the two existing classes in `src/services/`, both TypeScript, both `<Noun>Service`.
   Fix: `SummaryService` in `src/services/summary-service.ts`, matching the file naming of its two neighbors.
   (naming)

Checked: reuse, tests, comments, AI tells, naming, drift, length, over-engineering, error handling, surface area, type slop, deterministic.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md, or lint config in the repo), stale docs (skipped: repo has no README, changelog, ADRs, or doc comments for the change to contradict).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
