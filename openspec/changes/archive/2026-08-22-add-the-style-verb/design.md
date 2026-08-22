# Design — add the style verb

## Context

Reviso ships two verbs: `/reviso:review` (single-pass, opus, the inner
loop) and `/reviso:audit` (multi-agent pipeline, the pre-PR gate). The
style/slop judgment the user actually wants on its own — AI slop, drift
from repo norms, comment bloat, oversized methods, duplication — exists
only as lenses inside those verbs: the anti-slop lens in `review.md` and
the `reviso-finder-slop` / `reviso-finder-conventions` agents in the
audit. There is no way to run just that pass.

The shared harness is mature and reusable as-is: deterministic mock-PR
assembly (mock-pr-assembly spec), the finding schema, the confidence
rubric with its drop-below-80 gate, the false-positive exclusion list,
and the zero-token detector suite. Commands are auto-discovered from
`commands/`, so a new verb is one new file plus spec deltas.

Decisions already made by the user: the verb is named **`style`**
(`/reviso:style`), and it is **single-pass** — no subagents.

## Goals / Non-Goals

**Goals:**

- A `/reviso:style` verb that reviews `base..HEAD` + uncommitted changes
  through style lenses only, cheap enough to run casually.
- Every finding calibrated against the repo's own norms, with the baseline
  cited — this is the differentiation from `/code-review`, which judges
  against general standards.
- Full reuse of the shared harness; the precision-over-recall invariant
  and report-only contract hold unchanged.

**Non-Goals:**

- No bug hunting of any kind — no bugs, history, or code-comment-compliance
  lenses. The command's report points users at `/reviso:review` /
  `/reviso:audit` for that.
- No changes to `/reviso:review`, `/reviso:audit`, or the finder agents.
- No new deterministic detectors (length/comment metrics are
  judgment-relative by design — see D3).
- No eval-corpus work beyond noting the gap; measuring the style verb is
  its own future change.

## Decisions

### D1 — Single-pass on the `opus` tier alias

The command mirrors `review.md`'s architecture: one session assembles the
mock PR, runs the detector suite, applies the lenses itself, self-verifies
against the rubric, reports. Pinned to `model: opus`, same as
`/reviso:review`.

- *Why opus, when cheap was the point:* the trust gate (rubric scoring,
  drop-below-80) runs in the same session as finding generation. Style
  findings are the most taste-adjacent thing Reviso ships; precision over
  recall is the plugin's first invariant, and the gate is where it lives.
  Cost stays below a `/reviso:review` run anyway because the scope is
  narrower — no bug/history lenses, no blame archaeology.
- *Alternative considered:* `sonnet` (the tier the audit's slop finder
  runs on). Rejected: in the audit, sonnet finders are deliberately
  ungated — an opus orchestrator and verifier judge their output. Here
  there is no second pair of eyes.

### D2 — Five lenses, three reused and two new

| Lens | Source |
| --- | --- |
| Anti-slop (P0 set: pattern drift, ~3× verbosity, reimplemented utilities, comment slop) | Reused verbatim from `review.md`'s anti-slop lens |
| Duplication (4+/3-with-a-rule/≤2-never bar) | Reused verbatim from `review.md` |
| Conventions (CLAUDE.md / AGENTS.md / lint configs, code-shaped rules only) | Reused from `review.md`, minus its branch-shape and doc-staleness clauses (process review, not style) |
| **Repo-style drift** | New — see D3 |
| **Outlier length** (methods and comments) | New — see D3 |

### D3 — New lenses cite the baseline, never a threshold

The two new lenses answer "comment length, method length, code style by
looking at the repo" without becoming a linter:

- **Repo-style drift**: before flagging, the reviewer must locate how the
  repo already writes this kind of code — naming, error-handling shape,
  module layout, test structure — and cite at least two existing examples
  by `file:line` in `evidence`. No cited baseline, no finding. This
  extends the conventions lens from *written* rules (CLAUDE.md) to
  *demonstrated* ones.
- **Outlier length**: a method or comment is flagged only as an outlier
  against comparable units in this repo — the finding must name the
  comparable functions/comments it was measured against and their rough
  sizes. Absolute thresholds ("functions over 50 lines") are banned: they
  are linter territory per the false-positive exclusion list, and any
  fixed number would be someone else's taste.

