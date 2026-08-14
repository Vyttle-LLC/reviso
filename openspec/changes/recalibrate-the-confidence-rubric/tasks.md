# Tasks — recalibrate the confidence rubric

Prerequisite: `move-judgment-to-the-orchestrator` is landed and its task
6.2 has reported. This change's delta is written against that change's
version of the gate requirement and must not land before it.

## 1. Decide whether the rest of this change is needed

- [ ] 1.1 Read task 6.2's result: did `match.sh` (68) and `extract.sh` (40)
      recover on `reviso-6` from the gate relocation alone?
- [ ] 1.2 If both recovered, reduce this change to section 5
      (documentation of the fork) and close the remainder with the
      measurement recorded as the reason.
- [ ] 1.3 If either did not, continue — and record the post-relocation
      scores, since they are the new baseline the band revision must move.

## 2. Revise the bands

- [ ] 2.1 Add an explicit band for verified contract and enforcement
      defects to `skills/reviso/references/confidence-rubric.md`: a stated
      guarantee (in code, comment, prompt, or config) that the
      implementation does not deliver, with the gap demonstrated.
- [ ] 2.2 State that such a defect is not scored down for firing rarely,
      and is not required to read as critical to functionality — its cost
      is that the guarantee is false whenever relied upon.
- [ ] 2.3 Separate realness and importance into distinct inputs with an
      explicit combination rule, so the two stop resolving to one middling
      number.
- [ ] 2.4 Keep the 0–100 shape and the 80 threshold unchanged.
- [ ] 2.5 Add a rubric revision identifier to the file.

## 3. Resolve the held actionability work

- [ ] 3.1 Review `7c9c073`'s actionability precondition and its three
      exclusion-list additions against the diagnosis.
- [ ] 3.2 Keep whatever survives as an orchestrator scoring input, not as a
      finder-level or verifier-level drop.
- [ ] 3.3 Record the disposition of the rest, and clear
      `feature/termic-review-prompt` of the held commit one way or the
      other.

## 4. Rubric revision as run identity

- [ ] 4.1 Record the rubric revision in run metadata alongside CLI version,
      resolved model IDs, and review tier.
- [ ] 4.2 Teach `judge.sh` to refuse comparisons across differing rubric
      revisions, and to refuse a run whose revision is absent.
- [ ] 4.3 Mark the existing calibration stale, and re-check the judge
      against the calibration labels under the new bands before publishing
      any parity figure.
- [ ] 4.4 Check whether `skills/reviso/feedback/build-payload.sh`'s
      `oneof --confidence 80s 90s 100` still covers every score the new
      bands can produce; it hard-fails on an out-of-set value, and the
      bucketing instructions in both commands must agree with it.

## 5. Documentation

- [ ] 5.1 State in the rubric which bands are inherited from the reference
      recipe and which are Reviso's own, so the fork is legible.
- [ ] 5.2 Update `skills/reviso/SKILL.md`, which currently describes the
      rubric as forked from the official plugin.
- [ ] 5.3 Publish the discontinuity in `docs/evals.md`: numbers before and
      after the band change are not comparable, and say why.

## 6. Verification

- [ ] 6.1 Re-run the audit gold subset; confirm the two known regressions
      clear the gate.
- [ ] 6.2 Confirm clean-case false positives did not rise — the tripwire
      for admitting a class that should have stayed out.
- [ ] 6.3 Confirm a cross-revision judge comparison is refused.
- [ ] 6.4 `markdownlint-cli2` and `lychee` pass; every commit signed off
      (`git commit -s`).
