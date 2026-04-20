# WHAT WE FED — AI ASSET PROMPT ENGINE (V3)

## 1. THE MISSION: ASSET ORCHESTRATION
This document is a technical specification for the **Asset Orchestrator Agent**. It defines how to translate GDScript data into high-fidelity prompts for external generative AI, ensuring that all assets maintain the "Timing Truth" and "Lane Readability" required by the core gameplay.

---

## 2. THE GLOBAL STYLE ANCHOR (The Black Signal)
**EVERY visual prompt MUST include this suffix to ensure aesthetic continuity:**
> "...in the style of 2D dark fantasy concept art, high-contrast chiaroscuro, biological horror, visceral textures, bone-carving aesthetics, sharp silhouettes, muted palette of charcoal-grey, dried-blood crimson, and tarnished gold, no glowing particles, no soft gradients, flat 2D game asset, white background, inspired by Darkest Dungeon and Bloodborne."

---

## 3. VISUAL GENERATION GRAMMAR (Token Stacking)
AI Agents should use **Token Stacking** rather than natural language for more reliable results in Midjourney/Stable Diffusion.

### A. Creature Sprite Sheets
**Template**: `{species_id}_creature, {stage}_stage, {primary_type}_type, {archetype}_archetype, [VISUAL_ANCHOR: {wrong_detail}], {visual_descriptors}, dark_fantasy_2d, high_contrast, ink_wash, sharp_silhouette, orthographic_side_view, white_background --ar 1:1`

### B. Projectile Families (Geometry = Speed)
*   **MASS**: `jagged_heavy_calcified_bone_projectile, asymmetric, high_inertia, debris_trail`
*   **NEEDLE**: `razor_thin_obsidion_shard_projectile, linear, vibrating_blur, zero_drag`
*   **VEIL**: `smoky_hollow_ring_projectile, distorted_eye_shape, blurred_edges, ethereal`
*   **CHORUS**: `circular_geometric_disc_projectile, vibrating_layers, ritual_gold, pulse_effect`

---

## 4. AUDIO GENERATION GRAMMAR (Timing Truth)
**EVERY audio prompt MUST enforce zero-latency transients for rhythmic alignment:**
> "Dry foley sound effect, 44.1kHz mono, {material} {action}, {quality_modifiers}. Sharp transient, immediate attack, zero-latency, resonant tail. No background noise."

### Quality Modifiers:
*   **PERFECT**: "Deep sub-bass thump, heavy metallic ring-out, satisfying visceral crunch."
*   **GOOD**: "Sharp click, metallic scrape, shorter duration."
*   **PARRY**: "Glassy obsidian clink, crystalline, cold, immediate, sharp ping."

---

## 5. AGENTIC VALIDATION GATE (The Quality Checks)
Before an asset is integrated, the Agent must perform a **Vision Audit**:
1.  **Silhouette Check**: Is the shape distinct from a distance (Lane Readability)?
2.  **Wrong Detail Check**: Is the unique feature (e.g., the unhinged jaw) the primary visual read?
3.  **Palette Check**: Does it adhere to the Charcoal/Bone/Crimson/Gold limit?
4.  **Timing Check (Audio)**: Does the peak volume occur within 5ms of file-start?

---

## 6. THE ASSET MANIFEST (Handshake)
The Agent maintains `docs/ai/ASSET_MANIFEST.json` as the source of truth for all pending and integrated assets. 
