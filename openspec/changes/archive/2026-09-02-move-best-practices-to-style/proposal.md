# Move the best-practices lens to style

## Why

Michael's call: the ecosystem check belongs in the style lane, not the
audit. `/reviso:style` is the "is this clean?" verb a user reaches for
on a fresh AI-written change — exactly when a deprecated API or a
superseded idiom slipped in — and it is single-pass, so the lens runs
without a subagent, cheaper and simpler than the audit's seventh finder.
0.11.0 shipped the lens in the audit; this moves it, same contract.

## What Changes

- `/reviso:style` gains `--web` and runs the best-practices lens
  **inline as its seventeenth lens**: same four classes (deprecated or
  removed API, documented misuse, known advisory, superseded idiom with
  a stated consequence), same `docs/web.md` contract (opt-in flag only,
  ecosystem-fact query vocabulary, 12-search/2-fetch bounds,
  fetch-verified primary sources, `Source:` line, `Web:` block under
  `--explain`), same version-applicability gate.
- The lens is ecosystem-relative, so it joins the comments bar and
  placeholder text as a **named exception to the cardinal rule** — it is
  measured against the ecosystem's own documentation, never this repo's
  norms. It also keeps its own severity band (P1 removed API / critical
  advisory reachable from external input may be P0), the way
  deterministic detector findings keep theirs — these are documented
  facts, not taste, and the style P2/P1 band does not cap them.
- **`/reviso:audit` gives the lens up**: no `--web` flag, six finders
  again, `agents/reviso-finder-best-practices.md` deleted. **BREAKING**
  for anyone who ran `/reviso:audit --web` on 0.11.0 (one release,
  unannounced beyond the changelog); the flag now errors as unknown
  with the one-line note pointing at style.
- Gold: the `bp-*` pair moves to the style tier (`REVISO_TIER=style`
  with `--web` in `REVISO_CMD_ARGS`); `tiers.sh` logic is already
  command-agnostic.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `style-command`: gains the best-practices lens requirements (opt-in
  fan-in, source anchoring, gate, coverage, severity exception).
- `review-pipeline`: the two 0.11.0 best-practices requirements are
  removed (lens relocated).
- `web-lookup-contract`: unchanged in substance; the requirement and
  scenarios that name `/reviso:audit` now name `/reviso:style`.

## Impact

- `commands/style.md` (lens, gate, ledger family, report, feedback
  mapping), `commands/audit.md` (revert to six finders),
  `agents/reviso-finder-best-practices.md` (deleted), `docs/web.md`,
  `README.md`, `eval/corpus/*` bp entries, `eval/runners/candidate.sh`
  comment, `docs/evals.md`, `CHANGELOG.md` 0.13.0, `plugin.json`.
  0.12.0 was taken by the base-inference change (#39).
