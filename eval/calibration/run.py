#!/usr/bin/env python3
"""Score one matcher call per hand-labeled pair, preserving per-pair decisions."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("labels", type=Path)
    parser.add_argument("outdir", type=Path)
    args = parser.parse_args()
    pairs = [json.loads(line) for line in args.labels.read_text().splitlines() if line.strip()]
    if len(pairs) < 30 or sum(pair.get("trap", False) for pair in pairs) < 10:
        parser.error("calibration requires at least 30 pairs and 10 traps")
    if len({pair["id"] for pair in pairs}) != len(pairs):
        parser.error("pair IDs must be unique")
    if any(pair["label"] not in ("match", "no-match") or
           (pair.get("trap", False) and pair["label"] != "no-match") for pair in pairs):
        parser.error("labels must be match/no-match; traps must be no-match")
    args.outdir.mkdir(parents=True, exist_ok=False)
    matcher = Path(__file__).resolve().parents[1] / "runners/match.sh"
    host = os.environ.get("MATCH_HOST", "claude")
    results = []
    for pair in pairs:
        with tempfile.TemporaryDirectory(prefix="reviso-calibration-") as directory:
            root = Path(directory)
            a, b = root / "a.json", root / "b.json"
            a.write_text(json.dumps([pair["a"]]))
            b.write_text(json.dumps([pair["b"]]))
            result = subprocess.run(["sh", str(matcher), str(a), str(b)],
                                    capture_output=True, text=True)
        if result.returncode:
            (args.outdir / (pair["id"] + ".error.txt")).write_text(result.stderr)
            raise SystemExit(f"matcher failed on {pair['id']}; see error artifact")
        matches = json.loads(result.stdout)
        observed = "match" if matches else "no-match"
        row = {"id": pair["id"], "label": pair["label"], "observed": observed,
               "trap": pair.get("trap", False), "agrees": observed == pair["label"],
               "matches": matches}
        results.append(row)
        with (args.outdir / "judgments.jsonl").open("a") as output:
            output.write(json.dumps(row) + "\n")
        print(f"{pair['id']}: {observed}, {'agree' if row['agrees'] else 'DISAGREE'}", flush=True)
    traps = [row for row in results if row["trap"]]
    agreement = sum(row["agrees"] for row in results)
    false_matches = sum(row["observed"] == "match" for row in traps)
    summary = {
        "date": datetime.now(timezone.utc).date().isoformat(), "host": host,
        "model": os.environ.get("MATCH_CODEX_MODEL") if host == "codex" else os.environ.get("JUDGE_MODEL", "sonnet"),
        "effort": os.environ.get("MATCH_CODEX_EFFORT") if host == "codex" else None,
        "cli_version": subprocess.check_output([host, "--version"], text=True).strip(),
        "matcher_sha256": hashlib.sha256(matcher.read_bytes()).hexdigest(),
        "labels_sha256": hashlib.sha256(args.labels.read_bytes()).hexdigest(),
        "pairs": len(results), "agreement": agreement,
        "agreement_pct": agreement / len(results) * 100,
        "traps": len(traps), "trap_false_matches": false_matches,
        "trap_false_match_pct": false_matches / len(traps) * 100,
        "passed": agreement / len(results) >= 0.9 and false_matches == 0,
    }
    (args.outdir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    raise SystemExit(0 if summary["passed"] else 1)


if __name__ == "__main__":
    main()
