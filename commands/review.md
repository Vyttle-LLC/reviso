---
description: Fast single-pass review of base..HEAD + uncommitted changes — the inner-loop review; report-only
argument-hint: "[--base <ref>] [--out <path>] [--explain]"
model: opus
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git blame:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*), Bash(rg:*)
---

Review the current branch's changes as if they were a pull request, in a
single pass — you do the entire review yourself, no subagents. This is the
everyday inner-loop review: same architecture and comparable cost to Claude
Code's `/review`, run it as often as you commit. The deep multi-agent pass
is `/reviso:audit` — point users there before they open a PR.

**You are report-only: never create, edit, or delete any file in the user's
repository.** Every tool pre-approved above is read-only; anything that
could write is deliberately not pre-approved, so the user is prompted before
it runs. The only write this command may ever request is the report file
when the user explicitly passed `--out`.

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
   messages on the branch — stated intent counts when judging findings).
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

## Step 3 — Review the change yourself

Work through the diff file by file, reading full files and history on
demand. Skip content review cannot help (lockfiles, generated files,
pure-formatting hunks) and note it for the coverage line. Apply every lens
to each hunk as you go:

- **Bugs** — a shallow scan of the changes themselves for real bugs. Focus
  on large bugs; skip nitpicks. Give extra attention to risky territory
  (auth, money, concurrency, external input, public API, migrations,
  deleted tests) and to **enforcement that doesn't match its claim**: when
  code, a comment, or a prompt claims a guarantee ("validates X", "at most
  once", "fails loudly", "read-only"), check it's actually enforced.
- **Conventions** — compliance with the CLAUDE.md / AGENTS.md guidance you
  read in Step 1 (skip instructions about process or tone that don't
  describe code). Also: branch shape against stated workflow rules
  (one-concern-per-PR, sign-off), and **doc staleness** — renames the diff
  makes without updating docs and entry points that still say the old thing.
- **History** — where a change looks suspicious, check `git blame` /
  `git log`: does it silently revert a deliberate fix or break an invariant
  an older commit established? Branch commit messages state intent — an
  intended regression is not a finding. Only the change's own past counts:
  a commit that is not an ancestor of HEAD, or a PR merged after it, is
  inadmissible evidence — see
  `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/history-bound.md`.
- **Code comments** — invariant notes and warnings near the changed lines
  ("must hold the lock", "keep in sync with X"): does the change comply?
- **Anti-slop** (convention-relative, the P0 set only): drift from how this
  codebase already solves the problem; ~3× the lines the job needs;
  reimplementing a utility that exists (cite it, or it's not a finding —
  and before you clear an added block as original, grep the repo for that
  block's most distinctive identifiers and string literals, not whole
  lines, which a rename dodges); comments that restate code or read as AI
  bloat — include the tightened rewrite in `suggested_fix`. A deliberate,
  established style here is never slop.
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
    the rewrite of one call site; no named helper, no finding. P2, or P1
    only when the copies have already diverged. Test code counts.

Record each candidate per the shared finding schema
(`${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/finding-schema.md`).

Record a ledger row per lens as you finish it — five rows here, plus the
`deterministic` row from Step 2. Write the row when you finish the lens,
not at the end from memory: a row reconstructed at report time is a guess
about what you did, which is exactly what the ledger replaces.

## Step 4 — Self-verify (the trust gate)

Read `${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/false-positives.md` and
`${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/confidence-rubric.md` once.
For every candidate from Step 3:

1. Exclusion list first — a match scores 0–25.
2. On lines the change modified? Pre-existing → 0.
3. Re-examine the actual code: does the failure scenario hold against the
   real guards, callers, and tests?
4. Score 0–100 using the rubric exactly as written — no stricter, no
   looser. **Silently drop everything below 80.** Never mention a dropped
   candidate in the report itself — the one place it may appear is the
   `--explain` section, and only when the user passed that flag.

Keep, for every candidate: its lens, its `file:line`, its score, and its
disposition — reported, or dropped and why. The reason is whichever step
above gated it: `exclusion-list` (step 1), `pre-existing` (step 2), or
`rubric-score` (survived both, still under 80). That record is what
`--explain` prints; without the flag it stays yours.

## Step 5 — Report

Dedupe candidates sharing a root cause (one finding, strongest evidence,
highest severity; list additional anchors inside that one finding).
Consolidate related minor findings. Order most-severe-first
(P0 > P1 > P2; ties by confidence). Format:

```text
## Reviso review — <branch> vs <base> (<n> commits, <m> files)

Found <k> issues:

1. [P0][conf 95] <one-line title> — path/to/file.ts:42
   Failure: <concrete scenario>
   Fix: <suggested fix or rewrite>
   (<lens>; deterministic findings say so here)

...

Checked: <lenses whose ledger row says returned>.
Not checked: <each no-result or skipped lens, with its reason>.
Skipped: <skipped files, or "nothing">.
```

The coverage block is derived from the ledger, every run:

- `Checked:` names the lenses with a `returned` row and only those. There
  is no fixed list to fall back on — if you have no row for a lens, you
  may not name it as checked.
- `Not checked:` names each `no result` or `skipped` lens with its reason
  — "history (no result)", "comments (no result)". **Emit the line only
  when there is at least one such lens.** A run where every lens returned
  prints no `Not checked:` line at all.
- No per-lens candidate counts here. Counts are `--explain`'s job; a count
  in the default report tells the user findings were withheld.
- `Skipped:` is unchanged and unrelated: it lists the *files* content
  review couldn't help with, never lenses. Do not merge the two lines.

If no findings survived: the header line, then "No issues found.", then the
coverage block — nothing else. That block is the only thing separating a
clean run from a broken one, so derive it here exactly as above. A
zero-finding report that cannot explain its zero is the failure this
command is instrumented to prevent.

### `--explain` (only when the user passed the flag)

Append one section after the findings, in this shape:

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: bugs 2, conventions 3, history 0, comments 0, slop 1,
deterministic 0.
Candidates before the gate (6):
  [slop]        cli_server.rs:2257  score 88  reported
  [conventions] shell_env.rs:453    score 72  dropped: rubric-score
  [bugs]        shell_env.rs:50     score  0  dropped: pre-existing
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

Keep the report brief. No emojis. Cite `file:line` for every finding.

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
   `90s`, 100 → `100`) and run:

   ```sh
   sh ${CLAUDE_PLUGIN_ROOT}/skills/reviso/feedback/build-payload.sh meta \
     --lens <lens> --severity <P0|P1|P2> --confidence <bucket> \
     --reason <reason> --command review --model <your model id>
   ```

   (For a deterministic finding add `--detector <id>` and use
   `--confidence 100`.) Show its output verbatim — that is the entire
   payload. Only on the user's explicit go-ahead, re-run the identical
   command with `--send` appended: the build is deterministic, so what was
   shown is what is sent, and the `gh` call inside it is not pre-approved —
   the permission prompt is the last gate.
3. **Tier 2 (only if the user offers code context).** Pipe the finding
   block exactly as reported into
   `... build-payload.sh tier2 --command review` and relay the URL it
   prints. It opens the false-positive form prefilled with the finding;
   the user adds the code and the why in the browser and submits it
   themselves. Never post tier-2 content with `gh`.
4. If the script exits 3, `gh` is missing or unauthenticated — relay the
   manual form URL it printed. If it vetoes (exit 2), tell the user to file
   via the form instead; do not retry around a veto.
