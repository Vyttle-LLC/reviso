# Tasks — give style its own confidence rubric

## 1. The rubric

- [x] 1.1 Write `skills/reviso/references/style-confidence-rubric.md`:
      header naming `/reviso:style` as its only user and a revision
      identifier; bands as ranges (0, 1–49, 50–79, 80–89, 90–100) per the
      spec, each defined by evidence quality; an explicit list of inputs
      the rubric does not take (importance, frequency, impact on
      functionality, senior-engineer willingness, rank against the rest
      of the change).
- [x] 1.2 State in the same file how the exclusion list's two
      importance-shaped entries read in this lane: they match only a
      candidate that fails its lens's protocol.
- [x] 1.3 Add one line to the shared `confidence-rubric.md` header: the
      style lane scores on its own rubric. No band changes there.

## 2. Wire `/reviso:style`

- [x] 2.1 `commands/style.md` Step 4: read the style rubric instead of the
      shared one; keep the exclusion-list step, adding the lens-protocol
      reading of the nitpick and general-quality entries alongside the
      existing comments/placeholder carve-out; keep the baseline check,
      the re-examination, the 80 gate, and the drop-reason set unchanged.
- [x] 2.2 `commands/style.md` Step 4 scoring sentence: "using the style
      rubric exactly as written — no stricter, no looser", and name the
      inputs it does not take, so the instruction and the reference agree.
- [x] 2.3 Confirm Step 6's bucket mapping (`80s` / `90s` / `100`) covers
      every shipping score the new bands produce; no change expected.
- [x] 2.4 `skills/reviso/SKILL.md`: list the new reference and say which
      command scores on which rubric.

## 3. Version and docs

- [x] 3.1 `CHANGELOG.md` 0.10.0 entry under Changed: what the style gate
      now measures, what it no longer takes as input, and that the 80
      threshold, reporting policy, and shared rubric are unchanged.
- [x] 3.2 `.claude-plugin/plugin.json` version 0.10.0.
- [x] 3.3 `docs/evals.md`: note that style candidate scores before and
      after 0.10.0 are not comparable, in the same place the page records
      model and CLI discontinuities.

## 4. Verification

- [x] 4.1 Re-run the three style gold case sets (2026-08-19, 2026-08-22
      reader, 2026-08-22 surface) under 0.10.0 into a new
      `eval/runs/<date>-gold-style-rubric/`; every expected-clean case
      stays silent; every labeled finding is still reported. Add the row
      to `docs/evals.md`.
- [ ] 4.2 Field funnel, before: run `/reviso:style --explain` under 0.9.0
      on at least three real branches; record per branch, numbers only:
      candidates, reported, and drops by reason (`rubric-score`,
      `no-baseline` + `no-search` + `no-quote`, `exclusion-list`,
      `pre-existing`). No diff content, finding text, or repository
      identity.
- [ ] 4.3 Field funnel, after: the same branches under 0.10.0, same
      columns.
- [ ] 4.4 Publish both funnels as one table in `docs/evals.md` with a
      one-paragraph reading: did reported rise, and where do the remaining
      drops sit. If `no-baseline` dominates after, record that the
      evidence protocols are the next change, and name the lens.
- [x] 4.5 Report-only check: no new tool in `commands/style.md`'s
      allowed-tools; the rubric is read-only reference material.
- [ ] 4.6 `markdownlint-cli2` and `lychee` with the CI globs pass; every
      commit signed off (`git commit -s`); openspec sync and archive ride
      this change's PR.
