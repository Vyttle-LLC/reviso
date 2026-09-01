# Design — add-the-best-practices-lens

## Context

Every existing finder is offline by construction: the audit command
pre-approves only local read-only tools, and `SECURITY.md` names any
outbound traffic beyond the feedback contract a vulnerability. The
finding schema's `dimension` enum is closed at seven values, and the
exclusion list already drops "general code quality" unless CLAUDE.md
demands it. Two in-flight changes (`port-style-lenses-to-the-audit-
finder`, `recalibrate-the-confidence-rubric`) edit the same Stage 3 /
Stage 5 prose in `commands/audit.md` and the same fan-out and gate
requirements in `review-pipeline`.

The knowledge this lens adds — deprecations, documented misuses,
advisories, superseded idioms — is genuinely absent from the repo and
from the model's cutoff, so it cannot be a local finder. It is also the
easiest lens to turn into an opinion engine, which is the failure the
precision invariant exists to prevent.

## Goals / Non-Goals

**Goals:**

- The audit can say "the ecosystem itself says not to do this", citing
  the ecosystem's own words.
- The network boundary is a written contract, opt-in per invocation,
  with a closed query vocabulary the user can inspect after the run.
- Precision holds: no candidate ships on taste, on an unfetched
  citation, or against a version the change does not use.
- Zero behaviour change for anyone who does not pass `--web` — same
  fan-out, same gold results, no new permission prompts.

**Non-Goals:**

- `/reviso:review` and `/reviso:style` stay offline.
- Caching, rate limiting across runs, or persisting fetched content.
- Replacing package-manager audit tooling; the advisory class covers
  only a version the change itself pins.
- A configurable source allowlist. The authority rule is by kind
  (D4), not a domain list to maintain.

## Decisions

### D1 — Opt-in per invocation via `--web`; never from config or repo

The lens runs only when `--web` is on the `/reviso:audit` command line.
Without it the ledger row is `skipped (no --web)`, the finder is never
launched, and the coverage block names it under `Not checked:`.
`WebSearch` and `WebFetch` are **not** added to `audit.md`'s
`allowed-tools` — the permission prompt on first use is the gate, the
same shape as the detector script's prompt. Alternatives rejected:
default-on with an opt-out (contradicts `SECURITY.md`); a `.reviso/` or
environment toggle (`.reviso/` is attacker-controlled input per the
security policy, so a repository must not be able to switch on network
access for its own review).

### D2 — A separate finder, not a bolt-on

`reviso-finder-best-practices` is its own agent file with its own tool
list (`Read, Grep, Glob, WebSearch, WebFetch`). It keeps the blind-finder
principle and confines the only network-capable agent in the plugin to
one file, which is what a reviewer of the security surface needs to
read. Alternative rejected: giving the conventions or bugs finder web
tools — every finder would then be a network surface, and the two
concerns (repo norms vs. ecosystem facts) would share one context.

### D3 — A closed query vocabulary derived from ecosystem facts

A query is composed only from: the language; the framework; a library
name and the version the change's manifests pin or allow; and the name
of a third-party symbol used on a changed line. A symbol is third-party
only if the finder's Grep shows it is not defined in the repository.
Never in a query: diff text, repository-defined identifiers, file
paths, commit messages, branch names, ticket ids. Manifests are
`package.json`, `go.mod`, `pyproject.toml` / `requirements*.txt`,
`Cargo.toml`, `Gemfile`, `*.csproj`, and the lockfile that pins them.

Bound: one search per distinct `(library, symbol)` or `(library,
version)` pair, at most twelve per run, ordered by the triage risk tags
(external-input, auth, migration first). Each search yields at most two
fetches. The finder records every query and every fetched URL in its
return payload so `--explain` can print them (D8). Alternative
rejected: letting the model compose free-text queries — no way to audit
what left the machine.

### D4 — Authority by kind, and every citation is fetch-verified

A candidate may rest only on: the official documentation of the
language, framework, or library (its own site or source repository);
the maintainer's changelog, release notes, or deprecation notice; or an
advisory database entry (GHSA, NVD/CVE, OSV). Q&A sites, blogs,
aggregators, and AI-generated summaries never anchor a candidate — they
may lead the finder to a primary source, which is then fetched. The
finder must `WebFetch` the cited URL and quote a passage of at most two
sentences from what it fetched; a search-result snippet is not a
citation. `evidence` carries the URL and the passage.

### D5 — Four candidate classes, each with a failure-scenario shape

