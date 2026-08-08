# Design — import-crb-corpus

## Context

`re-aim-parity-eval` fixed what the harness measures (built-in medium,
correctness tier, identity-carrying runs) but not its scale: one public
case, and a per-case cost dominated by three baseline `/code-review` runs.
reviso-api's eval (retired with the API approach) imported
`withmartian/code-review-benchmark` (MIT): 50 real-PR fixtures with
`gold_issues` (165 total) and `expected_clean` flags, tagged by language
and difficulty, plus 13 synthetics. Fixtures store inline patches; the
plugin-based Reviso needs real checkouts, so import means re-pinning the
underlying PRs to SHAs (verified feasible: old merged PRs still expose
`baseRefOid`/`headRefOid`).

Two labeled private cases (sagechat-15, sagechat-watchos-202) taught us:
upstream medium's precision is high-variance, so parity numbers alone are
a noisy quality signal; and hand labels are the scarce resource — CRB's
gold labels are 165 more of them, free.

## Goals / Non-Goals

**Goals:**

- Public corpus: 1 → ~50 SHA-pinned, gold-labeled entries.
- A gold-mode runner cheap enough to run on every meaningful pipeline
  change (candidate-only; no baseline invocations).
- One labels schema shared by hand-labeled private cases and imported
  gold cases, so tier calibration uses both.
- Clear metric separation in published docs: gold recall/precision (whole
  corpus, per release) vs parity-vs-medium (active subset, per re-baseline
  event).

**Non-Goals:**

