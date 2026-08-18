## Reviso audit — HEAD (detached) vs cb3f63a (6 commits, 44 files)

Found 5 issues:

```text
1. [P1][conf 95] testfocus regex flags any `.fit(` call as a committed focused test — skills/reviso/detectors/detect.awk:37
   Failure: A change adds `model.fit(X_train, y_train)` to tests/test_model.py.
   Line 37's class `[^A-Za-z0-9_]` admits `.`, so the sklearn call matches and is
   emitted as a `testfocus` finding. Verified by running both patterns: line 37
   matches `model.fit(...)` and `clf.fit(...)`; line 36's `[^A-Za-z0-9_.]`
   correctly rejects `wrapper.it.only(1)`. Deterministic findings ship at
   confidence 100 and bypass the Stage 5 gate, so this false positive is
   unfilterable — against DISCOVERY.md:3 ("FP-free by construction") and
   CLAUDE.md's "a false positive costs more than a miss".
   Fix: Add `.` to the class on line 37 to match its sibling on line 36:
   `(^|[^A-Za-z0-9_.])(fit|fdescribe)[ \t]*\(`
   (bugs)

2. [P1][conf 90] Majority-vote baseline double-counts one defect as two — eval/runners/baseline.sh:43
   Failure: Runs 1 and 3 match a defect via match-13, and run 2's differently-worded
   version matches run 3 via match-23 but not run 1 via match-12. The jq excludes an
   f2 finding only by membership in `$b12`, never transitively, so both the f1 and f2
   representations land in baseline.json. Reproduced by re-running the verbatim jq
   against synthetic inputs: two entries for one defect. Downstream this inflates
   `baseline_count`, depresses parity_pct, and can fabricate a `missed_P0_regressions`
   entry for a defect the candidate actually caught — which eval/README.md treats as
   a P0 regression, not a percentage.
   Fix: Track consumed f3 indices across both the f1-f3 and f2-f3 match sets, and
   exclude an f2 finding whose f3 counterpart is already represented via f1.
   (bugs)

3. [P2][conf 90] CLAUDE.md still tells agents the plugin "is not here yet" — CLAUDE.md:42
   Failure: The Scope section was accurate at base cb3f63a — none of `.claude-plugin/`,
   `commands/`, `skills/`, `agents/`, `eval/` existed. This branch adds all five, so the
   claim is now false, and the `TODO(plugin)` grep it directs readers to no longer maps
   to what is outstanding. CLAUDE.md opens "This is what an agent should know before
   touching this repo," so an agent reads it and may re-scaffold work that already exists.
   The branch's own task 6.1 ("Resolve TODO(plugin) blocks") is checked off, and commit
   e76eda9 updated README, CONTRIBUTING, and docs/evals.md while leaving this.
   Fix: Update the Scope section to state the P0 surface has landed, and narrow the
   TODO(plugin) pointer to what genuinely remains (docs/ci.md, /reviso:audit).
   (conventions, history, comments — merged)

4. [P2][conf 88] match.sh's "matches at most once" invariant is documented but unenforced — eval/runners/match.sh:30
   Failure: Validation checks only `type == "array"` and key presence. Given
   `[{"a_idx":0,"b_idx":1},{"a_idx":0,"b_idx":2}]` against a 1-finding baseline,
   judge.sh:28-29 computes matched_count 2 and parity_pct 200 — a reported parity
   above 100%. The invariant is enforced only by prompt wording at match.sh:24.
   The missed_P0_regressions list is unaffected (it uses `index()` membership),
   which is what holds this at P2.
   Fix: After the shape check, assert `(map(.a_idx)|unique|length) == length` and
   the same for b_idx, exiting loudly like the existing malformed-output check.
   (bugs, comments — merged)

5. [P2][conf 82] Stale `/reviso review` (no colon) left after this change established the namespace — docs/evals.md:7
   Failure: This branch creates `.claude-plugin/plugin.json` (name "reviso") and
   commands/review.md, making `/reviso:review` the resolvable command — 20+ uses across
   README, CONTRIBUTING, SKILL.md, eval/, and openspec. Commit e76eda9 fixed this exact
   typo twice in README.md and edited docs/evals.md lines 3-5, but left line 7 two lines
   below it. A reader copying that form types a command that does not resolve.
   Fix: Change docs/evals.md:7 to `/reviso:review`. The same two-character fix applies
   to .github/ISSUE_TEMPLATE/false-positive.yml:53 and bug.yml:36, which carry the
   same stale form.
   (conventions, history — merged)
```

Checked: deterministic, conventions, bugs, history, prior reviews (commit history only — `gh` unavailable, so it degraded as designed), comments, slop.
Skipped: eval/reference/code-review-recipe-2026-08-03.md, eval/reference/code-review-recipe-LICENSE, eval/runs/.gitignore, openspec/changes/add-reviso-review/.openspec.yaml, openspec/config.yaml.

```text
--- explain: pipeline diagnostics (not review findings) ---
Finders: deterministic 0, conventions 5, bugs 8, history 2, prior-reviews 0,
comments 4, slop 2.
Candidates before the gate (21):
  [bugs]        detect.awk:37                 score 95  reported
  [bugs]        baseline.sh:43                score 90  reported
  [conventions] CLAUDE.md:42                  score 90  reported
  [history]     CLAUDE.md:42                  score 90  reported (merged)
  [comments]    CLAUDE.md:42                  score 90  reported (merged)
  [bugs]        match.sh:30                   score 88  reported
  [comments]    match.sh:3                    score 88  reported (merged)
  [conventions] docs/evals.md:7               score 82  reported
  [history]     docs/evals.md:7               score 82  reported (merged)
  [bugs]        run.sh:22                     score 70  dropped: rubric-score
  [bugs]        detect.awk:36                 score 68  dropped: rubric-score
  [bugs]        detect.awk:15                 score 65  dropped: rubric-score
  [slop]        reviso-finder-bugs.md:19      score 65  dropped: rubric-score
  [bugs]        detect.awk:7                  score 62  dropped: rubric-score
  [bugs]        extract.sh:27                 score 60  dropped: rubric-score
  [comments]    extract.sh:3                  score 60  dropped: rubric-score
  [conventions] tasks.md:3 (one-concern/PR)   score 40  dropped: rubric-score
  [conventions] docs/ci.md:4                  score 30  dropped: pre-existing
  [conventions] false-positive.yml:53         score 25  dropped: pre-existing
  [comments]    eval/README.md:32             score 20  dropped: exclusion-list
  [slop]        candidate.sh:18               score 15  dropped: rubric-score
```

Notes on the gate, since `--explain` was passed:

- **`run.sh:22` (pipefail, 70)** was the closest call. The mechanism is real — no `pipefail` in POSIX `sh`, and the closing awk's `BEGIN`/`END` print `[]` on empty input, so a broken `detect.awk` yields exit 0 and a clean-looking scan. It dropped because it requires a *future* breakage; nothing in this change triggers it. Worth fixing anyway: it is exactly the "produced nothing vs. found nothing" confusion this command's own coverage ledger exists to prevent.
- **`eval/README.md:32` (20)** was excluded rather than scored down: tasks 5.6/5.7 are openly unchecked and no corpus driver exists for *either* tier, so it documents intended design, not a broken promise.
- **The slop duplication candidate (65)** cleared the occurrence bar at 6, but the substantive policy is already centralized in `skills/reviso/references/`; only a two-line pointer is duplicated, and both real historical edits to it touched all six files without drift.
- Two evidence agents cited commits not reachable from HEAD (eval-fixture leakage). I discarded that evidence and verified the detect.awk claims against the file myself; the prior-reviews finder had correctly rejected the same commits under the history-bound rule.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
