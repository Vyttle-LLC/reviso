# Reviso audit workflow

Audit the current branch's changes as if they were a pull request, using the
full multi-agent pipeline: blind dimension finders in parallel, per-candidate
evidence gathering, then a single confidence gate you apply yourself with
the whole change in view. This is the deep pass — run it before opening
a PR, after `/reviso:review` has handled the inner-loop iterations. Expect
several minutes and meaningfully more usage than `/reviso:review`.

Read and follow [the shared execution contract](../execution.md).

Invocation options may contain `--base <ref>` (diff base; otherwise inferred
from the PR, the tracking branch, or the default branch — Stage 0), `--out <path>` (also write the report
to that file; terminal-only otherwise), and `--explain` (append the
pipeline diagnostics described in Stage 6; off by default). Ignore
unknown flags with a one-line note — for `--web`, the note says the
best-practices lens lives in `/reviso:style --web`.

Follow these steps precisely. Make a todo list first.

## The coverage ledger (maintained throughout, reported in Stage 6)

Every lens this run touches gets exactly one ledger row, recorded the
moment that lens resolves — not reconstructed at report time. A row is:
lens name, outcome, candidate count. There are exactly three outcomes:

- **returned** — the lens ran and handed you a findings array. An empty
  array is `returned`: the lens looked and found nothing, which is a
  result. Record the count, zero included.
- **no result** — the lens handed you nothing usable: the agent never
  returned, it errored, or its output was not a findings array.
- **skipped** — the lens had nothing in scope (prior reviews in a repo
  with no GitHub remote, say). Note the reason.

A lens you recorded no row for is `no result`. Never assume a silent lens
was clean: "found nothing" and "produced nothing" are different facts, and
a report that cannot tell them apart is the failure this ledger exists to
prevent. Stage 6 reports from these rows and may not name a lens it has no
row for.

## Stage 0 — Assemble the mock PR (deterministic; run these yourself, no agents)

Follow [context assembly](../context.md). In audit mode, pass file paths
to finders so they can read full files on demand.

## Stage 1 — Deterministic detectors (free; before any agent)

Run the detector suite against the assembled diff:

```sh
sh "${REVISO_SKILL_ROOT}/detectors/run.sh" <base-ref>
```

(This script is read-only; run under the host’s execution policy.)
Collect its findings. They use the shared finding schema, are tagged
`deterministic`, bypass Stage 4 evidence-gathering and the Stage 5 gate,
and report at confidence 100.

Record the `deterministic` ledger row now: `returned` with the finding
count if the suite ran, `no result` if execution was denied
or the script failed. A denied run is not a clean detector pass, and
the report must not claim it was.

## Stage 2 — Triage

Launch one `reviso-triage` agent with the diff and changed-file list.
It returns, per hunk: risk tags (auth, money, concurrency, external-input,
public-api, migration, deleted-tests) and a skip-tier marking for lockfiles,
generated code, and pure-formatting hunks. Skip-tier hunks are excluded from
Stage 3 and listed in the report's coverage summary.

## Stage 3 — Finders (parallel, blind)

Launch the six independent finder roles using the host adapter in
[the execution contract](../execution.md), within its available capacity.
Keep each finder blind to the others’ results. Give each: the report header facts, the
non-skipped diff hunks with their risk tags, the commit messages, the ticket
(if any), the conventions file paths, and the changed-file list. Do not
paste file contents or reference-file text into agent prompts — finders
Read files and their shared references on demand; relaying bulk text
through your own context is what blows it up. The finders:

1. `reviso-finder-conventions` — CLAUDE.md / AGENTS.md compliance, branch
   shape, doc staleness
2. `reviso-finder-bugs` — shallow scan of the changes for real bugs,
   including enforcement-vs-claim gaps
3. `reviso-finder-history` — bugs in light of git blame / history
4. `reviso-finder-prior-reviews` — recurring feedback from prior PRs (if a
   GitHub remote exists; otherwise it degrades to commit-message history)
5. `reviso-finder-comments` — compliance with guidance in code comments
6. `reviso-finder-slop` — the anti-slop lens (P0 slop set,
   convention-relative), including duplication above the calibrated bar

Each returns structured candidates per the shared finding schema
(`${REVISO_SKILL_ROOT}/references/finding-schema.md`); every
candidate must carry a concrete failure scenario and a suggested fix.

Finders 3 and 4 read history, and both are bound by
`${REVISO_SKILL_ROOT}/references/history-bound.md`: only
commits reachable from the change's head are admissible evidence. Give
them `MB` and the head SHA so they can check reachability rather than
guess at it.

As each finder resolves, record its ledger row before you move on — six
finders, six rows, written here rather than inferred later. A finder that
returns `[]` is `returned` with a count of zero; a finder whose invocation never
came back, errored, or returned prose instead of a findings array is `no
result`. If you reach Stage 4 with fewer than six rows, the missing ones
are `no result`, not silence you may read as clean.

## Stage 4 — Gather evidence (no filtering here)

For every LLM candidate (not deterministic findings), launch a parallel
`reviso-evidence` agent. Give each: the candidate, the relevant
diff hunks, and the conventions file paths. It re-examines the code and
returns findings of fact — whether the cited lines are part of this
change, what guards, callers, and tests bear on the claimed failure
scenario, whether that scenario reproduces — plus a severity check and a
one-sentence summary. It returns no score, no drop reason, and no
verdict, and it filters nothing: every candidate comes back with its
evidence attached. Judgment happens in Stage 5, and it is yours.

