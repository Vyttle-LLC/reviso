---
description: Single-pass style-only review of base..HEAD + uncommitted changes — slop, drift, duplication, comments, dead weight, over-engineering, test slop, AI tells; report-only
argument-hint: "[--base <ref>] [--out <path>] [--explain]"
model: opus
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git blame:*), Bash(rg:*)
---

Review the current branch's changes for style only, in a single pass — you
do the entire review yourself, no subagents. This is the dedicated style
lane: AI slop, drift from this repo's own norms, bloated comments,
oversized methods, duplication, over-engineering, dead weight, test slop,
and AI tells. It hunts no bugs — that is what
`/reviso:review` (inner loop) and `/reviso:audit` (pre-PR deep pass) are
for, and your report says so.

**You are report-only: never create, edit, or delete any file in the
user's repository.** Every tool pre-approved above is read-only; anything
that could write is deliberately not pre-approved, so the user is prompted
before it runs. The only write this command may ever request is the report
file when the user explicitly passed `--out`.

The cardinal rule of every lens here: **style is relative to this
codebase's own norms, never to your taste or to absolute thresholds.** A
deliberate, established style in this repo is never a finding. When the
repo itself is verbose, verbose new code matches its norms. The rule has
exactly two named exceptions, defined in their lens entries: the comments
lens's earn-its-place bar (only a written convention overrides it) and
placeholder text in the AI-tells lens (nothing overrides it). Everything
else yields to the repo.

Arguments: `$ARGUMENTS` may contain `--base <ref>` (diff base; default is
the repository's default branch), `--out <path>` (also write the report
to that file; terminal-only otherwise), and `--explain` (append the
pipeline diagnostics described in Step 5; off by default). Ignore unknown
flags with a one-line note.

Make a todo list first, then work through these steps.

## The coverage ledger (maintained throughout, reported in Step 5)

Every lens gets exactly one ledger row, recorded as that lens resolves —
not reconstructed at report time. A row is: lens name, outcome, candidate
count. There are exactly three outcomes:

- **returned** — you applied the lens across the non-skipped hunks and
  reached a conclusion. Finding nothing is a conclusion: record it as
  `returned` with a count of zero.
- **no result** — you did not actually get through the lens: you ran out
  of room, the pass was cut short, or you cannot honestly say you applied
  it to the change.
- **skipped** — the lens had nothing in scope. Note the reason.

A lens you recorded no row for is `no result`. Never assume a lens you
didn't get to was clean: "found nothing" and "never looked" are different
facts, and a report that cannot tell them apart is worthless as a gate.
Step 5 reports from these rows and may not name a lens it has no row for.

## Step 1 — Assemble the mock PR (deterministic)

Run this exact sequence of read-only git commands. Given identical git state
and flags it must produce identical context — no judgment calls, no sampling.

1. Resolve the base:
   - If `--base <ref>` was given, use it.
   - Else `git rev-parse --abbrev-ref origin/HEAD` → use that branch;
     if unset, use `main` if it exists (`git rev-parse --verify main`), else `master`.
   - Compute the merge base: `git merge-base <base> HEAD` → `MB`.
2. Collect the change:
   - Committed: `git diff MB..HEAD`
   - Uncommitted: `git diff HEAD` plus untracked files from
     `git ls-files --others --exclude-standard` (treat their full content as added lines)
   - Changed-file list: union of `git diff --name-status MB..HEAD` and
     `git diff --name-status HEAD` and the untracked list.
   - If the combined change is empty: report "Nothing to review on
     `<branch>` vs `<base>`" and stop.
3. Collect intent: `git log --format='%h %s%n%b' MB..HEAD` (all commit
   messages on the branch — stated intent counts when judging findings:
   "port kept verbatim from X" clears a drift flag).
4. Collect conventions: root `CLAUDE.md` / `AGENTS.md`, any in directories
   containing changed files, and lint configs governing changed paths.
   Read the conventions files — they are part of the review.
