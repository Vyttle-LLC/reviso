## Reviso style — HEAD (detached) vs `5acf77a` (0 commits, 1 file)

Found 1 style issue:

1. **[P1][conf 92]** Catch swallows and logs where every sibling wraps in `StorageError` — `src/storage/upload-blob.ts:5`
   Baseline: both existing catch sites in this module surface the error with a keyed message and the original cause — `src/storage/read-blob.ts:7-8` (`catch (cause) { throw new StorageError(\`failed to read blob ${key}\`, { cause }); }`) and `src/storage/delete-blob.ts:6-7` (`catch (cause) { throw new StorageError(\`failed to delete blob ${key}\`, { cause }); }`). The repo never demonstrates the log-and-return-null shape; `StorageError` exists at `src/storage/errors.ts:1` and this file is the only one in `src/storage/` that does not import it. The message `"upload failed"` is also generic where the repo's two are specific (both interpolate `key`), and the catch binds `err` where the repo binds `cause`.
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
   (error handling; anchors also at `upload-blob.ts:6` generic message, `upload-blob.ts:5` catch-binding name)

   Related anchor, same root cause: the `| null` in the return type at `upload-blob.ts:1` exists only to carry the swallowed failure — the siblings' signatures (`Promise<Uint8Array>`, `Promise<void>`) use no nullable failure channel. Once the catch throws, the remaining `null` is `etag`'s genuine absence, not an error signal, so the type can stay `string | null` but now means one thing instead of two.

Checked: shape (drift, length, over-engineering, error handling, surface area), text (comments, AI tells, naming, stale docs — see below), reuse (slop, duplication, dead weight, derived state), deterministic.
Not checked: conventions (skipped: no CLAUDE.md / AGENTS.md / lint config in the repo); stale docs (skipped: no README, changelog, or ADRs in the repo); test slop (skipped: no test files exist).
Skipped: nothing.

Style only — for bugs, run `/reviso:review` (inner loop) or `/reviso:audit` (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
