Detectors clean; I've worked the diff myself across all five lenses. Report:

```text
## Reviso review — HEAD (detached) vs cb3f63a (6 commits, 44 files)

Found 4 issues:

1. [P1][conf 95] Three subagents grant bare `Bash`, which the change's own spec forbids — agents/reviso-verifier.md:4
   Also: agents/reviso-finder-history.md:4, agents/reviso-finder-prior-reviews.md:4
   Failure: openspec/.../review-command/spec.md:27-31 requires "the command and every
   subagent it spawns SHALL be restricted to read-only tools ... MUST NOT include Bash
   patterns that permit writes", and design.md D3 (line 67) calls report-only "enforced
   structurally, not by convention ... a write attempt is then a tool-permission failure."
   Bare `Bash` is the broadest write-permitting grant there is; the read-only restriction
   in these three agents exists only as prose ("use Bash exclusively for read-only git
   commands"). Under `--dangerously-skip-permissions` — how eval/runners/candidate.sh may
   invoke the plugin via CANDIDATE_CLAUDE_FLAGS — nothing stands between a verifier
   subagent and `git checkout`/`sed -i` in the user's tree.
   Fix: scope each grant the way commands/review.md:4 already does in this same change —
   `tools: Read, Grep, Glob, Bash(git blame:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*)`
   for the verifier and history finder; add `Bash(gh pr list:*), Bash(gh pr view:*),
   Bash(gh search:*)` for prior-reviews.
   (conventions)

2. [P1][conf 88] Baseline runner will produce empty baselines on every corpus PR — eval/runners/baseline.sh:16
   Failure: baseline.sh runs `/review <PR>` on corpus entries, and step 1 of the vendored
   recipe it targets (eval/reference/code-review-recipe-2026-08-03.md:11) aborts —
   "do not proceed" — when the PR is closed, is obviously fine, or already carries a review
   from Claude. Corpus entries are historical PRs with SHAs pinned at entry time
   (eval/corpus/README.md:12), i.e. merged and closed. The abort text parses cleanly as
   `[]`, and extract.sh's loud-failure guard only fires on the literal phrase
   `found <N> issue` (eval/runners/extract.sh:27), so the run exits 0 with an empty
   baseline. judge.sh then reports parity `n/a` and zero misses — the exact silent
   reduction eval/README.md:25 and the parity-eval spec's "Parse failure is loud" scenario
   promise cannot happen.
   Fix: assert the baseline actually reviewed. Either drive `/review` against a local
   checkout of base_sha..head_sha instead of a live PR number, or have baseline.sh fail
   when a run's text lacks the recipe's report header (`### Code review`) — an eligibility
   abort is a failed run, not a clean one.
   (bugs)

3. [P1][conf 85] Report's coverage line is a hardcoded string, so it claims dimensions that may never have run — commands/review.md:124
   Failure: Stage 6 hardcodes `Checked: conventions, bugs, history, prior reviews, comments,
   slop, deterministic.` as literal template text, and line 128 tells the orchestrator to
   emit "exactly" that on a clean review. If a Stage 3 finder errors, returns unparseable
   output, or is never launched, the report still asserts that dimension was checked. The
   review-command spec's clean-review scenario (spec.md:58-62) requires the report to state
   "which dimensions were checked" — a fixed string cannot. A user treating a zero-finding
   report as a pre-PR gate cannot tell "found nothing" from "never looked".
   Fix: have Stage 3/4 record one row per dimension as it resolves (dimension, outcome,
   candidate count) and derive `Checked:` from the rows that actually returned; name
   unresolved dimensions on a separate `Not checked:` line with the reason. A dimension with
   no row may not be listed as checked.
   (conventions)

4. [P2][conf 85] Docs still describe the pre-plugin repo the change just superseded — CLAUDE.md:43
   Also: docs/evals.md:7
   Failure: CLAUDE.md's Scope section still reads "The plugin itself — `.claude-plugin/`,
   `commands/`, `skills/`, `agents/`, and the `eval/` corpus — is not here yet. Grep for
   `TODO(plugin)` to see what's waiting on it." This change adds all five. An agent opening
   the file that announces itself as "what an agent should know before touching this repo"
   concludes the plugin is unbuilt and may recreate it; the `TODO(plugin)` grep it directs
   you to now returns CLAUDE.md's own line plus openspec planning docs. Separately,
   docs/evals.md:7 still says `/reviso review` four lines below a hunk this change edited,
   while README.md:31 renamed it to `/reviso:review` — a user types the old form and gets
   no such command. tasks.md:75 marks task 6.1 ("Resolve `TODO(plugin)` blocks") complete.
   Fix: replace CLAUDE.md's Scope section with what actually ships (`commands/review.md`
   orchestrator, `agents/` finders, `skills/reviso/` harness, `eval/` parity harness) and
   point the remaining TODO(plugin) at docs/ci.md:4, the one real leftover; change
   docs/evals.md:7 to `/reviso:review`.
   (conventions)

Checked: bugs, conventions, history, comments, slop, deterministic.
Skipped: eval/reference/code-review-recipe-2026-08-03.md, eval/reference/code-review-recipe-LICENSE (vendored verbatim, explicitly not ours to edit).
```

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: bugs 3, conventions 4, history 0, comments 2, slop 1, deterministic 0.
Candidates before the gate (10):
  [conventions] agents/reviso-verifier.md:4        score 95  reported
  [bugs]        eval/runners/baseline.sh:16        score 88  reported
  [conventions] commands/review.md:124             score 85  reported
  [conventions] CLAUDE.md:43                       score 85  reported
  [conventions] docs/evals.md:7                    score 82  reported (merged into #4)
  [comments]    eval/runners/candidate.sh:25       score 70  dropped: rubric-score
  [bugs]        eval/runners/match.sh:30           score 60  dropped: rubric-score
  [slop]        agents/reviso-finder-bugs.md:19    score 55  dropped: rubric-score
  [comments]    CONTRIBUTING.md:67                 score 50  dropped: rubric-score
  [bugs]        eval/runners/extract.sh:27         score 45  dropped: rubric-score
```

Two notes on what I deliberately did not flag: the `--disallowedTools "Bash(gh pr comment:*)"` block in baseline.sh:17 is adequate — the vendored recipe's own `allowed-tools` line has no other mutating `gh` path, so the comment's "block PR mutation" claim holds. And the repeated schema/FP-list citation block across the six finder agents is single-sourcing by design (skills/reviso/SKILL.md:10), not duplication — agent frontmatter has no include mechanism, so there is no helper to name.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
