# Infer the diff base

## Why

**Every verb hard-codes the base to the default branch.** Step 1 resolves
`--base`, else `origin/HEAD`, else local `main`. On a stacked branch that
diffs the whole stack against `main`, so the parent's landed work is
reviewed again as if it were new, and the findings are about code the
branch did not touch. A day of stacked work produced main-sized reports
for one-commit layers.

Git already records the parent in two places Reviso never reads: the open
PR's `baseRefName`, and the branch's tracking ref when the layer was cut
with `--track <parent>`. The CLI's built-in `/code-review` reads the
second (`git diff @{upstream}...HEAD`) and that is the whole of why it
appears to handle stacks.

The one thing Reviso already did better is print the range it reviewed,
which is how the wrong base was noticed at all. Keep that, and make it
say why.

## What Changes

- **Step 1 takes the first of four signals**: `--base`, the open PR's
  target, the tracking branch (unless it is only the pushed copy of
  HEAD), then the default branch. Same sequence in all three verbs.
- **The default branch is the remote one.** `origin/main` before local
  `main`; a stale local default branch re-reviews landed work.
- **The report names the base and the signal that chose it**, plus the
  merge-base, directly under the header. A wrong base is visible before
  the findings are read.
- **History-based guessing is a non-goal.** Picking the branch with the
  nearest merge-base looks attractive and is wrong: squash-merged
  branches left undeleted sit one commit off the stack and outrank
  `main`. Precision over recall applies to the base too.
- `/reviso:style` gains `Bash(gh pr view:*)` for the PR signal.
  Read-only; the report-only invariant is unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `review-command`: the default base is inferred from PR, upstream, then
  default branch rather than fixed to the default branch, and every
  report states which signal chose it.

## Impact

- `commands/review.md`, `commands/audit.md`, `commands/style.md`: Step 1
  / Stage 0 base resolution, the empty-change message, the report header.
- `README.md`: how the base is chosen; the `--track` habit for stacks.
- `CHANGELOG.md` 0.12.0, `plugin.json` bump.
- Repo rules: `git commit -s`, one concern per PR, lint green.
