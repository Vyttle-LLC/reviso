# Contributing to Reviso

## The most useful thing you can contribute

Not code — **evidence**.

- **[False positive report](../../issues/new?template=false-positive.yml)** —
  Reviso flagged something that wasn't a problem. This is the single most
  valuable issue you can file. Noise is how review tools die.
- **[Missed finding](../../issues/new?template=missed-finding.yml)** — a real
  bug Reviso didn't catch, or something `/review` caught and we didn't. The
  second kind is a **P0** for us.

Both become cases in the eval corpus, which is how review quality actually
improves. A good FP report beats a good PR.

## Sign your commits off (DCO)

Every commit needs a `Signed-off-by` line. Add it with `-s`:

```bash
git commit -s -m "your message"
```

This appends:

```text
Signed-off-by: Your Name <your.email@example.com>
```

### What you're agreeing to

The [Developer Certificate of Origin](https://developercertificate.org/) — a
short statement that you wrote the contribution, or otherwise have the right to
submit it under this project's licence.

**We do not use a CLA.** You keep your copyright and you assign us nothing. Your
contribution is licensed under Apache-2.0, same as everything else here, per
Apache-2.0 §5. We think asking contributors to sign away rights to a company is
a bad trade, so we don't.

### If you forget

Common and fine. You have three options, easiest first:

1. **Push a remediation commit.** No rebase, no force-push. The failing check
   gives you the exact text to use.
2. **Ask a maintainer.** We have third-party remediation enabled, so we can sign
   off on your behalf. Just say so on the PR — especially for typo fixes.
3. **Amend and force-push**, if you'd rather have clean history:

   ```bash
   git rebase --signoff origin/main   # all commits on your branch
   git push --force-with-lease
   ```

If you edit files through the GitHub web UI, the sign-off is added
automatically.

We will never bounce a good contribution over a missing sign-off. Worst case we
add it for you.

## Setup

```bash
git clone https://github.com/Vyttle-LLC/reviso.git
cd reviso
# TODO(plugin): dev setup lands with the plugin build
```

## Pull requests

- One concern per PR. Small and reviewable beats complete.
- Prompt and lens changes **must** include eval results — see below.
- We squash-merge. Your PR title becomes the commit message, so write it well.

### Changing review behaviour

Anything that touches prompts, lens definitions, the false-positive exclusion
list, or the confidence rubric changes what Reviso says to people. Those PRs
need eval numbers before and after, run on the corpus in `eval/`. A change that
improves recall while quietly hurting precision is a regression here, and we
would rather find that in the PR than in someone's terminal.

If you can't run the evals, open the PR anyway and say so — we'll run them.

## Style

Match what's already there. Reviso enforces convention inheritance on other
people's code; the least we can do is follow our own.

## Code of Conduct

[Contributor Covenant](CODE_OF_CONDUCT.md). Reports go to <support@vyttle.com>.
