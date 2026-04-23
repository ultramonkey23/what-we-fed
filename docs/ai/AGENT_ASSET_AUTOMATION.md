# Agent Asset Automation (Headless-Only)

This is the canonical, agent-usable asset generation stack for WHAT WE FED.

## Kept (Agent-Usable)
- `tools/asset_orchestrator.py`: headless orchestrator for manifest-driven generation.
- `tools/asset_orchestrator.ps1`: Windows wrapper for agents using PowerShell.
- `tools/generate_shot_sprites.py`: deterministic projectile overlay/body generation.
- `tools/generate_visual_replacements.py`: deterministic combat/UI/background visual generation.
- ComfyUI HTTP API (`http://127.0.0.1:8188` by default) for prompt-based image drafts.

## Scrapped From Agent Pipeline (Not Headless Here)
- Aseprite / Krita / Blockbench / ArmorPaint / Material Maker (GUI-first tools).
- Godot editor plugins that require manual editor interaction for generation.
- Asset sources that are only static packs (import helpers are fine, but not generation automation).

## Manifest Source Of Truth
- `docs/ai/ASSET_MANIFEST.json` stays authoritative for pending/integrated assets.
- Prompt grammar and style anchor rules remain in `docs/ai/PROMPT_ENGINE.md`.

## Commands
From repo root:

```powershell
# Show pending manifest entries (defaults to status=pending)
.\tools\asset_orchestrator.ps1 manifest-list

# Show only pending image-generation entries
.\tools\asset_orchestrator.ps1 manifest-list --image-only

# Generate a subset from ComfyUI (requires running ComfyUI + checkpoint installed there)
.\tools\asset_orchestrator.ps1 manifest-generate --provider comfyui --checkpoint "<your_model>.safetensors" --limit 3

# Generate a specific asset id
.\tools\asset_orchestrator.ps1 manifest-generate --provider comfyui --checkpoint "<your_model>.safetensors" --ids bond_remnant_adult

# Dry-run before generation
.\tools\asset_orchestrator.ps1 manifest-generate --provider comfyui --checkpoint "<your_model>.safetensors" --dry-run

# Refresh deterministic in-repo assets
.\tools\asset_orchestrator.ps1 procedural-refresh --preset all
```

## Notes
- Generated outputs are written to each entry's `target_path` (`res://...`) on disk.
- Manifest status is not auto-switched to `integrated`; review and validation remain explicit.
- This keeps combat readability safe: generation is offline/headless and does not touch live runtime logic.
