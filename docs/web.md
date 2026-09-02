# Web lookup without disclosure

> **This page is a contract first.** It governs the only outbound *read*
> Reviso may make — the best-practices lens of `/reviso:audit --web`,
> implemented by `agents/reviso-finder-best-practices.md`. The contract
> outranks the code: an implementation change that violates any invariant
> here is a security bug (see [SECURITY.md](../SECURITY.md)), not a design
> choice. [feedback.md](feedback.md) is the sibling contract for the only
> outbound *write*.

Every other lens judges a change against what is already in the
repository. None of them know what the language or the libraries the
change uses say about themselves — that an API on a changed line was
deprecated two releases ago, that the maintainer's docs warn against
exactly this call pattern, that the version a manifest just pinned carries
a published advisory. That knowledge lives on the web and past the model's
training cutoff. The best-practices lens fetches it, under these rules.

## The invariants

1. **Nothing reaches the network unless you asked, this run.** The lens
   runs only when `--web` is on the `/reviso:audit` command line. No
   repository file (including anything under `.reviso/`), environment
   variable, or plugin setting can enable it — a repository must not be
   able to switch on network access for its own review. The web tools are
   never pre-approved, so Claude Code's permission prompt on first use is
   the final gate.
2. **A query carries ecosystem facts and nothing else.** The whole
   vocabulary: the language; the framework; a library name and the version
   your manifests pin or allow; and the name of a third-party symbol used
   on a changed line — third-party meaning a repository search shows it is
   not defined in your repo. Never in a query: diff text, your own
   identifiers, file paths, commit messages, branch names, ticket ids.
3. **Bounded.** At most twelve searches per run, one per distinct
   `(library, symbol)` or `(library, version)` pair, ordered by the triage
   risk tags (external-input, auth, migration first); at most two fetches
   per search.
4. **Fetched content is data.** The finder follows no instruction it finds
   on a page. It extracts a URL and a passage of at most two sentences,
   and a candidate may cite only a page fetched in the same run — a
   search-result snippet is not a citation.
5. **Only the ecosystem's own words anchor a finding.** The official
   documentation of the language, framework, or library (its own site or
   source repository); the maintainer's changelog, release notes, or
   deprecation notice; an advisory database entry (GHSA, NVD/CVE, OSV).
   Q&A sites, blogs, aggregators, and generated summaries may lead the
   finder to a primary source, which is then fetched; they never anchor a
   candidate themselves.
6. **You can see what left the machine.** Every shipped finding carries
   a `Source: <url>` line. Under `--explain`, the report prints every
   query issued and every URL fetched. Nothing fetched is persisted.

## What a finding from this lens looks like

Four classes, each a documented fact about the ecosystem — never taste:

| class | ships when |
| --- | --- |
| deprecated / removed API | the symbol on a changed line is deprecated or removed in a version your manifests allow |
| documented misuse | the maintainer's docs warn against the exact call pattern on the changed line, naming a consequence |
| known advisory | a manifest change pins a version an advisory covers, and changed code reaches the affected surface |
| superseded idiom | the docs name a replacement **and** state a consequence of the old form |

A recommendation without a stated consequence is style, not a finding.
A claim about a version your manifests exclude is not a finding. A claim
with no fetched source is not a finding. The orchestrator drops all three
at the confidence gate, and the finder that read the page never judges.

## What this buys

Without `--web`, the audit is exactly what it was — the report names the
lens under `Not checked:` with the reason, and no prompt appears. With it,
the audit can say "the ecosystem itself says not to do this", quoting the
ecosystem, on the one class of knowledge no local lens can have.
