# VISUAL TRUTH LOOP (V2.3 "Hybrid-Automated Pulse")

## Core Concept
Agents lack "eyes" by default. To bridge the gap between mechanical truth (code) and visual truth (the screen), the **Visual Truth Loop** establishes a strict pipeline for inspecting game aesthetics, HUD readability, and VFX clutter.

## The Loop
1. **Capture**: The user, `tools/capture_audit_frame.gd`, or an automated test script captures screenshot(s) or short video frame sequences of the specific gameplay moment in question.
   - *Convention*: Save visual evidence to `what-we-fed/docs/ai/visual_audits/pending/`.
   - *Reviewed Convention*: Move completed receipt/evidence packets to `what-we-fed/docs/ai/visual_audits/reviewed/` only after BRAIN has accepted the result or ALFRED has completed the patch.
   - *Hybrid Automation*: In dev builds, attach `tools/capture_audit_frame.gd` to the active scene or autoload it. Press `F12` for a manual capture. The tool can also auto-capture on high-value EventBus moments such as `player_took_damage`, `timed_attack_resolved`, `player_parried`, `player_dodged`, `bonded_support_triggered`, and `ultimate_fired`.
   - *Metadata Requirement*: Every capture must have a sibling `.json` receipt seed with scene, viewport, camera, combat tier, song/resonance, lane, support, and active mutation context when available. Unknown values must be written as `unknown`, not invented.
2. **Summon INSPECTOR**: The BRAIN routes a task to the **Inspector** agent, providing the file paths to the captured visual evidence and metadata packet.
   - *Canonical Specialist*: `docs/ai/agents/INSPECTOR.md`.
3. **Audit**: The Inspector analyzes the visual evidence against:
   - `HUD_READABILITY_DOCTRINE.md` (Are lanes 0, 1, 2 obscured? Are timing elements readable?)
   - `PROTOTYPE_VISUAL_REPLACEMENT_PROMPTS_V1.md` (Do the visuals match the "Premium Menace" target, or are they flat and prototype-y?)
4. **Receipt**: The Inspector generates a **Visual Audit Receipt** using the schema below. Prose is allowed after the schema, but ALFRED consumes the schema as source of truth.
5. **Mutation**: The BRAIN hands the receipt to ALFRED (Surgeon) to implement the specific GDScript or Shader changes necessary to correct the visual drift.
6. **Re-Capture & Verify**: User re-captures the moment. CYBORG (Auditor) verifies the new screenshot against the receipt.

## Visual Audit Receipt Schema
Use JSON so ALFRED can parse it with zero ambiguity.

There are two JSON artifacts in the loop:
- **Capture Seed**: produced by `tools/capture_audit_frame.gd`; factual runtime metadata only.
- **Visual Audit Receipt**: produced by INSPECTOR; judgment, violations, suspected targets, and acceptance criteria.

### Capture Seed Schema
The capture tool writes this beside each screenshot.

```json
{
  "schema_version": "visual_audit_capture.v2",
  "audit_id": "YYYYMMDD_HHMMSS_moment_slug",
  "capture_source": "manual_f12 | eventbus_auto | external",
  "image_path": "res://docs/ai/visual_audits/pending/example.png",
  "metadata_path": "res://docs/ai/visual_audits/pending/example.json",
  "png_error": 0,
  "moment_id": "player_took_damage",
  "event_payload": {},
  "scene": "res://scenes/combat/CombatScene.tscn",
  "viewport": {"width": 1280, "height": 720},
  "camera": {"zoom": {"x": 1.0, "y": 1.0}, "offset": {"x": 0.0, "y": 0.0}, "global_position": {"x": 0.0, "y": 0.0}},
  "combat": {"tier": "rampage", "combo_count": 12, "style_score": 640.0, "active_lane": 1},
  "song": {"id": "tricky", "section_id": "verse", "beat_index": 32, "beat_quality": "good", "intensity": 0.65, "resonance_tier": "drive"},
  "lane": {"active": 1, "source": 2, "support": -1, "y_positions": [260.0, 360.0, 460.0]},
  "support": {"species_id": "ashclaw", "charge": 75.0, "effect_id": "unknown"},
  "game_state": {"available": true, "run_number": 1, "in_combat": true, "active_mutations": []}
}
```

### Inspector Receipt Schema
The Inspector transforms capture seed(s) plus screenshot evidence into this patch-ready receipt.

```json
{
  "schema_version": "visual_audit_receipt.v1",
  "audit_id": "YYYYMMDD_HHMMSS_moment_slug",
  "evidence": {
    "image_paths": ["docs/ai/visual_audits/pending/example.png"],
    "metadata_paths": ["docs/ai/visual_audits/pending/example.json"],
    "capture_source": "manual_f12 | eventbus_auto | external"
  },
  "capture_context": {
    "scene": "res://scenes/combat/CombatScene.tscn",
    "viewport": {"width": 1280, "height": 720},
    "camera": {"zoom": {"x": 1.0, "y": 1.0}, "offset": {"x": 0.0, "y": 0.0}},
    "moment_id": "player_took_damage",
    "combat_tier": "rampage",
    "resonance_tier": "unknown",
    "song": {"id": "unknown", "section_id": "unknown", "beat_index": -1, "beat_quality": "unknown", "intensity": -1.0},
    "lane": {"active": -1, "source": 1, "y_positions": []},
    "support": {"species_id": "unknown", "charge": -1.0, "effect_id": "unknown"},
    "active_mutations": []
  },
  "doctrine_checks": {
    "lane_floor_visible": "pass | fail | uncertain",
    "timing_elements_readable": "pass | fail | uncertain",
    "combat_hud_urgency_only": "pass | fail | uncertain",
    "shells_not_slabs": "pass | fail | uncertain",
    "support_enemy_color_language": "pass | fail | uncertain",
    "premium_menace_alignment": "pass | fail | uncertain"
  },
  "violations": [
    {
      "id": "V001",
      "severity": "blocker | major | minor",
      "type": "lane_obscured | timing_unreadable | slab_ui | support_color_drift | enemy_color_drift | clutter | prototype_flatness | unknown",
      "lane": 1,
      "region": {"x": 0, "y": 0, "w": 0, "h": 0},
      "description": "Short factual statement.",
      "suspected_targets": ["systems/CombatPresentationController.gd"],
      "acceptance_criteria": ["Lane 1 floor highlight visible during the same moment."]
    }
  ],
  "alfred_patch_order": ["Fix blocker lane readability before aesthetic polish."],
  "verification_plan": ["Re-capture the same moment_id and compare doctrine_checks."]
}
```

## Required Tooling Support
- `tools/capture_audit_frame.gd`: Optional debug Node that snapshots the screen and dumps a `.png` plus sibling `.json` metadata into `docs/ai/visual_audits/pending/`. It is intentionally not wired into combat by default; attach it to a debug scene/autoload when visual truth work is active.
- Image context injection in the agent chat (e.g., via Cursor/Claude attachments) must be explicitly requested when Visual Truth drifts.

## Role Extraction Decision
- **Extract Shader Surgeon as a role pack now, not a sixth lobe.** Visual priority is real, but shader/VFX mutation remains ALFRED-owned implementation work. INSPECTOR finds visual truth failures; Shader Surgeon should handle shader/material fixes under ALFRED when the receipt points at `.gdshader`, `ShaderMaterial`, particle, flash, or post-process drift.
- Do not let Shader Surgeon audit screenshots. That would overlap INSPECTOR and weaken the evidence chain.
