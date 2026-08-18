# reviso-6 — review tier, v0.5.0, after judgment moved to the orchestrator

The review-tier leg of `move-judgment-to-the-orchestrator`'s verification
(task 6.3): confirm the single-pass tier still behaves as it did once
reporting policy moved from the shared finding schema into
`commands/review.md` itself. Compare against
`../2026-08-14-reviso-6-review-v040/` — same case, same SHAs, same runner.

```text
command   /reviso:review --base cb3f63a4… --explain
cost      $2.49
wall      8m 48s
models    claude-opus-5
```

## Result

| | v0.4.0 | this run (v0.5.0) |
| --- | --- | --- |
| candidates before the gate | 10 | 14 |
| reported | 4 (one merge) | 7 (one merge) |
| cost | $2.04 | $2.49 |

Per-lens candidate yield: bugs 6, conventions 5, comments 1, slop 2,
history 0, deterministic 0.

## What it shows about the policy move

**Every policy the command now states for itself was applied.** No
finding below P2 shipped (the report is 4×P1 + 3×P2); the 8-finding cap
held (8 scored ≥80, one merged, 7 shipped); related candidates were
consolidated (the detect.awk pair merged into one finding); the coverage
line was derived from the ledger; the `--explain` section carries every
candidate with score and disposition. The gate itself is unchanged — the
review tier's orchestrator was always its own finder and judge, and its
Step 4 self-gate reads identically.

**The volume delta is not attributable to the policy move.** The prompt
text this change touched in `review.md` restates the same floor and cap
the schema used to carry; nothing loosened. Candidate volume on this case
has swung far wider than 10→14 between runs of *identical* versions (the
audit tier recorded 13 hand vs 5 runner at v0.4.0). Task 6.3's check is
policy meaning, not byte identity, and the meaning held.
