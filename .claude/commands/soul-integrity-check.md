# /soul-integrity-check

Verify the active AI context hasn't drifted from WHAT WE FED's identity.

## Run the checks

```bash
python tools/ai/check_soul_integrity.py .
python tools/ai/check_active_ai_doctrine.py .
```

## What it enforces

**Forbidden in active docs (warn/fail):**
- "Premium Menace" as base style → use Legendary Pixel Fable Ink
- Strict lane combat as current design → 360-degree spatial is current
- LaneManager.gd as current spatial authority → ZoneManager is the authority
- "Lanes 0, 1, or 2" as strict combat constraint → spatial sectors, not fixed lanes
- Humanoid/slime/ghost player framing → Vessel is non-humanoid orb-like anomaly
- Mobile game framing → WHAT WE FED is desktop
- `AI_CONTROL_PLANE.md` reference → file no longer exists; use AI_ARCHITECTURE_LEDGER.md
- Quig creator-reference rules that use "Cody" → must use "the monkeydog"

**Required somewhere in active AI corpus:**
- Legendary Pixel Fable Ink
- Fed Anomaly / Vessel
- non-humanoid
- feeding, bonding, mutation
- spatial or 360-degree combat
- ZoneManager
- Quig
- the monkeydog

## When FAIL
Fix before the next implementation task.

## When WARN
Note as remaining risk. Create evolution proposal if the stale term is in an active
agent entrypoint you can correct without approval.

## Archived docs
`docs/ai/archive_legacy/` is excluded — old terms there are intentionally ignored.

See `docs/ai/LIVING_COMMAND_LOOP.md` for what can be updated directly vs. proposals.
