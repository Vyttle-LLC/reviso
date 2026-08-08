Detectors couldn't run — the `run.sh` invocation needed approval and was declined, so I did the review without it. Here is the result.

```text
## Reviso review — HEAD (detached) vs f3e0908 (0 commits, 1 file)

No issues found.

Checked: bugs, conventions, history, comments, slop.
Skipped: nothing.
```

Notes on what I looked at, since the result is empty:

- The change is a single untracked file, `src/services/profile-summary.ts` (57 lines), treated entirely as added. No commits on the branch, so no stated intent to weigh against.
- No `CLAUDE.md` / `AGENTS.md` and no lint or tsconfig in the repo — the conventions lens and the anti-slop lens both had no repo norms to measure drift against, so neither can produce a finding here by the rules (slop must be relative to the codebase's own norms).
- The nullable field is genuinely guarded: `profile.address !== null` at `src/services/profile-summary.ts:43` covers the declared `Address | null` type before `.city` / `.state` are read at line 44, and `location` has a default at line 42.
- Candidates I looked at and did not report: unencoded `userId` in the URL at line 26, `new Date` on an unvalidated `createdAt` at line 36, unvalidated `response.json()` at line 30, and `var` over `const`. Each is either linter/typechecker territory or too speculative without a caller to verify against — none cleared the confidence gate.

Deterministic detector coverage is the one gap: approve the `run.sh` command if you want that pass too, and I'll re-run just that step.
