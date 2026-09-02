# Eval corpus

One JSONL entry per case. For parity cases both tools review the identical
`base..head` range, so comparison is apples-to-apples; gold cases are
judged against their labels file instead.

## Entry schema

```json
{"id": "repo-shortname-123", "repo": "owner/name", "pr": 123, "base_sha": "<full sha>", "head_sha": "<full sha>", "clone_url": "https://github.com/owner/name.git", "language": "go", "active_parity": false, "labels": "labels/<id>.json", "notes": "why this PR earns a corpus slot"}
```

- `base_sha` / `head_sha` are pinned at corpus-entry time — PR branches move;
  SHAs don't. Recorded from `gh pr view <n> --json baseRefOid,headRefOid`.
- `labels` (optional) points at the case's gold labels relative to this
  directory; cases without labels are parity-only.
- `active_parity: true` opts the case into parity sweeps (baseline runs
  cost real money; gold mode ignores the flag and runs everything).
- Synthetic cases carry `synthetic: true` and a `fixture` pointer instead
  of repo/PR/SHAs — they are **gold-mode-only**; parity tooling refuses
  them (`sweep.sh` errors rather than skipping quietly).
- `notes` says what the case exercises (a known bug it introduced, a slop
  pattern, a clean case that tests the silence discipline).

## Hand-authored gold cases

`termic-162` — [simion/termic#162](https://github.com/simion/termic/pull/162),
the duplication lens's seed exemplar and the corpus's **only**
`duplication`-category label. Upstream is AGPL-3.0; the entry is a pointer
and the label is our own prose, so nothing upstream is vendored (see
`labels/PROVENANCE.md`). Gold-only — `active_parity: false`.

It is an in-lane case: `duplication` is not in the cleanup family
(`eval/runners/tiers.sh`), so a miss here counts against
`gold_recall_correctness` and is listed individually rather than reported
informationally.

## Style-lens gold cases (synthetic)

The `slop-*` cases (23) measure `/reviso:style`'s sixteen lenses: eleven
true-positive / expected-clean pairs, one per lens added since 0.6.0 —
over-engineering, dead weight, comments, test slop, AI tells (authored
2026-08-19), derived state, naming, error handling, stale docs, surface
area, type slop (authored 2026-08-22)
— plus `slop-multilens-001`, one fixture planting ten findings across
seven lenses that must consolidate to the eight its label lists, most
severe first: the only case that exercises dedupe, the 8-finding cap,
and ordering under load. Findings are category `slop` (in-lane, so
misses count against `gold_recall_correctness`); each clean look-alike
guards the matching lens's precision (a mocked *dependency* vs a mocked
subject, a genuinely nullable value vs a dead defense, a repo that
really does name its services `*Manager`, and so on).

Fixture files carry a `status`: `added` files are the change under
review; `context` files are committed into the throwaway repo's base
first, so a convention-relative lens has an existing same-language
baseline to cite (the naming and error-handling pairs need one — without
it the TP has no norm to diverge from and the clean case nothing to
match). A fixture with no `context` files reviews against an empty base,
as before. A filename listed as both `context` and `added` is a
*modified* file: the `added` entry's full content overwrites the base
copy, so the working diff is the edit (the stale-docs pair renames a
flag this way while its README stays unchanged).

The command's report renders its sixteen ledger rows by lens family
(shape, text, reuse, tests, plus deterministic); the gold judge reads
findings, not the coverage block, so the family rendering is checked in
the field smoke, not here.

## Best-practices gold cases (synthetic)

The `bp-*` pair measures `/reviso:style`'s opt-in best-practices lens
(`docs/web.md`, moved from the audit in 0.13.0): `bp-deprecated-api-001` calls `datetime.utcnow()` under a
`context` `pyproject.toml` requiring Python `>=3.12`, where the official
docs deprecate it; `bp-deprecated-api-clean-001` is the look-alike on
`datetime.now(timezone.utc)`. Findings are category `best-practices`,
which `tiers.sh` treats as in lane **only when `REVISO_CMD_ARGS` contains
`--web`** — without the flag the lens never runs, the pair is out of
lane, and every flag-less gold run is unchanged. The label matches
on class, file, and line only: the network is live, so the quoted
passage is not part of the label.

**Style-tier gold runs are meaningful only against style-labeled or
expected-clean cases.** Running `REVISO_TIER=style` over a bug-labeled
case scores zero recall by design — the style lane hunts no bugs — and
says nothing about either product. The inverse holds too: review/audit
tiers are not measured against the `slop-*` cases.

## Imported gold cases (CRB)

50 entries came from `withmartian/code-review-benchmark` via
`import-crb.sh <fixtures-dir>` (re-run is idempotent): real PRs in
calcom/cal.com (ts), grafana/grafana (go), keycloak/keycloak (java),
getsentry/sentry (py), and the `ai-code-review-evaluation/*` mirror repos
(ruby + extra java/py), each with gold labels under `labels/` — see
`labels/PROVENANCE.md` for license and the category mapping. 13 synthetic
cases (5 expected-clean) came from `import-synthetics.sh`; their
reviewable content lives under `synthetic/`.

### The active_parity subset (12)

Chosen for per-language and per-repo spread with a mix of gold densities:
3 typescript (cal.com 8087/14740/22345), 3 go (grafana
79265/94942/103633), 2 java (keycloak 38446, keycloak-greptile-1),
2 python (sentry 67876, sentry-greptile-1), 2 ruby (discourse-graphite
1/4). No CRB case is expected-clean (task-1.1 audit), so clean-case
discipline is covered by gold mode's synthetics, not this subset. Edit
the flags in `public.jsonl` to change the subset — it's corpus data, not
code.

## Tiers

- **Public** — `public.jsonl` in this directory, committed. OSS PRs (and/or
  seeded-bug PRs, OQ4). Published runs in `docs/evals.md` come from this
  tier only.
- **Private (Vyttle)** — a JSONL of the same schema outside this repo,
  referenced via `REVISO_EVAL_PRIVATE_CORPUS`
  (default `~/.config/reviso-eval/private.jsonl`, per the Vyttle
  outside-the-repo config convention). No entry, diff content, or finding
  text from it ever lands in this repository; its run artifacts go to
  `eval/runs/private/` (gitignored).

## Intake

Issues labelled `eval-candidate` are the corpus queue — the false-positive
and missed-finding forms apply the label, and tier-1 feedback reports
(see [docs/feedback.md](../../docs/feedback.md)) carry it too. A tier-2
report with code becomes a corpus entry directly; a tier-1 metadata report
can't (no code), but recurring ones tell us which lens or detector needs a
seeded case. Close the issue with a pointer to the entry it became, or to
the calibration change it motivated.
