# Design: add-reviso-review

## Context

The repo is an OSS scaffold (governance, CI, brand) with no plugin. The PRD
(v2, 2026-07-24) resolved the build-vs-wrap spike: `/review`'s quality comes
from richer context plus a documented multi-agent flow, and that flow is a
readable 92-line prose command on disk
(`claude-plugins-official/plugins/code-review/commands/code-review.md`):
Haiku eligibility/CLAUDE.md/summary passes → 5 parallel Sonnet finders →
per-finding Haiku confidence score (0–100 rubric) → filter <80 → formatted
comment, plus a battle-tested false-positive exclusion list. Reviso forks
that recipe with three changes: local mock-PR context instead of `gh pr`,
an added anti-slop dimension, and a report instead of a PR comment.

Constraints: report-only (repo invariant, SECURITY.md), precision over recall
(silence over a maybe), runs within a personal Max plan, Claude Code only.

## Goals / Non-Goals

**Goals:**

- `/reviso:review` producing `/review`-parity findings on `base..HEAD` +
  uncommitted changes, locally, report-only.
- Deterministic Stage 1 detectors for the mechanical subset of P0 slop.
- Parity eval harness with replayable corpus and finding-equivalence judge.
- Vendored, dated snapshot of the forked recipe for future drift checks.

**Non-Goals:**

- `/reviso:audit` (P1; command name reserved, no file shipped).
- Comment humanization, full slop set, convention inheritance depth (P1).
- `.reviso/` rules/learnings team memory (P2). Stage 5 reconcile is
  dedupe/consolidation only in this change.
- Eval in CI, hosted anything, multi-provider.

## Decisions

### D1 — Fork the official recipe verbatim-first, then diverge

Start from the on-disk recipe's exact structure: the 5 finder personas, the
0–100 confidence rubric (given to the scorer verbatim), the <80 gate, and the
false-positive exclusion list. Divergences in this change are only the three
planned ones (context source, +anti-slop finder, report sink). Rationale:
parity is the bar; the recipe is the known-good path to it; our own taste
enters via eval-driven tuning later, not day-one rewrites.
*Alternative rejected:* designing our own finder taxonomy first — burns the
schedule on the part that isn't the gap.

### D2 — Plugin anatomy

```text
.claude-plugin/plugin.json      name "reviso" → /reviso:review namespace
commands/review.md              the orchestrator (prose, forked recipe)
agents/                         finder + verifier subagent definitions
skills/reviso/                  shared harness prompts, FP list, report format
skills/reviso/detectors/        deterministic detector scripts
eval/                           corpus, runner, judge, reference snapshot
```

The command file orchestrates via the Task tool (the `pr-review-toolkit`
plugin proves this pattern runs pre-PR on `git diff`). Finder/verifier
personas live in `agents/` so `audit` (P1) can reuse them at different
depths. Model tiers mirror the recipe: Haiku for triage/scoring, Sonnet for
finders.

### D3 — Report-only enforced structurally, not by convention

`commands/review.md` frontmatter `allowed-tools` grants only read-only tools:
`Read`, `Grep`, `Glob`, `Task`, and `Bash(git diff:*)`-class read commands.
No Edit/Write/NotebookEdit anywhere in the command or agent definitions. A
write attempt is then a tool-permission failure, not a reviewable behavior.
Report goes to the terminal by default; `--out <path>` writes a file only
where the user explicitly points it. This is the SECURITY.md invariant made
mechanical.

### D4 — Mock-PR assembly is deterministic git, not an agent

Stage 0 is a fixed sequence of read-only git commands, not LLM judgment:
merge-base with `--base` (default: the repo's default branch via
`origin/HEAD`), full `base..HEAD` diff plus working-tree/index changes,
`git log base..HEAD` messages, full contents of changed files, ticket
inference from branch name / commit trailers, conventions files (CLAUDE.md,
AGENTS.md, lint configs on changed paths). Deterministic assembly makes eval
runs reproducible and keeps token spend for the stages that need it.

### D5 — Deterministic detectors: ship only what cannot false-positive

