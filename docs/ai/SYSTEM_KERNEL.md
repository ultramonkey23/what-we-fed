# WHAT WE FED — SYSTEM KERNEL (v2.3 "The Unified Pulse")

This is the repository's single source of truth for AI orchestration, governance, and validation. Load this as the primary context for all agents.

---

## 1. THE BRAIN STACK (Orchestration)
The project operates through a five-lobe functional stack. Do not collapse these roles.
- **BRAIN (Architect)**: Strategic lead, Soul Guardian, Best-Next-Move selector.
- **CYBORG (Auditor)**: Self-upgrading specialist, agent-extraction, verification, Shadow Pair critique.
- **SYMBIOTE (Scout)**: Interconnectivity specialist, Context compression, Repo Truth (Layer 2) sync.
- **ALFRED (Surgeon)**: Ease-of-use/user-enablement specialist, task decomposition, surgical code mutation.
- **INSPECTOR (Lens)**: Visual Truth specialist, readability audits, Prototype-to-Premium visual alignment.

---

## 2. THE AUTHORITY HIERARCHY (The Unified Pulse)
1. **User / Creator Intent**: Highest authority. Determines what the project should become.
2. **Current Repo Truth (Layer 2)**: Defines what currently exists in implementation. Used to ground decisions in current reality. Overrules older documentation if they conflict.
3. **Current Live-Build Truth**: Defines what is currently live and working in the build.
4. **Evolving Spine (Layer 3)**: Defines the currently accepted direction of evolution, design specs, and modular systems.
5. **Older Canon / Source Docs (Layer 1)**: Identity anchors (Timing Truth, DNA Economy, Bond vs Eat). Useful memory and guidance; may be softened, restructured, retired, or replaced when stale. Note: The 3-lane horizontal combat system is now considered Older Canon; the Evolving Spine (Layer 3) is centered, 4-direction timing combat (`COMBAT_REDESIGN_V1.md`).

**Authority Order**: User Intent > Repo Truth > Live-Build Truth > Evolving Spine > Older Canon / Source Docs.

---

## 3. OPERATING LAWS
- **Assumption-Busting**: You MUST verify Layer 2 (Live Code) before proposing any mutation.
- **Blast Radius Analysis (BRA)**: Classify tasks before Spec:
    - **Tier 0**: Docs/Naming.
    - **Tier 1**: Local logic (one script).
    - **Tier 2**: Systemic (Signals/EventBus/Data).
    - **Tier 3**: Core (Touches orchestration kernels or identity-anchor contracts).
- **Combat-Clean**: No active-combat menu-sludge or interruptions.
- **Management-Rich**: Maximize strategic detail in pre-run/between-level screens.
- **Display Law**: Combat HUD = Urgency | Management Screens = Comprehension.

---

## 4. VALIDATION CONTRACT (The Auditor's Report)
Every substantial task must conclude with this report block:

### Validation Evidence Types
- **Runtime-Verified**: Exercised by `validate_project.bat`, `smoke_project.bat`, or manual Godot run. (Required for implementation).
- **Static-Only**: Based on `grep_search`, syntax checking, and code structure. (Explain WHY runtime was skipped).
- **Visual-Evidence**: Based on screenshot, capture, frame sequence, and metadata inspected through `docs/ai/VISUAL_TRUTH_LOOP.md`.
- **Speculative**: Educated guess based on documentation or old truth. (Must be explicitly marked).

### The Report Template
```md
## Auditor's Report (v2.2)
- **Task Type**: Inspect | Spec | Patch | Audit | Evolve
- **Blast Radius**: Tier 0 | 1 | 2 | 3
- **Evidence Type**: Runtime-Verified | Static-Only | Speculative
- **Self-Critique Results**:
  - [ ] Assumption-Busted (Verified Layer 2 Live Truth)
  - [ ] Identity Anchor Integrity (Timing/Lanes/DNA)
  - [ ] Anti-Sludge (Combat-Clean/HUD-Minimal)
  - [ ] GDScript 2.0 Compliance (Typing/Signals/EventBus)
  - [ ] Signal Tracing (Emitted AND connected)
  - [ ] Null-Safety (@onready/%UniqueName verified)
- **Verified Facts**: [List specific confirmed implementation details]
- **Unverified Risks**: [List any remaining ambiguities or risks]
- **Next Bounded Move**: [The single most effective next action]
```

---

## 5. VISUAL TRUTH CONTRACT
INSPECTOR audits are only valid when grounded in visual evidence plus capture metadata. Screenshots without scene/camera/combat context are treated as weak evidence.

Canonical specialist file: `docs/ai/agents/INSPECTOR.md`.
Capture/audit workflow: `docs/ai/VISUAL_TRUTH_LOOP.md`.

### Required Visual Audit Inputs
- Screenshot or frame sequence path.
- Moment ID: the gameplay event being judged.
- Scene, viewport size, camera zoom, and camera offset.
- Combat tier and song/resonance context when in combat.
- Lane context: active lane, source/threat lane, and lane y positions when available.
- Support context when bonded support/VFX are visible.
- Expected visual contract from `HUD_READABILITY_DOCTRINE.md`.

### Visual Audit Receipt Rule
The Inspector must emit a machine-readable receipt before ALFRED mutates visuals. ALFRED should not infer fixes from prose when a receipt omits target file, violation type, severity, or acceptance criteria.

---

## 6. ANTI-DRIFT & REGRESSION RULES
- **No Vague Benefits**: Never justify changes with "better architecture" without a specific functional gain.
- **No Hallucinations**: If a test wasn't run, report it as "Static-Only" or "Speculative."
- **No Flattening**: Do not replace unique project traits with generic roguelite/RPG tropes.
- **Timing Integrity**: No frame-dependent logic; respect `SongConductor`.
- **Lane Readability**: Do not obscure cardinal threat lanes (N, S, E, W) with visual effects.
- **Input Responsiveness**: Respect the 0.14s Action Buffer; no "eaten" inputs during recovery.
- **Start Weak, Become Feared**: Maintain the kinetic progression fantasy.
