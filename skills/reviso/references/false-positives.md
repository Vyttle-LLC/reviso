# False-positive exclusion list

Forked from the official `code-review` plugin (Apache-2.0; dated snapshot in
`eval/reference/`), adapted from PR review to local pre-PR review. These are
never findings, no matter how plausible they look. This list is the
orchestrator's input — the one stage that judges — and is not required
reading for any subagent; the orchestrator scores a match 0–25 at the gate.

- Pre-existing issues — anything already true before this change.
- Something that looks like a bug but is not actually a bug.
- Pedantic nitpicks that a senior engineer wouldn't call out.
- Issues that a linter, typechecker, or compiler would catch (missing or
  incorrect imports, type errors, broken tests, formatting, pedantic style
  issues like newlines). Assume those run separately in CI; never run build
  steps to check.
- General code quality issues (lack of test coverage, general security
  posture, poor documentation) unless explicitly required in CLAUDE.md.
- Issues that CLAUDE.md calls out but the code explicitly silences (e.g. a
  lint-ignore comment).
- Changes in functionality that are likely intentional or directly related
  to the broader change — read the commit messages; stated intent counts.
- Real issues on lines the change did not modify.

Reviso addition (the anti-slop lens has its own trap):

- A codebase's deliberate, established style is never slop. Slop findings
  must be relative to the repo's own norms — flag drift from the codebase,
  not from the reviewer's taste.
