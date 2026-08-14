```text
## Reviso audit — detached HEAD (e76eda9) vs cb3f63a4 (6 commits, 44 files)

Found 2 issues:

1. [P0][conf 90] Report-only invariant is not enforced by the tool grants this change ships — agents/reviso-verifier.md:4
   Failure: `tools: Read, Grep, Glob, Bash` — a bare, unscoped Bash grant — in
   agents/reviso-verifier.md:4, agents/reviso-finder-history.md:4, and
   agents/reviso-finder-prior-reviews.md:4 lets those subagents run any command
   (`git commit`, `rm`, `curl`), not the read-only git/gh set their own prose
   promises. Separately, commands/review.md:4 pre-approves `Bash(git branch:*)`,
   which the command body never invokes and which permits `-D`/`-m`/`-f`. These
   subagents' sole input is untrusted diff, commit-message, and comment text —
   the prompt-injection vector SECURITY.md names explicitly. The change's own
   spec (openspec/changes/add-reviso-review/specs/review-command/spec.md) states
   the command "and every subagent it spawns" SHALL be read-only and MUST NOT
   include Bash patterns that permit writes.
   Fix: scope each agent's grant — `Bash(git blame:*), Bash(git log:*),
   Bash(git show:*), Bash(git diff:*)` for the history finder; `Bash(git log:*),
   Bash(git show:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*)`
   for prior-reviews; the verifier needs only the read-only git set. Drop
   `Bash(git branch:*)` from commands/review.md entirely.
   (prior-reviews; merged with the allowed-tools finding, same root cause)

2. [P2][conf 85] Untracked-file findings anchor to the wrong path — skills/reviso/detectors/run.sh:13
   Failure: run.sh never cds to the repo root. `git diff -U0 "$MB"` (line 17)
   always emits repo-root-relative paths, but `git ls-files --others` (line 19)
   and the `git diff --no-index` on line 20 emit cwd-relative ones. Invoke
   /reviso:review from a subdirectory and a conflict or testfocus hit in an
   untracked file reports a path the rest of the pipeline cannot resolve, while
   tracked-file hits resolve correctly. commands/review.md establishes no
   cwd invariant before calling the script.
   Fix: add `cd "$(git rev-parse --show-toplevel)"` before computing MB.
   (prior-reviews)

Checked: deterministic, conventions, bugs, history, prior reviews, comments, slop.
Skipped: eval/reference/code-review-recipe-2026-08-03.md, eval/reference/code-review-recipe-LICENSE, openspec/config.yaml, openspec/changes/add-reviso-review/.openspec.yaml, eval/runs/.gitignore.
```

```text
--- explain: pipeline diagnostics (not review findings) ---
Finders: conventions 2, bugs 2, history 1, prior-reviews 7, comments 0, slop 1,
deterministic 0.
Candidates before the gate (13):
  [prior-reviews] reviso-verifier.md:4     score 90  reported (merged into #1)
  [prior-reviews] review.md:4              score 88  reported (merged into #1)
  [prior-reviews] run.sh:13                score 85  reported
  [prior-reviews] match.sh:27              score 68  dropped: rubric-score
  [prior-reviews] baseline.sh:16           score 60  dropped: rubric-score
  [bugs]          match.sh:30              score 52  dropped: rubric-score
  [bugs]          extract.sh:27            score 40  dropped: rubric-score
  [prior-reviews] detect.awk:6             score 40  dropped: rubric-score
  [slop]          reviso-triage.md:15      score 20  dropped: exclusion-list
  [conventions]   CLAUDE.md:42             score 10  dropped: exclusion-list
  [conventions]   docs/evals.md:7          score  5  dropped: pre-existing
  [prior-reviews] docs/evals.md:7          score  5  dropped: pre-existing (dupe)
  [history]       README.md:58             score  0  dropped: exclusion-list

Four caveats on this run's trustworthiness:

- This repo's object store contains the project's future history (commits after
  e76eda9 on other refs). The prior-reviews and history finders reached it via
  `git log --all` and sourced evidence from the very commits that later fixed
  these issues. I re-verified all seven affected candidates with future commits
  ruled inadmissible; the three that survived stand on the state at HEAD alone.
  The history finder's one candidate did not survive that test — its claim that
  `/plugin marketplace add` rejects `owner/repo` shorthand is false. Treat the
  prior-reviews lens's raw recall on this run as inflated.
- Two verifiers could not read the rubric and exclusion list at the configured
  comp/ path (permission denied) and scored partly on instructions alone. One
  fell back to the in-repo copies; the other (run.sh:13, reported above) did not
  gate against the exclusion list at all and flagged that itself.
- My verifier prompt for the slop candidate asserted a "2-or-fewer occurrences"
  duplication bar. That bar does not exist in false-positives.md — my error, and
  the verifier caught and disregarded it.
- detect.awk:6 bundled a real bug (line 37's fit/fdescribe boundary class omits
  `.`, so `model.fit(` false-positives) with a disproven one, and was dropped as
  a unit. The real half is worth a look independently.
- The vendored snapshot's claimed SHA-256 in eval/reference/README.md:12 is
  unverified; the shasum command was not approved.
```

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
