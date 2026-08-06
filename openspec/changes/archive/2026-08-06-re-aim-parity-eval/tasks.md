# Tasks — re-aim-parity-eval

## 1. Smoke-run the real baseline (validates D1's assumptions before any code)

- [x] 1.1 Run built-in `/code-review medium <PR-15>` headless with Task in
      `--allowedTools`, `--setting-sources project,local`; confirm the
      8-angle fan-out runs (no single-pass disclaimer), confirm the level
      argument is honored, and capture the output shape (JSON contract vs
      prose)
- [x] 1.2 Record what the smoke run establishes in the design's Open
      Questions (argument syntax, setting-sources interaction, output
      contract); adjust D1/D2 if reality disagrees

## 2. Baseline runner

- [x] 2.1 `baseline.sh`: change `REVIEW_CMD` default to `/code-review
      medium`, add Task to `--allowedTools`, keep `gh pr comment` blocked
- [x] 2.2 `baseline.sh`: write `meta.json` per run — `claude --version`,
      pinned level, resolved model ID; fail the run if any field is missing
- [x] 2.3 `baseline.sh`: detect the skill's single-pass-fallback
      self-report in output and fail that run loudly
- [x] 2.4 `extract.sh`: fast path parsing the skill's JSON findings block
      (preserve `category` and `verdict`); prose extraction stays as
      fallback

## 3. Judge and metrics

- [x] 3.1 `judge.sh`/`match.sh`: carry `category` through matching; bucket
      misses into correctness-tier (P0) vs cleanup-tier (informational)
- [x] 3.2 Judge classifies uncategorized baseline findings, defaulting to
      correctness-tier on ambiguity
- [x] 3.3 Judge refuses (or labels non-comparable) comparisons across
      differing recorded CLI versions

## 4. Reference and docs

- [x] 4.1 `eval/reference/`: add the extraction method (script + notes)
      producing local-only skill text, plus per-CLI-version content hash
      and structural summary; commit no verbatim text
- [x] 4.2 `eval/reference/README.md`: mark the 2026-08-03 marketplace
      snapshot superseded (retained as history), point at the behavioral
      drift process
- [x] 4.3 `eval/README.md`: rewrite target definition (built-in medium,
      correctness tier, comparability rule, CLI-roll = re-baseline);
      re-state the cost target against the new denominator
- [x] 4.4 Add `SUPERSEDED` notes to `eval/runs/2026-08-03-*` and
      `2026-08-04-*` identifying them as fallback-mode baselines
- [x] 4.5 `docs/evals.md`: update published-metrics description to the
      correctness-tier scope

## 5. Calibration entry (private tier)

- [x] 5.1 Add PR-15 as a private-corpus entry (via
      `REVISO_EVAL_PRIVATE_CORPUS`); nothing private committed
- [x] 5.2 Labels file: per finding across the three runs (Reviso, medium,
      xhigh) — source run, category, hand verdict (real / not-real /
      out-of-lane); Michael supplies the verdicts
- [x] 5.3 Re-run the judge on the labeled entry; record agreement and the
      tolerance used; gate publishing parity numbers on it