5. Infer the ticket: match the branch name and commit trailers against
   `[A-Z][A-Z0-9]+-[0-9]+`. Record it if found; absence is not an error.

## Step 2 — Deterministic detectors (free)

Run the detector suite against the assembled diff:

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/reviso/detectors/run.sh <base-ref>
```

(Read-only; not pre-approved above, so the user may be prompted once —
expected.) Detector findings are tagged `deterministic`, skip Step 4
scoring, and report at confidence 100.

Record the `deterministic` ledger row now: `returned` with the finding
count if the suite ran, `no result` if the permission prompt was declined
or the script failed. A declined prompt is not a clean detector pass, and
the report must not claim it was.

## Step 3 — Review the change yourself (style lenses only)

Work through the diff file by file, reading full files and history on
demand. Skip content review cannot help (lockfiles, generated files,
pure-formatting hunks) and note it for the coverage line. Apply every lens
to each hunk as you go.

**No bug hunting.** If you notice a likely bug, do not record it, score
it, or mention it as a finding — this command's contract is style only.
The report's closing scope note points the user at the sibling verbs; that
is the only trace a noticed bug leaves.

- **Slop** (convention-relative, the P0 set minus what the dedicated
  lenses below carry): ~3× the lines the job needs, measured against how
  this codebase writes similar code — `suggested_fix` sketches the
  tighter version; reimplementing a utility that exists (cite the
  existing utility's `file:line`, or it's not a finding — and before you
  clear an added block as original, grep the repo for that block's most
  distinctive identifiers and string literals, not whole lines, which a
  rename dodges).
- **Comments** — every changed comment, against an absolute bar, not
  this repo's habits: a comment earns its place only when the code
  cannot be made to say the same thing — through naming, extraction, or
  types — and even then it is as short as the point allows. Comments
  that restate the code, narrate control flow, or pad a necessary point
  with generated filler are findings; `suggested_fix` carries the
  tightened rewrite, or deletion when the code speaks for itself. The
  only override is a written convention: a CLAUDE.md / AGENTS.md rule or
  a lint rule governing the changed paths (e.g. require-jsdoc) that
  demands the comment shape in question. Demonstrated verbosity in the
  repo's existing comments clears nothing.
- **Duplication** — the same logic living in more than one place, in
  either direction: new code copying something the repo already has, or
  the change copying itself. The unit is a rule-encoding expression or
  predicate, a declaration or definition, or a verbatim/near-verbatim
  block; count the new occurrences together with any copies already in
  the repo, then apply this bar. **4 or more occurrences** ships — the
  repetition is itself the evidence. **Exactly 3** ships only if the
  duplicated unit encodes a rule that can change (a predicate, a policy
  constant, a shared type or contract — something a future edit has to
  change in every copy at once); three occurrences of incidental
  similarity, like setup boilerplate or assertion scaffolding, stay
  silent. **2 or fewer** never ships, **however long the copied block
  is.** Below the bar, say nothing rather than softening it into a
  smaller finding. Evidence is text you can quote — no
  structural similarity scoring. Cite every occurrence by `file:line`; one
  duplicated thing is one finding, never one per occurrence.
  `failure_scenario` is the drift risk, concrete ("the rule is encoded
  in 6 places; the next change lands in one and the other five silently
  disagree"). `suggested_fix` names the helper — name, signature, and
  the home it belongs in following this repo's existing layout — plus
  the rewrite of one call site; no named helper, no finding. Test code
  counts only when the repo wrote the rule: a duplication whose
  occurrences are all in test code ships only if a written convention
  (CLAUDE.md / AGENTS.md / lint config / skill doc governing the changed
  paths) demands shared test helpers — a demonstrated-but-unwritten
  helper idiom doesn't open the gate. Any production occurrence and the
  ordinary bar applies. The bar itself — 4-or-more / exactly-3 /
  2-or-fewer, the helper-naming requirement, the search protocol — is
  shared with
  `/reviso:review` and the audit's anti-slop finder and must not drift;
  severity and gating are each surface's own (the audit's finder reports
  below-bar candidates for its orchestrator to judge — do not copy that
  here).
- **Conventions** — compliance with the CLAUDE.md / AGENTS.md guidance and
  lint configs you read in Step 1. Code-shaped rules only: skip
  instructions about process, tone, branch shape, or workflow — those are
  `/reviso:review`'s territory.
- **Drift** — the change writes this kind of code differently from how
  the repo demonstrably writes it: naming, error-handling shape, module
  layout, test structure. This is the *demonstrated*-conventions
  counterpart to the written ones above. Before flagging, locate how the
  repo already does it and cite **at least two existing examples** by
  `file:line` in `evidence` — no cited baseline, no finding. One
  divergent precedent elsewhere in the repo is not a norm; two files
  doing it the established way is the minimum bar for calling it
  established.
- **Length** — a changed method/function or comment far outside the size
  of comparable units in this repo. "Comparable" means same kind of thing:
  handlers against handlers, tests against tests, doc comments against
  doc comments. The finding's `evidence` must name the comparable units
  it was measured against and their approximate sizes. **Absolute
  thresholds are banned** — "functions over 50 lines" is linter
  territory and someone else's taste; the only admissible yardstick is
  this repo. `suggested_fix` sketches the split (for a method) or the
  tightened text (for a comment).
- **Over-engineering** — machinery the change builds that nothing needs:
  an abstraction with a single consumer (an interface, factory, or
  config knob serving one caller), defensive handling of states the
  types or call sites make impossible, a backwards-compatibility shim
  with no second consumer. `evidence` cites the absence by `file:line` —
  the only consumer, the type or call sites that make the defended state
  unreachable, the shim's missing second caller. Convention-relative
  like drift: two existing files building this kind of code the same
  defensive way make it the repo's norm, not a finding.
- **Dead weight** — code the change adds that nothing uses, scoped to
  what linters cannot see. Read the lint configs governing the changed
  paths first: anything a configured rule already covers is excluded,
  and unused imports and unused locals are excluded always — linter
  territory. In scope: an added helper or export with no caller anywhere
  in the repo, a parameter accepted but never read, a flag or config key
  never consumed, a branch the surrounding code makes impossible. The
  search protocol is mandatory: grep the repo for the symbol's most
  distinctive identifiers, and check for dynamic access (reflection,
  string-keyed dispatch, DI registration) near the definition before
  trusting an empty result. `evidence` states what you searched and that
  it came back empty — no recorded search, no finding.
- **Test slop** — tests that cannot fail: tautological assertions,
  asserting the value a mock was just configured to return, mocking the
  subject under test; also sleep-based waits where the repo demonstrates
  a deterministic waiting idiom (cite it). Quote the assertion (or the
  wait) in `evidence` and state concretely why it cannot fail or what it
  actually exercises instead of the subject. `suggested_fix` sketches
  the test as it should be written, or its deletion.
- **AI tells** — text artifacts of machine generation, quoted verbatim
  in `evidence`: temporal or comparative naming (`newHelper`,
  `enhancedFoo`, `utils2`), changelog-style comments ("// Fixed bug
  where…"), emoji or tonal flourishes foreign to this repo's text.
  Convention-relative with one absolute item: placeholder text ("in a
  real implementation…", "in production you would…") is always a finding
  — no repo's norm is unimplemented code presented as implemented. For
  everything else, two existing examples of the pattern in the repo make
  it the repo's own idiom, not a tell.

Record each candidate per the shared finding schema
(`${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/finding-schema.md`).
The schema's `dimension` enum predates this command: record `conventions`
candidates as `conventions`, and every other lens's candidates — slop,
comments, duplication, drift, length, over-engineering, dead weight, test
slop, AI tells — as `slop`; the ledger and the report carry the precise
lens name.

Record a ledger row per lens as you finish it — ten rows here, plus the
`deterministic` row from Step 2. Write the row when you finish the lens,
not at the end from memory: a row reconstructed at report time is a guess
about what you did, which is exactly what the ledger replaces.

## Step 4 — Self-verify (the trust gate)

Read `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/false-positives.md` and
`${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/confidence-rubric.md` once.
For every candidate from Step 3:

1. Exclusion list first — a match scores 0–25, with one carve-out: the
   deliberate-style entry ("a codebase's deliberate, established style is
   never slop") does not apply to comments-lens candidates or to
   placeholder text. Those two bars are absolute here; for a comments
   candidate, only the lens's written-convention override clears it — and
   a candidate whose comment shape a written convention actually demands
   scores 0.
2. On lines the change modified? Pre-existing → 0.
3. Baseline check, this command's own gate: a drift or over-engineering
   candidate without its cited `file:line` evidence (two examples of the
   established pattern; the absence citation), or a length candidate that
   doesn't name its comparable units, scores 0 — the citation *is* the
   evidence, and without it the finding is taste. A dead-weight candidate
   whose evidence doesn't state the search performed and its empty result
   also scores 0.
4. Re-examine the actual code: does the failure scenario hold against the
   real baseline, and is the repo's own style genuinely on your side?
5. Score 0–100 using the rubric exactly as written — no stricter, no
   looser. **Silently drop everything below 80.** Never mention a dropped
   candidate in the report itself — the one place it may appear is the
   `--explain` section, and only when the user passed that flag.

Keep, for every candidate: its lens, its `file:line`, its score, and its
disposition — reported, or dropped and why. The reason is whichever step
above gated it: `exclusion-list` (step 1), `pre-existing` (step 2),
`no-baseline` or `no-search` (step 3), or `rubric-score` (survived all
three, still under 80). That record is what `--explain` prints; without
the flag it stays yours.

## Step 5 — Report

Dedupe candidates sharing a root cause (one finding, strongest evidence,
highest severity; list additional anchors inside that one finding).
Consolidate related minor findings. Order most-severe-first, ties by
confidence.

Severity, this command's band: style findings are **P2** by default, and
**P1** only when the finding actively misleads: a wrong comment, a
shadowed utility with different behavior, duplicated copies that have
already diverged in behavior, or a test that appears to cover behavior
but cannot fail. The style lenses never emit P0 — nothing
purely stylistic blocks a merge. Deterministic detector findings keep
their own severities.

Reporting policy — this command's own, since the shared schema carries
format only: no finding ranking below P2 ships (there is no P3; a nit
below the bar is dropped, not reported). At most 8 findings ship, most
severe first — if more survived the gate, the ninth wasn't worth
reporting.

Format:

```text
## Reviso style — <branch> vs <base> (<n> commits, <m> files)

Found <k> style issues:

1. [P2][conf 90] <one-line title> — path/to/file.ts:42
   Baseline: <the repo norm it was measured against, with file:line>
   Fix: <suggested fix or rewrite>
   (<lens>; deterministic findings say so here)

...

Checked: <lenses whose ledger row says returned>.
Not checked: <each no-result or skipped lens, with its reason>.
Skipped: <skipped files, or "nothing">.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

The `Baseline:` line replaces the review command's `Failure:` line for
drift and length findings; every other lens and deterministic findings
keep `Failure:` (the concrete cost to the next reader/maintainer). Every
finding cites `file:line`.

The coverage block is derived from the ledger, every run:

- `Checked:` names the lenses with a `returned` row and only those. There
  is no fixed list to fall back on — if you have no row for a lens, you
  may not name it as checked.
- `Not checked:` names each `no result` or `skipped` lens with its reason
  — "drift (no result)", "length (no result)". **Emit the line only
  when there is at least one such lens.** A run where every lens returned
  prints no `Not checked:` line at all.
- No per-lens candidate counts here. Counts are `--explain`'s job; a count
  in the default report tells the user findings were withheld.
- `Skipped:` is unchanged and unrelated: it lists the *files* content
  review couldn't help with, never lenses. Do not merge the two lines.
- The scope line ("Style only — …") closes every report, findings or not.

If no findings survived: the header line, then "No style issues found.",
then the coverage block — nothing else. That block is the only thing
separating a clean run from a broken one, so derive it here exactly as
above. A zero-finding report that cannot explain its zero is the failure
this command is instrumented to prevent.

### `--explain` (only when the user passed the flag)

Append one section after the findings, in this shape:

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: slop 2, comments 1, duplication 0, conventions 1, drift 1,
length 0, over-engineering 0, dead-weight 0, test-slop 0, ai-tells 0,
deterministic 0.
Candidates before the gate (4):
  [drift]       cli_server.rs:2257  score 88  reported
  [length]      shell_env.rs:453    score  0  dropped: no-baseline
  [slop]        shell_env.rs:50     score 72  dropped: rubric-score
```

The ledger with counts, then every candidate you kept a record of in Step
4 — one line each, with its score and disposition. Rules: it goes after
the findings, never among them; every line in it is a diagnostic, never a
finding; and the findings section above it is identical whether or not the
flag was passed. Without `--explain`, none of this appears — no dropped
candidate, no score, no reason.

Sink: print to the terminal. If `--out <path>` was given, additionally write
the same report to that path (this triggers a permission prompt — correct
behavior; approval applies only to that file). Never write anywhere else.
The `--explain` section follows the report to the same sink and adds no
write of its own.

Keep the report brief. No emojis.

## Step 6 — False-positive feedback (only if the user asks)

If the report had findings, close with exactly one line: "Wrong about
something? Say which finding — I can file feedback (metadata-only by
default)." Nothing below runs unless the user then names a finding. Never
run the feedback script unprompted, never batch findings the user didn't
name, and read the contract it implements if in doubt:
`${CLAUDE_PLUGIN_ROOT}/docs/feedback.md`.

When the user names a finding:

1. Pick the reason from what they said (ask if unclear):
   `codebase-convention`, `upstream-guarantee`, `deliberate-choice`,
   `linter-territory`, `wrong-on-facts`, or `other`.
2. **Tier 1 (default).** Bucket the confidence (80–89 → `80s`, 90–99 →
   `90s`, 100 → `100`), map the lens to its schema dimension (slop,
   comments, duplication, drift, length, over-engineering, dead weight,
   test slop, AI tells → `slop`; conventions → `conventions`;
   deterministic → `deterministic`), and run:

   ```sh
   sh ${CLAUDE_PLUGIN_ROOT}/skills/reviso/feedback/build-payload.sh meta \
     --lens <dimension> --severity <P1|P2> --confidence <bucket> \
     --reason <reason> --command style --model <your model id>
   ```

   (For a deterministic finding add `--detector <id>` and use
   `--confidence 100`.) Show its output verbatim — that is the entire
   payload. Only on the user's explicit go-ahead, re-run the identical
   command with `--send` appended: the build is deterministic, so what was
   shown is what is sent, and the `gh` call inside it is not pre-approved —
   the permission prompt is the last gate.
3. **Tier 2 (only if the user offers code context).** Pipe the finding
   block exactly as reported into
   `... build-payload.sh tier2 --command style` and relay the URL it
   prints. It opens the false-positive form prefilled with the finding;
   the user adds the code and the why in the browser and submits it
   themselves. Never post tier-2 content with `gh`.
4. If the script exits 3, `gh` is missing or unauthenticated — relay the
   manual form URL it printed. If it vetoes (exit 2), tell the user to file
   via the form instead; do not retry around a veto.
