# Design — Move judgment to the orchestrator

## Context

The audit pipeline inherited its shape from the Apache-2.0 marketplace
recipe (`eval/reference/code-review-recipe-2026-08-03.md`): five Sonnet
finders, a Haiku scorer, an 80 threshold. That recipe reviews every PR in a
repository unattended and forever, where silence is the correct default and
a cheap independent scorer is the right economy.

Reviso is a gate a user invokes deliberately, and it added lenses on top of
the recipe without re-deriving the recipe's filtering posture against that
difference. The result is subtractive at every layer: six finders each
applying the exclusion list, a candidate cap and a severity floor in the
shared schema, an isolated per-candidate scorer with veto power, then
dedupe and consolidation. Nothing in the pipeline is additive.

`7f1234d` already identified the error asymmetry — "a weak candidate costs
some compute and dies at the gate; a wrong veto costs the entire finding,
silently, with no recovery path" — and responded by upgrading the gate's
model from Haiku to Sonnet. The diagnostic run on `reviso-6` was taken
after that change, at v0.4.0, and the veto still killed two verified-real
findings at 68 and 40. The tier was not the problem; the position was.

The measured funnel: 13 candidates from seven lenses on a 44-file diff,
correctness contributing two, three reported, $9.73.

## Goals / Non-Goals

**Goals:**

- Concentrate every filtering decision in the one stage that holds the
  whole change.
- Preserve the report's precision. Nothing uncertain ships; the decision
  simply moves to where it can be made well.
- Keep the expensive code-reading in subagents, out of the orchestrator's
  context.
- Remove the rubric and exclusion list from subagent inputs entirely.

**Non-Goals:**

- Not a threshold change. Measured drops were 68 and below; 75–79 was
  empty on this run.
- Not a rubric-content change. Whether the rubric mis-scores
  enforcement-vs-claim defects is a separate proposal.
- Not new lenses, new detectors, or corpus work.
- Not a change to `/reviso:review`'s behaviour. Its orchestrator is already
  its finder; only the source of its policy text moves.

## Decisions

**Demote the verifier rather than delete it.** The alternative — drop
Stage 4 and let the orchestrator judge from finder output alone — is
cheaper and simpler, and it was rejected because the verifier does real
work the orchestrator should not: reading full file context, walking blame,
tracing callers, attempting the failure scenario against live code. That
labour is exactly what should be parallel and out-of-context. What must not
be parallel and out-of-context is the *decision*. Splitting labour from
judgment keeps the benefit and removes the harm; deleting the stage would
push code-reading into the orchestrator's context, which is the one budget
the pipeline genuinely cannot afford.

**Verification returns facts, not verdicts.** A verifier that returns "this
is 68" has already decided. A verifier that returns "the guard at line 88
handles null; no caller passes an empty slice; the scenario reproduces only
when `--force` is set" hands the orchestrator something it can weigh
against every other candidate. Facts compose; scores do not.

**Candidate volume is not a context risk.** The audit orchestrator was
moved to Opus in `7f1234d`, and candidates are small structured objects —
13 candidates was negligible, and even a hundred is on the order of 15k
tokens. `commands/audit.md`'s existing warning about context ("do not paste
file contents or reference-file text into agent prompts") is about bulk
file text, and this change does not touch it. If volume ever became real,
the correct response is summarizing evidence fields, not restoring
distributed vetoes.

**Policy leaves the shared schema.** `finding-schema.md` is cited by both
commands and every agent. Today it carries the candidate cap and the
severity floor, so a rule intended for reporting is enforced at
serialization by every finder. Splitting format from policy lets audit's
finders return everything while `/reviso:review` — where the orchestrator
*is* the finder — keeps its existing behaviour by restating the policy it
used to inherit. Alternative considered: fork the schema per tier.
Rejected — two schemas drift, and drift between stages is what the shared
reference exists to prevent.

**The unreadable-reference defect is dissolved, not patched.** Two of
thirteen verifiers could not read `confidence-rubric.md` and
`false-positives.md` at the plugin root and scored anyway. Once no subagent
needs those files, the failure mode has nowhere to occur. A fix that hard-fails
a verifier unable to load its references would have been the alternative;
it is strictly worse, because it converts a silent miscalibration into a
lost lens.

**Precision is preserved as a goal, relocated as a mechanism.**
`CLAUDE.md`'s "a false positive costs more than a miss" is unchanged. What
changes is that the claim is now enforced by the model that can see whether
a candidate is a false positive, rather than by six models that can each
see a fragment. This reinterpretation is deliberate and is written into the
spec rather than left implicit.

## Risks / Trade-offs

- **False positives could rise.** The whole point is to stop dropping real
  findings, and the same move admits more candidates to judgment →
  `measure-the-audit-tier` lands first so precision is observed on the gold
  corpus, whose clean-case tier exists to catch exactly this; the
  clean-case false-positive count is the tripwire.
- **The orchestrator becomes a single point of judgment.** A bad
  orchestrator run now degrades everything, where before six finders
  provided accidental redundancy → the redundancy was costing far more than
  it bought, and `--explain` plus the coverage ledger make an orchestrator
  failure visible in a way a silent finder veto never was.
- **Cost is uncertain in direction.** Thirteen Sonnet verifier spawns
  become evidence-gatherers rather than disappearing, while the Opus
  orchestrator does more reasoning → record cost per run and compare
  against the $9.73 anchor; if audit cost rises materially without a recall
  gain, the evidence-gathering stage is the thing to trim.
- **Removing the cap could produce very long candidate lists on large
  diffs** → consolidation and the severity floor still apply at the
  reporting stage, where they were always meant to; only the pre-emptive
  truncation goes away.

## Migration Plan

1. Land `measure-the-audit-tier` first. Without it there is no way to
   observe this change's effect, and shipping blind repeats `7f1234d`.
2. Record the pre-change audit baseline on `reviso-6` (that change's task
   5.1) and, ideally, on the two field branches once imported.
3. Land the finder and schema changes together — leaving the cap in the
   schema while telling finders not to self-gate is contradictory guidance.
4. Land the verifier demotion and the orchestrator gate in the same commit;
   a demoted verifier without an orchestrator gate has no gate at all.
5. Re-run the audit gold subset and compare candidate yield, reported
   findings, clean-case false positives, and cost against the baseline.

Rollback: the change is confined to prompt text and one reference file.
Reverting restores the previous distribution of authority; no artifact
format changes, so recorded runs stay readable either way.

## Open Questions

- Does the verifier stage stay a per-candidate fan-out, or become
  per-file — several candidates in one file share the reading work, and
  thirteen agents to read four files is waste.
- What is the right disposition of `7c9c073` ("Sharpen the precision bar")?
  Its actionability precondition — would this change's author fix it if
  they knew? — is a sound question badly placed: as a finder-level and
  verifier-level drop it is another distributed veto, but as an
  orchestrator-level scoring input it may be exactly right.
- Should the orchestrator's per-candidate score remain a 0–100 number at
  all once it is judging comparatively, or become an ordering plus a
  cutoff? Deferred: the eval matcher's calibration currently assumes the
  bands.
