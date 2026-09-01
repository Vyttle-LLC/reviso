# Tasks — infer the diff base

## 1. Resolution

- [x] 1.1 Replace Step 1's base resolution in `commands/review.md`,
      `commands/audit.md`, and `commands/style.md` with the four-signal
      sequence: flag, PR target, tracking branch unless it is
      `<remote>/<current branch>`, default branch preferring the remote
      ref.
- [x] 1.2 Update the `--base` argument description in all three verbs.
- [x] 1.3 Add `Bash(gh pr view:*)` to `commands/style.md` allowed-tools.

## 2. Visibility

- [x] 2.1 Add the `Base: <base> via <signal> — merge-base <sha>` line under
      the report header in all three verbs.
- [x] 2.2 Name the signal in the empty-change message.

## 3. Docs and release

- [x] 3.1 README: how the base is chosen; the `--track` habit for stacks.
- [x] 3.2 `CHANGELOG.md` 0.12.0 entry; `plugin.json` version 0.12.0.
- [x] 3.3 Spec sync: apply the `review-command` delta.
- [x] 3.4 Lint green; every commit signed off.
