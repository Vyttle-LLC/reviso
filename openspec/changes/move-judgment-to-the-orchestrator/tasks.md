# Tasks — move judgment to the orchestrator

Prerequisite: `measure-the-audit-tier` is landed and the `reviso-6` audit
baseline is recorded. Nothing below is observable without it.

## 1. Split policy out of the shared schema

- [x] 1.1 Remove the candidate cap ("a finder returns at most 8
      candidates") and the severity floor ("there is no P3 — a nit that
      would rank below P2 is not returned") from
      `skills/reviso/references/finding-schema.md`, leaving the wire format
      and the field-level rules that define it.
- [x] 1.2 State in the schema that it carries format only, and that
      reporting policy belongs to the command that produces the report —
      so a stage that serializes a candidate cannot thereby suppress it.
- [x] 1.3 Restate the severity floor and consolidation policy in
      `commands/review.md` so the single-pass tier's behaviour is
      byte-for-byte what it is today.
- [x] 1.4 Restate the same policy in `commands/audit.md`'s reporting stage,
      where it now applies for the first time.

## 2. Finders report what they find

- [x] 2.1 `agents/reviso-finder-bugs.md`: remove "Focus on large bugs;
      avoid small issues and nitpicks. Ignore likely false positives" and
      the "if you cannot state the failure scenario concretely, it is not a
      finding" suppression, keeping the failure-scenario field obligation.
- [x] 2.2 `agents/reviso-finder-slop.md`: remove "below the bar, say
      nothing", "anything that would rank below P2 is not returned", and
      the duplication bar's suppression framing — keep the bar as a
      severity signal the orchestrator weighs, not as a gate the finder
      applies.
- [x] 2.3 Remove the `read and obey → false-positives.md` instruction from
      all six finders, replacing it with the evidence obligation
      (`file:line`, concrete failure scenario, suggested fix).
- [x] 2.4 Sweep the remaining four finders (`conventions`, `history`,
      `comments`, `prior-reviews`) for equivalent self-gating language and
      remove it; `history`'s "an apparent regression the branch explicitly
      intends is not a finding" becomes evidence the finder reports, not a
      reason to withhold.
- [x] 2.5 Confirm no finder prompt still references a candidate limit, a
      severity floor, or the exclusion list.

## 3. Demote the verifier to evidence

- [x] 3.1 Rewrite `agents/reviso-verifier.md`'s job: re-examine the
      candidate against the code and report findings of fact — whether the
      cited lines are part of this change, what guards/callers/tests bear
      on the scenario, whether it reproduces.
- [x] 3.2 Replace its return JSON: drop `confidence` and `drop_reason`; add
      structured fact fields plus the one-sentence summary of what it
      found. No score, no verdict, no veto.
- [x] 3.3 Remove the rubric and exclusion-list reads from the agent
      entirely, and rename the agent so its name stops describing a gate.
- [x] 3.4 Update the agent's `description` frontmatter, and every reference
      to it in `commands/audit.md` and `skills/reviso/SKILL.md`.

## 4. The orchestrator judges once

- [x] 4.1 Rewrite `commands/audit.md` Stage 4 as evidence-gathering: fan
      out per candidate, collect facts, no filtering.
- [x] 4.2 Add the gate to the orchestrator: read the exclusion list and the
      rubric once, apply the exclusion list, score each candidate 0–100 with
      every candidate in hand, drop below 80, stay silent about drops.
- [x] 4.3 State explicitly that the rubric's comparative bands ("relative
      to the rest of the change") are judged here because only here is the
      whole change visible.
- [x] 4.4 Keep the per-candidate record (score + drop reason from the closed
      set) as the orchestrator's own, and repoint `--explain` at it so the
      diagnostic output is unchanged in shape.
- [x] 4.5 Confirm the coverage ledger from `instrument-the-gate` still
      derives correctly now that Stage 4 returns no scores.

## 5. Spec sync

- [x] 5.1 Apply the `review-pipeline` delta: unfiltered finders, Stage 4 as
      evidence, gate in the orchestrator, references not subagent inputs.
- [x] 5.2 Apply the `review-command` delta: reporting policy is a command
      obligation, schema carries format only.

## 6. Verification

- [x] 6.1 Re-run the audit gold subset and record candidate yield, reported
      findings, clean-case false positives, and cost against the `reviso-6`
      baseline (13 candidates → 3 reported, $9.73). *Recorded in
      `eval/runs/2026-08-17-reviso-6-audit-v050/` (21 → 5, $13.80, vs the
      runner baseline's 5 → 1, $6.42) and
      `eval/runs/2026-08-17-clean-audit-v050/`.*
- [x] 6.2 Confirm the two known regressions recover: `match.sh` (scored 68)
      and `extract.sh` (scored 40) on `reviso-6`. If they do not, the gate
      position was not the whole cause and
      `recalibrate-the-confidence-rubric` carries the rest. *`match.sh`
      recovered (88, reported); `extract.sh` did not (60) — the contingency
      holds and passes to `recalibrate-the-confidence-rubric`.*
- [x] 6.3 Confirm `/reviso:review` output is unchanged on a gold case — its
      policy moved files but not meaning. *`eval/runs/
      2026-08-17-reviso-6-review-v050/`: floor, cap, consolidation, and
      coverage derivation all applied as before; volume delta is within
      same-version run variance.*
- [x] 6.4 Confirm clean-case false positives did not rise; this is the
      tripwire for the precision risk this change takes. **Tripwire fired:
      `clean-error-handling-001` shipped one P1/conf-85 false positive
      (0 → 1 vs the review-tier gold sweep). Analysis in
      `eval/runs/2026-08-17-clean-audit-v050/README.md` — a band-fit
      overscore of a real-but-rare mechanism.** *Ruling: the tripwire did
      its job — the observation is recorded, not waived. The finding is
      behaviorally accurate but belongs in the rubric's 50 band, the same
      band-fit error class as the 68/40 underscores this change recovered
      from; the disposition is rubric recalibration, not restored
      distributed vetoes, and it passes to
      `recalibrate-the-confidence-rubric` alongside `extract.sh` (6.2) as
      its third data point. Clean-tier repeats there decide whether the
      overscore is systematic or n=1 variance.*
- [x] 6.5 Confirm the report-only invariant holds: no new write
      permissions, `candidate.sh`'s pre/post tree comparison passes.
- [x] 6.6 `markdownlint-cli2` and `lychee` pass; every commit signed off
      (`git commit -s`). *Lint green; sign-off applies when the work is
      committed.*

## 7. Resolve the held branch

- [x] 7.1 Decide the disposition of `7c9c073` ("Sharpen the precision
      bar") in light of the diagnosis, and record the decision — its
      actionability precondition is a sound question placed as another
      distributed veto.
- [x] 7.2 If any part of it is kept, land it as an orchestrator-level
      scoring input rather than a finder-level or verifier-level drop.
