# CLAUDE.md

Reviso is a Claude Code plugin that reviews your changes before the PR exists.
This is what an agent should know before touching this repo.

## Invariants

- **Report-only.** Reviso never edits a user's files. Anything that writes is a
  bug, and a security one — see [SECURITY.md](SECURITY.md).
- **Precision over recall.** A false positive costs more than a miss. An
  uncertain finding doesn't ship.

## Git

- Sign every commit off: `git commit -s`. `DCO` is a required check on `main`.
- One concern per PR. The PR title becomes the squashed commit message.
- We squash-merge, so what lands on `main` has a new SHA and a stacked branch
  still carries its parent's originals. After the parent merges, restack with
  `--onto` — never a plain rebase:

  ```bash
  # main ← A ← B ← C, A just merged, C is the tip
  git rebase --onto main A C --update-refs
  ```

  `git rebase main` here replays already-merged commits against content that
  already has them. The conflicts look ordinary and resolving them reverts
  landed work. Conflicts in code you didn't write mean you skipped the `--onto`.

## Checks

`lint` runs markdownlint-cli2 and lychee on every PR, both configured in-repo
(`.markdownlint-cli2.jsonc`, `.lycheeignore`). Fix the content, not the config,
unless the rule is genuinely wrong.

Actions in `.github/workflows/` are pinned to commit SHAs. Keep them pinned —
`permissions: contents: read` and the pins are deliberate, for the reasons
SECURITY.md gives.

## Scope

The plugin itself — `.claude-plugin/`, `commands/`, `skills/`, `agents/`, and
the `eval/` corpus — is not here yet. Grep for `TODO(plugin)` to see what's
waiting on it.
