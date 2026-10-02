# Matcher calibration

`match.sh` decides what counts as "the same finding" — every parity number
rests on it. It is not trusted until it agrees with hand labels (task 5.5).

## Format

`labels.jsonl` — one hand-labeled pair-judgment per line:

```json
{"id": "sample-001", "a": {<finding>}, "b": {<finding>}, "label": "match | no-match", "why": "one sentence"}
```

Build the sample from real baseline runs (both matched-looking and
trap pairs: same file + similar topic but different root cause). Aim for
~30 pairs with at least 10 traps.

## Procedure

1. Run `match.sh` over the labeled pairs (one pair per call, lists of 1).
2. Score: agreement rate overall, and separately on traps
   (false-match rate is the number that matters — a lenient matcher
   inflates parity).
3. Record results + matcher prompt version below. Tune the prompt, never
   the labels. Re-run after any prompt or `JUDGE_MODEL` change.

## Results

| date | model | pairs | agreement | trap false-match | notes |
| --- | --- | --- | --- | --- | --- |
| 2026-08-06 | sonnet | 5 (spot-check) | 5/5 | 0/1 | Private-corpus `sagechat-15` cross-run pairs (4 true pairs + 1 contradictory-root-cause trap, authentic per-run wordings). Spot-check only — the ~30-pair sample above is still owed. |
| 2026-10-02 | Codex `gpt-6.1-sol`, medium | 30 | **30/30** | **0/15** | Authentic CRB gold/candidate pairs from the first sweep; 15 same-root-cause pairs and 15 same-topic traps. [Recorded judgments](results/2026-10-02-codex/judgments.jsonl), [run identity](results/2026-10-02-codex/summary.json). |

The sample now lives in [labels.jsonl](labels.jsonl). Each pair preserves
the authentic finding text and points to its source artifact and index;
the hand label and rationale were fixed before the first model call.
The sample includes null-file/zero-line gold anchors, adjacent defects in
the same file, and similar symptoms with different causes. One trap is a
false match from the original sweep: process-randomized cache keys are not
the same defect as added network latency or stale TTL eligibility.

Run one independent matcher call per pair:

```sh
MATCH_HOST=codex MATCH_CODEX_MODEL=gpt-6.1-sol MATCH_CODEX_EFFORT=medium \
  python3 eval/calibration/run.py eval/calibration/labels.jsonl <new-outdir>
```

For Claude, omit `MATCH_HOST` and pin `JUDGE_MODEL`. The runner requires at
least 30 pairs and 10 traps and passes at ≥90% agreement with zero trap
false matches. It records the CLI version, requested model/effort, and
hashes of the matcher and labels. Codex uses the same matching prompt in
an isolated, read-only session; its settings are required, never implicit.

**This result calibrates the named Codex configuration only.** Claude was
unavailable for this session; its historical five-pair spot-check remains
its only measurement. Do not retroactively treat old Claude judgments as
validated or transfer this result across models, hosts, or prompt changes.

## Tier calibration (judge P0 scope)

The judge's correctness-vs-cleanup tiering is calibrated against the same
hand-labeled cases (labels live in the private corpus; numbers only here).
Publish gate: **≥90% tier agreement**, plus zero trap false-matches on the
matcher checks.

| date | case | agreement | notes |
| --- | --- | --- | --- |
| 2026-08-06 | `sagechat-15` (20 findings, 4 runs) | 16/20 → **19/20 (95%)** | `observability` and `deploy-safety` added to the cleanup list per the labels (all such findings ruled out-of-lane). Remaining disagreement: one efficiency finding labeled actionable — the efficiency-tier boundary stays open, tracked in the private calibration record. |
