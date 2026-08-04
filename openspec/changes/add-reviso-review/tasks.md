# Tasks: add-reviso-review

Groups map to the intended PR stack (one concern per PR, repo rule).

## 1. Plugin skeleton

- [x] 1.1 Create `.claude-plugin/plugin.json` (name `reviso`) and verify
      `/reviso:review` namespace resolves on a local install
- [x] 1.2 Check `claude-plugins-official` license for verbatim vendoring
      (OQ2); vendor dated recipe snapshot into `eval/reference/` (or hash +
      structural summary if redistribution is unclear)
- [x] 1.3 Stub `commands/review.md` with read-only `allowed-tools`
      frontmatter (D3) and flag parsing (`--base`, `--out`)

## 2. Mock-PR assembly (Stage 0)

- [x] 2.1 Implement deterministic assembly steps in the command: base
      resolution (`origin/HEAD` default, `--base` override), full
      `base..HEAD` diff + uncommitted, commit messages, changed-file
      contents
- [x] 2.2 Add conventions gathering (root + path CLAUDE.md / AGENTS.md,
      lint configs on changed paths) and ticket inference (branch name,
      commit trailers)
- [x] 2.3 Verify reproducibility: two runs on identical git state produce
      identical assembled context

## 3. Review pipeline (Stages 2–4 + report)

- [x] 3.1 Write finder agent definitions in `agents/`: the five recipe
      dimensions forked to local mock-PR context, blind fan-out via Task
- [x] 3.2 Write the anti-slop finder (P0 slop set, convention-relative,
      failure scenario + suggested rewrite per candidate)
- [x] 3.3 Write the triage pass (risk tags + skip-tier; tags injected into
      finder prompts; skipped content listed in coverage summary)
- [x] 3.4 Write the verifier agent: recipe rubric verbatim + FP exclusion
      list, per-finding scoring, <80 gate, deterministic-finding bypass
- [x] 3.5 Write the report stage: dedupe, consolidation, severity ranking,
      line-anchored format, terminal default / `--out` sink, clean-review
      message
- [ ] 3.6 End-to-end dogfood on a real Vyttle branch; confirm report-only
      invariant (working tree byte-identical after run)

## 4. Deterministic detectors (Stage 1)

- [x] 4.1 Discovery (OQ1): prototype candidate detectors against real
      Vyttle diffs; keep only FP-free survivors, route the rest to the
      anti-slop finder
- [x] 4.2 Implement surviving detectors as zero-dependency scripts under
      `skills/reviso/detectors/`, emitting the shared finding schema
      tagged `deterministic`, change-scoped only
- [x] 4.3 Wire Stage 1 into the command ahead of all LLM stages; verify
      zero-token cost and gate bypass

## 5. Parity eval harness

- [x] 5.1 Define corpus entry schema + two-tier layout (`eval/corpus/`
      public; private tier by local path, never committed)
- [x] 5.2 Build the baseline runner: 3 headless `/review` runs per PR,
      majority-of-2 baseline, raw + parsed outputs to `eval/runs/`, loud
      parse failures
- [x] 5.3 Build the candidate runner: checkout head SHA, `/reviso:review`
      against recorded base SHA, same output capture
- [x] 5.4 Write the judge: conservative root-cause matching →
      matched / missed / claimed-win; metrics report with per-miss P0
      listing, parity %, verified wins, dismissal rate
- [ ] 5.5 Calibrate the judge on a hand-labeled sample; record calibration
      results in `eval/`
- [ ] 5.6 Seed the private tier with Vyttle PRs and run the first full
      parity eval; file each miss as a P0 issue
- [ ] 5.7 Seed a small public tier (OQ4: curated OSS PRs and/or seeded-bug
      PRs) and publish the first run per docs/evals.md

## 6. Docs

- [x] 6.1 Resolve `TODO(plugin)` blocks: README install instructions,
      CONTRIBUTING dev setup, docs/evals.md corpus + runs
- [x] 6.2 Note deferred items where users will look for them: `audit` (P1),
      humanization (P1), `.reviso/` memory (P2), `--staged` decision (OQ3)

## 7. First-cycle findings (dogfood + baseline, 2026-08-03)

- [ ] 7.1 Cost parity: get `/reviso:review` per-run cost to ≤1.5× a `/review`
      run (measured 2026-08-03: ~$10 vs ~$3 equivalent). Levers: stop
      pasting full-file contents to every finder (let them Read on demand),
      inline the schema/FP text into agent prompts instead of per-agent
      Reads, fold triage into the orchestrator turn, record cost per run in
      eval artifacts
- [ ] 7.2 Work the parity miss list from the reviso#6 baseline (real bugs
      confirmed fixed same-day: write-capable allowed-tools patterns,
      unscoped agent Bash, `.fit(` detector FP, plus-plus header misparse,
      stale docs spelling, proposal/design dimension drift). Remaining
      misses need finder/context tuning, then re-judge
- [ ] 7.3 baseline.sh: fail loudly when `/review` refuses eligibility
      (closed/draft PR) instead of producing an empty-looking run
- [ ] 7.4 extract.sh: broaden the claims-issues cross-check beyond the
      "found N issues" phrasing (refusals, alternate formats)
- [ ] 7.5 Document the prompt-injection surface in SECURITY.md (finder
      inputs: commit messages, blame, PR comments; eval scripts interpolate
      untrusted review text into prompts)
- [ ] 7.6 Add a committed fixture test for detect.awk (the scratchpad
      fixture, made repeatable) so detector changes are CI-checked
