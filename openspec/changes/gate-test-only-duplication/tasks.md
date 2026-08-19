# Tasks — gate test-only duplication

## 1. The gate

- [x] 1.1 Add the test-only entry to
      `skills/reviso/references/false-positives.md` under the Reviso
      additions: all-occurrences-in-test-code duplication is excluded
      unless a written convention governing the changed paths demands
      shared test helpers; written rules only; mixed findings unaffected
- [x] 1.2 Rewrite the "Test code counts" clause of the duplication item
      in `commands/review.md` to the gated rule
- [x] 1.3 Rewrite the same clause in `commands/style.md` (identical
      wording — the surfaces must not drift)
- [x] 1.4 Leave `agents/reviso-finder-slop.md` returning test-only
      candidates; add the one-line note that shipping them is the
      orchestrator's written-convention call

## 2. Specs and docs

- [x] 2.1 Apply the review-pipeline delta to
      `openspec/specs/review-pipeline/spec.md`
- [x] 2.2 Add the bullet to the unreleased 0.6.0 CHANGELOG entry

## 3. Verification

- [x] 3.1 Fixture run: a repo with a 7-copy mock lambda across test files
      and no written convention — `/reviso:style` ships no duplication
      finding, and `--explain` shows the candidate dropped as
      `exclusion-list`. Confirmed: two 7-occurrence test-only candidates
      cleared the numeric bar, both dropped `exclusion-list` (score 10);
      clean report; no writes, no subagents
- [x] 3.2 Re-check the termic-162 e2e finding logic: confirm the skill-doc
      rule cited by the 4.2 run (`use the shared helpers in
      e2e/helpers.ts`) satisfies the written-convention gate as worded —
      it does: `.claude/skills/e2e/SKILL.md` is a skill doc governing the
      changed spec paths, so that finding still ships under the gate
- [x] 3.3 `lint` passes on touched files — markdownlint 0 issues,
      lychee 2/2 OK
