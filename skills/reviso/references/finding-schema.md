# Shared finding schema

Every finding — from a deterministic detector or an LLM finder — is one JSON
object with exactly these fields. Finders return a JSON array of them (empty
array if nothing found), and nothing else.

```json
{
  "file": "relative/path/from/repo/root.ts",
  "line": 42,
  "severity": "P0 | P1 | P2",
  "dimension": "conventions | bugs | history | prior-reviews | comments | slop | deterministic",
  "title": "one line, ≤80 chars, the claim itself",
  "failure_scenario": "concrete: these inputs / this state → this wrong outcome",
  "suggested_fix": "the change (or rewrite) that resolves it",
  "evidence": "what in the code/history/conventions supports the claim, with file:line cites",
  "confidence": 0
}
```

Rules:

- This file defines the wire format every stage speaks, and nothing else.
  Reporting policy — which findings ship, severity floors, consolidation,
  any limit on how many findings a report carries — belongs to the command
  that produces the report, so a stage that merely serializes a candidate
  cannot thereby suppress it.
- `line` anchors to a line the change touched.
- `failure_scenario` is mandatory and concrete, but its shape depends on
  the dimension. For correctness/security: inputs/state → wrong outcome.
  For conventions, docs, and slop: the concrete consequence — who is
  misled, what process breaks, what the next reader pays. "Could cause
  issues" is never acceptable; a stale doc that tells users a command that
  doesn't exist is ("a user runs `/reviso review` and gets an error").
- `suggested_fix` is shown in the report for the human to apply. Reviso
  never applies it.
- Severity: **P0** breaks correctness/security in practice; **P1** a real
  defect or contract violation likely to be hit; **P2** consequential but
  contained.
- `confidence` is set by the orchestrator when it scores the candidate;
  finders leave it at 0. Deterministic detectors set it to 100.
- Brevity is part of the contract: `evidence` ≤ 2 sentences,
  `failure_scenario` ≤ 2 sentences.
