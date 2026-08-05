# Feedback without disclosure

> **This page is a contract first.** The assisted flow below is implemented
> by `skills/reviso/feedback/build-payload.sh` and offered by both commands
> after a report. The contract outranks the code: an implementation change
> that violates any invariant here is a security bug (see
> [SECURITY.md](../SECURITY.md)), not a design choice. You can always skip
> the assistance and file manually via the
> [false positive](../../../issues/new?template=false-positive.yml) and
> [missed finding](../../../issues/new?template=missed-finding.yml) forms.

False-positive reports are the metric Reviso is tuned against — and the
hardest report to file, because every finding is about *your* code, which is
often exactly what you can't paste into a public issue. The assisted flow
exists to remove that friction without ever removing your control: at the end
of a review, Reviso can offer to file the report for you.

## The invariants

1. **Nothing is ever sent automatically.** No telemetry, no phone-home, no
   "anonymous usage data". A report exists because you said yes to that
   specific report, in that session. Silence sends nothing.
2. **One outbound channel.** The only network write Reviso may ever make is a
   feedback report to this repository's issue tracker. Any other destination,
   or any other kind of write, is a vulnerability.
3. **The model never composes an outbound payload.** Prompts are a request,
   not a guarantee. A deterministic script builds every payload from the
   allowlist below; the model may only select a finding and pick from enums.
   Unknown fields are dropped, not sent.
4. **Code travels only through your hands.** Anything beyond metadata opens
   as a prefilled issue form in your browser. You read it, edit it, and
   submit it yourself — nothing leaves the machine that a human didn't see.

## Tier 1 — the metadata report (default)

Built by the script, shown in full before sending, small enough to read in
one glance.

Sent:

- The lens that produced the finding (`bugs`, `conventions`, `history`,
  `prior-reviews`, `comments`, `slop`, `deterministic`) and, for
  deterministic findings, the detector id
- Severity and confidence bucket (80s / 90s / 100)
- Why you judged it wrong, from a fixed list: codebase convention, upstream
  guarantee, deliberate choice, linter territory, wrong on the facts, other
- The command that ran, the plugin version, the model

Never sent, by construction: file paths, the finding's title, failure
scenario, evidence, suggested fix, code snippets, diff hunks, branch names,
ticket ids, or any free text. A tier-1 payload has nowhere to put your code.

## Tier 2 — the code-context report (opt-in per report)

Tier 1 tells us *which* lens or detector misfires and how often — enough to
recalibrate confidence. It cannot tell us *why* a specific finding was wrong.
When you're willing to show the code, Reviso hands you a link to the
[false positive form](../../../issues/new?template=false-positive.yml)
prefilled with the finding as reported — nothing else. You open it, add the
code and the why yourself, edit anything, and submit it yourself. The form
is the payload: you see every character before it exists anywhere but your
machine. Redact freely; a redacted report is still an eval case.

Reports are GitHub issues filed from your account, so your GitHub identity
is attached — the same as any issue you file by hand.

## Backstops

Belt and braces on top of the allowlist, all in the deterministic script:

- Secret-pattern and high-entropy scan on the final payload; any hit
  refuses to send and says why
- Reject payloads containing code fences or diff markers, and any tier-1
  field value shaped like a path — no payload field can name a file in
  your tree
- A hard length cap a code snippet can't fit under
- The exact payload is printed before the send, every time

## What this buys

Tier 1 flows freely because it can't hurt you, so calibration data arrives
at volume. Tier 2 carries the insight, and arrives only through a human's
deliberate act. Both land labelled `eval-candidate` — the pipeline that
turns them into eval cases is described in [evals.md](evals.md).
