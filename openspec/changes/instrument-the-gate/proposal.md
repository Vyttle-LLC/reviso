# Instrument the gate

Reviso's deep tier returned **"No issues found"** on two consecutive real
changes that another reviewer found 12 and 5 genuine defects in. Before any
lens is retuned, the pipeline has to be able to say *why* it found nothing.
Right now it cannot, and neither can we.

## Why

Two audits, two different repositories, both clean reports:

| branch | `/reviso:audit` | `/code-review` (opus, xhigh) |
| --- | --- | --- |
| `feature/cli-phase4` (10 files, 2 commits) | 0 findings | 12 findings — 13 fixes accepted by the author |
| `feature/nix-186` (1 file, +370/−48) | 0 findings | 5 findings, incl. a medium UI-freeze |

Three of those misses landed on lenses that have dedicated finder agents,
and each is a textbook in-bar case:

1. **Duplication, `cli_server.rs:2257`** — a third near-verbatim copy of the
   id/title/ambiguous resolver. `agents/reviso-finder-slop.md` ships this
   bar: *"**Exactly 3** — ships only if the duplicated unit encodes a rule
   that can change: a predicate, a policy constant, a shared type or
   contract."* A selector resolver is that. The harm had already
   materialized in the same diff — the reviewer's finding #1, a
   trim-then-match-raw bug, is a direct consequence of the drift.
2. **Conventions, `shell_env.rs:453`** — a `thread::sleep` poll loop the
   repository's own `CLAUDE.md` bans, introduced by the changed lines.
   `reviso-finder-conventions` exists for exactly this.
3. **Comments / enforcement-vs-claim, `shell_env.rs:50`** —
   `MAX_STARTUP_ATTEMPTS`'s doc comment says "attempts left after the first
   failure"; `run_probe_loop` does `1..=max_attempts`. The bugs finder calls
   this class out by name.

Prompt calibration does not fail that uniformly across three independent
lenses. Something structural is more likely, and we currently have no way
to tell — which is the actual defect this change addresses.

**The report cannot distinguish a clean review from a broken one.**
`commands/audit.md` Stage 6 prints a hardcoded string:

```text
Checked: conventions, bugs, history, prior reviews, comments, slop, deterministic.
```

That line is a literal, not a derivation. A genuinely clean diff and a run
where every finder silently failed — an agent that never launched, a finder
handed empty hunks, a verifier that zeroed everything — produce
byte-identical output. Both zero-finding reports above carried it in full.

This is our own enforcement-doesn't-match-its-claim bug, sitting in the
line that claims the lenses ran.

Worth noting the orchestrator is doing real work: the `nix-186` report
correctly named the skipped doc-comment hunk at `shell_env.rs:498`, so
assembly and triage ran. The failure is downstream of triage.

## What Changes

**1. The coverage line reports what actually ran.**
Derive `Checked:` from the finders that returned, and name any that
returned nothing or errored — separately from finders that returned an
empty array, which is a real signal and not the same thing. A zero-finding
report must be able to explain its zero. Applies to `commands/audit.md`
(Stage 6, per-finder) and `commands/review.md` (Step 5, per-lens).

**2. Pre-gate candidate visibility, behind a flag.**
Today sub-80 candidates are dropped silently and the command is instructed
never to mention them — correct for users, blinding for maintainers. Add an
opt-in `--explain` flag that emits every candidate before the gate with its
verifier score and the reason it was dropped: exclusion-list match,
pre-existing, actionability precondition, or rubric score. Default off; the
ordinary report is unchanged.

**3. Finder-return accounting in the audit orchestration.**
Stage 3 launches six agents; nothing records what each returned. Capture
per-finder candidate counts so Stage 6 can report them and so a launch
failure is visible rather than indistinguishable from silence.

The diagnostic run these three buy is **not** in this change — see
follow-ups. It needs the instrumented plugin installed, and neither field
branch is reachable from the machine this was built on. Shipping the
instrumentation without waiting on the run is deliberate: the three items
above are improvements on their own terms, and a truthful coverage line
does not need a diagnosis to justify it.

## Non-goals

- **Do not retune any lens prompt yet.** The point of this change is to
  find out which half is broken. Tuning before that is guessing.
- **Do not touch the 0.4.0 gate.** It is committed and deliberately not
  merged, pending this diagnosis.
- **No new lenses, detectors, or corpus work.** Separate concerns.
- **Do not weaken the default report.** Users still see clean output; the
  new detail is opt-in.

## Capabilities

### New Capabilities

None. This change instruments surfaces both existing specs already own.

### Modified Capabilities

- `review-pipeline`: the reporting stage gains a truthfulness requirement —
  reported coverage reflects the finders that actually returned, and a
  finder that failed to return is surfaced rather than absorbed into the
  same sentence as a finder that returned cleanly. Stage 3 gains per-finder
  return accounting; Stage 4 gains a structured drop reason per gated
  candidate.
- `review-command`: the report shape gains the opt-in pre-gate diagnostic
  output and its default-off contract, and the clean-review scenario is
  tightened — "which dimensions were checked" becomes a derived claim, not
  a fixed string.

## Impact

- `commands/audit.md` (Stages 3, 4, and 6), `commands/review.md`
  (Steps 3–5) — argument parsing for `--explain` in both.
- `agents/reviso-verifier.md`: the return JSON gains a structured drop
  reason, so the orchestrator reports why a candidate was gated instead of
  inferring it.
- **Report-only is non-negotiable.** No new write permissions, no
  additions to either command's `allowed-tools`. Diagnostic output goes to
  the terminal, or to `--out` when the user asked for a file.
- Repo rules: sign off every commit (`git commit -s`, DCO is a required
  check), one concern per PR, `markdownlint-cli2` and `lychee` must pass.
- Branch state: `feature/termic-review-prompt` carries six commits — five
  eval-harness commits that are independent and mergeable, and `7c9c073`
  (the 0.4.0 precision bar) which is **held** pending this work.

## Open questions for the implementer

- Did the six finder agents launch at all? Agent-name resolution across a
  plugin boundary is worth verifying directly before assuming prompts.
- Were the finders handed non-empty hunks? Stage 3 passes "the non-skipped
  diff hunks"; triage ran correctly, but what reached the finders is
  unverified.
- Does the verifier zero candidates for reasons the orchestrator never
  sees? Its return schema carries `confidence` and a one-sentence verdict;
  a structured drop reason is added here for exactly that gap.

## Follow-ups, explicitly not this change

- **The diagnostic run, then triage.** Re-run `/reviso:audit --explain` on
  both branches once the instrumented plugin is installed, and classify:
  **no candidates generated** → the finders are the problem (prompts, hunk
  delivery, or agent launch); **candidates generated and zeroed** → the
  gate is, and 0.4.0 tightened the wrong screw. Opposite fixes, so the
  classification comes before the fix. Both are possible at once.
- Import both branches as corpus cases. They are human-adjudicated — 12 and
  5 findings, with reasoned rejections alongside the accepts — and our own
  tool scores zero on both. Better regression anchors than anything
  currently in the corpus.
- Grow the clean-case tier (5 cases carrying 4 findings today) and add
  labels for whether an author would *act* on a finding, not only whether
  it is real. The gold corpus reports 50% recall while the field shows
  0-of-12; it does not currently track field behavior.
- Decide 0.4.0's fate once the diagnosis lands. The measured noise floor
  (recall moved on 10 cases between two identical runs, versus 6 across the
  change) means the corpus cannot adjudicate it either way — see
  `docs/evals.md`.