- No OWASP import (single-file Java security benchmark — wrong shape).
- No baseline runs on the imported cases beyond the active parity subset.
- No changes to the Reviso pipeline itself; this measures, it doesn't fix
  (the slop-lens gap in #9 is separate work this suite will then detect).
- No re-hosting of CRB PR diffs or upstream code in this repo — corpus
  entries stay pointers (repo/PR/SHAs) plus labels derived from CRB's
  MIT-licensed golden comments.

## Decisions

### D1 — Import re-pins PRs; fixtures' inline patches are not the review substrate

The importer reads each CRB fixture only for identity (source repo, PR
number) and labels. The review substrate is a real clone at the pinned
SHAs, same as every other corpus entry — Reviso's finders want git
history, project config, and sibling files, and the parity subset needs
what `/code-review` needs. Fixtures whose PR can't be resolved to SHAs
anymore are skipped with a loud line in the import report (expectation:
near-zero, verified on cal.com#8087). Alternative — replaying inline
patches in a synthetic repo — rejected: it silently disables the history/
conventions/cross-file lenses on both sides.

### D2 — Gold labels go through the same tiering as everything else

CRB golden comments mix real bugs with style/process notes (observed:
`error-handling` "consider try-catch" at severity low next to genuine
async-forEach and negative-slicing bugs). The importer maps
`gold_issues.category`/`severity` into the harness label schema and the
judge's existing correctness/cleanup tiering applies verbatim: gold recall
is scored on correctness-tier gold issues; cleanup-tier gold issues are
informational, exactly as in parity mode. Severity `low` does not
auto-demote — tier comes from category, ambiguity resolves to
correctness (same fail-loud rule).

### D3 — Gold mode reuses the parity judge, swapping the baseline for labels

`gold.sh <workdir> <case> <outdir>` = `candidate.sh` (unchanged) + a
judge invocation where the "baseline" side is the case's labels file.
`match.sh` already does root-cause matching of two findings lists; labels
are findings. New metrics emitted by the judge in gold mode:
`gold_recall_correctness` (matched correctness-tier gold / total),
`precision_proxy` (candidate findings matching any gold issue ÷ all
candidate findings — labeled a proxy: unmatched candidate findings may be
real-but-unlabeled, the same claimed-wins caveat parity mode has), and
`clean_case_fp_count` (any finding on an `expected_clean` case is a false
positive, no judge call needed). Alternative — a separate gold judge —
rejected: two matchers means two calibrations.

### D4 — Labels live in-repo for the public tier, with CRB attribution

`eval/corpus/labels/<case-id>.json`, same schema as the private labels
files (minus hand-verdict fields; gold labels carry
`origin: "code-review-bench"` instead of `labeled_by`). CRB is MIT: its
LICENSE is vendored beside the labels dir with a provenance note
(upstream repo, import date, transformation applied). Private-tier labels
stay outside the repo as before — one schema, two homes, and the tier
calibration harness may consume both.

### D5 — `active_parity` is data, not a separate file

Corpus entries gain an optional boolean `active_parity`. The importer
marks a spread of ~12 cases (per-language and per-repo coverage, mix of
difficulties, at least 2 expected-clean); everything else defaults false.
Baseline/parity tooling filters on it; gold mode ignores it. Selection is
editable by hand afterward — it's corpus data, not code.

### D6 — Synthetics import as diff-only cases, marked so runners can skip

The 13 synthetic fixtures have no upstream repo to pin. They import with
`synthetic: true` and an inline-diff pointer; gold mode materializes them
into a throwaway git repo (init + apply patch + commit) so the candidate
still reviews a real checkout, with the known limitation that
history/conventions lenses see a bare repo. Parity tooling skips
synthetics. Cheap to include, and the clean-* ones are the best
silence-discipline smoke tests we have.

## Task 1.1 audit record (2026-08-06)

- **Identity**: all 50 CRB fixtures carry a full PR URL in `source_id`
  (upstream repos for cal.com/grafana/keycloak/sentry; the
  graphite/greptile sets live in `ai-code-review-evaluation/*` mirror
  repos as real open PRs). 9/9 sampled across every repo family resolve
  to base/head SHAs via `gh pr view`.
- **Category → harness mapping** (original kept as `crb_category`):
  `bug` → `correctness`, `security` → `security`, `error-handling` →
  `robustness`, `performance` → `efficiency`. Under the judge's tiering,
  the first three land correctness-tier, `efficiency` lands cleanup-tier —
  no `CLEANUP_RE` change needed.
- **Anchor quality**: gold `file` is often `*` (map → null) and `line`
  often null (map → 0); matching is root-cause-based so this is
  acceptable, but per-line anchor metrics are off the table.
- **Expected-clean**: zero CRB cases are expected-clean (the suite's 24
  clean cases were synthetic/OWASP). Spec amended: the parity subset drops
  the ≥2-clean clause; clean discipline lives in gold mode's synthetics.

## Risks / Trade-offs

- [CRB gold labels may be incomplete or stale relative to what a modern
  reviewer finds] → precision is explicitly a proxy; genuinely-real
  unmatched findings can be promoted into the labels file via the
  eval-candidate intake, with `origin: "hand"` distinguishing them.
- [Gold recall could be gamed by tuning to CRB's comment style] → the
  private hand-labeled cases and the parity subset stay in the loop; a
  release is judged on all three numbers, not gold alone.
- [Large upstream repos (grafana, keycloak) make clones slow] → clone
  cache under `eval/.cache/` (already gitignored) keyed by repo, fetch
  SHAs into it; document disk expectations in the corpus README.
- [Old PRs' code may reference dead APIs, tempting the reviewer into
  flagging staleness] → both modes review the diff at its
  contemporaneous SHAs; the judge's existing conservative matching keeps
  anachronism findings in the unmatched bucket, visible but not fatal.
- [Two metric families could confuse published docs] → docs/evals.md
  gets a metrics glossary distinguishing gold (absolute, whole corpus)
  from parity (relative, active subset, re-baseline-gated).

## Migration Plan

1. Land importer + labels + corpus entries (no runner changes needed to
   merge safely).
2. Land gold.sh + judge gold path; smoke on 2 cases (one with gold
   issues, one expected-clean) + 1 synthetic.
3. First full gold sweep; record in docs/evals.md as the new per-release
   number. Parity subset runs on the existing re-baseline cadence.

Rollback: corpus entries and labels are additive data; runners are new
files. Reverting is deletion.

## Open Questions

- Whether `import-crb.ts` ports to POSIX sh + jq like the other runners
  or stays a small TS script run via npx (leaning sh for zero-dep
  consistency; the fixture JSON is simple).
- Whether gold-mode precision should eventually gate releases or stay
  informational until the labels have been hand-audited once.
