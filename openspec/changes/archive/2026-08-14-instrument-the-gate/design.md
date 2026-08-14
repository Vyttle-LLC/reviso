# Design — instrument the gate

## Context

Reviso's pipeline is prompt-defined: `commands/audit.md` is the
orchestrator, `agents/reviso-*.md` are the workers, and the "code" is
markdown. There is no runtime that can hold a ledger for us — anything we
want recorded has to be recorded by the orchestrator, on instruction,
before it moves to the next stage.

Current state, on this branch (`main` + nothing):

- **Stage 3** (`commands/audit.md:82-105`) launches six finder Tasks in one
  message and passes their candidates to Stage 4. Nothing between those two
  stages records what each finder returned, so a finder that returned `[]`,
  a finder that returned unparseable text, and a finder whose Task never
  launched are all the same to the rest of the run.
- **Stage 4** (`:107-114`) tells the orchestrator to "silently drop every
  finding scoring below 80" and to "never mention dropped findings". The
  verifier (`agents/reviso-verifier.md:36-38`) returns
  `{confidence, verdict, severity_check}` — a free-text verdict, nothing
  the orchestrator can bucket.
- **Stage 6** (`:139`) prints `Checked: conventions, bugs, history, prior
  reviews, comments, slop, deterministic.` as a literal. `commands/review.md:156`
  does the same for its six inline lenses.

The same literal is printed whether seven lenses ran clean or zero ran at
all. Two field audits returned "No issues found" against 12 and 5
human-confirmed defects, and neither report carried a single bit that
distinguishes those cases. That missing bit is the whole subject here.

Two constraints frame every decision below. **Report-only** (CLAUDE.md,
SECURITY.md): nothing in this change may add a write path or a new entry to
either command's `allowed-tools`. And **precision over recall**: the
default report is what users see, so instrumentation may not push
below-bar candidates in front of them.

## Goals / Non-Goals

**Goals:**

- A zero-finding report can explain its zero. A reader — user or
  maintainer — can tell a clean review from a broken pipeline without
  re-running anything.
- Per-lens outcomes are recorded where they happen (Stage 3 for the audit,
  Step 3 for the single-pass review) rather than reconstructed at report
  time.
- Maintainers can see the pre-gate population — every candidate, its score,
  and why it was dropped — on demand, without changing what users see.
- The verifier reports *why* it gated something in a form the orchestrator
  can count, not only in prose.

**Non-Goals:**

- Retuning any lens prompt. This change buys the evidence; the tuning is a
  later change and would be guessing today.
- Touching the 0.4.0 precision bar (held on `feature/termic-review-prompt`,
  commit `7c9c073`). Its fate is decided by the diagnosis, not here.
- Machine-readable diagnostic output (JSON, a run log, an artifact file).
  Report-only makes a written run log the wrong shape, and nothing consumes
  one yet.
- Any change to how findings are scored, deduped, or ranked. The gate keeps
  its threshold and its silence; only its observability changes.

## Decisions

### D1 — Three per-lens outcomes, and "empty" is not "absent"

Every lens ends a run in exactly one state:

| state | meaning | default report |
| --- | --- | --- |
| `returned` | the lens ran and produced candidates (any number, including zero) | listed in `Checked:` |
| `no result` | the lens produced nothing usable: no return, an error, or output that isn't a findings array | listed in `Not checked:` with the reason |
| `skipped` | the lens had nothing in scope (e.g. no GitHub remote for prior-reviews) | listed in `Not checked:` with the reason |

An empty array is a **positive** result — the lens looked and found
nothing — and it belongs in `Checked:` alongside a lens that returned four
candidates. Collapsing "found nothing" into "produced nothing" is the exact
conflation that made both field reports unreadable, so the two states are
kept apart at the point of capture, not merged and re-split later.

*Alternative considered:* a boolean ran/didn't-run. Rejected — it cannot
express the case that actually bit us, a finder that launched, was handed
empty hunks, and dutifully returned `[]`.

### D2 — The ledger is written at Stage 3, before Stage 4 runs

The orchestrator records one row per finder the moment its Task returns:
lens name, outcome, candidate count. The instruction is explicit that an
unrecorded lens is `no result` — never assumed clean — so a Task that
silently failed to launch produces a row saying so rather than a gap
nobody notices.

Stage 6 renders from that ledger. It may not print a lens name it does not
have a row for, and the old literal is removed from the file so there is
nothing left to copy.

*Alternative considered:* have Stage 6 infer coverage from the findings it
holds. Rejected — that is what the code effectively does now, and it is
unrecoverable by construction: zero findings from a lens and zero contact
with a lens look identical downstream.

The deterministic detector suite (Stage 1 / Step 2) is a lens under this
rule too. `run.sh` is deliberately not pre-approved, so a user who declines
the permission prompt gets no detector pass — today the report still claims
`deterministic` in `Checked:`. That becomes a `no result` row.

### D3 — The default report gains status, not counts

The default `Checked:` line names lenses; it does not print per-lens
candidate counts. A failed or skipped lens adds a second line:

```text
Checked: conventions, bugs, history, comments, slop, deterministic.
Not checked: prior reviews (no GitHub remote).
Skipped: package-lock.json.
```

Pre-gate counts stay behind `--explain` (D4).

*Alternative considered:* always print counts — `conventions (3), bugs (0)`.
Rejected on the precision-over-recall constraint: `conventions (3)` in a
report that ships zero conventions findings tells the user three things
were found and withheld, which invites exactly the "what did you hide"
conversation the silent gate exists to avoid. The diagnostic value is for
maintainers; maintainers can pass a flag. The failure case a user *does*
need — a lens that didn't run — is what the new `Not checked:` line
carries, and it appears only when there is something to say.

