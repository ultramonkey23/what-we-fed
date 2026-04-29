# GODLY Manifest: Vessel Purity Cleanup
- **Goal**: Resolve all 'UNUSED_PARAMETER' and 'UNUSED_VARIABLE' warnings across the core combat and systems directories. Prefix intended unused parameters with an underscore and remove truly redundant variables to ensure absolute codebase purity and optimal runtime performance.
- **Tier**: sprintlet
- **Mode**: medium-evolution
- **Allowed Paths**: [scenes/combat/**, systems/**, autoloads/**, data/**, tools/**]
- **Forbidden Paths**: [project.godot, .git/**]
- **Budgets**: 
  - Max Tasks: 5
  - Max Files: 15
  - Line Cap: 2000
- **Commit Allowed**: No
- **Validation Level**: 3
- **Rollback Plan**: git checkout HEAD -- scenes/combat/ systems/ autoloads/ data/ tools/

## Lead Lane Selection
Choose the specialist to lead this run:
- [ ] **SIGNAL** (Vibe Coder): Tone, juice, style.
- [ ] **BRAIN** (Architect): Strategy, architecture, delegation.
- [x] **AUDITOR** (Cyborg): Hardening, consistency, extraction.
- [ ] **SURGEON** (Alfred): Implementation, surgical fixes.
- [ ] **VISUALS** (Inspector): Aesthetic truth, HUD readability.
- [ ] **VOID** (Crash Hunter): Blocks, crashes, instance safety.
- [ ] **SCOUT** (Symbiote): Mapping, truth discovery, compression.

## Read first: [docs/ai/SOVEREIGN_CORE.md](SOVEREIGN_CORE.md)
