# Eval corpus

One JSONL entry per PR. Both tools review the identical `base..head` range,
so comparison is apples-to-apples.

## Entry schema

```json
{"id": "repo-shortname-123", "repo": "owner/name", "pr": 123, "base_sha": "<full sha>", "head_sha": "<full sha>", "clone_url": "https://github.com/owner/name.git", "notes": "why this PR earns a corpus slot"}
```

- `base_sha` / `head_sha` are pinned at corpus-entry time — PR branches move;
  SHAs don't. Recorded from `gh pr view <n> --json baseRefOid,headRefOid`.
- `notes` says what the PR exercises (a known bug it introduced, a slop
  pattern, a clean PR that tests the silence discipline).

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
