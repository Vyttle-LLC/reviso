"""Offline integration checks for packaging, helper relocation, and host adapters."""

import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
import sys


ROOT = Path(__file__).resolve().parents[2]
SKILL = ROOT / "skills/reviso"
spec = importlib.util.spec_from_file_location("candidate_codex", Path(__file__).with_name("candidate-codex.py"))
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class PortabilityTests(unittest.TestCase):
    def test_runtime_paths_exist(self):
        paths = list(SKILL.rglob("*.md")) + list((ROOT / "commands").glob("*.md")) + list((ROOT / "agents").glob("*.md"))
        for path in paths:
            for prefix, suffix in re.findall(r"\$\{(REVISO_SKILL_ROOT|CLAUDE_PLUGIN_ROOT)\}(/[^\s`\"<>]+)", path.read_text()):
                root = SKILL if prefix == "REVISO_SKILL_ROOT" else ROOT
                self.assertTrue((root / suffix.lstrip("/")).exists(), (path, suffix))

    def test_version_consistency(self):
        version = (SKILL / "VERSION").read_text().strip()
        for host in ("claude", "codex"):
            self.assertEqual(version, json.loads((ROOT / f".{host}-plugin/plugin.json").read_text())["version"])

    def test_candidate_artifacts_and_failure_states(self):
        with tempfile.TemporaryDirectory(prefix="reviso-runner-") as temp:
            temp = Path(temp)
            repo = temp / "repo"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "-c", "user.name=Fixture",
                            "-c", "user.email=fixture@example.com", "commit", "--allow-empty",
                            "-qm", "base"], check=True)
            fake = temp / "codex"
            fake.write_text('''#!/usr/bin/env python3
import json, os, pathlib, sys
if '--version' in sys.argv:
    print('codex-cli fixture')
    sys.exit(0)
assert sys.argv[sys.argv.index('--sandbox') + 1] == 'read-only'
mode = os.environ['FIXTURE_MODE']
if mode == 'error':
    sys.exit(1)
out = pathlib.Path(sys.argv[sys.argv.index('--output-last-message') + 1])
result = {'report': 'No issues found.', 'findings': [], 'coverage': [
    {'lens': lens, 'outcome': 'returned', 'reason': ''}
    for lens in ('bugs', 'conventions', 'history', 'comments', 'slop', 'deterministic')]}
if mode == 'partial':
    result['coverage'] = result['coverage'][:1]
if mode == 'empty':
    result['coverage'] = []
if mode == 'duplicate':
    result['coverage'].append(result['coverage'][0])
if mode == 'unavailable':
    result['coverage'][0]['outcome'] = 'no result'

if mode == 'invalid':
    result['findings'] = 'not an array'
if mode == 'mutation':
    repo = pathlib.Path(sys.argv[sys.argv.index('--cd') + 1])
    (repo / 'unexpected.txt').write_text('changed')
out.write_text(json.dumps(result))
''')
            fake.chmod(0o755)
            env = dict(os.environ, PATH=str(temp) + os.pathsep + os.environ["PATH"])
            for mode in ("success", "partial", "empty", "duplicate", "unavailable", "invalid", "error", "mutation"):
                with self.subTest(mode=mode):
                    out = temp / mode
                    env["FIXTURE_MODE"] = mode
                    result = subprocess.run([
                        sys.executable, str(Path(__file__).with_name("candidate-codex.py")),
                        str(repo), "HEAD", "HEAD", str(out), "--tier", "review",
                        "--model", "fixture", "--effort", "high",
                    ], env=env, capture_output=True, text=True)
                    self.assertEqual(result.returncode == 0, mode in ("success", "partial", "empty", "unavailable"), result.stderr)
                    meta = json.loads((out / "meta.json").read_text())
                    expected = "returned" if mode == "success" else "failed"
                    if mode in ("partial", "empty", "unavailable"):
                        expected = "incomplete"
                    if mode == "mutation":
                        expected = "report-only-violation"
                    self.assertEqual(meta["status"], expected)
                    if mode == "success":
                        self.assertEqual([], json.loads((out / "candidate.json").read_text()))

    def test_coverage_requires_every_lens_for_each_tier(self):
        for tier, lenses in runner.EXPECTED_LENSES.items():
            coverage = [{"lens": lens, "outcome": "returned", "reason": ""} for lens in lenses]
            if tier == "style":
                next(row for row in coverage if row["lens"] == "best-practices").update(
                    outcome="skipped", reason="no --web")
            with self.subTest(tier=tier):
                self.assertEqual("returned", runner.coverage_status(tier, coverage))
                for omitted in lenses:
                    partial = [row for row in coverage if row["lens"] != omitted]
                    self.assertEqual("incomplete", runner.coverage_status(tier, partial))
                with self.assertRaisesRegex(ValueError, "Duplicate"):
                    runner.coverage_status(tier, coverage + [coverage[0]])
        review = [{"lens": lens, "outcome": "returned", "reason": ""}
                  for lens in runner.EXPECTED_LENSES["review"]]
        self.assertEqual("incomplete", runner.coverage_status("audit", review))

    def test_standalone_feedback_and_final_state_detectors(self):
        with tempfile.TemporaryDirectory(prefix="reviso space ") as temp:
            temp = Path(temp)
            installed = temp / "standalone skill"
            shutil.copytree(SKILL, installed)
            result = subprocess.check_output([
                "sh", str(installed / "feedback/build-payload.sh"), "meta",
                "--lens", "slop", "--severity", "P2", "--confidence", "80s",
                "--reason", "wrong-on-facts", "--command", "review", "--model", "gpt-5.4",
            ], text=True)
            self.assertIn((SKILL / "VERSION").read_text().strip(), result)
            for invalid in ("gpt-5.4/file", "source.py", "gpt-5.4\nprivate/file", "gpt-" + "1" * 40 + ".4"):
                rejected = subprocess.run([
                    "sh", str(installed / "feedback/build-payload.sh"), "meta",
                    "--lens", "slop", "--severity", "P2", "--confidence", "80s",
                    "--reason", "wrong-on-facts", "--command", "review", "--model", invalid,
                ], capture_output=True)
                self.assertNotEqual(rejected.returncode, 0)
                self.assertEqual(rejected.stdout, b"")
            repo = temp / "repo"
            repo.mkdir()
            def git(*args):
                return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()
            git("init", "-q")
            git("config", "user.name", "Fixture")
            git("config", "user.email", "fixture@example.com")
            file = repo / "sample.test.js"
            file.write_text("test('works', () => {});\n")
            git("add", ".")
            git("commit", "-qm", "base")
            base = git("rev-parse", "HEAD")
            file.write_text("test.only('works', () => {});\n")
            git("commit", "-qam", "focus")
            before = runner.snapshot(repo)
            def detect():
                return json.loads(subprocess.check_output(
                    ["sh", str(installed / "detectors/run.sh"), base], cwd=repo))
            self.assertTrue(detect())
            self.assertEqual(before, runner.snapshot(repo))
            file.write_text("test('works', () => {});\n")
            self.assertEqual([], detect())
            self.assertNotEqual(before, runner.snapshot(repo))
            odd = repo / "untracked\nfile.txt"
            odd.write_text("first")
            before = runner.snapshot(repo)
            odd.write_text("second")
            self.assertNotEqual(before, runner.snapshot(repo))


if __name__ == "__main__":
    unittest.main()
