---
description: Deep multi-agent review of base..HEAD + uncommitted changes — the pre-PR gate; report-only
argument-hint: "[--base <ref>] [--out <path>] [--explain]"
model: sonnet
allowed-tools: Read, Grep, Glob, Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git blame:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*), Bash(rg:*)
---

Audit the current branch's changes as if they were a pull request, using the
full multi-agent pipeline: blind dimension finders in parallel, then a
per-finding verification gate. This is the deep pass — run it before opening
a PR, after `/reviso:review` has handled the inner-loop iterations. Expect
several minutes and meaningfully more usage than `/reviso:review`.

**You are report-only: never create, edit, or delete any file in the user's
repository.** Every tool pre-approved above is read-only; anything that
could write is deliberately not pre-approved, so the user is prompted before
it runs. The only write this command may ever request is the report file
when the user explicitly passed `--out`.

Arguments: `$ARGUMENTS` may contain `--base <ref>` (diff base; default is
the repository's default branch), `--out <path>` (also write the report
to that file; terminal-only otherwise), and `--explain` (append the
pipeline diagnostics described in Stage 6; off by default). Ignore unknown
flags with a one-line note.

Follow these steps precisely. Make a todo list first.

## The coverage ledger (maintained throughout, reported in Stage 6)

Every lens this run touches gets exactly one ledger row, recorded the
moment that lens resolves — not reconstructed at report time. A row is:
lens name, outcome, candidate count. There are exactly three outcomes:

- **returned** — the lens ran and handed you a findings array. An empty
  array is `returned`: the lens looked and found nothing, which is a
  result. Record the count, zero included.
- **no result** — the lens handed you nothing usable: the agent never
  returned, it errored, or its output was not a findings array.
- **skipped** — the lens had nothing in scope (prior reviews in a repo
  with no GitHub remote, say). Note the reason.

A lens you recorded no row for is `no result`. Never assume a silent lens
was clean: "found nothing" and "produced nothing" are different facts, and
a report that cannot tell them apart is the failure this ledger exists to
prevent. Stage 6 reports from these rows and may not name a lens it has no
row for.

## Stage 0 — Assemble the mock PR (deterministic; run these yourself, no agents)

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
   - If the combined change is empty: report "Nothing to audit on
     `<branch>` vs `<base>`" and stop.
3. Collect intent: `git log --format='%h %s%n%b' MB..HEAD` (all commit
   messages on the branch, subjects and bodies).
4. Record the changed-file list with per-file status. Do NOT read file
   contents into your own context — finders read the files they need on
   demand. For deleted files, note the deletion.
5. Collect conventions:
   - Root `CLAUDE.md` and `AGENTS.md` if they exist.
   - Any `CLAUDE.md` / `AGENTS.md` in directories containing changed files
     (walk each changed path upward to the repo root).
   - Lint/format configs that govern changed paths (e.g. `.eslintrc*`,
     `.markdownlint*`, `ruff.toml`, `.golangci.yml`) — paths only, read on demand.
6. Infer the ticket: match the branch name and commit trailers against
   `[A-Z][A-Z0-9]+-[0-9]+`. Record it if found; absence is not an error.
7. Record the header facts for the report: branch, base, MB (short), commit
   count, changed-file count.

## Stage 1 — Deterministic detectors (free; before any agent)

Run the detector suite against the assembled diff:

```sh
sh ${CLAUDE_PLUGIN_ROOT}/skills/reviso/detectors/run.sh <base-ref>
```

(This script is read-only — it inspects git output and never writes. It is
not pre-approved above, so the user may be prompted once; that is expected.)
Collect its findings. They use the shared finding schema, are tagged
`deterministic`, bypass Stage 4 verification, and report at confidence 100.

Record the `deterministic` ledger row now: `returned` with the finding
count if the suite ran, `no result` if the permission prompt was declined
or the script failed. A declined prompt is not a clean detector pass, and
the report must not claim it was.

## Stage 2 — Triage

Launch one `reviso-triage` agent (Haiku) with the diff and changed-file list.
It returns, per hunk: risk tags (auth, money, concurrency, external-input,
public-api, migration, deleted-tests) and a skip-tier marking for lockfiles,
generated code, and pure-formatting hunks. Skip-tier hunks are excluded from
Stage 3 and listed in the report's coverage summary.

## Stage 3 — Finders (parallel, blind)

Launch all six finder agents in parallel — a single message with six Task
calls — each blind to the others. Give each: the report header facts, the
non-skipped diff hunks with their risk tags, the commit messages, the ticket
(if any), the conventions file paths, and the changed-file list. Do not
paste file contents or reference-file text into agent prompts — finders
Read files and their shared references on demand; relaying bulk text
through your own context is what blows it up. The finders:

1. `reviso-finder-conventions` — CLAUDE.md / AGENTS.md compliance, branch
   shape, doc staleness
2. `reviso-finder-bugs` — shallow scan of the changes for real bugs,
   including enforcement-vs-claim gaps
3. `reviso-finder-history` — bugs in light of git blame / history
4. `reviso-finder-prior-reviews` — recurring feedback from prior PRs (if a
   GitHub remote exists; otherwise it degrades to commit-message history)
5. `reviso-finder-comments` — compliance with guidance in code comments
6. `reviso-finder-slop` — the anti-slop lens (P0 slop set,
   convention-relative), including duplication above the calibrated bar

