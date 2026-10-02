"""Exercise the Codex gold adapter and reject incomplete coverage offline."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


GOLD = Path(__file__).with_name("gold.sh")


class CodexGoldTests(unittest.TestCase):
    def run_gold(self, incomplete=False, tier="review"):
        with tempfile.TemporaryDirectory(prefix="reviso-codex-gold-test-") as directory:
            root = Path(directory)
            (root / "labels.json").write_text(json.dumps({"expected_clean": True, "findings": []}))
            (root / "fixture.json").write_text(json.dumps({"files": [
                {"filename": "sample.py", "status": "added", "patch": "+answer = 42"}]}))
            (root / "corpus.jsonl").write_text(json.dumps({"id": "fixture", "synthetic": True,
                                                          "fixture": "fixture.json", "labels": "labels.json"}) + "\n")
            fake = root / "codex"
            fake.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
if '--version' in sys.argv:
    print('codex fixture')
    sys.exit(0)
assert sys.argv[sys.argv.index('--sandbox') + 1] == 'read-only'
assert '--ignore-user-config' in sys.argv
assert '--ignore-rules' in sys.argv
assert sys.argv[sys.argv.index('--model') + 1] == 'fixture-model'
tier = os.environ['REVISO_TIER']
if tier == 'audit':
    assert sys.argv[sys.argv.index('--enable') + 1] == 'multi_agent'
lenses = ['bugs', 'conventions', 'history', 'comments', 'slop', 'deterministic']
if tier == 'audit':
    lenses.append('prior-reviews')
coverage = [{'lens': lens, 'outcome': 'returned', 'reason': ''} for lens in lenses]
if os.environ['GOLD_TEST_INCOMPLETE'] == '1':
    coverage[0]['outcome'] = 'no result'
    coverage[0]['reason'] = 'fixture unavailable'
output = Path(sys.argv[sys.argv.index('--output-last-message') + 1])
output.write_text(json.dumps({'report': 'No issues found.', 'findings': [], 'coverage': coverage}))
''')
            fake.chmod(0o755)
            out = root / "out"
            env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                       CORPUS_FILE=str(root / "corpus.jsonl"), REVISO_TIER=tier,
                       CANDIDATE_HOST="codex", CANDIDATE_CODEX_MODEL="fixture-model",
                       CANDIDATE_CODEX_EFFORT="medium", REVISO_PYTHON=os.sys.executable,
                       GOLD_TEST_INCOMPLETE="1" if incomplete else "0")
            result = subprocess.run(["sh", str(GOLD), "fixture", str(out)],
                                    env=env, capture_output=True, text=True)
            meta = json.loads((out / "meta.json").read_text())
            return result, meta, (out / "gold-judge.json").exists()

    def test_codex_gold_keeps_the_repository_unchanged(self):
        for tier in ("review", "audit"):
            with self.subTest(tier=tier):
                result, meta, judged = self.run_gold(tier=tier)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(meta["repository_unchanged"])
                self.assertEqual(meta["host"], "codex")
                self.assertTrue(judged)

    def test_incomplete_coverage_is_not_scored(self):
        result, meta, judged = self.run_gold(incomplete=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(meta["status"], "incomplete")
        self.assertFalse(judged)


if __name__ == "__main__":
    unittest.main()
