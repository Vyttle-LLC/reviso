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

Note the tiering consequence: `judge.sh` lists `duplication` among the
cleanup-family categories, so a miss on this case reports as informational
rather than counting against `gold_recall_correctness`. The case still earns
its slot — it stops a correct duplication finding from being scored as an
unmatched false positive in `precision_proxy_pct`, which is what every
duplication finding was before this label existed.

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
