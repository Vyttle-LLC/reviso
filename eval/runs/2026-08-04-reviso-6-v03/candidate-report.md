## Reviso review — HEAD (detached) vs `cb3f63a4` (6 commits, 44 files)

Found 3 issues:

1. **[P1][conf 90] Report-only tool grants are wider than the spec allows — write-capable Bash surface** — `commands/review.md:4`; also `agents/reviso-finder-history.md:4`, `agents/reviso-finder-prior-reviews.md:4`, `agents/reviso-verifier.md:4`
   Failure: This branch's own spec (`openspec/changes/add-reviso-review/specs/review-command/spec.md:29-31`) says the command and every subagent "SHALL be restricted to read-only tools" and `allowed-tools` "MUST NOT include Bash patterns that permit writes", and design D3 promises a write attempt is "a tool-permission failure, not a reviewable behavior". Neither holds: the command pre-approves `Bash(git branch:*)` (permits `git branch -D`/`-f <branch>` — deletes or moves branches with no prompt) and `Bash(git symbolic-ref:*)` (permits `git symbolic-ref HEAD refs/heads/x`, repointing HEAD), and the history, prior-reviews, and verifier agents grant unscoped `Bash`, so any shell command a derailed subagent issues is limited only by prose and the user's permission config — with `--dangerously-skip-permissions` or broad Bash allows there is no structural backstop at all.
   Fix: Scope the grants to what the steps actually run: in the command, replace `Bash(git branch:*)` with `Bash(git branch --show-current)` and `Bash(git symbolic-ref:*)` with `Bash(git symbolic-ref refs/remotes/origin/HEAD)`; in the three agents, replace bare `Bash` with the scoped forms each agent's own prose lists (e.g. `Bash(git blame:*), Bash(git log:*), Bash(git show:*), Bash(git diff:*)` for history/verifier, plus the `gh pr list/view`, `gh search` forms for prior-reviews).
   (bugs — enforcement doesn't match its claim; also conventions: CLAUDE.md's "anything that writes is a bug, and a security one")

2. **[P2][conf 85] Vendored snapshot's private-repo link will trip the weekly external link sweep** — `eval/reference/code-review-recipe-2026-08-03.md:86`
   Failure: Line 86 contains a bare-prose URL to `github.com/anthropics/claude-cli-internal/...`, a private repo that returns 404 to an unauthenticated GitHub runner. `link-check.yml` sweeps `**/*.md` externally every Monday and files/updates a `link-rot` issue on failure — so this permanently dead-from-CI link generates a recurring false-alarm issue, the exact failure mode `.lycheeignore`'s existing comments exist to prevent. The snapshot itself can't be fixed ("Do not edit the snapshot").
   Fix: Add `^https://github\.com/anthropics/claude-cli-internal` to `.lycheeignore` with a vendored-verbatim comment, mirroring the existing contributor-covenant entry (or add `--exclude-path eval/reference` to the lychee invocations).
   (conventions)

3. **[P2][conf 80] `docs/evals.md` still uses the old `/reviso review` spelling this diff renames** — `docs/evals.md:7`
   Failure: The diff deliberately standardizes on the colon form — README's twin sentence ("the parity bar is that `/reviso review` catches…") was changed to `/reviso:review` in this branch, and every new file uses the colon form — but `docs/evals.md:7`, three lines below a hunk this change edits, keeps the space form. A reader typing `/reviso review` gets an unknown-command error.
   Fix: Change to `` `/reviso:review` ``.
   (conventions — doc staleness)

Checked: bugs, conventions, history, comments, slop, deterministic (detector suite ran clean).
Skipped: `eval/reference/code-review-recipe-2026-08-03.md` and `code-review-recipe-LICENSE` (vendored verbatim; content not reviewed, though the snapshot's CI-facing links were checked). Note: the documented snapshot SHA-256 could not be verified — the hash command wasn't pre-approved in this environment.
