# WHAT WE FED — SYSTEM KERNEL (v2.3 "The Unified Pulse")

This is the repository's single source of truth for AI orchestration, governance, and validation. Load this as the primary context for all agents.

---

## 1. THE BRAIN STACK (Orchestration)
The project operates through a five-lobe functional stack. Every lobe has a formal mandate file in `docs/ai/agents/`.
- **BRAIN (Director)**: Strategic lead, Soul Guardian, Handoff Compiler lead. (`BRAIN.md`, `HANDOFF_COMPILER.md`)
- **CYBORG (Auditor)**: Self-upgrading specialist, agent-extraction, Build Doctor lead. (`CYBORG.md`, `BUILD_DOCTOR.md`)
- **SYMBIOTE (Scout)**: Interconnectivity specialist, Repo Truth sync, Snapshot Generator lead. (`SYMBIOTE.md`, `SNAPSHOT_GENERATOR.md`)
- **ALFRED (Surgeon)**: User-enablement, surgical code mutation. (`GDSCRIPT_SURGEON.md`, etc.)
- **INSPECTOR (Lens)**: Visual Truth lead, readability audits, aesthetic alignment. (`INSPECTOR.md`)

---

## 2. THE AUTHORITY HIERARCHY (The Unified Pulse)
1. **User / Creator Intent**: Highest authority. Determines what the project should become.
2. **Current Repo Truth (Layer 2)**: Defines what currently exists in implementation. Used to ground decisions in current reality. Overrules older documentation if they conflict.
3. **Current Live-Build Truth**: Defines what is currently live and working in the build.
4. **Evolving Spine (Layer 3)**: Defines the currently accepted direction of evolution, design specs, and modular systems. Note: Previous lane-locked systems are now considered Older Canon; the Evolving Spine is an action-RPG hunting field with beat-feel.
5. **Older Canon / Source Docs (Layer 1)**: Identity anchors (Timing Truth, DNA Economy, Bond vs Eat). Useful memory and guidance; may be softened, restructured, retired, or replaced when stale.

**Authority Order**: User Intent > Repo Truth > Live-Build Truth > Evolving Spine > Older Canon / Source Docs.

---

## 3. OPERATING LAWS
- **Spatial Purity (ARPG Rule)**: Snapping is banned. No mechanical interaction (Damage/Status) may rely on lane indices. Interactions must use **Enemy IDs** or **Spatial Area** checks.
- **Manga Framing (Impact Rule)**: Combat is a sequence of high-intensity frames. Hyperbolic feedback—**Hit-Stop** (time scale reduction) and **Heavy Shake**—is mandatory on perfect impact.
- **The Sentient System (Extraction Rule)**: Growth is diegetic "Trait Extraction" (Slime/Gamer). Leveling up must be **Deterministic** (Aggression = Power, etc.). No RNG stat sludge.
- **Meta-Persistence**: Only **Potential** and **Luck** survive the run reset.
- **Combat-Clean**: No active-combat menu-sludge or interruptions.
- **Management-Rich**: Maximize strategic detail in pre-run/between-level screens.
- **Display Law**: Combat HUD = Urgency | Management Screens = Comprehension. Lanes are strictly **Visual Spawn Sectors**.

---

## 4. VALIDATION CONTRACT (The Auditor's Report)
Every substantial task must conclude with this report block:

### Validation Evidence Types
- **Runtime-Verified**: Exercised by `validate_project.bat`, `smoke_project.bat`, `validate_data.bat`, or manual Godot run. (Required for implementation).
- **Data-Validated**: Verified by the headless Data Content Validator (`tools/validate_data_content.gd`).
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
  - [ ] Identity Anchor Integrity (Timing/DNA/Beat-Feel)
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
- Field context: active/focused cardinal direction, source/threat direction, and cardinal spawn/hit-zone positions when available.
- Support context when bonded support/VFX are visible.
- Expected visual contract from `HUD_READABILITY_DOCTRINE.md`.

### Visual Audit Receipt Rule
The Inspector must emit a machine-readable receipt before ALFRED mutates visuals. ALFRED should not infer fixes from prose when a receipt omits target file, violation type, severity, or acceptance criteria.

---

## 6. ANTI-DRIFT & REGRESSION RULES
- **No Vague Benefits**: Never justify changes with "better architecture" without a specific functional gain.
- **No Hallucinations**: If a test wasn't run, report it as "Static-Only" or "Speculative."
- **No Flattening**: Do not replace unique project traits with generic roguelite/RPG tropes.
- **Timing Integrity**: No frame-dependent logic; respect `SongConductor` and Beat-Feel.
- **Field/Directional Readability**: Do not obscure cardinal threat directions (N, S, E, W) with visual effects.
- **Input Responsiveness**: Respect the 0.14s Action Buffer; no "eaten" inputs during recovery.
- **Start Weak, Become Feared**: Maintain the kinetic progression fantasy.
