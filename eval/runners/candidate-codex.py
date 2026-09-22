#!/usr/bin/env python3
"""Run an explicitly configured Codex candidate on an existing corpus checkout.

Does not fetch or checkout: prepare the disposable workdir at head_sha first.
Artifacts are separate from Claude's parity runner (no cross-host cost claims).
"""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time

import jsonschema


# Canonical ledger names supplied to the model, matching the workflow lenses.
EXPECTED_LENSES = {
    "review": ("bugs", "conventions", "history", "comments", "slop", "deterministic"),
    "audit": ("bugs", "conventions", "history", "comments", "slop",
              "prior-reviews", "deterministic"),
    "style": ("drift", "length", "over-engineering", "conventions", "error-handling",
              "surface-area", "comments", "ai-tells", "naming", "stale-docs", "slop",
              "duplication", "dead-weight", "derived-state", "test-slop", "type-slop",
              "best-practices", "deterministic"),
}


def coverage_status(tier, coverage):
    names = [row["lens"] for row in coverage]
    if len(names) != len(set(names)):
        raise ValueError("Duplicate coverage lens names")
    missing = set(EXPECTED_LENSES[tier]) - set(names)
    return "incomplete" if missing or any(
        row["outcome"] == "no result" for row in coverage) else "returned"


def git(workdir, *args):
    return subprocess.check_output(["git", "-C", str(workdir), *args])


def snapshot(workdir):
    """Hash tracked and untracked content, including filenames with whitespace."""
    names = git(workdir, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
    digest = hashlib.sha256()
    for name in sorted(set(names.split(b"\0")) - {b""}):
        path = workdir / name.decode("utf-8", "surrogateescape")
        digest.update(name + b"\0")
        if path.is_symlink():
            digest.update(b"link:" + str(path.readlink()).encode())
        elif path.is_file():
            digest.update(str(path.stat().st_mode).encode() + b":" + path.read_bytes())
        else:
            digest.update(b"missing-or-directory")
    digest.update(git(workdir, "diff", "--cached", "--binary"))
    digest.update(git(workdir, "rev-parse", "HEAD"))
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workdir", type=Path)
    parser.add_argument("base_sha")
    parser.add_argument("head_sha")
    parser.add_argument("outdir", type=Path)
    parser.add_argument("--tier", required=True, choices=["review", "style", "audit"])
    parser.add_argument("--model", required=True)
    parser.add_argument("--effort", required=True)
    parser.add_argument("--timeout", type=int, default=900)
    args = parser.parse_args()
    workdir, out = args.workdir.resolve(), args.outdir.resolve()
    if out == workdir or workdir in out.parents:
        parser.error("outdir must be outside the reviewed repository")
    if args.timeout <= 0:
        parser.error("timeout must be positive")
    head = git(workdir, "rev-parse", "--verify", args.head_sha + "^{commit}").decode().strip()
    base = git(workdir, "rev-parse", "--verify", args.base_sha + "^{commit}").decode().strip()
    if git(workdir, "rev-parse", "HEAD").decode().strip() != head:
        parser.error("prepare workdir at head_sha before running")
    out.mkdir(parents=True, exist_ok=False)
    here = Path(__file__).resolve().parent
    skill = here.parents[1] / "skills/reviso/SKILL.md"
    prompt = (
        f"Use $reviso at {skill} to run {args.tier} --base {base} --explain. "
        "Read the skill and selected references. No feedback sends or web lookups. "
        "Return the normal report in report, the shipped findings in findings, "
        "and the actual coverage ledger in coverage, matching the output schema. "
        f"Use these exact coverage lens names: {', '.join(EXPECTED_LENSES[args.tier])}. "
        "Include one row per lens; use comments for code comments and slop for anti-slop. "
        "For style, report individual lenses, not families; mark best-practices skipped "
        "with reason no --web. If audit falls back to review, mark unavailable audit "
        "lenses no result. Do not write files. Record unavailable lenses honestly."
    )
    command = [
        "codex", "exec", "--ignore-user-config", "--ignore-rules", "--ephemeral",
        "--sandbox", "read-only", "--model", args.model,
        "-c", "model_reasoning_effort=" + json.dumps(args.effort),
        "--cd", str(workdir), "--json",
        "--output-schema", str(here / "codex-output.schema.json"),
        "--output-last-message", str(out / "candidate-output.json"), prompt,
    ]
    before = snapshot(workdir)
    started = time.monotonic()
    meta = {"host": "codex", "tier": args.tier, "base_sha": base, "head_sha": head,
            "requested_model": args.model, "reasoning_effort": args.effort,
            "cli_version": subprocess.check_output(["codex", "--version"], text=True).strip(),
            "status": "failed"}
    try:
        with (out / "candidate-events.jsonl").open("w") as events, (out / "stderr.txt").open("w") as errors:
            subprocess.run(command, stdin=subprocess.DEVNULL, stdout=events, stderr=errors, check=True, timeout=args.timeout)
        result = json.loads((out / "candidate-output.json").read_text())
        # Schema enforcement is supplied to Codex; validate again before accepting artifacts.
        jsonschema.validate(result, json.loads((here / "codex-output.schema.json").read_text()))
        status = coverage_status(args.tier, result["coverage"])
        (out / "candidate-report.md").write_text(result["report"] + "\n")
        (out / "candidate.json").write_text(json.dumps(result["findings"], indent=2) + "\n")
        (out / "coverage.json").write_text(json.dumps(result["coverage"], indent=2) + "\n")
        meta["status"] = status
    finally:
        meta["duration_ms"] = round((time.monotonic() - started) * 1000)
        meta["repository_unchanged"] = snapshot(workdir) == before
        if not meta["repository_unchanged"]:
            meta["status"] = "report-only-violation"
        (out / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
        if not meta["repository_unchanged"]:
            raise RuntimeError("REPORT-ONLY VIOLATION: review changed repository state")


if __name__ == "__main__":
    main()
