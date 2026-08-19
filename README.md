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
code, verbose AI-written prose, reinvented utilities, the same rule copy-pasted
across five call sites, three times the lines the job needed.

Reviso is the missing review. Three commands, all local, all report-only:

- **`/reviso:review`** — the inner-loop review: assembles a mock PR
  (`base..HEAD` plus uncommitted work) and reviews it in a single pass, the
  way `/review` does, at comparable cost. Plus the slop lens. Run it as
  often as you commit.
- **`/reviso:audit`** — the pre-PR gate: parallel blind finders per
  dimension, per-candidate evidence gathering, then a single confidence
  gate applied by the orchestrator with the whole change in view. Slower
  and heavier, for when the branch is about to become a PR. (Full
  adversarial multi-skeptic depth lands in P1.)
- **`/reviso:style`** — the style lane: slop, drift from your repo's own
  conventions, comment and method length, duplication, over-engineering,
  dead weight, test slop, AI tells — and nothing else. Every finding is
  measured against how *your* codebase writes, with the baseline cited —
  no bug hunting, no absolute thresholds, with two deliberate exceptions:
  a comment must earn its place (only a written convention overrides),
  and placeholder text is always a finding.

The intended rhythm: code → `review` → fix → a few more commits →
`audit` → open the PR. Reach for `style` when the question is "is this
clean?" rather than "is this correct?" — a fresh AI-written change, a
refactor you suspect got verbose, a branch you're about to hand off.

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

## Feedback that can't leak your code

The catch with false-positive reports: the finding is about *your* code. So
the feedback design is bound by a written privacy contract —
[docs/feedback.md](docs/feedback.md). The short version: nothing is ever sent
automatically; the default report is metadata-only, built by a deterministic
script from an allowlist the model can't reach past; and anything that
includes code opens as a prefilled issue in your browser for you to read,
edit, and send yourself. After a review, name a wrong finding and Reviso
offers to file it under exactly those rules.

## Install

In Claude Code, run these as two separate commands (use the full clone
URL — `owner/repo` shorthand is not accepted):

```text
/plugin marketplace add https://github.com/Vyttle-LLC/reviso.git
```

```text
/plugin install reviso@reviso
```

Then run `/reviso:review` on any branch. Default diff base is your repo's
default branch; override with `--base <ref>`.

Updates are not automatic: `/plugin update reviso@reviso` pulls the latest
release, or enable auto-update for the marketplace under `/plugin` →
Marketplaces. `/plugin list` shows the version you're running.

To try it without installing (or to hack on it), load it straight from a
checkout:

```bash
claude --plugin-dir /path/to/reviso
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

Early. The parity bar is that `/reviso:review` catches everything `/review`
catches on the same changes; anything it misses is a P0. Our eval results —
including the runs we lose — are published in [docs/evals.md](docs/evals.md).

What's here today: `/reviso:review` (single-pass mock-PR review, anti-slop
lens, deterministic detectors), `/reviso:audit` (the multi-agent
finder + verify pipeline), `/reviso:style` (the single-pass style-only
lane, calibrated to your repo's own norms), the parity eval harness in
[eval/](eval/), and the assisted false-positive feedback flow under the
[docs/feedback.md](docs/feedback.md) privacy contract.
Deliberately not yet: audit's full adversarial multi-skeptic depth (P1),
comment humanization (P1), `.reviso/` team memory — rules and dismissal
learnings (P2) — and a lane restructure under consideration (`review` at
`/code-review` parity, `audit` as review + style + architecture).
Report-only is permanent; those aren't.

## Contributing

Yes please. See [CONTRIBUTING.md](CONTRIBUTING.md). Commits need a `Signed-off-by`
line (`git commit -s`) — it takes one flag and we'll help you fix it if you forget.

The most valuable contribution isn't code: it's a **false positive report** or a
**missed finding**. Those become eval cases, and eval cases are how this gets good.

## Licence

[Apache-2.0](LICENSE). The code is open; the name and logo are not — see
[TRADEMARKS.md](TRADEMARKS.md).

Built by [Vyttle](https://vyttle.com).
