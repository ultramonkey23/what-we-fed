#!/usr/bin/env python3
"""Validate AI report scorer fixture exit codes."""

import sys

sys.dont_write_bytecode = True

import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCORER = ROOT / "tools" / "ai" / "score_agent_report.py"
FIXTURES = [
    ("PASS", ROOT / "docs" / "ai" / "examples" / "_sample_report_pass.txt", 0),
    ("WARN", ROOT / "docs" / "ai" / "examples" / "_sample_report_warn.txt", 1),
    ("FAIL", ROOT / "docs" / "ai" / "examples" / "_sample_report_fail.txt", 2),
]


def run_fixture(label, path, expected_code):
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"

    result = subprocess.run(
        [sys.executable, str(SCORER), str(path)],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )

    if result.returncode == expected_code:
        print(f"PASS: {label} fixture exited {expected_code}")
        return True

    print(
        f"FAIL: {label} fixture exited {result.returncode}; "
        f"expected {expected_code}"
    )
    if result.stdout:
        print("--- stdout ---")
        print(result.stdout.rstrip())
    if result.stderr:
        print("--- stderr ---")
        print(result.stderr.rstrip())
    return False


def main():
    missing = [path for _, path, _ in FIXTURES + [("SCORER", SCORER, 0)] if not path.exists()]
    if missing:
        for path in missing:
            print(f"FAIL: missing required file: {path}")
        return 1

    ok = True
    for label, path, expected_code in FIXTURES:
        ok = run_fixture(label, path, expected_code) and ok

    if ok:
        print("PASS: AI report scorer fixture contract validated")
        return 0

    print("FAIL: AI report scorer fixture contract mismatch")
    return 1


if __name__ == "__main__":
    sys.exit(main())
