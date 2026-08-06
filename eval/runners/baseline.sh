#!/bin/sh
# baseline.sh <workdir> <pr> <outdir> — capture the upstream code-review
# baseline for a corpus PR: 3 headless runs, majority = findings matched in
# ≥2 of 3. <workdir> is a throwaway clone of the corpus repo
# (gh-authenticated). Env: REVIEW_CMD (default "/code-review medium"),
# BASELINE_CLAUDE_FLAGS.
#
# The baseline is the built-in /code-review skill PINNED to a level.
# Ambient session effort defaults to xhigh — a recall-biased review with a
# different philosophy — so a command that doesn't name its level would
# silently swap the parity target (design D1).
#
# Clean context: runs load project/local settings only (no user-level
# CLAUDE.md, memory, or plugins), so the baseline is the stock built-in —
# not one shaped by whoever's personal config — and results reproduce
# across machines.
set -eu
WD="${1:?usage: baseline.sh <workdir> <pr> <outdir>}"
PR="${2:?usage: baseline.sh <workdir> <pr> <outdir>}"
OUT="${3:?usage: baseline.sh <workdir> <pr> <outdir>}"
HERE=$(cd "$(dirname "$0")" && pwd)
REVIEW_CMD="${REVIEW_CMD:-/code-review medium}"
mkdir -p "$OUT"

# The executed command must name the review level explicitly (D1).
LEVEL=$(printf '%s' "$REVIEW_CMD" | grep -oE '(^| )(low|medium|high|xhigh|max)( |$)' | head -1 | tr -d ' ') || true
if [ -z "${LEVEL:-}" ]; then
  echo "baseline.sh: REVIEW_CMD must pin a review level (low|medium|high|xhigh|max); got: $REVIEW_CMD" >&2
  exit 1
fi

# CLI version is part of the baseline's identity: runs are comparable only
# when (cli_version, level, resolved models) all match (design D4).
CLI_VERSION=$(claude --version 2>/dev/null | awk '{print $1}')
if [ -z "$CLI_VERSION" ]; then
  echo "baseline.sh: could not determine claude CLI version" >&2
  exit 1
fi

