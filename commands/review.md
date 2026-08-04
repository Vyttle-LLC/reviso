---
description: Review base..HEAD + uncommitted changes locally, pre-PR — report-only
argument-hint: "[--base <ref>] [--out <path>]"
allowed-tools: Read, Grep, Glob, Task, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(git ls-files:*), Bash(git blame:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*), Bash(rg:*)
---

Review the current branch's changes as if they were a pull request, and report
findings. **You are report-only: never create, edit, or delete any file in the
user's repository.** Every tool pre-approved above is read-only; anything that
could write is deliberately not pre-approved, so the user is prompted before it
runs. The only write this command may ever request is the report file when the
user explicitly passed `--out`.

Arguments: `$ARGUMENTS` may contain `--base <ref>` (diff base; default is the
repository's default branch) and `--out <path>` (also write the report to that
file; terminal-only otherwise). Ignore unknown flags with a one-line note.

Follow these steps precisely. Make a todo list first.

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
   - If the combined change is empty: report "Nothing to review on
     `<branch>` vs `<base>`" and stop.
3. Collect intent: `git log --format='%h %s%n%b' MB..HEAD` (all commit
   messages on the branch, subjects and bodies).
4. Collect full file context: Read the current content of every changed file
   (post-change state). For deleted files, note the deletion; don't read.
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
(if any), the conventions file paths, and the changed-file list. The finders:

1. `reviso-finder-conventions` — CLAUDE.md / AGENTS.md compliance
2. `reviso-finder-bugs` — shallow scan of the changes for real bugs
3. `reviso-finder-history` — bugs in light of git blame / history
4. `reviso-finder-prior-reviews` — recurring feedback from prior PRs (if a
   GitHub remote exists; otherwise it degrades to commit-message history)
5. `reviso-finder-comments` — compliance with guidance in code comments
6. `reviso-finder-slop` — the anti-slop lens (P0 slop set, convention-relative)

Each returns structured candidates per the shared finding schema
(`${CLAUDE_PLUGIN_ROOT}/skills/reviso/references/finding-schema.md`); every
candidate must carry a concrete failure scenario and a suggested fix.

## Stage 4 — Verify (the trust gate)

For every LLM candidate (not deterministic findings), launch a parallel
`reviso-verifier` agent (Haiku). It re-examines the code, applies the 0–100
confidence rubric and the false-positive exclusion list, and returns a score.
**Silently drop every finding scoring below 80.** Never mention dropped
findings. If nothing survives and Stage 1 found nothing, skip to the report.

## Stage 5 — Reconcile

Dedupe: findings sharing an underlying root cause merge into one, keeping the
strongest evidence and the highest severity. Consolidate: related minor
findings in the same area become one comment, not several. Prefer silence
over a maybe — an uncertain finding does not ship.

## Stage 6 — Report

Order findings most-severe-first (P0 > P1 > P2; ties by confidence). Format:

```text
## Reviso review — <branch> vs <base> (<n> commits, <m> files)

Found <k> issues:

1. [P0][conf 95] <one-line title> — path/to/file.ts:42
   Failure: <concrete scenario: inputs/state → wrong outcome>
   Fix: <suggested fix or rewrite>
   (<dimension>; deterministic findings say so here)

...

Checked: conventions, bugs, history, prior reviews, comments, slop, deterministic.
Skipped: <skip-tier files, or "nothing">.
```

If no findings survived: report exactly the header line, then "No issues
found.", then the Checked/Skipped lines — nothing else.

Sink: print to the terminal. If `--out <path>` was given, additionally write
the same report to that path (this triggers a permission prompt — correct
behavior; approve applies only to that file). Never write anywhere else.

Keep the report brief. No emojis. Cite `file:line` for every finding.
