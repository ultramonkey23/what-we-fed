# HUMAN PLAYTEST PROTOCOL
Makes manual playtest evidence usable by AI agents as structured repo truth.

---

## When To Use
Fill this out after any manual run of the game, debug harness session, or partial scene test. AI agents cannot substitute for it. Static docs cannot substitute for it.

---

## Playtest Report Template

```
WHAT WE FED PLAYTEST REPORT

Tester: [name or "developer"]
Date: [YYYY-MM-DD]
Build / branch / commit: [branch name or short hash]
Input device: [keyboard / controller / touch / other]

---

Route through game:
1. [step — e.g. boot → title screen]
2. [step — e.g. enter LairScene]
3. [step — e.g. enter CombatScene, species: X]
4. [step — e.g. complete one encounter]
5. [add steps as needed]

---

What felt good:
- [observation]

What felt bad or unclear:
- [observation]

Bugs seen:
- [bug description — include scene/action if possible]
- none

Screenshots / video:
- [path or "none"]

---

Pass / Warn / Fail: [circle one]

PASS — intended behavior confirmed, no blocking bugs, feel is readable
WARN — functional but one or more readability, feel, or minor bug issues
FAIL — blocking bug, wrong behavior, or feel is broken

---

One recommended next step:
- Agent:
- Task:
```

---

## What AI Agents Do With Playtest Reports
- Treat PASS as Level 4 validation for the tested scenario.
- Treat WARN as Level 3 with caveats — note the issues.
- Treat FAIL as evidence of a known bug — route to CYBORG or ALFRED for fix.
- Never upgrade a WARN or FAIL to PASS without another playtest.
- Never use an old playtest report to validate a new build. Date matters.

---

## What Playtest Reports Cannot Validate
- Code that was changed after the playtest date.
- Scenes not visited during the route.
- Systems not exercised (e.g., a bond action not triggered).
- Data not loaded (e.g., a species not selected).

Be explicit. "I tested route X with species Y" is honest. "The whole game works" is not.

---

## Routing After A Playtest
| Result | Next Step |
|---|---|
| PASS — nothing to fix | Promote to confirmed runtime truth; move to next task |
| WARN — feel issue | Route to BRAIN for design review or ALFRED for targeted fix |
| WARN — minor bug | Route to CYBORG or ALFRED for bounded fix |
| FAIL — blocking bug | Route to CYBORG immediately before other work |
| Unsure what failed | Route to Gemini for fresh audit with playtest notes as context |
