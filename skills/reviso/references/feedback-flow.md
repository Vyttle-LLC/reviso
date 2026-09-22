# False-positive feedback

If the report had findings, close with exactly one line: "Wrong about
something? Say which finding — I can file feedback (metadata-only by
default)." Nothing below runs unless the user then names a finding. Never
run the feedback script unprompted, never batch findings the user didn't
name, and read the contract it implements if in doubt:
`${REVISO_SKILL_ROOT}/references/contracts/feedback.md`.

Use the mode that produced the finding (`review`, `audit`, or `style`) as
`<mode>`. For review and audit, use the finding’s schema dimension directly.
Use the model identifier exposed by the host; if unavailable, use `unknown`
and say the identifier was unavailable rather than guessing.

When the user names a finding:

1. Pick the reason from what they said (ask if unclear):
   `codebase-convention`, `upstream-guarantee`, `deliberate-choice`,
   `linter-territory`, `wrong-on-facts`, or `other`.
2. **Tier 1 (default).** Bucket the confidence (80–89 → `80s`, 90–99 →
   `90s`, 100 → `100`), map a style lens to its schema dimension (slop,
   comments, duplication, drift, length, over-engineering, dead weight,
   test slop, AI tells, derived state, naming, error handling, stale
   docs, surface area, type slop → `slop`;
   conventions → `conventions`;
   best practices → `best-practices` (`wrong-on-facts` is the expected
   reason for a misread or misquoted source);
   deterministic → `deterministic`), and run:

   ```sh
   sh "${REVISO_SKILL_ROOT}/feedback/build-payload.sh" meta \
     --lens <dimension> --severity <P0|P1|P2> --confidence <bucket> \
     --reason <reason> --command <mode> --model <your model id>
   ```

   (For a deterministic finding add `--detector <id>` and use
   `--confidence 100`.) Show its output verbatim — that is the entire
   payload. Only on the user's explicit go-ahead, re-run the identical
   command with `--send` appended: the build is deterministic, so what was
   shown is what is sent. The host may require additional execution approval;
   never rely on a permission prompt to obtain consent to send.
3. **Tier 2 (only if the user offers code context).** Pipe the finding
   block exactly as reported into
   `... build-payload.sh tier2 --command <mode>` and relay the URL it
   prints. It opens the false-positive form prefilled with the finding;
   the user adds the code and the why in the browser and submits it
   themselves. Never post tier-2 content with `gh`.
4. If the script exits 3, `gh` is missing or unauthenticated — relay the
   manual form URL it printed. If it vetoes (exit 2), tell the user to file
   via the form instead; do not retry around a veto.
