# Tasks — measure the audit tier

## 1. The tier parameter

- [ ] 1.1 Add a required review-tier input to `eval/runners/candidate.sh`
      (env `REVISO_TIER` or a positional argument — pick one and use it
      everywhere), accepting `review` and `audit` and mapping each to its
      slash command in the `claude -p` invocation.
- [ ] 1.2 Make an absent or unrecognized tier exit with an error naming the
      accepted values, matching how `baseline.sh` refuses an unpinned
      upstream level. No default.
- [ ] 1.3 Extend the headless `--allowedTools` for the audit tier so the
      orchestrator can fan out to its finder and verifier agents, keeping
      the detector script's absolute-path grant already present.
- [ ] 1.4 Pass the tier explicitly from `gold.sh` and `sweep.sh` at every
      call site; no caller relies on an implicit value.

## 2. Tier identity in run artifacts

- [ ] 2.1 Record the tier in `candidate.sh`'s `meta.json` beside
      `cli_version` and the resolved model IDs.
- [ ] 2.2 Teach `judge.sh` to refuse a comparison whose baseline and
      candidate tiers differ, and to refuse a candidate whose tier field is
      absent — same shape as its existing CLI-version refusal, including
      the escape-hatch env var if one is kept.
- [ ] 2.3 Key `sweep.sh`'s summary aggregation by tier so recall,
      precision-proxy, and clean-case counts are reported per tier and
      never pooled; a run with no tier lands in its own visible bucket.
- [ ] 2.4 Record which corpus subset an audit sweep covered, so a partial
      sweep cannot be read as a full one.

## 3. Bound finder history access

- [ ] 3.1 In `agents/reviso-finder-history.md`, state that evidence
      reachable only through commits that are not ancestors of the change's
      head is inadmissible, and that a candidate resting solely on such a
      commit is not returned.
- [ ] 3.2 Apply the same rule to
      `agents/reviso-finder-prior-reviews.md`, covering both its `git log`
      access and prior-PR lookups that surface work merged after the head.
- [ ] 3.3 Mirror the rule in the shared harness reference so both commands
      cite one copy rather than drifting
      (`skills/reviso/references/`), and note the eval rationale in one
      sentence.

## 4. Spec sync

- [ ] 4.1 Apply the `gold-eval` delta: tier-parameterized candidate leg,
      explicit-tier requirement, per-tier metrics.
- [ ] 4.2 Apply the `parity-eval` delta: renamed replay requirement,
      tier-parameterized candidate, cross-tier comparison refusal.
- [ ] 4.3 Apply the `review-pipeline` delta: finder history bounded by the
      change under review.

## 5. The audit-tier baseline

- [x] 5.1 Commit the hand-produced `reviso-6` audit run under `eval/runs/`
      with its raw output, parsed findings, cost, and the `--explain`
      candidate table (13 candidates → 3 reported; scores 90/88/85 reported,
      68/60/52/40/40 rubric-dropped, 20/10/0 exclusion, 5/5 pre-existing).
      Landed as `eval/runs/2026-08-13-reviso-6-audit-v040/`, ahead of this
      change, so the baseline exists before anything can move it.
- [x] 5.2 Write its `meta.json` to record provenance honestly: produced by
      hand at v0.4.0 before the runner existed, tier and case fields
      asserted rather than machine-recorded, CLI 2.1.232.
- [ ] 5.3 Produce the first runner-generated `/reviso:audit` gold run on
      `reviso-6` and record it alongside; note any divergence from the
      hand-produced run rather than reconciling it away.

## 6. Documentation

- [ ] 6.1 Update `eval/README.md`: the candidate leg names a tier, what
      each tier costs, and which subset the audit sweep covers.
- [ ] 6.2 Update `docs/evals.md` to attribute every existing published
      number to the review tier explicitly, so the 48% figure stops reading
      as "Reviso's recall", and add the audit-tier baseline row.
- [ ] 6.3 State in both that pre-existing artifacts carry no tier field and
      are therefore non-comparable under the new judge rule.

## 7. Verification

- [ ] 7.1 Re-run one in-repo gold case on the review tier after the history
      bound lands and confirm the affected lenses still return candidates —
      the bound must not silence them outright.
- [ ] 7.2 Confirm a cross-tier judge invocation is refused, and that a
      pre-existing artifact is refused for a missing tier.
- [ ] 7.3 Confirm the report-only invariant still holds on an audit-tier
      run: `candidate.sh`'s pre/post tree comparison passes unchanged.
- [ ] 7.4 `markdownlint-cli2` and `lychee` pass; every commit signed off
      (`git commit -s`).
