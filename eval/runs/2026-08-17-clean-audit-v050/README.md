# Clean synthetics — audit tier, v0.5.0: the precision tripwire

The clean-case leg of `move-judgment-to-the-orchestrator`'s verification
(task 6.4). The change removes every distributed filter and judges once at
the orchestrator; its named risk is that false positives rise, and the
clean-case tier exists to catch exactly that. These are the first
audit-tier runs on the clean synthetics — the prior clean-case anchor is
the review-tier gold sweep (`../2026-08-07-gold-sweep-v0/`), which scored
all three cases at zero false positives.

| case | FPs | cost | wall |
| --- | --- | --- | --- |
| clean-no-issues-001 | 0 | $1.12 | 3m 26s |
| clean-foreach-optional-001 | 0 | $1.58 | 5m 00s |
| clean-error-handling-001 | **1** | $1.91 | ~9m |

## The tripwire fired: one false positive

`clean-error-handling-001` shipped a P1 at confidence 85:
"stat() failure after a successful write deletes the uploaded file"
(`src/services/file-upload.ts:49`).

The finding is *behaviorally accurate*: `writeFile` and `stat` share a try
block whose catch unconditionally unlinks, so a `stat` failure after a
successful write would destroy a valid upload and report it as a write
failure. What it is not is *likely*: `stat` on a just-written local path
failing while the write succeeded is a transient-corner case. The rubric's
75 band requires "very likely … a real issue that will be hit in
practice"; judged as written, this belongs in the 50 band ("might be a
nitpick or not happen very often in practice") and under the gate. The
orchestrator scored the mechanism, not the likelihood.

Two readings, deliberately left open for the rubric work:

- **Precision regression** — the distributed gate (review tier, v0)
  reported nothing here; the orchestrator gate at n=1 shipped a
  low-likelihood finding. The mitigation named in the change's design —
  observe on the clean tier, treat the FP count as the tripwire — worked;
  this run is the observation.
- **Rubric miscalibration, not position** — the same rubric that
  underscored real enforcement-vs-claim findings at 68/40 overscored a
  real-but-rare mechanism at 85. Both errors are band-fit errors, which is
  `recalibrate-the-confidence-rubric`'s territory, not an argument for
  restoring distributed vetoes.

n=1 per case; a variance read needs repeats.
