All lenses and verifiers resolved. Report:

```text
## Reviso audit — HEAD (detached at e76eda9) vs cb3f63a (6 commits, 44 files)

Found 1 issue:

1. [P0][conf 90] Finder/verifier agents grant unrestricted Bash while their prompts claim read-only — agents/reviso-finder-history.md:4
   Also: agents/reviso-finder-prior-reviews.md:4, agents/reviso-verifier.md:4
   Failure: all three declare `tools: Read, Grep, Glob, Bash` with no command
   allowlist, while their own prose promises Bash is used "exclusively for
   read-only git commands". reviso-finder-history and reviso-finder-prior-reviews
   read commit messages and blame output verbatim — the exact attacker-controlled
   surface SECURITY.md names as in-scope, citing the CodeRabbit RCE precedent. A
   hostile commit message in a diff under review can induce `git checkout -- <file>`,
   `rm`, or `git commit`, and nothing at head stops it: there is no
   `.claude/settings.json` or other runtime permission config in this change, so
   the only enforcement is prose the injection is competing with. That breaks
   CLAUDE.md's top invariant ("Anything that writes is a bug, and a security one").
   The same change shows the correct pattern one directory over —
   commands/review.md:4 scopes every grant as `Bash(git status:*)`,
   `Bash(git diff:*)`, … — and the other five agents omit Bash entirely.
   Fix: scope each agent's `tools` frontmatter to the read-only subcommands it
   needs, e.g. `tools: Read, Grep, Glob, Bash(git blame:*), Bash(git log:*),
   Bash(git show:*), Bash(git diff:*)` for the two history lenses, plus
   `Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh search:*)` for prior-reviews.
   (bugs)

Checked: deterministic detectors, conventions, bugs, history, prior reviews, comments, slop.
Skipped: eval/reference/code-review-recipe-2026-08-03.md, eval/reference/code-review-recipe-LICENSE (vendored upstream snapshots).
```

```text
--- explain: pipeline diagnostics (not review findings) ---
Lenses: deterministic 0, conventions 2, bugs 2, history 0, prior-reviews 0,
comments 1, slop 0.
Candidates before the gate (5):
  [bugs]        agents/reviso-finder-history.md:4        score 90  reported
  [bugs]        eval/runners/match.sh:30                 score 55  dropped: rubric-score
  [comments]    skills/reviso/detectors/detect.awk:15    score 50  dropped: rubric-score
  [conventions] docs/evals.md:7                          score  0  dropped: exclusion-list
  [conventions] CLAUDE.md:41                             score  0  dropped: pre-existing
```

Two notes on the run, outside the findings: the prior-reviews lens found the GitHub remote reachable but every admissible PR (#1–#5) carrying zero review comments — it correctly excluded PR #6, which is near-identical in scope to this change but is not an ancestor of `e76eda9`, and everything after it. The history lens independently reached the same Bash-grant observation as the bugs lens but dropped it, because the only evidence it had was a non-ancestor commit; the bugs lens reached it from in-branch files alone, which is what let it through the gate.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
