All stages complete. One finding survived the confidence gate. Final report:

```text
## Reviso review — HEAD (detached, e76eda9) vs cb3f63a (6 commits, 44 files)

Found 1 issue:

1. [P1][conf 80] Finder/verifier agents grant unscoped Bash, not read-only-scoped —
   agents/reviso-finder-history.md:4 (also agents/reviso-finder-prior-reviews.md:4,
   agents/reviso-verifier.md:4)
   Failure: These agents consume attacker-controlled input (commit messages, git
   blame, PR review comments — the exact prompt-injection surfaces SECURITY.md
   names). Their frontmatter grants bare `Bash`, so an injected instruction to run
   a write/exfil shell command is blocked only by prose ("use Bash exclusively for
   read-only git commands"), not by the tool-permission layer. This contradicts
   the change's own design D3 ("report-only enforced structurally, not by
   convention") and the review-command spec ("every subagent it spawns SHALL be
   restricted to read-only tools"), while commands/review.md:4 itself scopes every
   Bash grant to `Bash(git …:*)` patterns.
   Fix: Scope each agent's Bash grant to the subcommands its prose needs, e.g.
   `tools: Read, Grep, Glob, Bash(git blame:*), Bash(git log:*), Bash(git show:*)`
   for reviso-finder-history; equivalent allow-lists for reviso-finder-prior-reviews
   (plus `gh pr list/view`, `gh search`) and reviso-verifier (plus `git diff`).
   (conventions)

Checked: conventions, bugs, history, prior reviews, comments, slop, deterministic.
Skipped: eval/reference/code-review-recipe-2026-08-03.md, eval/reference/code-review-recipe-LICENSE (vendored verbatim).
```

No `--out` was passed, so terminal-only. Stage 1 deterministic detectors ran clean, and the working tree was untouched throughout (report-only held).