Each returns structured candidates per the shared finding schema
(`${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/finding-schema.md`); every
candidate must carry a concrete failure scenario and a suggested fix.

As each finder resolves, record its ledger row before you move on — six
finders, six rows, written here rather than inferred later. A finder that
returns `[]` is `returned` with a count of zero; a finder whose Task never
came back, errored, or returned prose instead of a findings array is `no
result`. If you reach Stage 4 with fewer than six rows, the missing ones
are `no result`, not silence you may read as clean.

## Stage 4 — Verify (the trust gate)

For every LLM candidate (not deterministic findings), launch a parallel
`reviso-verifier` agent (Haiku). Give each: the candidate, the relevant
diff hunks, and the conventions file paths. It re-examines the code,
applies the rubric as written, and returns a score and a `drop_reason`
(`exclusion-list`, `pre-existing`, `rubric-score`, or `none`).
**Silently drop every finding scoring below 80.** Never mention a dropped
finding in the report itself — the one place it may appear is the
`--explain` section, and only when the user passed that flag. If nothing
survives and Stage 1 found nothing, skip to the report.

Keep, for every candidate: its lens, its `file:line`, its score, and its
disposition — reported, or dropped with the reason. That record is what
`--explain` prints; without the flag it stays yours. A verifier return
that omits `drop_reason` counts as `rubric-score` below 80 and `none` at
or above — degrade, don't stall.

## Stage 5 — Reconcile

Dedupe: findings sharing an underlying root cause merge into one, keeping the
strongest evidence and the highest severity. Consolidate: related minor
findings in the same area become one comment, not several. Prefer silence
over a maybe — an uncertain finding does not ship.

## Stage 6 — Report

Order findings most-severe-first (P0 > P1 > P2; ties by confidence). Format:

```text
## Reviso audit — <branch> vs <base> (<n> commits, <m> files)

Found <k> issues:

1. [P0][conf 95] <one-line title> — path/to/file.ts:42
   Failure: <concrete scenario: inputs/state → wrong outcome>
   Fix: <suggested fix or rewrite>
   (<dimension>; deterministic findings say so here)

...

Checked: <lenses whose ledger row says returned>.
Not checked: <each no-result or skipped lens, with its reason>.
Skipped: <skip-tier files, or "nothing">.
```

The coverage block is derived from the ledger, every run:

- `Checked:` names the lenses with a `returned` row and only those. There
  is no fixed list to fall back on — if you have no row for a lens, you
  may not name it as checked.
- `Not checked:` names each `no result` or `skipped` lens with its reason
  — "history (no result)", "prior reviews (no GitHub remote)". **Emit the
  line only when there is at least one such lens.** A run where every lens
  returned prints no `Not checked:` line at all.
- No per-lens candidate counts here. Counts are `--explain`'s job; a count
  in the default report tells the user findings were withheld.
- `Skipped:` is unchanged and unrelated: it lists skip-tier *files* from
  Stage 2, never lenses. Do not merge the two lines.

If no findings survived: report exactly the header line, then "No issues
found.", then the coverage block — nothing else. That block is the only
thing separating a clean run from a broken one, so derive it here exactly
as above. A zero-finding report that cannot explain its zero is the
failure this command is instrumented to prevent.

### `--explain` (only when the user passed the flag)

Append one section after the findings, in this shape:

```text
--- explain: pipeline diagnostics (not review findings) ---
Finders: conventions 3, bugs 2, history 0, prior-reviews no result,
comments 0, slop 1.
Candidates before the gate (6):
  [slop]        cli_server.rs:2257  score 88  reported
  [conventions] shell_env.rs:453    score 72  dropped: rubric-score
  [bugs]        shell_env.rs:50     score  0  dropped: pre-existing
```

The ledger with counts, then every candidate you kept a record of in Stage
4 — one line each, with its score and disposition. Rules: it goes after
the findings, never among them; every line in it is a diagnostic, never a
finding; and the findings section above it is identical whether or not the
flag was passed. Without `--explain`, none of this appears — no dropped
candidate, no score, no reason.

Sink: print to the terminal. If `--out <path>` was given, additionally write
the same report to that path (this triggers a permission prompt — correct
behavior; approve applies only to that file). Never write anywhere else.
The `--explain` section follows the report to the same sink and adds no
write of its own.

Keep the report brief. No emojis. Cite `file:line` for every finding.

## Stage 7 — False-positive feedback (only if the user asks)

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
     --lens <dimension> --severity <P0|P1|P2> --confidence <bucket> \
     --reason <reason> --command audit --model <your model id>
   ```

   (For a deterministic finding add `--detector <id>` and use
   `--confidence 100`.) Show its output verbatim — that is the entire
   payload. Only on the user's explicit go-ahead, re-run the identical
   command with `--send` appended: the build is deterministic, so what was
   shown is what is sent, and the `gh` call inside it is not pre-approved —
   the permission prompt is the last gate.
3. **Tier 2 (only if the user offers code context).** Pipe the finding
   block exactly as reported into
   `... build-payload.sh tier2 --command audit` and relay the URL it
   prints. It opens the false-positive form prefilled with the finding;
   the user adds the code and the why in the browser and submits it
   themselves. Never post tier-2 content with `gh`.
4. If the script exits 3, `gh` is missing or unauthenticated — relay the
   manual form URL it printed. If it vetoes (exit 2), tell the user to file
   via the form instead; do not retry around a veto.
