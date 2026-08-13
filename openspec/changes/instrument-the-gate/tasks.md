# Tasks — instrument the gate

## 1. The verifier's drop reason

- [x] 1.1 Add `drop_reason` to the return JSON in `agents/reviso-verifier.md`,
      with the closed set `exclusion-list | pre-existing | rubric-score | none`
      and one line tying each value to the step that produces it (step 2 →
      `exclusion-list`, step 3 → `pre-existing`, sub-80 survivor →
      `rubric-score`, cleared → `none`).
- [x] 1.2 State in the same file that the reason is machine-read by the
      orchestrator and does not replace the one-sentence `verdict`.

## 2. Audit orchestration — the Stage 3 ledger

- [x] 2.1 In `commands/audit.md` Stage 3, instruct the orchestrator to record
      one row per finder as each Task returns: lens, outcome
      (`returned` / `no result` / `skipped`), candidate count.
- [x] 2.2 State the two rules that make the ledger trustworthy: an empty
      findings array is `returned` (the lens looked and found nothing), and a
      finder with no recorded row is `no result` — never assumed clean.
- [x] 2.3 Extend the same accounting to the deterministic suite in Stage 1: a
      declined permission prompt or a failed `run.sh` is a `no result` row for
      the `deterministic` lens, not a silent pass.
- [x] 2.4 In Stage 4, instruct the orchestrator to keep each candidate's score
      and `drop_reason` alongside the ledger, tolerating a verifier return
      that omits the reason (`rubric-score` below 80, `none` at or above).

## 3. Audit report — derived coverage

- [x] 3.1 Delete the hardcoded `Checked: conventions, bugs, history, prior
      reviews, comments, slop, deterministic.` literal from Stage 6 so there
      is nothing left to copy.
- [x] 3.2 Replace it with a derivation: name the lenses whose rows say
      `returned`, and emit a `Not checked:` line — only when non-empty —
      naming each `no result` / `skipped` lens with its reason.
- [x] 3.3 State that the default report prints no per-lens candidate counts,
      and that a lens without a ledger row may not be named as checked.
- [x] 3.4 Update the no-findings branch ("report exactly the header line,
      then 'No issues found.'…") so it renders the same derived coverage
      block.

## 4. Single-pass review — the same contract, per lens

- [x] 4.1 In `commands/review.md` Step 3, instruct the session to record per
      lens whether it applied that lens across the non-skipped hunks, using
      the same three outcomes.
- [x] 4.2 Apply the same accounting to Step 2's detector run.
- [x] 4.3 Replace the Step 5 `Checked: bugs, conventions, history, comments,
      slop, deterministic.` literal with the derived block and the
      conditional `Not checked:` line, matching the audit's wording.
- [x] 4.4 Carry the Step 4 self-verification scores into the same
      score-plus-reason accounting the audit keeps, so `--explain` has the
      same population to show.

## 5. `--explain`

- [x] 5.1 Add `--explain` to `argument-hint` and the arguments paragraph in
      both `commands/audit.md` and `commands/review.md`; unknown flags keep
      their existing one-line-note behavior.
- [x] 5.2 Specify the diagnostic section in both files: fenced, labelled
      diagnostics-not-findings, placed after the findings, carrying the
      ledger with counts and every pre-gate candidate with score and
      disposition.
- [x] 5.3 State the default-off contract explicitly in both files — without
      the flag, nothing about a dropped candidate appears; with it, the
      findings section is byte-identical.
- [x] 5.4 State the sink rule: diagnostics follow the report to the terminal
      and to `--out` when given, and nowhere else.
- [x] 5.5 Confirm neither command's `allowed-tools` frontmatter changed
      (`git diff` on the two files' frontmatter must be empty).

## 6. Repo hygiene

- [x] 6.1 Add a CHANGELOG entry under a new `## [Unreleased]` section
      covering the derived coverage line, `--explain`, and the verifier's
      `drop_reason`.
- [x] 6.2 Run `markdownlint-cli2` and `lychee` over the changed files; fix the
      content, not the config.
- [x] 6.3 Sync the two delta specs into `openspec/specs/` (`/opsx:sync`) once
      the command files match them.

The diagnostic run this instrumentation was built for is deliberately not a
task here — it needs the instrumented plugin installed, and neither field
branch is reachable from this machine. It moved to the proposal's
follow-ups.