for i in 1 2 3; do
  # Block PR mutation so the run prints instead of commenting.
  # Model pinned for reproducibility: the baseline is the review as a typical
  # subscriber runs it, not on whatever this machine's default is.
  # Clean context drops any personal allowlists, so pre-approve the read-only
  # gh/git set the review needs; posting (gh pr comment) stays blocked.
  # Task/Agent is allowed so the skill's finder/verifier fan-out actually
  # runs — without it the skill degrades to a single-pass fallback, which is
  # rejected below (D1).
  (cd "$WD" && claude -p "$REVIEW_CMD $PR" --output-format json \
      --model "${BASELINE_MODEL:-opus}" \
      --setting-sources project,local \
      --allowedTools "Task,Agent,Bash(gh pr view:*),Bash(gh pr diff:*),Bash(gh pr checks:*),Bash(git diff:*),Bash(git status:*),Bash(git log:*),Bash(git show:*),Bash(git remote show:*),Bash(git fetch:*),Read,Grep,Glob" \
      --disallowedTools "Bash(gh pr comment:*)" \
      ${BASELINE_CLAUDE_FLAGS:-}) > "$OUT/baseline-raw-$i.json"
  jq -r '.result' "$OUT/baseline-raw-$i.json" > "$OUT/baseline-text-$i.md"

  # Findings source, best first (design D2): the typed ReportFindings call
  # in the run's transcript — deterministic, and it carries level, category,
  # and verdict exactly. Prose extraction is the fallback (transcript layout
  # is a CLI internal and may move under us).
  SESSION_ID=$(jq -r '.session_id // ""' "$OUT/baseline-raw-$i.json")
  REPORT_SOURCE="prose"
  OBSERVED_LEVEL=""
  if [ -n "$SESSION_ID" ] && sh "$HERE/report-findings.sh" "$WD" "$SESSION_ID" > "$OUT/baseline-report-$i.json" 2>/dev/null; then
    REPORT_SOURCE="report_findings"
    OBSERVED_LEVEL=$(jq -r '.level // ""' "$OUT/baseline-report-$i.json")
    # The one real level-honored check: the skill reported which level ran.
    if [ -n "$OBSERVED_LEVEL" ] && [ "$OBSERVED_LEVEL" != "$LEVEL" ]; then
      echo "baseline.sh: run $i reported level '$OBSERVED_LEVEL' but the baseline pins '$LEVEL' — refusing a mislevelled baseline" >&2
      exit 1
    fi
    jq '.findings' "$OUT/baseline-report-$i.json" > "$OUT/baseline-findings-$i.json"
  else
    rm -f "$OUT/baseline-report-$i.json"
    # A fallback-mode run is not a baseline. The skill self-reports in its
    # summary when it ran single-pass without subagent fan-out; a degraded
    # pipeline must fail loudly, never be recorded (same policy as parse
    # failures). Checked only on the prose path, and the regex is anchored
    # to the disclaimer's self-referential shape — a review OF code that
    # merely discusses "single-pass reviews" (e.g. this repo's own docs)
    # must not trip it.
    if grep -qiE '(this|the) (review )?was (a |run )?single.pass|single.pass (inline )?review (done|performed|run) without|without the (Task|Agent) tool|not the full multi-agent fan-out' "$OUT/baseline-text-$i.md"; then
      echo "baseline.sh: run $i self-reports the single-pass fallback — fan-out did not run; refusing to record it as a baseline" >&2
      exit 1
    fi
    sh "$HERE/extract.sh" "$OUT/baseline-text-$i.md" > "$OUT/baseline-findings-$i.json"
  fi

  # Per-run metadata: complete or the run fails (parity-eval spec).
  jq -n --arg v "$CLI_VERSION" --arg l "$LEVEL" --arg cmd "$REVIEW_CMD" \
    --arg src "$REPORT_SOURCE" --arg ol "$OBSERVED_LEVEL" \
    --slurpfile r "$OUT/baseline-raw-$i.json" \
    '{cli_version: $v, level: $l, review_cmd: $cmd,
      report_source: $src, observed_level: (if $ol == "" then null else $ol end),
      models: ($r[0].modelUsage // {} | keys)}' > "$OUT/baseline-meta-$i.json"
  if jq -e '.cli_version == "" or .level == "" or (.models | length) == 0' "$OUT/baseline-meta-$i.json" >/dev/null; then
    echo "baseline.sh: run $i metadata incomplete (cli_version/level/models) — refusing to record a run with unknown identity" >&2
    cat "$OUT/baseline-meta-$i.json" >&2
    exit 1
  fi
done

# Merged baseline identity; the three runs must agree on it.
if [ "$(jq -s 'map({cli_version, level, models}) | unique | length' \
        "$OUT"/baseline-meta-[123].json)" != "1" ]; then
  echo "baseline.sh: the 3 runs disagree on cli_version/level/models — not a coherent baseline" >&2
  exit 1
fi
cp "$OUT/baseline-meta-1.json" "$OUT/meta.json"

# Pairwise matches for the majority rule.
sh "$HERE/match.sh" "$OUT/baseline-findings-1.json" "$OUT/baseline-findings-2.json" > "$OUT/match-12.json"
sh "$HERE/match.sh" "$OUT/baseline-findings-1.json" "$OUT/baseline-findings-3.json" > "$OUT/match-13.json"
sh "$HERE/match.sh" "$OUT/baseline-findings-2.json" "$OUT/baseline-findings-3.json" > "$OUT/match-23.json"

# Majority baseline: run-1 findings matched in run 2 or 3, plus run-2
# findings matched in run 3 that no run-1 finding already represents.
jq -n \
  --slurpfile f1 "$OUT/baseline-findings-1.json" \
  --slurpfile f2 "$OUT/baseline-findings-2.json" \
  --slurpfile m12 "$OUT/match-12.json" \
  --slurpfile m13 "$OUT/match-13.json" \
  --slurpfile m23 "$OUT/match-23.json" '
  ($f1[0]) as $f1 | ($f2[0]) as $f2 |
  ($m12[0] | map(.a_idx)) as $a12 |
  ($m13[0] | map(.a_idx)) as $a13 |
  ($m12[0] | map(.b_idx)) as $b12 |
  ($m23[0] | map(.a_idx)) as $a23 |
  [ $f1 | to_entries[] | select((.key as $i | $a12 | index($i)) != null
                             or (.key as $i | $a13 | index($i)) != null) | .value ]
  + [ $f2 | to_entries[] | select(((.key as $j | $a23 | index($j)) != null)
                              and ((.key as $j | $b12 | index($j)) == null)) | .value ]
' > "$OUT/baseline.json"

# Cost is a first-class metric: a candidate that matches findings at 3x the
# price fails the everyday-use bar (target: candidate <= 1.5x baseline mean).
# D11: record resolved model IDs alongside cost — a tier alias like "opus"
# means different models on different dates; the artifact pins which.
jq -s '{runs: [.[].total_cost_usd], mean: (([.[].total_cost_usd] | add) / length), models: ([.[].modelUsage // {} | keys] | add | unique)}' \
  "$OUT/baseline-raw-1.json" "$OUT/baseline-raw-2.json" "$OUT/baseline-raw-3.json" \
  > "$OUT/baseline-cost.json"

echo "baseline: $(jq 'length' "$OUT/baseline.json") majority findings ($(jq 'length' "$OUT/baseline-findings-1.json")/$(jq 'length' "$OUT/baseline-findings-2.json")/$(jq 'length' "$OUT/baseline-findings-3.json") per run), mean cost \$$(jq -r '.mean' "$OUT/baseline-cost.json") → $OUT/baseline.json" >&2
