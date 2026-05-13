# AGENT REPORT SCORE — EXAMPLES
Two mini-reports illustrating FAIL and PASS/WARN scoring.

---

## Example 1 — Bad Report (Expected: FAIL)

```
WHAT WE FED AGENT REPORT
Agent: Claude
Date:
Task type: docs update
Files inspected: various
Files changed: various
Validation run: looks good
Validation level: 3
Validation result: passed
Confirmed repo truth: the system is working, all lanes functional
Unverified assumptions:
Recommended next step: rewrite the entire combat system and SongConductor.gd
Risks:
```

**Score: FAIL**

Why it fails:
- `Date` is blank — required field missing.
- `Files inspected` is "various" — no explicit list; cannot verify scope.
- `Files changed` is "various" — no explicit list.
- `Validation run` is "looks good" — not a real validation command or method.
- `Validation level` claims 3 (runtime validated) but no runtime evidence exists.
- `Confirmed repo truth` makes a broad system claim ("all lanes functional") from an inspection that listed no specific files.
- `Recommended next step` recommends rewriting `SongConductor.gd` (a fragile system) with no scoped evidence of breakdown.
- `Risks` is blank.
- Stale-truth warning: recommends editing `SongConductor.gd` with no audit evidence.

**Final Recommendation: REJECT / REQUEST REWORK**

---

## Example 2 — Acceptable Report (Expected: WARN)

```
WHAT WE FED AGENT REPORT
Agent: Claude (ALFRED)
Date: 2026-04-24
Branch/commit if available: master / e0910e0
Task type: AI architecture/tooling upgrade
Files inspected:
  - docs/ai/AI_ARCHITECTURE_LEDGER.md
  - docs/ai/REPORT_INGESTION_GATE.md
  - docs/ai/PROMPT_CONTRACTS.md
Files changed:
  - tools/ai/score_agent_report.py (created)
  - docs/ai/AGENT_REPORT_SCORECARD.md (created)
  - docs/ai/REPORT_INGESTION_GATE.md (updated)
  - docs/ai/AI_ARCHITECTURE_LEDGER.md (updated)
  - docs/ai/PROMPT_CONTRACTS.md (updated)
Validation run: python tools/ai/score_agent_report.py --help; ran scorer against a sample report
Validation level: 2
Validation result: script runs without error; sample report scored and output printed correctly; no gameplay or scene files changed
Confirmed repo truth:
  - tools/ai/score_agent_report.py exists and runs on Python 3, no external dependencies
  - docs/ai/AGENT_REPORT_SCORECARD.md exists and matches script logic
  - docs/ai/REPORT_INGESTION_GATE.md, AI_ARCHITECTURE_LEDGER.md, PROMPT_CONTRACTS.md each updated with scorer pointer
Unverified assumptions:
  - Script has not been tested against a large corpus of real agent reports; edge cases may exist
  - Regex patterns may need tuning once more report formats are observed
Recommended next step:
  - Run the scorer against the next three real agent reports and note any false positives or missed flags
Risks:
  - Regex-based detection is heuristic; a well-formed-looking bad report may score WARN instead of FAIL
  - Fragile system detection depends on exact filename strings; novel filenames will not be caught
```

**Score: WARN**

Why it warns (not fails):
- All required fields are present.
- Files inspected and changed are explicitly listed.
- Validation is honest: level 2 (static/script test only — correct for a tooling task).
- Confirmed truth is separated from unverified assumptions.
- Exactly one recommended next step.
- Risks are named.

Warn reason: validation level 2 is honest but the task involved creating a new Python tool; level 3 (runtime run) is achievable here. Minor gap between what could be tested and what was tested. The report discloses this openly, so it is WARN not FAIL.

**Final Recommendation: ACCEPT WITH WARNINGS**
The scorer was run and functioned. Unverified assumptions are clearly flagged.
Watch edge cases on first few real-report runs.
