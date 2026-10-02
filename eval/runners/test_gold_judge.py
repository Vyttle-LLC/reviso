"""Check adjudication denominator changes without renumbering archived matches."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


JUDGE = Path(__file__).with_name("gold-judge.sh")


class GoldJudgeTests(unittest.TestCase):
    def judge(self, findings, matches):
        with tempfile.TemporaryDirectory(prefix="reviso-gold-test-") as directory:
            root = Path(directory)
            labels, candidate = root / "labels.json", root / "candidate.json"
            labels.write_text(json.dumps({"expected_clean": False, "findings": findings}))
            candidate.write_text(json.dumps([{"title": "one"}, {"title": "two"}]))
            (root / "match-gc.json").write_text(json.dumps(matches))
            result = subprocess.run(["sh", str(JUDGE), str(labels), str(candidate), str(root)],
                                    capture_output=True, text=True)
            output = root / "gold-judge.json"
            return result, json.loads(output.read_text()) if output.exists() else None

    def test_exclusions_keep_original_match_indices(self):
        findings = [{"title": "old", "policy_excluded": True},
                    {"title": "miss", "category": "correctness"},
                    {"title": "hit", "category": "correctness"}]
        result, judged = self.judge(findings, [{"a_idx": 0, "b_idx": 0}, {"a_idx": 2, "b_idx": 1}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(judged["metrics"]["gold_recall_correctness"], 50)
        self.assertEqual(judged["matched"][0]["gold"]["title"], "hit")
        self.assertEqual(judged["missed_correctness_gold"][0]["title"], "miss")
        self.assertEqual(judged["promotion_candidates"][0]["title"], "one")
        self.assertEqual(judged["excluded_recorded_matches"], [{"a_idx": 0, "b_idx": 0}])

    def test_all_excluded_is_unscored_not_expected_clean(self):
        findings = [{"adjudication": {"status": "label-wrong"}},
                    {"adjudication": {"status": "policy-excluded"}}]
        result, judged = self.judge(findings, [])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(judged["metrics"]["gold_recall_correctness"])
        self.assertFalse(judged["expected_clean"])
        self.assertNotIn("false_positives", judged)
        self.assertEqual(len(judged["excluded_gold"]), 2)

    def test_unknown_disposition_fails_loudly(self):
        result, judged = self.judge([{"adjudication": {"status": "typo"}}], [])
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(judged)
        self.assertIn("unknown adjudication", result.stderr)

    def test_live_matcher_sees_only_eligible_labels(self):
        with tempfile.TemporaryDirectory(prefix="reviso-gold-live-") as directory:
            root = Path(directory)
            labels, candidate = root / "labels.json", root / "candidate.json"
            labels.write_text(json.dumps({"findings": [
                {"title": "excluded-marker", "adjudication": {"status": "label-wrong"}},
                {"title": "eligible", "category": "correctness"}]}))
            candidate.write_text(json.dumps([{"title": "candidate"}]))
            fake = root / "claude"
            fake.write_text('''#!/bin/sh
case "$2" in *excluded-marker*) exit 1 ;; esac
printf '%s\\n' '{"result":"[{\\"a_idx\\":0,\\"b_idx\\":0}]"}'
''')
            fake.chmod(0o755)
            env = dict(os.environ, MATCH_HOST="claude", PATH=str(root) + os.pathsep + os.environ["PATH"])
            result = subprocess.run(["sh", str(JUDGE), str(labels), str(candidate), str(root)],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads((root / "match-gc.json").read_text()), [{"a_idx": 1, "b_idx": 0}])


if __name__ == "__main__":
    unittest.main()
