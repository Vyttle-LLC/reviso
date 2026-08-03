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
  "confidence": 100
}
```

Rules:

- `line` anchors to a line the change touched. Findings on untouched lines
  are false positives by definition (see the exclusion list).
- `failure_scenario` is mandatory and concrete. "Could cause issues" is not
  a failure scenario; if you cannot state inputs → wrong outcome, do not
  return the finding.
- `suggested_fix` is shown in the report for the human to apply. Reviso
  never applies it.
- Severity: **P0** breaks correctness/security in practice; **P1** a real
  defect or contract violation likely to be hit; **P2** consequential but
  contained. There is no P3 — a nit that would rank below P2 is not returned.
- `confidence` is set by the verifier (Stage 4); finders leave it at 0.
  Deterministic detectors set it to 100.
