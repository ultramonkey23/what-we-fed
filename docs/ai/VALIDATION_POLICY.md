# VALIDATION POLICY (v2.0 "The Auditor's Eye")

This file defines the validation contract for all V2 Agents (ARCHITECT, SURGEON, AUDITOR).

---

## 1. The Shadow Pair (Self-Critique Protocol)
Every non-trivial implement (Tier 2-3 Blast Radius) MUST be critiqued before being presented to the user.

- **SURGEON (Generator)**: Proposes the fix/feature based on GDScript 2.0 rules.
- **AUDITOR (Critic)**: Reviews the proposal against:
  - **Layer 1 Preservation**: Does this touch timing/lanes/DNA?
  - **Sludge Check**: Does this add HUD clutter or menu-based active-combat interruption?
  - **Safety Check**: Is it typed? Are signal connections safe?
  - **Reputation Check**: Does the implementation match the "Black Signal" vibe?

---

## 2. Validation Evidence Types (Honest Reporting)

### Runtime-Verified (High Certainty)
Used when behavior was exercised by `validate_project.bat`, `smoke_project.bat`, or a manual Godot run.
- **Requirement**: Must list the exact log/shell output confirming success.

### Static-Only (Medium Certainty)
Used when verification is based on `grep_search`, syntax checking, and code structure only.
- **Requirement**: Must explain WHY runtime was skipped (e.g., "Non-runnable data change").

### Speculative (Low Certainty)
Used when a claim is an educated guess based on documentation or older repo truth.
- **Requirement**: Must be explicitly marked as **[SPECULATIVE]** and include a follow-up check for the user.

---

## 3. The Validation Report (V2 Template)
```md
## Auditor's Report (V2)
- **Blast Radius**: Tier 0 | 1 | 2 | 3
- **Evidence Type**: Runtime-Verified | Static-Only | Speculative
- **Self-Critique Results**:
  - [X] Layer 1 Integrity (Timing/Lanes)
  - [X] Anti-Sludge (HUD/Combat-Clean)
  - [X] GDScript 2.0 Compliance (Typing/Signals)
- **Verified Facts**: ...
- **Unverified Risks**: ...
- **Next Bounded Move**: ...
```

---

## 4. Regression Rules (The Blockers)
The AUDITOR has the authority to block a SURGEON if:
1. **Timing Truth** is compromised (e.g., frame-dependent logic instead of `SongConductor` signals).
2. **Lane Readability** is obscured by new visual effects.
3. **Signal Bloat** is introduced (direct node coupling instead of `EventBus`).
4. **Data Sludge** is added (hardcoded stats instead of `Resource` objects).

---

## 5. Anti-Drift: The "Honest Reporting" Mandate
- Do not "hallucinate" success. If a test was not run, say so.
- Do not hide regressions behind "vague architectural benefits."
- If a patch creates a Layer 1 risk, it MUST be reported in the Auditor's Report.
