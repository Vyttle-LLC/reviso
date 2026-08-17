# Confidence rubric (0–100)

Forked from the official `code-review` plugin (Apache-2.0; dated snapshot in
`eval/reference/`). This rubric is the orchestrator's input — the one
stage that judges — and is not required reading for any subagent. Score
each issue on a scale from 0–100, indicating your level of confidence:

- **0**: Not confident at all. This is a false positive that doesn't stand up
  to light scrutiny, or is a pre-existing issue.
- **25**: Somewhat confident. This might be a real issue, but may also be a
  false positive. The agent wasn't able to verify that it's a real issue. If
  the issue is stylistic, it is one that was not explicitly called out in the
  relevant CLAUDE.md.
- **50**: Moderately confident. The agent was able to verify this is a real
  issue, but it might be a nitpick or not happen very often in practice.
  Relative to the rest of the change, it's not very important.
- **75**: Highly confident. The agent double checked the issue, and verified
  that it is very likely it is a real issue that will be hit in practice. The
  existing approach in the change is insufficient. The issue is very
  important and will directly impact the code's functionality, or it is an
  issue that is directly mentioned in the relevant CLAUDE.md.
- **100**: Absolutely certain. The agent double checked the issue, and
  confirmed that it is definitely a real issue, that will happen frequently
  in practice. The evidence directly confirms this.

The gate: findings scoring **below 80 are dropped silently**. For issues
flagged from CLAUDE.md instructions, double check that the CLAUDE.md actually
calls out that issue specifically.
