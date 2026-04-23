# BRAIN LOBE: VALIDATION POLICY (v2.1 Sovereignty)

This file defines the validation contract for the **BRAIN Orchestrator**, enforced by the **CYBORG** (Auditor) lobe.

---

## 1. The Shadow Pair (Self-Critique Protocol)
Every non-trivial implement (Tier 2-3 Blast Radius) MUST be critiqued before being presented to the user.

- **ALFRED (Surgeon/Generator)**: Proposes the fix/feature based on GDScript 2.0 rules.
- **CYBORG (Auditor/Critic)**: Reviews the proposal against:
  - **Assumption-Busting**: Did the Surgeon verify Layer 2 (Live Code) before coding?
  - **Context Compression**: Did the Scout drop unneeded files from memory?
  - **Layer 1 Preservation**: Does this touch timing/lanes/DNA?
  - **Sludge Check**: Does this add HUD clutter or menu-based active-combat interruption?
  - **Safety Check**: Is it typed? Are signal connections safe?
  - **Identity Check**: Does the implementation match the "Black Signal" vibe?

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

## 3. The BRAIN Validation Report (v2.1 Template)
```md
## Auditor's Report (v2.1)
- **Task Type**: Inspect | Spec | Patch | Audit | Evolve
- **Blast Radius**: Tier 0 | 1 | 2 | 3
- **Evidence Type**: Runtime-Verified | Static-Only | Speculative
- **Self-Critique Results**:
  - [X] Assumption-Busted (Checked Layer 2 Live Truth)
  - [X] Context Compressed (Dropped unneeded files)
  - [X] Layer 1 Integrity (Timing/Lanes)
  - [X] Anti-Sludge (HUD/Combat-Clean)
  - [X] GDScript 2.0 Compliance (Typing/Signals)
- **Verified Facts**: ...
- **Unverified Risks**: ...
- **Next Bounded Move**: ...
```

---

## 4. Regression Rules (The Blockers)
The CYBORG (Auditor) has the authority to block ALFRED (Surgeon) if:
1. **Timing Truth** is compromised (e.g., frame-dependent logic instead of `SongConductor` signals).
2. **Lane Readability** is obscured by new visual effects.
3. **Signal Bloat** is introduced (direct node coupling instead of `EventBus`).
4. **Data Sludge** is added (hardcoded stats instead of `Resource` objects).
5. **Assumption Failure**: Implementation relies on non-existent files or nodes.

---

## 5. Anti-Drift: The "Honest Reporting" Mandate
- **No Hallucinations**: Do not "hallucinate" success. If a test was not run, say so.
- **No Vague Benefits**: Do not hide regressions behind "vague architectural benefits."
- **Layer 1 Reporting**: If a patch creates a Layer 1 risk, it MUST be reported.
- **Sovereignty**: All validation failures must be reported to BRAIN for reassessment.
