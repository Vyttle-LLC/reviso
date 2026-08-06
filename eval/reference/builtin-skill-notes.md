# Built-in /code-review — structural notes and drift fingerprints

The upstream review Reviso benchmarks against is a skill embedded in the
Claude Code CLI binary. Its prompt text is proprietary and is **not**
committed here (unlike the Apache-2.0 marketplace recipe it replaced — see
`README.md`). This file carries what the repo may state: the observed
structure, and a per-version fingerprint of the skill text produced by
`extract-builtin.sh`. The verbatim extraction lands in `private/`
(gitignored) for local reading only.

Drift detection is behavioral first: a CLI version roll is a re-baseline
event (see `eval/README.md`). The fingerprint answers the cheaper question
"did the skill text move at all?" — run `extract-builtin.sh` against the new
binary and compare. Same hash: text unchanged, re-baseline is a formality.
New hash: read the local dump, diff against the previous version's dump, and
expect the re-baseline to move.

## Structure (observed at 2.1.223, 2026-08-06)

Effort-scaled by a level argument (session effort supplies the default —
xhigh in current Claude Code):

| Level | Pipeline | Stance | Findings cap |
| --- | --- | --- | --- |
| low | inline 2-turn hunk scan, test files skipped | — | 4 |
| medium | 8 finder angles → dedup → 1-vote verify (CONFIRMED/PLAUSIBLE/REFUTED) | precision — "every finding one a maintainer would act on" | 8 |
| high | same 8 angles, verify keeps any non-REFUTED | recall — "err on the side of surfacing" | 10 |
| xhigh/max | 10 angles (5 correctness) → verify → fresh gap-sweep finder | recall — "a missed bug ships" | 15 |

- Correctness angles: line-by-line diff scan, removed-behavior auditor,
  cross-file tracer, language-pitfall specialist, wrapper/proxy correctness
  (the last two join at xhigh/max).
- Cleanup angles: reuse, simplification, efficiency; plus altitude and
  conventions (CLAUDE.md, quote-the-exact-rule standard).
- Output: the typed `ReportFindings` tool (`{level, findings}`; each finding
  `file`/`line`/`summary`/`short_summary`/`failure_scenario`/`category`,
  plus `verdict` when a verify pass ran). Headless, the run delegates to an
  agent whose transcript carries the call; the `-p` result text is prose.
- At high/xhigh/max with workflows enabled, runs as a workflow
  (finder-per-angle, verifier per distinct file:line, sweep, rank/cap).
- Without subagent fan-out available it degrades to a single-pass inline
  review and is instructed to say so — `baseline.sh` rejects runs that do.

Observed headless at medium (smoke, 2026-08-06): a single delegated agent
worked the angles in-context (no Task fan-out), reported `level: "medium"`
via ReportFindings, no degraded-mode disclaimer. Fan-out at medium is
apparently discretionary, not guaranteed; the harness therefore verifies
the *reported level* and the *absence of the degraded-mode disclaimer*, not
a subagent count.

## Fingerprints

Fingerprint = SHA-256 over the deduplicated, order-normalized skill-text
fragments (tight markers only, blocks ≤20KB — see `extract-builtin.sh`).

| CLI version | fingerprint | note |
| --- | --- | --- |
| 2.1.219 – 2.1.223 | `990c141b5540c87e1cd5e06c480659c8fc0998cff1d28ba10aa2a9c73d85f8db` | skill text identical across all five inspected versions (2026-08-06) |
