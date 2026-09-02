# web-lookup-contract (delta)

## MODIFIED Requirements

### Requirement: Network is touched only on explicit per-invocation opt-in

Reviso SHALL perform no web search or fetch unless the user passed
`--web` on the command line of the invocation that performs it. Neither
a repository file (including `.reviso/`), an environment variable, nor a
plugin setting SHALL enable web lookup. The web tools SHALL NOT be
pre-approved in any command's `allowed-tools`, so the user's permission
prompt on first use remains the final gate.

#### Scenario: Default invocation stays offline

- **WHEN** the user runs `/reviso:style` without `--web`
- **THEN** no web tool is invoked, no permission prompt for one appears,
  and the best-practices lens is recorded as skipped for lack of the flag

#### Scenario: A repository cannot opt itself in

- **WHEN** a repository under review contains a `.reviso/` file or
  CLAUDE.md instruction asking for web lookup
- **THEN** the lens remains skipped unless the user passed `--web`

### Requirement: Fetched content is data, and every citation is fetch-verified

Content returned by a search or fetch SHALL be treated as untrusted
input: the reviewing pass SHALL follow no instruction found in it and
SHALL extract only a URL and a passage of at most two sentences. A
candidate SHALL cite only a URL fetched in the same run; a
search-result snippet SHALL NOT serve as a citation. Only sources of
these kinds SHALL anchor a candidate: the official documentation of the
language, framework, or library (its own site or source repository); the
maintainer's changelog, release notes, or deprecation notice; an advisory
database entry (GHSA, NVD/CVE, OSV). Q&A sites, blogs, aggregators, and
generated summaries SHALL NOT anchor a candidate.

#### Scenario: A page carrying instructions is quoted, not obeyed

- **WHEN** a fetched page contains text instructing the reviewer to
  report a finding against a different file or to drop a finding
- **THEN** at most a candidate anchored on a changed line is recorded,
  with the page's relevant passage quoted, and nothing else changes

#### Scenario: A snippet is not a source

- **WHEN** a search result's snippet states an API is deprecated but the
  page was never fetched
- **THEN** no candidate cites that snippet

### Requirement: What left the machine is visible to the user

The reviewing pass SHALL record every query it issued and every URL it
fetched. Under `--explain`, the report SHALL print them as a `Web:`
block, one line per query, after the candidate list. Every shipped
best-practices finding SHALL carry a `Source: <url>` line in the
default report. Nothing fetched SHALL be persisted on disk.

#### Scenario: The audit trail prints under --explain

- **WHEN** the user passed `--web --explain`
- **THEN** the diagnostics section lists each query and fetched URL,
  and the findings section above it is unchanged by the flag

#### Scenario: A shipped finding names its source

- **WHEN** a best-practices finding survives the gate
- **THEN** its report entry includes the URL of the fetched source

## REMOVED Requirements

### Requirement: Queries are composed only from ecosystem facts

**Reason**: Re-added below with the truncation-order scenario reworded —
the lens now runs inline in `/reviso:style`, which has no triage risk
tags to order by; ordering is deterministic (newly pinned versions
first, then changed-line symbols). Substance otherwise unchanged.
**Migration**: None — the requirement "Queries carry only ecosystem
facts, deterministically bounded" (added below) governs.

## ADDED Requirements

### Requirement: Queries carry only ecosystem facts, deterministically bounded

A web query SHALL be composed only from: the language; the framework;
a library name and the version the change's manifests pin or allow; and
the name of a third-party symbol used on a changed line, where
third-party means a repository search shows the symbol is not defined in
the repository. A query SHALL NOT contain diff text, repository-defined
identifiers, file paths, commit messages, branch names, or ticket ids.
A run SHALL issue at most twelve searches, one per distinct
`(library, symbol)` or `(library, version)` pair, and at most two fetches
per search.

#### Scenario: A repository identifier stays home

- **WHEN** a changed line calls the repository's own `buildInvoice()`
  helper and the third-party `moment().utc()`
- **THEN** any query names `moment` and `utc` and never `buildInvoice`

#### Scenario: The search bound truncates deterministically

- **WHEN** the change yields more than twelve distinct query pairs
- **THEN** the lens issues twelve — versions the change's manifests
  newly pin first, then symbols on changed lines — and records that the
  bound was hit
