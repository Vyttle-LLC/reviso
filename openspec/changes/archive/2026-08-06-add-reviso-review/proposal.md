# Proposal: add-reviso-review

## Why

Claude Code's excellent `/review` is PR-gated; the local `/code-review` is a
weaker review; and neither reviews for AI slop. Reviso's PRD (v2, ratified
post-grill 2026-07-24) defines the fix: `/review`-grade review, locally,
pre-PR, report-only, on the developer's own subscription. This change builds
P0 — the product: the `/reviso:review` command plus the parity eval harness
that proves it against `/review` from day one. The repo is currently an OSS
scaffold with no plugin; the reference recipe to fork (the official
`code-review` plugin's orchestration) is documented, on disk, and resolved as
the implementation path (PRD §7 spike, 2026-07-24).

## What Changes

- Add the OSS Claude Code plugin skeleton: `.claude-plugin/`, `commands/`,
  `skills/`, `agents/` — installable via plugin marketplace / vendoring.
- Add **`/reviso:review`** — the everyday mock-PR review. Default target
  `base..HEAD` + uncommitted changes; `--base <branch>` override.
  **Report-only: it never mutates the working tree** (repo invariant).
- Add **mock-PR assembly** (Stage 0): reconstruct what `/review` gets — full
  `base..HEAD` diff + uncommitted, all branch commit messages, full-file
  context for changed files, inferred ticket, repo conventions
  (CLAUDE.md / AGENTS.md / lint config).
- Add **deterministic detectors** (Stage 1): zero-token, no-LLM pass for the
  mechanically checkable P0 slop (dead code, restating comments, AI-comment
  tells). FP-free by construction; exact scope is a discovery task.
- Add the **review pipeline** (Stages 2–4 + report): triage/risk-score per
  hunk, parallel dimension finders forked from the official `code-review`
  recipe (conventions compliance, shallow-bug, git-history, prior-review
  feedback, code-comment guidance) plus an anti-slop finder, single-refute
  verify + confidence gate (<80 drop), consolidated most-severe-first
  report. Precision over recall: silence over a maybe.
- Add the **parity eval harness**: replay real PRs — `/review` on the PR
  (baseline = findings in ≥2 of 3 runs) vs `/reviso:review` on the same
  `base..HEAD` locally; LLM judge buckets findings matched / missed /
  claimed-win→verify. Misses are P0 regressions. Two corpus tiers: private
  (Vyttle PRs, dogfood) and public (published in `eval/`).
- Vendor a dated snapshot of the forked `code-review` recipe (the "what we
  forked" baseline for future drift checks).
- Update `README.md` / `CONTRIBUTING.md` / `docs/evals.md` `TODO(plugin)`
  blocks that this change unblocks.

Out of scope (deferred per PRD §15): `/reviso:audit` (P1 — command name
reserved, not built), comment humanization and the full slop set (P1),
`.reviso/` team memory (P2), hosted anything (P3+).

## Capabilities

### New Capabilities

- `review-command`: the `/reviso:review` front door — invocation, `--base`
  override, focus flags, and the report-only output contract (line-anchored
  findings with severity, concrete failure scenario, suggested fix,
  confidence; never edits files).
- `mock-pr-assembly`: Stage 0 context reconstruction — everything `/review`
  sees on a PR, assembled locally from git state and repo conventions.
- `deterministic-detectors`: the zero-token Stage 1 pass — mechanical slop
  detection, FP-free, runs always and free.
- `review-pipeline`: Stages 2–4 + report — triage/escalation, blind dimension
  finders, single-refute verify, confidence gate, consolidated report.
- `parity-eval`: the eval harness — corpus schema (two tiers), replay runner,
  finding-equivalence judge, parity/dismissal metrics.

### Modified Capabilities

None — no existing specs (first change in this repo).

## Impact

- **New trees:** `.claude-plugin/`, `commands/`, `skills/`, `agents/`,
  `eval/` — all currently absent (`TODO(plugin)` markers).
- **Docs:** `README.md` (install), `CONTRIBUTING.md` (dev setup),
  `docs/evals.md` (corpus + runs) get their TODO blocks resolved or narrowed.
- **CI:** unchanged in this change; eval-in-CI is future work (`docs/ci.md`
  stays TODO).
- **Dependencies:** none added for the plugin itself (prose + git commands);
  deterministic detectors' implementation language is a design decision.
- **Costs:** review runs on the user's own subscription (PRD G4); eval
  baseline runs consume `/review` invocations on real PRs.
