"""Offline checks for matcher failures that can inflate or invalidate recall."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


MATCHER = Path(__file__).with_name("match.sh")


class MatcherTests(unittest.TestCase):
    def run_matcher(self, response):
        with tempfile.TemporaryDirectory(prefix="reviso-match-test-") as directory:
            root = Path(directory)
            fake = root / "claude"
            fake.write_text("#!/bin/sh\nprintf '%s\\n' \"$MATCH_TEST_RESPONSE\"\n")
            fake.chmod(0o755)
            a, b = root / "a.json", root / "b.json"
            for path in (a, b):
                path.write_text(json.dumps([{"title": "one"}, {"title": "two"}]))
            env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                       MATCH_HOST="claude", MATCH_TEST_RESPONSE=json.dumps(response))
            return subprocess.run(["sh", str(MATCHER), str(a), str(b)],
                                  env=env, capture_output=True, text=True)

    def test_rejects_reused_indices_on_either_side(self):
        for matches in ([{"a_idx": 0, "b_idx": 0}, {"a_idx": 0, "b_idx": 1}],
                        [{"a_idx": 0, "b_idx": 0}, {"a_idx": 1, "b_idx": 0}]):
            with self.subTest(matches=matches):
                result = self.run_matcher({"result": json.dumps(matches)})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("duplicate index", result.stderr)

    def test_rejects_noninteger_or_out_of_range_indices(self):
        for index in (0.5, "0", -1, 2, None):
            with self.subTest(index=index):
                result = self.run_matcher({"result": json.dumps([{"a_idx": index, "b_idx": 0}])})
                self.assertNotEqual(result.returncode, 0)

    def test_surfaces_provider_failure(self):
        result = self.run_matcher({"is_error": True, "result": "session expired"})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("session expired", result.stderr)

    def test_accepts_distinct_matches(self):
        matches = [{"a_idx": 0, "b_idx": 1}, {"a_idx": 1, "b_idx": 0}]
        result = self.run_matcher({"result": json.dumps(matches)})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), matches)


if __name__ == "__main__":
    unittest.main()
