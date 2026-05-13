#!/usr/bin/env python3
"""
check_active_ai_doctrine.py — WHAT WE FED Active Doctrine Checker
Runs both stale doctrine checks and soul integrity checks.

Usage:
  python tools/ai/check_active_ai_doctrine.py [repo_root]

Exit codes:
  0 — PASS (all checks clean)
  1 — WARN (non-fatal issues found)
  2 — FAIL (hard violations found)
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def run_check(script: Path, repo_root: Path) -> tuple[int, str]:
    """Run a checker script and return (exit_code, combined_output)."""
    try:
        result = subprocess.run(
            [sys.executable, str(script), str(repo_root)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        output = (result.stdout + result.stderr).strip()
        return result.returncode, output
    except FileNotFoundError:
        return 1, f"SKIP: {script.name} not found"
    except subprocess.TimeoutExpired:
        return 1, f"TIMEOUT: {script.name} took too long"
    except Exception as exc:
        return 1, f"ERROR running {script.name}: {exc}"


def main(argv: list[str]) -> int:
    repo_root = Path(argv[1]).resolve() if len(argv) > 1 else Path.cwd()
    tools_dir = repo_root / "tools" / "ai"

    checks: list[tuple[str, Path]] = [
        ("Soul Integrity Check", tools_dir / "check_soul_integrity.py"),
        ("Soul Constants Check (validate_soul.py)", tools_dir / "validate_soul.py"),
    ]

    overall = 0
    for label, script in checks:
        print(f"\n=== {label} ===")
        if not script.exists():
            print(f"  SKIP: {script.name} not present")
            continue

        code, output = run_check(script, repo_root)
        if output:
            for line in output.splitlines():
                print(f"  {line}")
        if code > overall:
            overall = code

    print("\n" + "=" * 40)
    if overall == 0:
        print("[doctrine] PASS — all active doctrine checks clean.")
    elif overall == 1:
        print("[doctrine] WARN — non-fatal issues found. Review before next task.")
    else:
        print("[doctrine] FAIL — hard violations detected. Fix before implementation.")

    return overall


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