## Stage 5 — Judge (the gate, yours alone), then reconcile

Every filtering decision in the pipeline happens here, once, by you — the
only stage holding every candidate from every lens and the whole change.

Read once:

- `${REVISO_SKILL_ROOT}/references/false-positives.md`
- `${REVISO_SKILL_ROOT}/references/confidence-rubric.md`

For every LLM candidate, with its Stage 4 evidence in hand:

1. Exclusion list first — a match scores 0–25.
2. On lines the change modified? Pre-existing → 0.
3. Weigh the evidence: does the failure scenario survive the guards,
   callers, and tests Stage 4 found?
4. Score 0–100 using the rubric exactly as written — no stricter, no
   looser. The rubric's comparative bands ("relative to the rest of the
   change") are judged here and nowhere else, because only you can see
   the rest of the change: weigh the candidate against every other
   candidate before settling its score.
5. **Silently drop everything below 80.** Never mention a dropped
   candidate in the report itself — the one place it may appear is the
   `--explain` section, and only when the user passed that flag.

Duplication candidates additionally ship only above the calibrated bar,
judged from the occurrence count the slop finder reported: four or more
occurrences ship; exactly three only when the duplicated unit encodes a
rule that can change; two or fewer never ship.

Keep, for every candidate: its lens, its `file:line`, the score you
assigned, and its disposition — reported, or dropped with the reason. The
reason is whichever step above gated it: `exclusion-list` (step 1),
`pre-existing` (step 2), or `rubric-score` (survived both, still under
80); `none` marks a candidate that cleared. That record is what
`--explain` prints; without the flag it stays yours.

If nothing survives and Stage 1 found nothing, skip to the report.

Then reconcile what survived. Dedupe: findings sharing an underlying root
cause merge into one, keeping the strongest evidence and the highest
severity. Consolidate: related minor findings in the same area become one
comment, not several. Prefer silence over a maybe — an uncertain finding
does not ship.

## Stage 6 — Report

Order findings most-severe-first (P0 > P1 > P2; ties by confidence).

Reporting policy — this command's own, since the shared schema carries
format only: no finding ranking below P2 ships. There is no P3; a nit
below the bar is dropped, not reported.

Format:

```text
## Reviso audit — <branch> vs <base> (<n> commits, <m> files)
Base: <base> via <flag|pr|upstream|default> — merge-base <short sha>

Found <k> issues:

1. [P0][conf 95] <one-line title> — path/to/file.ts:42
   Failure: <concrete scenario: inputs/state → wrong outcome>
   Fix: <suggested fix or rewrite>
   (<dimension>; deterministic findings say so here)

...

Checked: <lenses whose ledger row says returned>.
Not checked: <each no-result or skipped lens, with its reason>.
Skipped: <skip-tier files, or "nothing">.
```

The coverage block is derived from the ledger, every run:

- `Checked:` names the lenses with a `returned` row and only those. There
  is no fixed list to fall back on — if you have no row for a lens, you
  may not name it as checked.
- `Not checked:` names each `no result` or `skipped` lens with its reason
  — "history (no result)", "prior reviews (no GitHub remote)". **Emit the
  line only when there is at least one such lens.** A run where every lens
  returned prints no `Not checked:` line at all.
- No per-lens candidate counts here. Counts are `--explain`'s job; a count
  in the default report tells the user findings were withheld.
- `Skipped:` is unchanged and unrelated: it lists skip-tier *files* from
  Stage 2, never lenses. Do not merge the two lines.

If no findings survived: report exactly the header line, then "No issues
found.", then the coverage block — nothing else. That block is the only
thing separating a clean run from a broken one, so derive it here exactly
as above. A zero-finding report that cannot explain its zero is the
failure this command is instrumented to prevent.

### `--explain` (only when the user passed the flag)

Append one section after the findings, in this shape:

```text
--- explain: pipeline diagnostics (not review findings) ---
Finders: conventions 3, bugs 2, history 0, prior-reviews no result,
comments 0, slop 1.
Candidates before the gate (6):
  [slop]        cli_server.rs:2257  score 88  reported
  [conventions] shell_env.rs:453    score 72  dropped: rubric-score
  [bugs]        shell_env.rs:50     score  0  dropped: pre-existing
```

The ledger with counts, then every candidate you kept a record of in Stage
5 — one line each, with the score you assigned and its disposition. Rules: it goes after
the findings, never among them; every line in it is a diagnostic, never a
finding; and the findings section above it is identical whether or not the
flag was passed. Without `--explain`, none of this appears — no dropped
candidate, no score, no reason.

Sink: print to the terminal. If `--out <path>` was given, additionally write
the same report to that path, subject to the host’s execution policy.
The invocation authorizes only that report file; never write anywhere else.
The `--explain` section follows the report to the same sink and adds no
write of its own.

Keep the report brief. No emojis. Cite `file:line` for every finding.

## Stage 7 — False-positive feedback (only if the user asks)

If the report had findings, close with exactly one line: "Wrong about
something? Say which finding — I can file feedback (metadata-only by
default)." Only if the user responds about a finding, read and follow
[the shared feedback procedure](../feedback-flow.md). Do not send anything
without explicit authorization for the displayed payload.
