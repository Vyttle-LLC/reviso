# Security Policy

## Reporting a vulnerability

Email **<support@vyttle.com>**, or use
[GitHub private vulnerability reporting](../../security/advisories/new).

Please don't open a public issue for a security bug.

We'll acknowledge within **3 business days** and aim to give you a fix timeline
within **10 business days**. We'll credit you in the advisory unless you'd
rather we didn't.

## Why this matters more than usual for a code review tool

Reviso reads untrusted input by design. A code review tool ingests diffs,
commit messages, branch names, code comments, and repository configuration —
all of it potentially attacker-controlled if the repo takes outside
contributions. This class of tool has already produced a real incident: a
[remote code execution in CodeRabbit](https://kudelskisecurity.com/research/how-we-exploited-coderabbit-from-a-simple-pr-to-rce-and-write-access-on-1m-repositories)
that reached write access on roughly a million repositories.

We take that seriously and you should hold us to it.

### In scope

- **Prompt injection** through diffs, commit messages, branch names, code
  comments, or `.reviso/` files — anything that makes Reviso suppress a real
  finding, fabricate one, or act outside its report-only contract
- Any path by which Reviso **modifies files** — it is report-only, so any write
  outside the explicitly requested `--out` report is a vulnerability
- Any **outbound network write** beyond the feedback contract in
  [docs/feedback.md](docs/feedback.md) — the only permitted send is a feedback
  report the user explicitly approved; any other destination, or a payload
  carrying content the user never saw, is a vulnerability
- Any **outbound network read** beyond the web-lookup contract in
  [docs/web.md](docs/web.md) — public ecosystem lookups are limited to the
  best-practices lens the user enabled with `--web` on that invocation;
  a lookup without the flag, a query carrying repository content (diff
  text, identifiers, paths, commit messages), or fetched content acting as
  an instruction is a vulnerability
- Command injection or path traversal in the detectors or context assembly
- Exfiltration of repository contents, environment variables, or credentials
- Escaping the repository sandbox

### Out of scope

- Reviso missing a bug in your code (that's a
  [missed finding](../../issues/new?template=missed-finding.yml))
- False positives (file a
  [false positive report](../../issues/new?template=false-positive.yml))
- Vulnerabilities in the host itself — report Claude Code issues to Anthropic
  and Codex issues to OpenAI
- Issues requiring an already-compromised local machine

## Supported versions

Pre-1.0: the latest release only.
