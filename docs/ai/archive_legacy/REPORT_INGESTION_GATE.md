# REPORT INGESTION GATE
Defines how agent reports are judged before their claims enter confirmed repo truth.

---

## Accept A Report Only If
- It names the agent (tool + repo-side specialist lane)
- It names files inspected
- It names files changed (or explicitly says "none")
- It states validation run (command, method, or "none")
- It states validation result (passed / failed / partial / unable)
- It separates confirmed repo truth from unverified assumptions
- It gives one recommended next step
- It names risks

---

## Reject Or Rework A Report If
- It says "looks good" without naming what was checked
- It claims runtime validation without run/playtest evidence
- It does not list files inspected or changed
- It makes broad claims from a narrow inspection (e.g., "system is working" from reading one file)
- It changes gameplay behavior while claiming docs-only work
- It recommends a large rewrite without proof that the current system is broken
- It treats design direction as confirmed implementation

---

## Report Score

**PASS** — all accept criteria met; confirmed truth can be promoted; next step is clear.

**WARN** — most criteria met but one or more of:
- Validation level is lower than the claim (static check for runtime behavior)
- Assumptions are not clearly separated from confirmed truth
- Recommended next step is vague
- Risk is understated
Action: accept with caveats; note the warnings in the ingestion summary.

**FAIL** — one or more reject criteria met. Do not promote claims as repo truth.
Action: return for rework or route to Gemini for a fresh audit.

---

## Ingestion Output Format
When Command Center or a lead agent ingests a report, produce this summary:

```
INGESTION SUMMARY
Report score: PASS / WARN / FAIL
Validation level achieved: (0–4)
Confirmed repo truth (promoted):
  - [fact]
New risks identified:
  - [risk]
Warnings (if WARN):
  - [warning]
One next move:
  - Agent:
  - Task:
```

---

## Automated Score Assist
Before accepting an agent report, optionally run:

```
python tools/ai/score_agent_report.py path/to/report.txt
```

The script does not replace human judgment. It catches missing fields, validation exaggeration,
stale-truth risk for fragile systems, and routing problems. Exits 0 (PASS), 1 (WARN), 2 (FAIL).

Scoring guide: `docs/ai/AGENT_REPORT_SCORECARD.md`
Examples: `docs/ai/examples/AGENT_REPORT_SCORE_EXAMPLE.md`

---

## Lockbox Report Rule
A Lockbox-related report may not mark a card VALIDATED COMPLETE unless:
- the report passes the ingestion gate
- the scorer returns PASS or accepted WARN
- validation level matches the type of claim
- Command Center v1 accepts the status update

---

## Notes
- Ingestion is not the same as implementation. A PASS report confirms truth; it does not automatically authorize the next step.
- A WARN report can still be useful — flag the caveats and use it with eyes open.
- A FAIL report produces no confirmed truth. Treat its claims as unverified assumptions only.
- When multiple reports conflict, route to Gemini for conflict sweep before ingesting either.
