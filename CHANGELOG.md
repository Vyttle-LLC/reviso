# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Changed

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
