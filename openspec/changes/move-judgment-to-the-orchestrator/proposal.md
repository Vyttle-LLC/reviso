# Move judgment to the orchestrator

## Why

**Reviso filters at the weakest layer and judges with the thinnest
context.** The false-positive exclusion list is applied **seven times** in
one audit run — independently by all six finders (`read and obey` →
`false-positives.md`) and again by the verifier — every application made by
a Sonnet agent seeing one keyhole of the change, all of it before the Opus
orchestrator sees anything. On top of that, finders are told to suppress:
"avoid small issues and nitpicks. Ignore likely false positives"
(`finder-bugs.md:14`), "below the bar, say nothing"
(`finder-slop.md:48`), "anything that would rank below P2 is not returned"
(`finder-slop.md:79`), "there is no P3" and "a finder returns at most 8
candidates" (`finding-schema.md:35,39`).

Filters compound. The diagnostic run on `reviso-6` produced **13 candidates
across seven lenses on a 44-file, 1953-line diff** — the dedicated
correctness lens contributed **two**. Three were reported.

**The gate destroys verified-real findings, and its structure is why.**
Two of the eight known baseline findings for that case were generated and
then killed: `match.sh` ("matches at most once" is prompt-enforced only)
scored **68**, and `extract.sh` (loud-failure cross-check greps one
phrasing) scored **40**. Both are the enforcement-vs-claim class that
`agents/reviso-finder-bugs.md:19-24` designates as Reviso's flagship —
"validation that checks shape but not the property, or a grep that matches
one phrasing of many, is a real bug even in scripts and prompts."

The rubric's own 50 band reads "relative to the rest of the change, it's
not very important." That is a comparative judgment, and a verifier handed
one finding in isolation cannot make it. The structure asks a
single-finding agent for a whole-change assessment, so it guesses low.

**A verifier that cannot read its own rubric still votes.** In the same
run, two of thirteen verifiers reported permission denied on
`confidence-rubric.md` and `false-positives.md` at the plugin root and
scored on instructions alone. One recovered only because the repository
under review happened to be Reviso and carried its own copies — no other
repository offers that fallback.

The pipeline's intelligence is concentrated at the top and its authority is
distributed to the bottom. Invert that: the subagents' value is reading
code the orchestrator should not spend context on; their harm is holding a
veto over work they cannot see the whole of.

## What Changes

- **Finders report what they find.** Remove the suppression clauses, the
  candidate cap, the no-P3 rule, and the instruction to apply the
  exclusion list. Finders still owe evidence — a `file:line`, a concrete
  failure scenario, a suggested fix — because those are what make a
  candidate judgeable, not what make it worthy.
- **Stage 4 stops being a gate and becomes evidence.** The verifier keeps
  the expensive work — read full context, walk blame, trace callers,
  attempt the failure scenario — and returns **findings of fact**: whether
  the cited lines are part of this change, what guards or callers exist,
  whether the scenario reproduces. It returns **no score, no drop reason,
  and no veto**.
- **The orchestrator judges once, with the whole change in view.** It
  applies the exclusion list, scores against the rubric, ranks, dedupes,
  and gates — the only stage that can honestly evaluate "relative to the
  rest of the change."
- **The finding schema splits format from policy.** `finding-schema.md`
  keeps the wire format every stage speaks. Reporting policy (severity
  floor, consolidation, how many findings ship) moves to the stage that
  applies it. **BREAKING** for anything that read policy out of the schema.
- **The rubric and exclusion list stop being subagent inputs**, which
  dissolves the unreadable-reference defect rather than patching it.
- **Non-goal: the 80 threshold does not move here.** The measured drops
  sit at 68 and below; nothing on this run occupied 75–79, so a threshold
  change would be motion without effect. Whether the rubric mis-scores the
  enforcement-vs-claim class is `recalibrate-the-confidence-rubric`.

## Capabilities

### New Capabilities

None. This redistributes authority across stages that already exist.

### Modified Capabilities

- `review-pipeline`: Stage 3 finders return unfiltered candidates rather
  than pre-gated ones; Stage 4 becomes a verification-evidence stage with
  no scoring authority; the confidence gate moves to the orchestrator and
  is applied once, with cross-candidate context.
- `review-command`: the reporting policy the shared schema used to carry is
  restated as a command obligation, so the single-pass tier — where the
  orchestrator is already the finder — keeps behaving exactly as it does
  today.

## Impact

- All six `agents/reviso-finder-*.md`: suppression clauses and exclusion-list
  obedience removed.
- `agents/reviso-verifier.md`: return schema loses `confidence` and
  `drop_reason`, gains structured findings of fact. Its name no longer
  describes a gate.
- `commands/audit.md`: Stage 4 rewritten as evidence-gathering; Stage 5
  gains scoring and gating; `--explain` reports orchestrator scores rather
  than verifier scores.
- `commands/review.md`: unchanged in behaviour, but restates the policy it
  used to inherit from the schema.
- `skills/reviso/references/finding-schema.md`: policy removed, format kept.
- **Report-only is unchanged.** No new write permissions.
- Repo rules: `git commit -s` (DCO required), one concern per PR,
  `markdownlint-cli2` and `lychee` must pass.
- **Sequencing: this change is not measurable until
  `measure-the-audit-tier` lands**, because no eval path currently invokes
  `/reviso:audit`. Landing it blind would repeat `7f1234d` — a pipeline
  change argued from a run of a different command.
- Resolves the disposition of `7c9c073` ("Sharpen the precision bar", held
  on `feature/termic-review-prompt`), which adds an actionability
  precondition and three further exclusion entries. It was held pending
  this diagnosis; the diagnosis points the other way.
