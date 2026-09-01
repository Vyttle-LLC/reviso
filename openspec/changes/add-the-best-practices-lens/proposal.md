# Add the best-practices lens

## Why

Every Reviso lens today judges a change against what is already in the
repository — its conventions, its history, its own norms. None of them
know what the language or the libraries the change uses say about
themselves: that an API on a changed line was deprecated two releases
ago, that the maintainer's docs warn against exactly this call pattern,
that the version a manifest just pinned carries a published advisory.
That knowledge is the reviewer's "you shouldn't do it that way anymore"
— and the audit has no source for it beyond the model's training
cutoff, which is stale by definition. A bounded web lookup, anchored to
the ecosystem's own documentation, closes that gap without turning the
audit into an opinion engine.

## What Changes

- A seventh Stage 3 finder, `reviso-finder-best-practices`, joins
  `/reviso:audit` with a new `best-practices` dimension. It identifies
  the change's ecosystem (language, framework, libraries and their
  pinned versions, from manifests and changed-line imports), runs a
  bounded set of web searches, and returns candidates in four concrete
  classes: a **deprecated or removed API** used on a changed line, a
  **documented misuse** the maintainer's docs warn against, a **known
  advisory** against a version the change pins, and an **idiom the
  official docs supersede** with a named replacement. "Best practice"
  as taste never ships — every candidate quotes an authoritative source
  (official language, framework, or library documentation; a
  maintainer's changelog or deprecation notice; a CVE/GHSA advisory) by
  URL and passage.
- **Opt-in, never default.** The lens runs only when the user passes
  `--web` to `/reviso:audit`. Without the flag the ledger records it
  `skipped (no --web)` and the report says so. Reviso's security policy
  treats any outbound traffic beyond the feedback contract as a
  vulnerability; this change adds a second, explicit contract
  (`docs/web.md`) rather than loosening the first.
- **Queries carry ecosystem facts only.** Language, framework, library
  name and version, and the third-party symbol on a changed line are
  the entire query vocabulary. Diff text, repository identifiers, file
  paths, commit messages, and branch names never leave the machine.
  The finder records every query it ran so the `--explain` section can
  print them.
- **Fetched content is untrusted input.** The finder extracts a quoted
  passage and a URL and follows no instruction it finds on a page. A
  candidate lacking a fetch-verified source, or resting on a claim that
  does not apply to the version the change's manifests allow, is a
  named entry on the false-positive exclusion list — the orchestrator
  scores it 0 with the existing `exclusion-list` reason, so the closed
  drop-reason set is unchanged.
- The audit's ledger, coverage block, `--explain` section, and
  feedback mapping gain the lens. The finding schema's `dimension`
  enum gains `best-practices`.
- Gold: one true-positive / expected-clean synthetic pair, in lane only
  when the eval passes `--web`; the existing gold results are untouched
  because the default invocation never reaches the network.

Out of scope: `/reviso:review` and `/reviso:style` (inner loop and
style-only; both stay offline); any lookup that is not a documented
fact about the ecosystem (Stack Overflow, blog posts, "idiomatic" opinion);
caching or persisting search results; dependency-audit tooling that a
package manager already provides (`npm audit`, `pip-audit`) — the
advisory class covers only versions the change itself pins.

## Capabilities

### New Capabilities

- `web-lookup-contract`: the boundary on Reviso's outbound reads — when
  the network may be touched at all, what a query may contain, how
  fetched content is handled, and what the user can see of it.

### Modified Capabilities

- `review-pipeline`: Stage 3 gains the best-practices finder with its
  four candidate classes and source-anchoring obligation; the ledger and
  coverage block carry its opt-in `skipped` state; the orchestrator
  gate gains the `no-source` drop reason.

## Impact

- `agents/reviso-finder-best-practices.md` — new finder (Sonnet;
  `Read, Grep, Glob, WebSearch, WebFetch`).
- `commands/audit.md` — `--web` flag; Stage 3 fan-out of seven; Stage 5
  `no-source` gate; ledger row and coverage wording; `--explain` query
  list; Stage 7 feedback mapping.
- `skills/reviso/references/finding-schema.md` — `best-practices` in
  the `dimension` enum.
- `skills/reviso/references/false-positives.md` — one Reviso addition
  clarifying that the "general code quality" exclusion is unchanged and
  that an ecosystem claim without a quoted authoritative source is a
  false positive.
- `docs/web.md` (new) and `SECURITY.md` — the web contract, referenced
  the way the feedback contract is.
- `eval/corpus/synthetic/`, `eval/corpus/README.md`,
  `eval/runners/tiers.sh` — the gold pair and its lane.
- `README.md`, `CHANGELOG.md` (next minor), `plugin.json` bump.
- Interaction with in-flight changes: `port-style-lenses-to-the-audit-
  finder` and `recalibrate-the-confidence-rubric` both edit the same
  Stage 3 / Stage 5 prose and the same `review-pipeline` requirement.
  This change restacks on whichever lands first; the delta spec is
  written against `main` as of today.
