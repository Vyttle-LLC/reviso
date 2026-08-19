# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] — 2026-08-19

### Added

- **The expanded slop set.** `/reviso:style` grows from five lenses to
  ten: **over-engineering** (abstractions with one consumer, defenses
  against states the types make impossible — absence cited by
  `file:line`), **dead weight** (added code nothing uses, scoped beyond
  linter coverage, with a mandatory recorded search), **test slop**
  (tests that cannot fail, mocked subjects, sleep waits), **AI tells**
  (temporal naming, changelog comments, placeholder text, quoted
  verbatim), and **comments**, promoted out of the slop lens. The
  ledger, `--explain` diagnostics, and feedback mapping carry all ten.
- **The comments lens holds an absolute bar.** A changed comment earns
  its place only when the code cannot say it, and then as short as the
  point allows. Only a *written* convention (a CLAUDE.md rule, a lint
  rule like require-jsdoc) overrides; the repo's own demonstrated
  verbosity does not. This and placeholder text are the cardinal rule's
  only two exceptions — everything else still yields to the repo's norms.
  Style-command-local: the shared exclusion list and the other verbs are
  unchanged.
- **`placeholder` detector.** The deterministic suite flags committed
  placeholder language ("in a real implementation…", "in production you
  would…") at P1, suppressed in markdown and example/demo/sample/fixture
  paths. Discovery re-run per D5: 0 false positives across ~2,700 commits
  in 10 repos; changelog comments, temporal naming, and emoji evaluated
  and rejected to the AI-tells lens (DISCOVERY.md has the tables).
- **The style tier is measurable.** `REVISO_TIER=style` runs
  `/reviso:style` through the gold harness like the sibling tiers, and
  ten synthetic corpus cases land with it — a true-positive and an
  expected-clean look-alike per new lens, findings labeled `slop`
  (in-lane for recall). Style-tier gold runs are meaningful only against
  style-labeled or expected-clean cases.

## [0.6.0] — 2026-08-18

### Added

- **`/reviso:style` — the dedicated style lane.** A third verb: a
  single-pass, report-only review that applies only the style lenses —
  the anti-slop P0 set, duplication (same bar as the sibling surfaces),
  code-shaped conventions, repo-style drift, and outlier length — and
  hunts no bugs. Every judgment is calibrated against the repo's own
  norms with the baseline cited in the finding: a drift finding needs two
  `file:line` examples of the established pattern, a length finding must
  name the comparable units it was measured against, and absolute
  thresholds are banned. Style findings cap at P1 — nothing purely
  stylistic blocks a merge. Same assembly, flags (`--base`, `--out`,
  `--explain`), deterministic detectors, confidence gate, and reporting
  policy as `/reviso:review`.
- The false-positive feedback builder accepts `--command style`.

### Changed

- **Test-only duplication is convention-gated.** Duplication whose
  occurrences are all in test code no longer ships unless a written repo
  convention (CLAUDE.md / AGENTS.md / lint config / skill doc governing
  the changed paths) demands shared test helpers — repetition in tests is
  a legitimate, often deliberate style (DAMP), and only a written rule
  makes it drift. Encoded once in the shared false-positive exclusion
  list, so review, style, and the audit orchestrator gate identically;
  finders still return the candidates. Driven by the style verb's first
  field false positive.

## [0.5.0] — 2026-08-17

### Changed

- **Judgment moved to the orchestrator.** The audit pipeline filtered at
  every layer — six finders each applying the false-positive exclusion
  list, a candidate cap and severity floor enforced at serialization, and
  an isolated per-candidate verifier holding veto power — all before the
  orchestrator saw anything. Every filtering decision now happens once, in
  the orchestrator, the only stage that holds every candidate and the
  whole change. Finders report everything they can evidence: the
  suppression clauses, the 8-candidate cap, the no-P3 rule, and the
  exclusion-list obedience are gone from all six finder prompts.
- **Stage 4 returns evidence, not verdicts.** The verifier agent is now
  `reviso-evidence`: it still reads full context, walks blame, and
  attempts the failure scenario, but returns findings of fact — whether
  the cited lines are in the change, what guards/callers/tests bear on the
  scenario, whether it reproduces — with no score, no drop reason, and no
  veto. The orchestrator applies the exclusion list and the 0–100 rubric
  once, with cross-candidate context; the 80 threshold and the default
  silence about drops are unchanged, and `--explain` now reports the
  orchestrator's scores.
- **The shared finding schema carries format only.** Reporting policy —
  the severity floor, consolidation, any count limit — moved to the
  commands that produce reports; `/reviso:review` restates the policy it
  used to inherit, so the single-pass tier behaves exactly as before.
- The confidence rubric and false-positive exclusion list are inputs to
  the orchestrator alone — no subagent is asked to read them, so no
  candidate can be gated against a reference an agent failed to load (two
  of thirteen verifiers in the 2026-08-13 run scored without their rubric
  for exactly that reason).

## [0.4.0] — 2026-08-13

### Added

- `--explain`, on both commands. Off by default; when passed, the report
  gains one labelled diagnostic section after the findings, carrying the
  per-lens ledger with candidate counts and every candidate considered
  before the confidence gate with its score and why it was dropped. The
  findings section is byte-identical with and without the flag, and the
  section follows the report to the same sink — terminal, plus `--out`
  when the user asked for a file. Nothing new is written, and neither
  command's `allowed-tools` gained an entry.
- The verifier returns a structured `drop_reason` alongside its score —
  `exclusion-list`, `pre-existing`, `rubric-score`, or `none` — so the
  orchestrator can count why candidates were gated instead of parsing the
  verdict prose. A return that omits it is read as `rubric-score` below 80
  and `none` at or above, so an older verifier degrades rather than stalls.

### Changed

- **The coverage line is derived, not printed from a literal.** Both
  commands hardcoded `Checked: conventions, bugs, history, …` — the same
  string whether every lens ran clean or none of them ran at all, which
  made a genuinely clean report and a silently broken pipeline
  byte-identical. Each lens now records an outcome as it resolves
  (`returned`, including an empty findings array, versus `no result` or
  `skipped`), `Checked:` names only the lenses that returned, and a
  `Not checked:` line names the rest with their reasons. That line is
  emitted only when there is something to say, so a healthy run reads as
  it did before. A zero-finding report can now explain its zero.
- A declined permission prompt on the deterministic detector script is
  recorded as `no result` for that lens. Previously the report still
  listed `deterministic` among the lenses it had checked.
- **The verifier runs on Sonnet, and the audit orchestrator on Opus.** The
  gate was the cheapest model in the pipeline and held veto power over
  everything six Sonnet finders produced — nothing shipped unless Haiku
  could independently re-derive it. The asymmetry is what makes that
  wrong: a weak candidate costs a little compute and dies at the gate, but
  a wrong veto costs the whole finding, silently. The audit orchestrator
  was Sonnet while the single-pass `/reviso:review` is Opus, so the deep
  pre-PR tier coordinated on a weaker model than the fast inner-loop tier
  reviews on. Both tiers were inherited from the upstream recipe, whose
  cost function is a bot reviewing every PR forever — not a gate a user
  invokes deliberately. The published 3-way run already measured what
  depth is worth here: same diff, same architecture, Opus found 5 findings
  to Sonnet's 1. Triage stays on Haiku; tagging hunks is the one job in
  the pipeline that is genuinely cheap.

## [0.3.0] — 2026-08-08

### Added

- **The duplication lens.** The anti-slop set gains a duplication item
  covering both directions — new code copying something the repository
  already has, and the change copying itself. Occurrences of the same unit
  of logic (a rule-encoding expression, a declaration, or a verbatim block)
  are counted together with copies already in the repo: **four or more
  ships; exactly three ships only when the duplicated unit encodes a rule
  that can change**, so incidental look-alikes like setup boilerplate stay
  quiet; two or fewer never ship, however long the copied block is. Every
  finding cites each occurrence and names the helper to extract — its name,
  signature, and the home it belongs in — or it is not a finding. The bar is
  calibrated against hand-labeled human review cases. This closes the
  verbatim-duplicate half of #9; the redundant-derived-state half of that
  report is a different shape and is not addressed here.
- Gold-mode eval: 64-case public corpus (50 real PRs imported from
  code-review-benchmark with MIT-attributed labels, 13 synthetics, and one
  hand-authored duplication case), `gold.sh`/`sweep.sh` runners, and the
  first published sweep (docs/evals.md). Repo-side only — the installed
  plugin is unchanged.
- `termic-162` joins the public corpus as the duplication lens's regression
  case — and the corpus's only `duplication` label, which is why every
  duplication finding was previously unmatchable by construction.
- The private corpus tier is runnable, not just documented: entry-relative
  paths resolve against the corpus file's own directory, sweeps pass their
  corpus selection down to per-case runners, and a gold run fails by name on
  a missing corpus, unknown case, or entry with no labels.
- `eval/runners/gold-judge.sh` splits judging from the candidate leg, so a
  recorded run can be re-judged when tiering changes without paying for the
  review again.

### Changed

- Eval tiering is now one shared list (`eval/runners/tiers.sh`) instead of a
  copy in each judge, and it encodes what Reviso *ships* rather than literal
  correctness. `duplication` left the cleanup family accordingly: a
  duplication finding the candidate misses is now a listed regression, in
  gold mode against a label and in parity mode against the built-in.
- The anti-slop "not reusing existing code" item now demands a search before
  an added block is cleared as original: grep the repo for that block's most
  distinctive identifiers and string literals, not whole lines, which a
  rename dodges. Nothing previously forced the lookup — the direct cause of
  the miss in #9.
- Parity eval re-aimed at the built-in `/code-review` pinned to medium
  (upstream `/review` is a CLI-embedded, effort-scaled skill; the
  marketplace recipe the harness previously tracked is dead). Baselines now
  record run identity (CLI version, level, resolved models), harvest the
  typed ReportFindings report, and score parity on correctness-tier
  findings only. Repo-side only — the installed plugin is unchanged.

## [0.2.0] — 2026-08-05

### Added

- Assisted false-positive feedback: a privacy contract (`docs/feedback.md`),
  a deterministic allowlist payload builder with secret/entropy/length
  backstops (`skills/reviso/feedback/build-payload.sh`), a post-report
  feedback step in both commands, and prefilled tier-2 issue-form links.
- Repository scaffold: Apache-2.0 licence, DCO contribution model, governance
  files, issue templates, and markdown/link linting.
