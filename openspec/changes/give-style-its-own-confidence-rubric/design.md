# Design — Give style its own confidence rubric

## Context

`/reviso:style` self-verifies every candidate in Step 4 against the shared
`confidence-rubric.md` — a verbatim fork of the reference recipe's step-5
scale, whose bands measure whether a PR comment on product code is worth
posting: will it be hit in practice, does it matter to functionality. The
style lenses already carry their own precision mechanism: each one names
the evidence a candidate must produce (two same-language `file:line`
examples for drift, naming, error handling, type slop, over-engineering;
comparable units for length; a quoted tell; a recorded search; every
lockstep write site). Step 4's baseline check zeroes anything without it.

So a style candidate reaching the rubric has already proved it is real
and callable. The rubric then asks a second question the lane has no
answer to — how important is it to functionality — and the honest answer
for nearly every style finding is the 50 band. Gate is 80.

Constraints: the 0–100 shape is spoken by `--explain`, the feedback
payload's buckets, and the gold judge; the sibling
`recalibrate-the-confidence-rubric` is editing the shared rubric for the
review/audit pipeline and must not be coupled to this; the corpus cannot
measure the field yield (seeded cases score 85+ under either rubric), so
acceptance needs a field instrument.

## Goals / Non-Goals

**Goals:**

- A verified style finding with a concrete fix ships at P2 without having
  to read as bug-shaped.
- Confidence in the style lane measures one thing — evidence quality —
  so the number is legible: 85 means "the protocol is satisfied and it
  holds against the code", never "real but I decided it doesn't matter".
- Precision holds: expected-clean gold cases stay silent; the change
  admits no candidate that failed its lens's protocol.
- A numbers-only field funnel that tells gate-too-high from
  lenses-not-generating, and decides whether the evidence protocols need
  their own follow-up.

**Non-Goals:**

- Moving the 80 threshold. The problem is what the number measures, not
  where the line is; a lower line on the old rubric re-admits "couldn't
  verify" alongside "verified but minor".
- Loosening any lens's evidence protocol. If the funnel shows
  `no-baseline` dominating, that is a separate change with its own
  evidence.
- Touching the shared rubric, the review/audit gate, or the exclusion
  list file.
- Changing reporting policy (P2 floor, cap 8, consolidation, silent
  drop).

## Decisions

**A separate rubric file, not a style section in the shared one.** The
shared rubric is under revision by the sibling change, which keeps
importance as a scoring input and combines two axes by rule — correct for
bugs, where "matters" is a real question. Style's answer is structurally
different: no importance axis at all. Putting both in one file would
couple two changes with different evidence and make either regression
unattributable, which this project has already paid for. Each file states
its scope in its header so a reader knows which command scores on which.

**Confidence measures evidence quality only.** Alternatives considered:
(a) lower the gate to ~60 on the shared rubric — rejected, because the
50–79 band on that rubric mixes "verified but minor" with "could not
verify", and the second class is exactly what the gate exists to stop;
(b) a two-axis score like the sibling's — rejected, because the second
axis (importance) has no legitimate value in this lane: the lens protocol
already decided the candidate is callable, and severity already says how
much it misleads. The rubric names the inputs it does not take —
importance, frequency, "would a senior engineer bother", how the
candidate ranks against the rest of the change — so a scorer cannot
smuggle the old bands back in.

**Bands as ranges, with a revision identifier.** The recipe's point
anchors (0/25/50/75/100) sit awkwardly around an 80 gate — nothing
naturally lands at 80–89. Ranges map the gate onto a stated boundary:
80–89 is "protocol satisfied, verified against the code, baseline
unambiguous, fix concrete"; 90–100 adds text-grade evidence (a written
convention, a lint rule, an existing helper cited by `file:line`, a
verbatim quote of the tell); 50–79 is "verified, but the baseline is
thin or the fix is arguable"; 1–49 is "protocol met on paper, evidence
does not survive re-examination"; 0 is the existing gates (exclusion
list, pre-existing, protocol unmet). The feedback payload's `80s` /
`90s` / `100` buckets cover everything that ships unchanged.

**The exclusion list is read through the lens protocols.** Two entries
are importance-shaped: "pedantic nitpicks that a senior engineer wouldn't
call out" and "general code quality issues (…poor documentation) unless
explicitly required in CLAUDE.md". Left as written they re-import the
importance axis through the side door and would zero most comments-lens
findings. The style command already carves the deliberate-style entry out
for comments and placeholder text; this extends the same mechanism: in
this lane those two entries match only a candidate that fails its lens's
protocol. The shared file is unchanged, so the review/audit surfaces keep
their reading.

**Volume control is the reporting policy, not the gate.** With more
candidates surviving, the P2 floor, consolidation of related findings,
and the cap of 8 most-severe-first are what keep the report short. They
exist for exactly this and were never reached while the gate ate
everything.

**Acceptance is a field funnel plus the gold tripwire, because the corpus
is blind.** Seeded style cases score 85–100 under either rubric, so a
gold sweep can only show precision held (clean cases silent) — it cannot
show recall moved. The instrument for recall is `--explain` on real
branches: candidates, reported, drops by reason, before and after,
numbers only in `docs/evals.md`. If the after-funnel still shows one
finding per run with drops concentrated in `no-baseline`, the diagnosis
was wrong about where the loss is, and the follow-up is the evidence
protocols, not this rubric.

## Risks / Trade-offs

- **Recall rises and the report fills with true-but-unwelcome P2s** →
  the cap of 8 most-severe-first and consolidation bound the volume; the
  field funnel records reported counts so the effect is visible, and the
  P2 floor already excludes what the lane calls a nit.
- **Scorers keep the old habit and score importance anyway** → the
  rubric lists the forbidden inputs explicitly, and `--explain` prints
  every score with its disposition, so a run that drops a
  protocol-satisfying candidate at `rubric-score` is diagnosable.
- **Two rubrics drift apart in what "80" means** → each file's header
  states its command and its axis; the style command cites only its own;
  the shared one's header says the style lane does not use it.
- **A candidate that satisfied its protocol but is genuinely
  pointless ships** → the protocol is where that judgment lives; if a
  lens admits pointless findings, the fix is that lens's definition, and
  the funnel will show which lens.
- **Style gold scores before and after are non-comparable** → correct
  and published: `docs/evals.md` marks the discontinuity, as it does for
  model and CLI rolls.

## Migration Plan

1. Add the rubric file; point `commands/style.md` Step 4 at it; update
   `SKILL.md`, changelog, version.
2. Re-run the three style gold sweeps (0.7.0, 0.8.0, 0.9.0 case sets)
   under 0.10.0; expected-clean cases must stay silent.
3. Run `--explain` on at least three real branches under 0.9.0 and again
   under 0.10.0; record the funnel table, numbers only.
4. Publish both in `docs/evals.md` with the non-comparability note.

Rollback: revert the Step 4 pointer; the shared rubric is unchanged, so
0.9.0 behavior is one edit away. The rubric file can stay or go.

## Open Questions

- If the after-funnel shows `no-baseline` as the dominant drop, which
  lens's protocol is too expensive on real repos — and is the fix a
  cheaper protocol or a smaller repo-size floor below which the lens
  records `skipped`?
- Should `/reviso:review`'s slop lens score its style-shaped candidates
  on this rubric too? Deferred: that lane mixes bug and style findings in
  one report and the sibling change owns its gate.
