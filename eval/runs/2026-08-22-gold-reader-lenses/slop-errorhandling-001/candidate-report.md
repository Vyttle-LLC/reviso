## Reviso style — HEAD vs 4b135b5 (0 commits, 1 file)

Found 1 style issue:

1. **[P1][conf 95] `uploadBlob` swallows the error and logs where the repo wraps and throws** — `src/storage/upload-blob.ts:5`
   Baseline: both sibling operations in this module wrap the caught error in `StorageError` with a key-bearing message and forward `cause` — `src/storage/read-blob.ts:7-9` (`throw new StorageError(\`failed to read blob ${key}\`, { cause })`) and `src/storage/delete-blob.ts:6-8` (`throw new StorageError(\`failed to delete blob ${key}\`, { cause })`). The new function instead does `console.warn("upload failed"); return null` — a different error shape (log-and-continue vs surface), a generic message that drops the key, and a discarded `cause`. `src/storage/errors.ts:1-6` exists solely to carry that shape.
   Fix:
   ```ts
   import { StorageError } from "./errors";

   export async function uploadBlob(key: string, body: Uint8Array): Promise<string | null> {
     try {
       const res = await fetch(`/blobs/${key}`, { method: "PUT", body });
       return res.headers.get("etag");
     } catch (cause) {
       throw new StorageError(`failed to upload blob ${key}`, { cause });
     }
   }
   ```
   The `| null` in the return type stays — `Headers.get` returns `string | null` independently of the catch.
   (error handling)

Checked: slop, duplication, drift, length, over-engineering, dead weight, AI tells, derived state, naming, error handling, deterministic.
Not checked: comments (skipped — the change adds no comments), conventions (skipped — no CLAUDE.md, AGENTS.md, or lint config in the repo), test slop (skipped — no tests in the change or the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: slop 0, comments skipped, duplication 0, conventions skipped,
drift 0, length 0, over-engineering 0, dead-weight 0, test-slop skipped,
ai-tells 0, derived-state 0, naming 1, error-handling 1, deterministic 0.
Candidates before the gate (2):
  [error-handling]  upload-blob.ts:5  score 95  reported
  [naming]          upload-blob.ts:5  score 20  dropped: exclusion-list
```

Notes on the near-misses, since you asked for diagnostics:

- **naming** — the catch binding is `err` where both siblings use `cause` (`read-blob.ts:7`, `delete-blob.ts:6`). Two same-language examples, so the baseline gate passes, but standalone it's a pedantic nit and the name is only `cause` there because it's forwarded as `{ cause }`. It disappears as a side effect of finding 1's fix, so it ships inside that finding rather than beside it.
- **duplication** — the `try { fetch } catch { throw new StorageError(...) }` unit currently has 2 occurrences (`read-blob.ts`, `delete-blob.ts`). The suggested fix makes it 3, which would put it at the exactly-3 bar for a rule that can change. Worth knowing, not worth flagging on a diff that doesn't yet create the third copy.
- **dead weight** — grepped `uploadBlob|readBlob|deleteBlob` across all `.ts`/`.js`/`.tsx`/`.json`; only the three definitions came back, no call sites. The new export has no caller, but neither do the two pre-existing ones, so this is the repo being a library slice with no in-tree consumers, not something the change introduced.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
