Detectors weren't approved to run, so this is a manual-only pass. Here's the review.

```text
## Reviso review — HEAD vs a8b18a7 (0 commits, 1 file)

Found 1 issue:

1. [P0][conf 95] Unguarded deref of nullable `profile.address` crashes summary — src/services/profile-summary.ts:42
   Failure: `UserProfile.address` is declared `Address | null` (line 13), but line 42 reads
   `profile.address.city` / `profile.address.state` with no null check. For any user whose
   API payload has `"address": null` — the case the type explicitly models — `getProfileSummary`
   throws `TypeError: Cannot read properties of null (reading 'city')` and the whole summary
   fails, rather than degrading to the "Not specified" fallback the very next line provides.
   The `.filter(Boolean)` + `|| "Not specified"` on lines 43/48 show missing location was
   meant to be a handled state; the null-address path just never reaches them.
   Fix:
     const address = profile.address;
     const location = address
       ? [address.city, address.state].filter(Boolean).join(", ")
       : "";
   (leave line 48's `location || "Not specified"` as the single fallback)
   (bugs)

Checked: bugs, conventions, history, comments, slop.
Skipped: deterministic detectors (permission for detectors/run.sh was declined).
```

Notes on scope: the repo has no `CLAUDE.md`/`AGENTS.md`, no tsconfig, and no lint config, so the conventions and history lenses had nothing to check against — `src/services/profile-summary.ts` is the first file in the tree and the base commit is empty. The `var` usage is internally consistent with no rule to cite, and unvalidated `response.json()` is ordinary practice absent a stated convention; neither cleared the bar.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
