## Reviso style — HEAD (detached) vs cfc35b8 (0 commits, 2 files)

Found 3 style issues:

1. **[P1][conf 100] Placeholder text committed — unimplemented behavior presented as implemented** — src/format.ts:19
   Failure: `// In a real implementation, this would use the user's locale settings` tells the next reader that locale-aware formatting is a deliberate stand-in; nothing in the call path ever applies locale settings, and `usageLine` ships the non-localized string as if it were the intended output.
   Fix: implement locale handling or drop the comment and the pretense — the function is `formatBytes` with a sign flip, and should read as that.
   (deterministic)

2. **[P1][conf 95] Generated-text artifacts in the `formatBytesEnhanced` block: comparative name, changelog comment, comment asserting behavior the code lacks** — src/format.ts:14 (also :13, :15)
   Failure: three verbatim tells in eight added lines — the comparative name `export function formatBytesEnhanced` (src/format.ts:14), the changelog comment `// Fixed bug where negative values were not handled` (src/format.ts:15), and `// Enhanced version with better handling of edge cases` (src/format.ts:13), which claims plural edge cases while the body handles exactly one (`n < 0`) and delegates everything else to `formatBytes`. A caller reading the name and banner reasonably expects hardened formatting — NaN, Infinity, sub-byte values all pass straight through unchanged. Nothing in the repo establishes comparative naming or changelog comments as an idiom; the base tree is empty.
   Fix: delete all three comments; move the negative branch into `formatBytes` (`if (n < 0) return \`-${formatBytes(-n)}\`;`) and delete `formatBytesEnhanced`. The one behavior it adds is described by the code.
   (AI tells; comments)

3. **[P2][conf 82] Redundant parallel entry point — a wrapper that delegates entirely, for one caller** — src/format.ts:14
   Failure: `formatBytesEnhanced` adds a second exported way to format bytes whose whole body is a sign flip plus `return formatBytes(n)` (src/format.ts:20). Its only consumer is src/usage.ts:4; grep for `formatBytes` across `src/` returns exactly the definition, its one delegating call, the self-recursion at src/format.ts:17, and that single import — no dynamic access (`require(`/`import(` return nothing in `src/`). Every future caller now has to pick between two exports that differ by one branch, and `formatBytes` stays quietly wrong for negatives.
   Fix: same edit as finding 2 — fold the negative branch into `formatBytes`, delete the wrapper, and change src/usage.ts:1 to `import { formatBytes } from "./format";`. This leaves one export doing the whole job.
   (slop; over-engineering)

Checked: reuse, deterministic, comments, AI tells, length, over-engineering, surface area.
Not checked: drift (skipped: base commit's tree is empty — no pre-existing code to cite as a norm), naming (skipped: same reason; the one comparative name is reported above under AI tells), conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in the repo), error handling (skipped: the change contains no error handling), stale docs (skipped: no prose or doc files in the repo), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
