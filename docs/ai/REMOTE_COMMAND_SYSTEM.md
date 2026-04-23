# BRAIN — REMOTE COMMAND SYSTEM (v1.0)

## Overview
This system allows sending **BRAIN commands** to the repository from GitHub (Web/Mobile) via Issues or Manual Workflow Dispatch. It ensures all remote moves are normalized and validated against the `BRAIN_KERNEL.md`.

---

## 1. HOW TO SEND A COMMAND

### Option A: GitHub Issues (Recommended)
1. Go to **Issues > New Issue**.
2. Select the **BRAIN Command** template.
3. Fill in the fields:
   - **Task Classification**: How the task is categorized (Inspect, Spec, Patch, etc.).
   - **Target Files**: Paths affected.
   - **Bounded Goal**: Specific outcome required.
   - **Working Truth**: Context/assumptions to respect.
   - **Creator Intent**: The creator's high-level goal.
   - **Technical Risk**: Potential impact or implementation guidance.
4. Submit the issue.
5. Apply the label `brain-command` (or wait for automation to detect it).

### Option B: Workflow Dispatch (Manual)
1. Go to **Actions > BRAIN Remote Command System**.
2. Click **Run workflow**.
3. Fill in the parameters.
4. Run.

---

## 2. AUTOMATED BEHAVIOR
When a command is detected:
1. **Normalization**: The `brain_remote_router.py` script parses the input.
2. **Kernel Verification**: The system verifies the `BRAIN_KERNEL.md` is reachable.
3. **Payload Generation**: A machine-readable JSON artifact (`brain-payload`) is created.
4. **Receipt Acknowledged**: The system comments back on the issue with a summary.

---

## 3. DOWNSTREAM INTEGRATION
The normalized `.brain_payload.json` is ready for future autonomous execution or local agent pickup.

```json
{
  "version": "2.2-remote",
  "kernel_verified": true,
  "classification": "Patch (ALFRED/SURGEON)",
  "files": ["data/CombatContent.gd"],
  "goal": "Add 'ashclaw' variant...",
  "truth": "Uses existing claw_vfx...",
  "intent": "Expand biological trophies lane...",
  "risk": "Ensure DNA economy lane integrity"
}
```

---

## 4. TROUBLESHOOTING
- **No Comment**: Ensure the `brain-command` label was applied.
- **Malformed Payload**: Check if the issue body follows the template headers strictly.
- **Workflow Failure**: Check GitHub Actions logs for `tools/brain_remote_router.py` errors.