### D4 — `--explain` is a diagnostic section, off by default

`--explain` appends one clearly-fenced section after the findings. It
carries the ledger with counts, then every pre-gate candidate with its
score and disposition:

```text
--- explain: pipeline diagnostics (not review findings) ---
Finders: conventions 3, bugs 2, history 0, prior-reviews no result,
comments 0, slop 1.
Candidates before the gate (6):
  [slop]        cli_server.rs:2257  score 88  reported
  [conventions] shell_env.rs:453    score 72  dropped: rubric-score
  [bugs]        shell_env.rs:50     score  0  dropped: pre-existing
```

Rules that keep it from becoming a second report: it is off unless the flag
is passed; the findings section above it is byte-identical with and without
the flag; and every line in it is labelled a diagnostic, never a finding.
It follows the report to the same sink — terminal, plus `--out` when the
user asked for a file — so it adds no write path.

*Alternative considered:* an env var (`REVISO_EXPLAIN=1`) instead of a flag.
Rejected — both commands already parse `--base` and `--out` and document
flags in `argument-hint`; a second mechanism for the same job is drift.

*Alternative considered:* writing diagnostics to a file automatically.
Rejected outright — report-only is the invariant, and an unrequested write
is a security bug in this repo's terms.

### D5 — The verifier returns a structured drop reason

`agents/reviso-verifier.md` gains one field:

```json
{"confidence": 0, "drop_reason": "exclusion-list | pre-existing | rubric-score | none",
 "verdict": "one sentence: why this score", "severity_check": "P0|P1|P2 — ..."}
```

The values map onto the verifier's own steps, in the order it already
performs them: step 2 is `exclusion-list`, step 3 is `pre-existing`, a
surviving-but-under-80 score is `rubric-score`, and `none` means the
candidate cleared the gate. The set is deliberately small and closed on
this branch — a later gate change that adds a precondition (the held 0.4.0
bar adds an actionability check) adds its value then, in the change that
adds the check. Naming `actionability` here would ship a reason nothing on
this branch can emit, which is the enforcement-doesn't-match-its-claim bug
this change exists to fix.

The field is additive: a verifier return without it is treated as
`rubric-score` when the score is under 80 and `none` otherwise, so the
orchestrator degrades rather than stalls.

*Alternative considered:* let the orchestrator infer the reason from the
free-text `verdict`. Rejected — the inference is exactly as reliable as the
prose, and the orchestrator cannot see what the verifier read.

### D6 — The single-pass review keeps the same contract, per lens

`/reviso:review` spawns nothing, so "the finder returned" has no meaning
there. Its ledger is per-lens instead: the session records, as it works
through Step 3, whether it applied each lens across the non-skipped hunks.
The report shape, the three states, the `Not checked:` line, and
`--explain` are identical to the audit's — the two surfaces already commit
to not drifting on the duplication item (`review-command` spec), and the
coverage claim is the same kind of contract.

The single-pass tier's `--explain` shows self-verification scores from Step
4, which is the same pre-gate population by a different route.

## Risks / Trade-offs

- **The ledger is prompt-enforced, not code-enforced — a model can still
  print a coverage line it didn't derive.** → Mitigated three ways: the
  literal string is deleted from both command files, so there is nothing to
  copy; the instruction states that an unrecorded lens is `no result`, so
  the failure mode of forgetting is a visible row rather than a silent
  omission; and `--explain` gives maintainers a second view that would
  disagree with a fabricated line. Residual risk accepted — it is strictly
  less than today's guaranteed-fixed literal.
- **`--explain` exposes below-bar candidates, which readers may treat as
  findings.** → Off by default, fenced and labelled as diagnostics,
  positioned after the findings, and the findings section is unchanged by
  the flag.
- **A longer coverage block makes clean reports noisier.** → The
  `Not checked:` line is emitted only when a lens actually failed or was out
  of scope. A fully healthy run prints one line, as it does today.
- **The instrumentation ships without the diagnostic run it was built
  for, so its payoff is deferred and unproven.** → Accepted deliberately.
  The run needs the instrumented plugin installed and the field branches in
  reach, neither of which is true today, and every item here stands on its
  own: a coverage line that lies is a defect whether or not it explains
  these two reports. The risk is that we ship instrumentation nobody reads
  — mitigated by the follow-up being written down with its classification
  criteria rather than left as intent.
- **The diagnosis, when it runs, may come back "both halves are
  broken."** → The classification is not exhaustive by accident; a run
  showing candidates generated *and* lenses missing is a legitimate third
  outcome, and the ledger plus the pre-gate dump separates them on the same
  run rather than requiring a second one.

## Migration Plan

Nothing to migrate — this is a prompt-file change in a plugin with no
persisted state. Installed copies pick it up on the next plugin update.
Rollback is reverting the commits; a report from an old copy is still a
valid report, just an uninformative one.

## Open Questions

- Did the six finder agents launch at all? Agent-name resolution across the
  plugin boundary is worth checking directly before any prompt is blamed —
  the ledger will show `no result` for all six if this is the fault.
- Were the finders handed non-empty hunks? Triage demonstrably ran (the
  `nix-186` report named the skipped hunk correctly), but what Stage 3
  actually passed downstream is unverified. If the ledger shows six lenses
  returning `[]`, hunk delivery is the first suspect.
- Does `--explain` need to show the *input* each finder received (hunk
  count, file count), not only what it returned? Left out of this design as
  scope, but if the answer to the previous question is "we still can't
  tell", it is the next instrument to add.