A detector ships only if it is FP-free by construction; anything borderline
moves to the anti-slop LLM finder. P0 candidates (final scope is a discovery
task): diff-introduced unused imports/symbols verifiable by search within
the change, comment-restates-code tells, mechanical AI-comment tells.
Detectors are standalone scripts under `skills/reviso/detectors/` invoked via
Bash, zero runtime dependencies beyond POSIX + git + ripgrep; they emit
findings in the same schema as LLM finders, tagged `deterministic`, and skip
Stage 4 verification. *Alternative rejected:* a Node/Python detector package
— adds an install step to a plugin that is otherwise pure prose.

### D6 — Triage (Stage 2) ships as a thin seam, not a cost model

P0 triage is one Haiku pass that tags hunks (auth/money/concurrency/external
input/public API/migration/deleted tests) and marks skip-tier files
(lockfiles, generated code, pure formatting). Tags flow into finder prompts;
skip-tier hunks bypass finders. The full earned-depth ladder (light vs deep
per hunk) is tuned later with eval data — the seam exists so tuning doesn't
restructure the pipeline.

### D7 — Verify = the recipe's scorer, kept as one agent per finding

The recipe's step-5 Haiku scorer already is the PRD's "refute + confidence"
pass: it double-checks the issue against the code and scores 0–100. Keep it
as a single per-finding verifier (rubric verbatim, FP list included), gate at
<80. If eval shows FPs slipping through, the first lever is Sonnet verifiers,
not a second pass. Deterministic findings bypass it.

### D8 — Eval harness: replay real PRs, majority baseline, three-bucket judge

```text
corpus entry: {repo, pr, base_sha, head_sha, notes}
  baseline:  /review on the PR, k=3 headless runs (claude -p),
             baseline = findings appearing in ≥2 runs
  candidate: checkout head_sha, /reviso:review --base <base_sha>
  judge:     LLM matcher on root cause (conservative: match only if same
             underlying defect) → matched | missed | claimed-win
  verify:    claimed-wins get a manual/skeptic pass before counting
metrics: parity % (matched / baseline), misses listed as P0 regressions,
         verified wins, dismissal rate
```

Two corpus tiers: `eval/corpus/` (public — OSS PRs and/or seeded-bug PRs,
published per docs/evals.md) and a private Vyttle tier referenced by path,
never committed here. Runs land in `eval/runs/` as JSON so drift re-checks
against future `/review` versions are just another run.

### D9 — Vendor the recipe snapshot, pending license check

`eval/reference/` holds a dated snapshot of the forked recipe as the drift
baseline. Before committing verbatim text, check `claude-plugins-official`'s
license; if redistribution is unclear, store a content hash + structural
summary instead. (Open question OQ2.)

## Risks / Trade-offs

- [Parity gap survives context reconstruction] → the eval harness exists
  precisely to find which finder/context piece is missing; build-our-own
  means every gap is tunable. Misses are P0 regressions by definition.
- [Too noisy → ignored (fatal for report-only)] → FP-free detectors,
  recipe's FP list + <80 gate, consolidation in the report stage; dismissal
  rate tracked in eval with a <10% target.
- [Cost blows a Max plan] → deterministic pass is free, triage skip-tier,
  Haiku for scoring; audit-depth work is deferred to P1's explicit command.
- [Baseline capture flaky (`/review` posts PR comments; headless runs may
  drift in format)] → runner captures raw output + parsed findings; parsing
  failures fail loudly, never silently shrink the baseline.
- [Judge miscounts equivalence] → conservative matching rules + a
  hand-labeled calibration sample before trusting parity numbers.
- [Recipe drift upstream] → dated snapshot (D9) + periodic re-benchmark
  against current `/review` as an ordinary eval run.

## Open Questions

- OQ1 — Final deterministic detector list (discovery task: prototype against
  real Vyttle diffs, keep only FP-free survivors).
- OQ2 — `claude-plugins-official` license for verbatim snapshot vendoring.
- OQ3 — Staged-only shorthand (PRD §16): ship `--staged` in P0 or defer?
  Default remains `base..HEAD` + uncommitted either way.
- OQ4 — Public corpus source: curated OSS PRs vs seeded-bug PRs (Macroscope
  style) vs both.
