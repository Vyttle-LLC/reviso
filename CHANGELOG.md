# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Gold-mode eval: 63-case public corpus (50 real PRs imported from
  code-review-benchmark with MIT-attributed labels, 13 synthetics),
  `gold.sh`/`sweep.sh` runners, and the first published sweep
  (docs/evals.md). Repo-side only — the installed plugin is unchanged.

### Changed

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
