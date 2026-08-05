```text
## Reviso review — HEAD (detached) vs cb3f63a4 (19 commits, 57 files)

Found 5 issues:

1. [P1][conf 92] Branch bundles ~6 concerns, violating one-concern-per-PR — CLAUDE.md:18
   Failure: CLAUDE.md's Git section states "One concern per PR." This branch
   lands the OpenSpec plan, the plugin surface (commands + 8 agents + skill),
   the Stage-1 detectors, the parity eval harness, a vendored upstream recipe
   snapshot, the D10 architecture split, and two published eval runs as one
   change. A reviewer cannot approve the detector logic without also approving
   the eval harness and the doc rewrite; the 19-commit stack was clearly built
   to be stacked PRs — CLAUDE.md documents the `--onto` restack workflow for
   exactly that.
   Fix: Split into stacked PRs along the existing commit boundaries (plan →
   plugin → detectors → eval harness → D10 split → published runs) and restack
   with `git rebase --onto` as each parent merges.
   (conventions)

2. [P2][conf 88] `/reviso:review` hard-pins `model: opus`, contradicting its own spec — commands/review.md:4
   Failure: `openspec/changes/add-reviso-review/specs/review-command/spec.md:9`
   requires the single-pass review to run "on the session's model —
   architecturally 1:1 with Claude Code's `/review` for parity and cost
   comparison". Commit 4236adf added `model: opus` and touched only that one
   file. A user on a Sonnet session now runs `/reviso:review` and silently gets
   Opus, so the per-run cost is several times the `/review` it is benchmarked
   against in that same session — the 1.42× cost ratio in docs/evals.md holds
   only because baseline.sh pins `--model opus` too.
   Fix: Either update the spec requirement (and the cost claim's framing) to say
   the review tier is pinned to Opus and why, or drop the frontmatter pin and
   pass the model at eval time via `CANDIDATE_CLAUDE_FLAGS`.
   (conventions, history)

3. [P2][conf 85] Harness docs still call `commands/review.md` the subagent orchestrator — skills/reviso/SKILL.md:9
   Failure: SKILL.md:3 ("Used by /reviso:review and its subagents") and :9 ("The
   orchestrator is `commands/review.md`; the agents are in `agents/`"), plus
   CONTRIBUTING.md:71 ("the orchestrator is `commands/review.md`, the
   finder/verifier subagents live in `agents/`"), all predate the D10 split in
   2dcaed2 and were not updated by it. `/reviso:review` now states "no
   subagents" (commands/review.md:9) and carries no `Task` grant; `agents/` is
   driven solely by `/reviso:audit`, which neither doc mentions. A contributor
   following CONTRIBUTING.md's map edits a finder to change `/reviso:review`
   behaviour and sees nothing happen. The openspec specs were updated correctly
   (task 8.4), so these two are the only stale copies.
   Fix: In both files, name `commands/audit.md` as the multi-agent orchestrator
   that owns `agents/`, and `commands/review.md` as the single-pass tier that
   uses `references/` and `detectors/` inline.
   (conventions)

4. [P2][conf 82] `[ -f ]` guard silently truncates the untracked-file scan — skills/reviso/detectors/run.sh:22
   Failure: Under `set -eu`, `[ -f "$f" ] && { ... }` is the last command in the
   loop body, so when the test fails the whole `while` subshell exits and every
   remaining untracked file is skipped — with exit status 0 and no message
   (verified: `sh -c 'set -eu; printf "a\nb\n" | while read -r f; do [ -f "$f" ]
   && echo x; done; echo AFTER'` never prints AFTER). `git ls-files --others`
   emits paths that fail `-f`: a nested untracked git repo (listed as `dir/`), a
   broken symlink, or any non-ASCII path (quoted by core.quotePath, so the
   literal quotes are part of `$f`). One such entry and the header's promise of
   "merge-base → working tree, plus untracked files" (run.sh:6-8) quietly stops
   holding — a conflict marker in a later untracked file goes unflagged and the
   run still reports success.
   Fix: Make the test non-terminal, e.g.
   `if [ -f "$f" ]; then git diff -U0 --no-index -- /dev/null "$f" || true; fi`.
   (bugs, comments)

5. [P2][conf 82] Parity numbers published while the matcher calibration gate is explicitly unrun — docs/evals.md:11
   Failure: eval/README.md:42-43 and eval/calibration/README.md:4 both state that
   `match.sh` "is not trusted until it agrees with hand labels (task 5.5)", and
   calibration's results table reads "_pending — task 5.5_" (tasks.md 5.5 is
   unchecked). docs/evals.md nonetheless presents 12% and 25% parity as measured
   results, and README.md:92 sends readers there as "Our eval results". Since
   parity is entirely a function of the uncalibrated matcher — and the calibration
   README warns "a lenient matcher inflates parity" — a reader takes a number the
   project's own gate says is untrusted. (The 1.42× cost ✅ is unaffected; cost is
   measured directly.)
   Fix: Add one line under the Runs table — "Parity depends on `match.sh`, not yet
   calibrated (task 5.5); cost is measured directly" — and drop it once 5.5 lands.
   (conventions, bugs)

Checked: bugs, conventions, history, comments, slop, deterministic.
Skipped: eval/reference/code-review-recipe-2026-08-03.md and
code-review-recipe-LICENSE (vendored verbatim, not ours to change);
eval/runs/**/* (machine-captured run artifacts, preserved verbatim).
```

Detectors ran clean (`[]` — no conflict markers, no focused tests). No `--out` was passed, so this is terminal-only; nothing was written.

Before opening this as a PR, `/reviso:audit` is the deeper pass — though finding 1 suggests splitting the branch first, which would make each piece far easier to audit.
