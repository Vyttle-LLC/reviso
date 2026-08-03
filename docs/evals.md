# Eval results

> **Stub.** The harness is built — see [eval/](../eval/README.md) for how
> baselines, candidates, and the judge work. Numbers land here with the
> first published public-corpus runs.

The parity bar: `/reviso review` should catch everything Claude Code's
`/review` catches on the same changes. Anything it misses is a P0.

We publish the runs we lose alongside the ones we win. A review tool that only
reports its wins is not measuring anything.

This page will cover:

- The corpus: where the cases came from, and how false-positive and
  missed-finding reports become new ones
- Precision and recall per lens, per release
- Head-to-head runs against `/review` and `/code-review`
- The regressions, and what we did about them
