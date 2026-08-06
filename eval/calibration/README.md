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
| _pending — task 5.5_ | – | – | – | – | – |
| 2026-08-06 | sonnet | 5 (spot-check) | 5/5 | 0/1 | Private-corpus `sagechat-15` cross-run pairs (4 true pairs + 1 contradictory-root-cause trap, authentic per-run wordings). Spot-check only — the ~30-pair sample above is still owed. |

## Tier calibration (judge P0 scope)

The judge's correctness-vs-cleanup tiering is calibrated against the same
hand-labeled cases (labels live in the private corpus; numbers only here).
Publish gate: **≥90% tier agreement**, plus zero trap false-matches on the
matcher checks.

| date | case | agreement | notes |
| --- | --- | --- | --- |
| 2026-08-06 | `sagechat-15` (20 findings, 4 runs) | 16/20 → **19/20 (95%)** | `observability` and `deploy-safety` added to the cleanup list per the labels (all such findings ruled out-of-lane). Remaining disagreement: one efficiency finding labeled actionable — the efficiency-tier boundary stays open, tracked in the private calibration record. |