*Why citation over computation:* a deterministic length metric (percentile
over the repo) sounds rigorous but produces exactly the FP class the
detector suite's DISCOVERY.md rejected — repo-relative judgment calls
dressed as mechanical facts. The citation requirement keeps the evidence
quotable, which is what the verifier rubric and the exclusion list are
built around.

### D4 — Full harness reuse, including the detector pass

Step 1 assembly is byte-identical to `review.md` (same git sequence, same
`--base` / `--out` / `--explain` flags, same coverage ledger). The
deterministic detector suite still runs — it is free, and its hygiene
findings (committed conflict markers, focused tests) are closer to style
than to bugs. Finding schema, rubric, exclusion list, dedupe rules, the
P2 floor, and the 8-finding cap all apply unchanged.

*Alternative considered:* a slimmer assembly without commit-message intent
collection. Rejected: stated intent legitimately clears style findings
("port kept verbatim from X" clears a drift flag), and divergence from the
shared assembly spec would fork mock-pr-assembly for no savings.

### D5 — Severity stays in slop's existing band

Style findings are P2 by default, P1 only when the finding actively
misleads (wrong comment, shadowed utility with different behavior) or
duplicated copies have already diverged — the same band
`reviso-finder-slop` uses today. The style verb never emits P0: nothing
purely stylistic blocks a merge. Deterministic detector findings keep
their own severities.

### D6 — Lens text is duplicated from review.md, not extracted

The P0 slop set now lives in three prompts (slop finder, `review.md`,
`style.md`). That is real drift risk, but extracting a shared
`references/style-lenses.md` would rewrite `review.md` and re-test the
existing verb inside this change — a second concern in the PR. The repo
already accepts this duplication between the finder and `review.md`;
this change adds one more copy and logs the extraction as the natural
follow-up (see Open Questions).

### D7 — review-command spec delta, not a parallel spec universe

`/reviso:style` is a third review command: it inherits the report-only
contract, the base..HEAD-plus-uncommitted scope, and the finding shape
that `review-command` already specifies. The delta updates the roster
requirement ("two tiers" → three verbs, each report pointing to the right
sibling for out-of-scope concerns) and generalizes the cross-command
contracts — scope, report-only, `--explain` — from "both commands" to
"every review command", so they bind the style verb directly instead of
being duplicated into its spec. `style-command` carries only what is
style-specific: the lenses, the calibration rules, the severity cap, and
the harness reuse.

## Risks / Trade-offs

- [Style is taste-adjacent; FP rate could sink trust in the whole plugin]
  → the citation requirements in D3 make every finding carry quotable
  repo evidence; the rubric gate drops sub-80 candidates; the P2 floor
  and 8-finding cap bound the noise even on a bad day.
- [Three copies of the slop-set text drift apart] → D6 accepts this
  knowingly; the follow-up extraction is logged, and the spec (not the
  prompts) remains the source of truth for the bar itself.
- [Overlap with `/reviso:review`, which already runs the anti-slop lens —
  users may see the same finding from both verbs] → intended: the verbs
  are entry points, not partitions. The style report says so ("review
  covers these lenses too, plus bugs").
- [No eval coverage at launch — precision of the new lenses is asserted,
  not measured] → mitigated only by reuse of measured components (rubric,
  exclusion list); accepted for this change and named in Open Questions.

## Migration Plan

Additive: one new command file plus spec updates, no behavior change to
existing verbs. Rollback is deleting `commands/style.md` and reverting
the spec delta. Version bump in `.claude-plugin/plugin.json` (minor —
new capability, no breaking change) and a CHANGELOG entry.

## Open Questions

- **OQ1 — Lens extraction**: after the verb settles, extract the shared
  P0 slop-set text into `skills/reviso/references/` and point all three
  prompts at it. Deliberately deferred (D6).
- **OQ2 — Measuring the style verb**: the eval corpus has no
  style-labeled cases, so the verb launches unmeasured. Needs its own
  change: seed cases where ground truth is "a maintainer agreed this was
  slop/drift" (e.g., style feedback from real PR reviews).