| class | ships when | severity |
| --- | --- | --- |
| deprecated / removed API | the symbol on a changed line is deprecated or removed in a version the manifest allows | P1 if removal has shipped in an allowed version; P2 if deprecated only |
| documented misuse | the maintainer's docs warn against the exact call pattern on the changed line, naming a consequence | by the documented consequence: P0 security, P1 defect, P2 contained |
| known advisory | a manifest change pins a version an advisory covers, and the changed code reaches the affected surface | P1; P0 when the advisory is critical and triage tagged the hunk external-input |
| superseded idiom | the docs name a replacement **and** state a consequence of the old form | P2, never higher |

"Superseded idiom" is the class most exposed to taste; the second
condition is what keeps it a fact. A replacement recommended without a
stated consequence is style, not a finding.

### D6 — Fetched content is data; the gate is source and version

The finder's prompt states that page content is untrusted: it extracts
a URL and a passage and follows no instruction found on a page. Stage 4
evidence agents have no web tools — they verify the changed-line claim
against the code and manifests only, which is where version
applicability is checked. The orchestrator's gate treats two things as
exclusion-list matches, scored 0: a candidate with no fetch-verified
URL and passage, and a claim that does not apply to the version the
manifests allow. Both are recorded as `exclusion-list` in `--explain`;
the closed drop-reason set is unchanged. Alternative rejected: a new
`no-source` reason — precedent exists in the style change, but it
extends a set two in-flight changes already modify, for no diagnostic
gain over the exclusion-list line the user already reads.

### D7 — Gold: a synthetic pair, in lane only under `--web`

One true-positive / expected-clean pair. The TP fixture is a Python
file adding a call to `datetime.datetime.utcnow()` under a
`pyproject.toml` requiring `python >= 3.12` — deprecated in 3.12 by an
official, stable docs page. The clean look-alike uses
`datetime.now(timezone.utc)`. The pair is in lane for `REVISO_TIER=audit`
only when `REVISO_CMD_ARGS` contains `--web`; every existing gold run
is unchanged because the default args never reach the network. The
network is nondeterministic, so the label matches on class, file, and
line, not on the quoted passage.

### D8 — Report shape: a `Source:` line, and queries under `--explain`

A shipped best-practices finding adds one line after `Fix:`:
`Source: <url>`, so the user can check the claim without asking for
diagnostics. Under `--explain`, the finder's recorded queries and
fetched URLs print as a `Web:` block after the candidate list — one
line per query — which is the user's audit trail for what left the
machine.

### D9 — The web contract is a document, referenced from the policy

`docs/web.md` states the contract the way `docs/feedback.md` does for
the only other outbound path: when network is touched, what a query
may contain, that fetched content is data, and what the user can see.
`SECURITY.md`'s in-scope list gains: any outbound traffic beyond the
feedback or web-lookup contracts, and any query carrying repository
content, is a vulnerability.

## Risks / Trade-offs

- [Fabricated or misquoted citation] → D4's fetch requirement, the
  `Source:` line in every shipped finding, and the gold TP's label; a
  field false positive files as `wrong-on-facts` and the lens is the
  first candidate for removal if it recurs.
- [Prompt injection via fetched pages] → D6; the finder can add a
  candidate only against a changed line, Stage 4 checks that line
  offline, and the orchestrator alone judges. A page cannot suppress a
  candidate from another lens because finders are blind to each other.
- [Query leaks repository content] → D3's closed vocabulary and the
  third-party check; `--explain` prints every query; `SECURITY.md`
  names it in scope.
- [Version-mismatched claims ("deprecated in v5", repo pins v4)] →
  version applicability is part of the candidate and checked offline
  in Stage 4; a mismatch is an exclusion-list drop.
- [Web tools unavailable in the environment] → ledger row `skipped
  (web tools unavailable)` with the coverage block naming it; never
  `returned, 0`.
- [Run time and cost] → the twelve-search / two-fetch bound; measured
  in the field smoke test against a no-`--web` audit on the same
  branch.
- [Three changes touching the same audit.md stages] → restack on
  whichever lands first; the delta spec adds requirements rather than
  modifying the fan-out or gate requirements, so the spec merge is
  additive.

## Migration Plan

Additive, opt-in. Next minor after the in-flight changes land. Users
who never pass `--web` see one new `Not checked:` entry naming the lens
and its reason, and nothing else.

## Open Questions

- Whether `--web` should later widen to `/reviso:review` with a smaller
  search bound. Default: no — the inner loop stays offline until the
  audit lens has one release of field precision.
- Whether the twelve-search bound should scale with diff size. Default:
  fixed; revisit if the smoke test shows the bound truncating
  high-risk hunks.
