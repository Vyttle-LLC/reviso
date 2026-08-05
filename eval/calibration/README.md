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
