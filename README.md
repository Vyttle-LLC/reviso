<p align="center">
  <img src="docs/assets/reviso-lockup-stacked-dark.svg#gh-dark-mode-only" width="220" alt="Reviso">
  <img src="docs/assets/reviso-lockup-stacked-light.svg#gh-light-mode-only" width="220" alt="Reviso">
</p>

<p align="center">
  <strong>The local, pre-PR code review that hits <code>/review</code> quality —
  and catches the AI slop <code>/review</code> misses.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="Apache-2.0"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/DCO-required-brightgreen.svg" alt="DCO"></a>
</p>

---

## What this is

Claude Code's `/review` is excellent — but it only runs on a pull request that
already exists. If you keep a tight commit log, you want that review *before*
you open the PR. The local alternative, `/code-review`, is a different and
weaker review that misses things `/review` catches.

And neither of them reviews for **slop**: dead code, comments that restate the
code, verbose AI-written prose, reinvented utilities, three times the lines the
job needed.

Reviso is the missing review. Two commands, both local, both report-only:

- **`/reviso review`** — assembles a mock PR (`base..HEAD` plus uncommitted work)
  and reviews it the way `/review` would, before the PR exists. Plus the slop lens.
- **`/reviso audit`** — the deep multi-agent adversarial pass, for when you want
  maximum rigour.

It runs on the Claude subscription you already pay for. There is no account, no
signup, and no telemetry.

## Report-only, always

Reviso never edits your files. It reports findings — each with a severity, a
concrete failure scenario, a suggested fix, and a confidence score — and you
decide. This is a permanent design constraint, not a v1 limitation.

## Precision over recall

A review tool that floods you with nitpicks gets muted within a week, and then
it catches nothing at all. Reviso would rather stay silent than show you a
maybe. If it's noisy for you, that's a bug — please
[report it](../../issues/new?template=false-positive.yml), because false
positives are the metric we care about most.

## Install

```bash
# TODO(plugin): install instructions land with the plugin release
```

## Using it in CI

**This is allowed and we've documented it** rather than hiding it — see
[docs/ci.md](docs/ci.md).

One caveat worth stating plainly: **run automation on an API key, not on a
personal subscription.** Subscriptions are licensed for interactive personal
use. If you want a hosted, supported, one-click version of this on your PRs,
that's [Reviso Cloud](https://reviso.dev) — which is how the open source gets
funded.

## Status

Early. The parity bar is that `/reviso review` catches everything `/review`
catches on the same changes; anything it misses is a P0. Our eval results —
including the runs we lose — are published in [docs/evals.md](docs/evals.md).

## Contributing

Yes please. See [CONTRIBUTING.md](CONTRIBUTING.md). Commits need a `Signed-off-by`
line (`git commit -s`) — it takes one flag and we'll help you fix it if you forget.

The most valuable contribution isn't code: it's a **false positive report** or a
**missed finding**. Those become eval cases, and eval cases are how this gets good.

## Licence

[Apache-2.0](LICENSE). The code is open; the name and logo are not — see
[TRADEMARKS.md](TRADEMARKS.md).

Built by [Vyttle](https://vyttle.com).
