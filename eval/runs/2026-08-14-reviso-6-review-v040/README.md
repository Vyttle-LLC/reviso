# reviso-6 — review tier, v0.4.0, after the history bound

The review-tier leg of `measure-the-audit-tier`'s verification (task 7.1):
re-run an in-repo case on `/reviso:review` once the history bound
(`skills/reviso/references/history-bound.md`) had landed, and check the
bound did not silence the lenses it constrains.

```text
command   /reviso:review --base cb3f63a4… --explain
cost      $2.04
wall      6m 25s
models    claude-opus-5
```

## Result

| | |
| --- | --- |
| candidates before the gate | 10 |
| reported | 4 (one merge) |

Per-lens candidate yield: conventions 4, bugs 3, comments 2, slop 1,
history 0, deterministic 0. The single-pass tier applies five lenses
inline; `prior-reviews` is an audit-tier finder and has no row here.

## What it shows about the bound

**The history lens returned, and returned nothing.** `returned` with a
count of zero is a result — the lens looked and concluded — and is what the
coverage ledger exists to distinguish from `no result`. So the bound did
not error the lens out or remove it from the pipeline.

**But zero is zero, and this run alone cannot attribute it.** There is no
pre-bound `/reviso:review --explain` run on this case to compare against,
so "the bound cost the history lens its candidates" and "the history lens
had nothing to say on this diff" are not separable here. Read on its own,
this run is consistent with either.

The attribution comes from the audit-tier run recorded the same day
(`../2026-08-14-reviso-6-audit-v040/`), where the bound is observable
rather than inferred: its `history` lens reached a real conclusion and
dropped it because the only evidence was a non-ancestor commit, and its
`prior-reviews` lens named the PR it excluded and why. The finding survived
anyway, through an unbounded lens that reached it from in-branch files. The
bound excluded contaminated evidence without costing a reported finding —
that is the claim task 7.1 needed, and it rests on that run, not this one.

## Note

The findings here describe the repository as it stood at `e76eda9` — the
bare `Bash` grants, the hardcoded coverage line, the stale `TODO(plugin)`
scope section. All three have since been fixed on `main`. The case is
pinned at that SHA on purpose; the findings are correct about the code
under review, not about the repository today.
