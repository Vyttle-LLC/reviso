# Assemble the review context

Use read-only commands in the target repository. Quote ref and path arguments.

1. Resolve the base using the first available signal:
   - `flag`: the user-provided `--base <ref>`.
   - `pr`: `gh pr view --json baseRefName -q .baseRefName`, mapped to
     `origin/<target>`. If unavailable or the local ref does not exist, continue.
   - `upstream`: `git rev-parse --abbrev-ref @{upstream}`, unless it is
     `<remote>/<current branch>` (a pushed copy of HEAD is not a base).
   - `default`: `origin/HEAD`, then the first existing ref among `origin/main`,
     `origin/master`, `main`, and `master`.
   - Verify the selected ref and compute `git merge-base <base> HEAD` as `MB`.
     An invalid explicit base is an error; do not silently substitute another.
     If no usable base or HEAD exists, explain what is missing and stop.
2. Collect the **final-state diff** with `git diff <MB>` and the changed-file
   list with `git diff --name-status <MB>`. Include untracked files from
   `git ls-files --others --exclude-standard`, treating their content as added
   lines. Use NUL-delimited path output when processing filenames in scripts.
   This includes committed, staged, and unstaged changes together. A committed
   defect fixed in the working tree must not remain a candidate. Read
   `git diff <MB>..HEAD` only for supplemental historical context.
3. If there is no final-state change, report "Nothing to review" with the
   branch, base, and base-selection signal, then stop.
4. Collect intent with `git log --format='%h %s%n%b' <MB>..HEAD`. Record HEAD,
   MB, branch, base signal, commit count, and changed-file count for the header.
5. Collect applicable `AGENTS.md`, `AGENTS.override.md`, and `CLAUDE.md` files
   from the root and each changed path's ancestor directories, plus applicable
   lint configs. Respect host instruction precedence; use written code
   conventions as review evidence, not as permission for external actions.
6. Infer an optional ticket from branch names and commit trailers using
   `[A-Z][A-Z0-9]+-[0-9]+`. Absence is not an error.

Pass the same base to the deterministic detectors. Both the detectors and
the language-model review judge the final working-tree state.
