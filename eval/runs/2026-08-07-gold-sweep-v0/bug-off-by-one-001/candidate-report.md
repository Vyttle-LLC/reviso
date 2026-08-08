## Reviso review — HEAD (detached) vs 209bb01 (0 commits, 1 file)

Found 1 issue:

1. **[P0][conf 100] Pagination loop is off by one — returns `pageSize + 1` items and overlaps adjacent pages** — src/utils/pagination.ts:29
   Failure: `for (var i = startIndex; i <= startIndex + pageSize; i++)` iterates `pageSize + 1` times. `paginate(['a','b','c','d','e'], 1, 2)` returns `items: ['a','b','c']` — three items for a page size of two. Page 2 (`startIndex = 2`) returns `['c','d','e']`, so `'c'` is duplicated across pages. Any consumer paging through the full set sees every boundary item twice, and `items.length` never matches the advertised `pageSize`. The `i < totalItems` guard only masks this on the final page, which is why a naive last-page test would pass.
   Fix: use the bounded slice, which also drops the hand-rolled loop and the redundant length guard:
   ```ts
   const items = data.slice(startIndex, startIndex + pageSize);
   ```
   (bugs; also resolves the slop candidate — a manual index loop reimplementing `Array.prototype.slice`)

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing. Notes: the deterministic detector suite was not run (permission for `detectors/run.sh` declined), so this pass is model-only. No `CLAUDE.md`/`AGENTS.md` or lint config exists in this repo, so the conventions lens had nothing to enforce; `var` usage is left unflagged as linter territory.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
