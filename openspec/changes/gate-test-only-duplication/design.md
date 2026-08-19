# Design — gate test-only duplication

## Context

The duplication bar (review-pipeline spec, "calibrated bar" requirement)
currently ends with "test code counts" on every surface. Post-0.5.0, the
gate architecture is: finders report everything; `/reviso:review` and
`/reviso:style` self-verify against the shared exclusion list; the audit
orchestrator applies the same list. The exclusion list is therefore the
one place a suppression rule reaches all three verbs.

## Goals / Non-Goals

**Goals:** test-only duplication stays silent in repos that never asked
for DRY tests, and still ships in repos whose written conventions demand
shared helpers. Deterministic, repo-relative, one encoding.

**Non-Goals:** changing the bar for production or mixed duplication;
changing what the audit's finder returns; inferring conventions from
code (see D2).

## Decisions

### D1 — Convention gate, not blanket exemption

All-test-code duplication ships only when a written convention governing
the changed paths demands shared test helpers. Sage Haven's sh-904 case
(no written rule) goes silent; termic's e2e case (skill doc rule) still
ships. Blanket exemption was rejected because it loses the latter, and
keep-as-is was rejected because contested style is taste, and precision
over recall decides taste against shipping.

### D2 — Written rules only

A demonstrated helper idiom in the same file (sh-904's tests had a
`_make_service()` helper) does not open the gate. Inference from code
reintroduces the judgment call the gate exists to remove; written-only
keeps the outcome predictable and the evidence quotable. The drift lens
remains free to cite demonstrated norms for *non-duplication* findings —
this decision is scoped to the duplication item.

### D3 — Encode at the exclusion list; align the two self-gating prompts

The rule lands once in `false-positives.md` (scored 0–25 at every gate).
`review.md` and `style.md` rewrite their "Test code counts" sentence to
the gated version so lens text and gate agree. The slop finder keeps
returning test-only candidates unmodified — finders don't gate, and the
orchestrator needs the candidate to apply the exclusion. "Test code
counts" remains literally true at the finder: it counts as a candidate.

### D4 — Test code is what the repo treats as test code

Test paths/files are identified by the repo's own layout and naming
(`tests/`, `*_test.*`, `*.e2e.*`, `spec/` …) — the same judgment the
severity and triage stages already make. No new path taxonomy.

## Risks / Trade-offs

- [A repo with strong-but-unwritten DRY-test culture loses findings] →
  the miss is cheap (their reviewers already enforce it) and the fix is
  theirs: write the rule down, and the findings return.
- [Fourth copy of duplication-lens text drifts] → no new copy is added;
  the two command prompts change in lockstep here, and VYT-152 (extract
  the shared lens text) remains the structural fix.

## Migration Plan

Additive suppression; no schema or flag changes. Revert = drop the
exclusion entry and restore the two sentences.

## Open Questions

None.
