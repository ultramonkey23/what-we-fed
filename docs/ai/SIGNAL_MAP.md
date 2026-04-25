# SIGNAL MAP

## Purpose
Generated signal-flow reference for AI agents.

## Warning
This is a static scan, not runtime proof.
Dynamic signal names or indirect connections may be missed.
When editing signal contracts, verify against source code and validation.

## Summary
- **Generated:** 2026-04-25T16:32:05Z
- **Scan root:** `C:\Users\harin\OneDrive\Desktop\gamesdevs\What We Fed\what-we-fed`
- **Files scanned:** 111
- **Signals declared (EventBus):** 61
- **Emitters found:** 187
- **Consumers / connects found:** 125
- **Disconnect references found:** 68

## EventBus Signals

| Signal | Declared In | Emitters | Consumers / Connects | Disconnect References | Confidence | Notes |
|---|---|---|---|---|---|---|
| `attack_timing_early_resolved` | `autoloads/EventBus.gd:23` | `scenes/combat/PlayerCombat.gd:859` | `scenes/combat/CombatScene.gd:3225` | `scenes/combat/CombatScene.gd:408` | HIGH | lane: int |
| `bonded_support_triggered` | `autoloads/EventBus.gd:113` | `systems/RunGrowth.gd:411` | `scenes/combat/CombatScene.gd:3240`<br>`systems/PerformanceRewardDirector.gd:422`<br>`systems/RunGrowth.gd:75`<br>`systems/RunStats.gd:44` | `scenes/combat/CombatScene.gd:434`<br>`systems/PerformanceRewardDirector.gd:447`<br>`systems/RunStats.gd:66` | HIGH | species_id: String, lane: int, effect_id: String |
| `boss_outcome_resolved` | `autoloads/EventBus.gd:117` | `autoloads/GameState.gd:747` | — | — | MEDIUM | outcome_id: String, payload: Dictionary |
| `capture_offered` | `autoloads/EventBus.gd:79` | `scenes/combat/CombatScene.gd:810`<br>`scenes/combat/CombatScene.gd:824`<br>`scenes/combat/CombatScene.gd:3553` | — | — | MEDIUM | creature_data: Dictionary |
| `combat_ended` | `autoloads/EventBus.gd:7` | `scenes/combat/LaneManager.gd:420`<br>`scenes/combat/PlayerCombat.gd:985` | `autoloads/GameState.gd:199`<br>`examples/demo_encounter_stack/CombatSystemIntegration.gd:52`<br>`scenes/combat/CombatScene.gd:3211`<br>`systems/QuigNarrativeSystem.gd:28` | `scenes/combat/CombatScene.gd:378` | HIGH | victory: bool |
| `combat_input_resolved` | `autoloads/EventBus.gd:29` | `scenes/combat/PlayerCombat.gd:358` | `scenes/combat/CombatScene.gd:3228` | `scenes/combat/CombatScene.gd:414` | HIGH | action: String, lane: int, accepted: bool, buffered: bool, reason: String, state: String, cooldowns: Dictionary |
| `combat_started` | `autoloads/EventBus.gd:5` | `scenes/combat/LaneManager.gd:166` | `autoloads/GameState.gd:197`<br>`examples/demo_encounter_stack/CombatSystemIntegration.gd:50`<br>`systems/CombatHUDPresenter.gd:122`<br>`systems/PerformanceRewardDirector.gd:412`<br>`systems/RunGrowth.gd:53` | `systems/PerformanceRewardDirector.gd:437` | HIGH | enemy_data: Array |
| `combo_broken` | `autoloads/EventBus.gd:57` | `systems/CombatMeter.gd:127`<br>`systems/CombatMeter.gd:158` | `scenes/combat/CombatScene.gd:3230`<br>`scenes/ui/CombatPerformanceHUD.gd:83` | `scenes/combat/CombatScene.gd:418` | HIGH | lost: int |
| `combo_changed` | `autoloads/EventBus.gd:55` | `systems/CombatMeter.gd:38`<br>`systems/CombatMeter.gd:239` | `scenes/combat/CombatScene.gd:3204`<br>`scenes/combat/PlayerCombat.gd:397`<br>`scenes/ui/CombatPerformanceHUD.gd:80`<br>`systems/RunGrowth.gd:61` | `scenes/combat/CombatScene.gd:364` | HIGH | count: int, tier: String |
| `creature_ascended` | `autoloads/EventBus.gd:89` | `autoloads/GameState.gd:488` | `systems/QuigNarrativeSystem.gd:30` | — | HIGH | data: Dictionary |
| `creature_bonded` | `autoloads/EventBus.gd:83` | `systems/VictoryRewardDirector.gd:73` | `autoloads/GameState.gd:193`<br>`scenes/combat/CombatScene.gd:3238`<br>`systems/QuigNarrativeSystem.gd:22`<br>`systems/RunGrowth.gd:67`<br>`systems/RunStats.gd:47`<br>`systems/VesselModifierDirector.gd:66` | `autoloads/GameState.gd:204`<br>`scenes/combat/CombatScene.gd:430`<br>`systems/RunStats.gd:72` | HIGH | creature_data: Dictionary |
| `creature_eaten` | `autoloads/EventBus.gd:87` | `systems/VictoryRewardDirector.gd:78` | `autoloads/GameState.gd:195`<br>`examples/demo_encounter_stack/CombatSystemIntegration.gd:54`<br>`systems/PerformanceRewardDirector.gd:420`<br>`systems/QuigNarrativeSystem.gd:23`<br>`systems/RunGrowth.gd:69`<br>`systems/RunStats.gd:48`<br>…+1 | `autoloads/GameState.gd:206`<br>`systems/PerformanceRewardDirector.gd:445`<br>`systems/RunStats.gd:74` | HIGH | creature_data: Dictionary |
| `dna_gained` | `autoloads/EventBus.gd:91` | `scenes/combat/CombatScene.gd:5751` | `scenes/combat/CombatScene.gd:3241`<br>`systems/RunStats.gd:49` | `scenes/combat/CombatScene.gd:436`<br>`systems/RunStats.gd:76` | HIGH | species_id: String, amount: float, total: float |
| `dna_lock_denied` | `autoloads/EventBus.gd:81` | `systems/VictoryRewardDirector.gd:63` | `scenes/combat/CombatScene.gd:3214` | `scenes/combat/CombatScene.gd:384` | HIGH | species_id: String, current: float, required: float |
| `dna_resonated` | `autoloads/EventBus.gd:93` | `scenes/combat/CombatScene.gd:5715`<br>`scenes/combat/CombatScene.gd:5762`<br>`scenes/combat/CombatScene.gd:5771`<br>`scenes/combat/CombatScene.gd:6302` | `scenes/combat/CombatScene.gd:3221` | `scenes/combat/CombatScene.gd:398` | HIGH | color: Color, intensity: float |
| `dna_routing_changed` | `autoloads/EventBus.gd:111` | `systems/RunGrowth.gd:435` | `scenes/combat/CombatScene.gd:3239` | `scenes/combat/CombatScene.gd:432` | HIGH | route_id: String, label: String |
| `enemy_damaged` | `autoloads/EventBus.gd:43` | `scenes/combat/LaneManager.gd:372` | `scenes/combat/CombatScene.gd:3212`<br>`systems/QuigNarrativeSystem.gd:27`<br>`systems/RunStats.gd:40` | `scenes/combat/CombatScene.gd:380`<br>`systems/RunStats.gd:58` | HIGH | enemy_id: int, damage: float |
| `enemy_defeated` | `autoloads/EventBus.gd:45` | `scenes/combat/LaneManager.gd:400` | `examples/demo_encounter_stack/MutationTracker.gd:33`<br>`scenes/combat/CombatScene.gd:3213`<br>`systems/PerformanceRewardDirector.gd:402`<br>`systems/RunGrowth.gd:55`<br>`systems/RunStats.gd:39` | `scenes/combat/CombatScene.gd:382`<br>`systems/PerformanceRewardDirector.gd:427`<br>`systems/RunStats.gd:56` | HIGH | enemy_id: int |
| `enemy_status_applied` | `autoloads/EventBus.gd:47` | `scenes/combat/LaneManager.gd:394`<br>`scenes/combat/LaneManager.gd:550` | `scenes/combat/CombatScene.gd:3243`<br>`systems/RunGrowth.gd:71` | `scenes/combat/CombatScene.gd:440` | HIGH | lane: int, status_id: String, params: Dictionary |
| `enemy_status_applied_requested` | `autoloads/EventBus.gd:51` | `systems/RunGrowth.gd:300` | `scenes/combat/CombatScene.gd:3217` | — | HIGH | lane: int, status_id: String, params: Dictionary |
| `enemy_status_cleared` | `autoloads/EventBus.gd:49` | `scenes/combat/LaneManager.gd:197`<br>`scenes/combat/LaneManager.gd:381`<br>`scenes/combat/LaneManager.gd:395`<br>`scenes/combat/LaneManager.gd:398`<br>`scenes/combat/LaneManager.gd:504`<br>`scenes/combat/LaneManager.gd:645` | `scenes/combat/CombatScene.gd:3244` | `scenes/combat/CombatScene.gd:442` | HIGH | lane: int |
| `mastery_context_updated` | `autoloads/EventBus.gd:115` | `scenes/combat/PlayerCombat.gd:478`<br>`scenes/combat/PlayerCombat.gd:490` | `scenes/combat/CombatScene.gd:3242` | `scenes/combat/CombatScene.gd:438` | HIGH | data: Dictionary |
| `phrase_milestone` | `autoloads/EventBus.gd:73` | `systems/CombatMeter.gd:186`<br>`systems/CombatMeter.gd:189` | `scenes/combat/CombatScene.gd:3245`<br>`systems/PerformanceRewardDirector.gd:414` | `scenes/combat/CombatScene.gd:444`<br>`systems/PerformanceRewardDirector.gd:439` | HIGH | count: int |
| `play_sfx` | `autoloads/EventBus.gd:141` | `scenes/combat/CombatScene.gd:5425`<br>`scenes/combat/CombatScene.gd:6291`<br>`scenes/combat/PlayerCombat.gd:919`<br>`systems/CombatPresentationRuntime.gd:601`<br>`systems/VesselModifierDirector.gd:141`<br>`systems/VesselModifierDirector.gd:147`<br>…+1 | `systems/CombatAudioPlayer.gd:10` | `systems/CombatAudioPlayer.gd:15` | HIGH | cue_id: String |
| `player_attacked` | `autoloads/EventBus.gd:19` | `scenes/combat/PlayerCombat.gd:771`<br>`scenes/combat/PlayerCombat.gd:830`<br>`scenes/combat/PlayerCombat.gd:890`<br>`scenes/combat/PlayerCombat.gd:926` | `examples/demo_encounter_stack/MutationTracker.gd:29`<br>`scenes/combat/CombatScene.gd:3223`<br>`systems/CombatHUDPresenter.gd:126` | `scenes/combat/CombatScene.gd:404` | HIGH | lane: int, damage: float, was_timed: bool |
| `player_died` | `autoloads/EventBus.gd:35` | `scenes/combat/PlayerCombat.gd:984` | — | — | MEDIUM |  |
| `player_dodged` | `autoloads/EventBus.gd:27` | `scenes/combat/PlayerCombat.gd:690` | `scenes/combat/CombatScene.gd:3227`<br>`systems/PerformanceRewardDirector.gd:410`<br>`systems/RunGrowth.gd:73`<br>`systems/VesselModifierDirector.gd:64` | `scenes/combat/CombatScene.gd:412`<br>`systems/PerformanceRewardDirector.gd:435` | HIGH | from_lane: int, to_lane: int |
| `player_healed` | `autoloads/EventBus.gd:37` | `scenes/combat/CombatScene.gd:497`<br>`scenes/combat/CombatScene.gd:5695`<br>`scenes/combat/CombatScene.gd:6728`<br>`scenes/combat/PlayerCombat.gd:971`<br>`systems/PerformanceRewardDirector.gd:1006`<br>`systems/PerformanceRewardDirector.gd:1019`<br>…+12 | `scenes/combat/CombatScene.gd:3208` | `scenes/combat/CombatScene.gd:372` | HIGH | amount: float |
| `player_no_stamina` | `autoloads/EventBus.gd:39` | `scenes/combat/PlayerCombat.gd:337`<br>`scenes/combat/PlayerCombat.gd:589`<br>`systems/CombatMeter.gd:60`<br>`systems/CombatMeter.gd:70` | `scenes/combat/CombatScene.gd:3229` | `scenes/combat/CombatScene.gd:416` | HIGH |  |
| `player_parried` | `autoloads/EventBus.gd:25` | `scenes/combat/PlayerCombat.gd:652` | `examples/demo_encounter_stack/MutationTracker.gd:31`<br>`scenes/combat/CombatScene.gd:3226`<br>`systems/PerformanceRewardDirector.gd:406`<br>`systems/QuigNarrativeSystem.gd:20`<br>`systems/RunGrowth.gd:59`<br>`systems/RunStats.gd:42`<br>…+1 | `scenes/combat/CombatScene.gd:410`<br>`systems/PerformanceRewardDirector.gd:431`<br>`systems/RunStats.gd:62` | HIGH | lane: int, quality: String, reflect_damage: float |
| `player_teleported` | `autoloads/EventBus.gd:17` | `scenes/combat/PlayerCombat.gd:543`<br>`scenes/combat/PlayerCombat.gd:682`<br>`scenes/combat/PlayerCombat.gd:1314` | `scenes/combat/CombatScene.gd:3231`<br>`systems/CombatHUDPresenter.gd:124` | `scenes/combat/CombatScene.gd:420` | HIGH | from_lane: int, to_lane: int |
| `player_took_damage` | `autoloads/EventBus.gd:33` | `scenes/combat/PlayerCombat.gd:979` | `scenes/combat/CombatScene.gd:3207`<br>`systems/PerformanceRewardDirector.gd:408`<br>`systems/QuigNarrativeSystem.gd:24`<br>`systems/RunGrowth.gd:65`<br>`systems/RunStats.gd:46` | `scenes/combat/CombatScene.gd:370`<br>`systems/PerformanceRewardDirector.gd:433`<br>`systems/RunStats.gd:70` | HIGH | amount: float, source_lane: int |
| `proc_feedback_requested` | `autoloads/EventBus.gd:143` | `autoloads/GameState.gd:380`<br>`autoloads/GameState.gd:649`<br>`examples/demo_encounter_stack/CombatSystemIntegration.gd:134`<br>`scenes/combat/LaneManager.gd:185`<br>`scenes/combat/PlayerCombat.gd:339`<br>`scenes/combat/PlayerCombat.gd:344`<br>…+8 | `scenes/combat/CombatScene.gd:3215` | — | HIGH | text: String, color: Color |
| `projectile_fired` | `autoloads/EventBus.gd:11` | `scenes/combat/LaneManager.gd:691`<br>`scenes/combat/LaneManager.gd:725` | `scenes/combat/PlayerCombat.gd:394` | `scenes/combat/PlayerCombat.gd:126` | HIGH | lane: int, enemy_id: int |
| `projectile_missed` | `autoloads/EventBus.gd:13` | `scenes/combat/LaneManager.gd:883` | — | — | MEDIUM | lane: int, damage: float |
| `quig_narrative_triggered` | `autoloads/EventBus.gd:127` | `systems/QuigNarrativeSystem.gd:108` | `scenes/combat/CombatScene.gd:3247` | `scenes/combat/CombatScene.gd:448` | HIGH | text: String, duration: float |
| `run_completed` | `autoloads/EventBus.gd:99` | `scenes/combat/CombatScene.gd:4994`<br>`systems/CombatRunDirector.gd:154` | — | — | MEDIUM | success: bool |
| `run_growth_changed` | `autoloads/EventBus.gd:101` | `systems/RunGrowth.gd:433` | `scenes/combat/CombatScene.gd:3234`<br>`scenes/ui/CombatPerformanceHUD.gd:84` | `scenes/combat/CombatScene.gd:422` | HIGH | level: int, current_exp: float, exp_to_next: float |
| `run_growth_level_resolved` | `autoloads/EventBus.gd:103` | `systems/RunGrowth.gd:478` | `scenes/combat/CombatScene.gd:3235`<br>`scenes/ui/CombatPerformanceHUD.gd:85` | `scenes/combat/CombatScene.gd:424` | HIGH | result: Dictionary |
| `run_started` | `autoloads/EventBus.gd:97` | `systems/CombatRunDirector.gd:68` | `systems/RunGrowth.gd:51`<br>`systems/RunStats.gd:38` | `systems/RunStats.gd:54` | HIGH | run_number: int |
| `screen_flash` | `autoloads/EventBus.gd:131` | `scenes/combat/CombatScene.gd:4127`<br>`scenes/combat/CombatScene.gd:4268`<br>`scenes/combat/CombatScene.gd:4828`<br>`scenes/combat/CombatScene.gd:4869`<br>`scenes/combat/CombatScene.gd:4872`<br>`scenes/combat/CombatScene.gd:5058`<br>…+38 | `scenes/combat/CombatScene.gd:3218` | `scenes/combat/CombatScene.gd:388` | HIGH | color: Color, duration: float |
| `screen_shake` | `autoloads/EventBus.gd:129` | `scenes/combat/CombatScene.gd:4128`<br>`scenes/combat/CombatScene.gd:4829`<br>`scenes/combat/CombatScene.gd:5059`<br>`scenes/combat/CombatScene.gd:5113`<br>`scenes/combat/CombatScene.gd:5121`<br>`scenes/combat/CombatScene.gd:6519`<br>…+4 | `scenes/combat/CombatScene.gd:3219` | `scenes/combat/CombatScene.gd:390` | HIGH | intensity: float, duration: float |
| `slow_motion` | `autoloads/EventBus.gd:133` | `scenes/combat/CombatScene.gd:6290`<br>`scenes/combat/PlayerCombat.gd:474`<br>`systems/CombatPresentationRuntime.gd:567` | `scenes/combat/CombatScene.gd:3222` | `scenes/combat/CombatScene.gd:402` | HIGH | scale: float, duration: float |
| `song_beat_pulse` | `autoloads/EventBus.gd:135` | `scenes/combat/CombatScene.gd:1418` | `scenes/combat/CombatScene.gd:3233`<br>`scenes/combat/LaneManager.gd:164`<br>`scenes/combat/PlayerCombat.gd:400`<br>`scenes/ui/CombatPerformanceHUD.gd:86` | `scenes/combat/CombatScene.gd:394` | HIGH | beat_index: int, intensity: float, quality: String |
| `sovereign_reached` | `autoloads/EventBus.gd:63` | `systems/CombatMeter.gd:243` | `systems/QuigNarrativeSystem.gd:25` | — | HIGH |  |
| `sovereign_threshold_reached` | `autoloads/EventBus.gd:65` | `scenes/combat/CombatScene.gd:5569` | `systems/QuigNarrativeSystem.gd:26` | — | HIGH | threshold: float |
| `stamina_changed` | `autoloads/EventBus.gd:61` | `systems/CombatMeter.gd:37`<br>`systems/CombatMeter.gd:47`<br>`systems/CombatMeter.gd:64`<br>`systems/CombatMeter.gd:74`<br>`systems/CombatMeter.gd:132`<br>`systems/CombatMeter.gd:217` | `scenes/combat/CombatScene.gd:3206` | `scenes/combat/CombatScene.gd:368` | HIGH | current: float, maximum: float |
| `style_changed` | `autoloads/EventBus.gd:59` | `systems/CombatMeter.gd:39`<br>`systems/CombatMeter.gd:240` | `scenes/combat/CombatScene.gd:3205` | `scenes/combat/CombatScene.gd:366` | HIGH | score: float, tier: String |
| `support_charge_changed` | `autoloads/EventBus.gd:109` | `systems/RunGrowth.gd:434` | `scenes/combat/CombatScene.gd:3237` | `scenes/combat/CombatScene.gd:428` | HIGH | current: float, maximum: float, active_species_id: String |
| `tempo_state_entered` | `autoloads/EventBus.gd:123` | `systems/CombatRunDirector.gd:131` | `systems/QuigNarrativeSystem.gd:19` | — | HIGH | state_id: String |
| `tendency_growth_resolved` | `autoloads/EventBus.gd:107` | `systems/RunGrowth.gd:479` | `scenes/combat/CombatScene.gd:3236`<br>`systems/RunStats.gd:45` | `scenes/combat/CombatScene.gd:426`<br>`systems/RunStats.gd:68` | HIGH | tendency_id: String, title: String, summary: String |
| `tier_changed` | `autoloads/EventBus.gd:75` | `systems/CombatMeter.gd:236` | `scenes/combat/CombatScene.gd:3246`<br>`systems/PerformanceRewardDirector.gd:416` | `scenes/combat/CombatScene.gd:446`<br>`systems/PerformanceRewardDirector.gd:441` | HIGH | new_tier: String, old_tier: String |
| `timed_attack_resolved` | `autoloads/EventBus.gd:21` | `scenes/combat/PlayerCombat.gd:831` | `scenes/combat/CombatScene.gd:3224`<br>`systems/EncounterEscalationDirector.gd:83`<br>`systems/PerformanceRewardDirector.gd:404`<br>`systems/QuigNarrativeSystem.gd:21`<br>`systems/RunGrowth.gd:57`<br>`systems/RunStats.gd:41`<br>…+1 | `scenes/combat/CombatScene.gd:406`<br>`systems/PerformanceRewardDirector.gd:429`<br>`systems/RunStats.gd:60` | HIGH | lane: int, quality: String, damage: float |
| `timing_ring_pressed` | `autoloads/EventBus.gd:137` | `scenes/combat/PlayerCombat.gd:218`<br>`scenes/combat/PlayerCombat.gd:279`<br>`scenes/combat/PlayerCombat.gd:309` | `scenes/combat/CombatScene.gd:3232` | `scenes/combat/CombatScene.gd:392` | HIGH | lane: int |
| `ui_shake` | `autoloads/EventBus.gd:139` | `scenes/ui/CombatPerformanceHUD.gd:438`<br>`systems/CombatHUDPresenter.gd:180`<br>`systems/CombatPresentationRuntime.gd:563` | `scenes/combat/CombatScene.gd:3220` | `scenes/combat/CombatScene.gd:396` | HIGH | intensity: float, duration: float |
| `ultimate_available` | `autoloads/EventBus.gd:67` | `systems/CombatMeter.gd:248` | `scenes/combat/CombatScene.gd:3209`<br>`scenes/ui/CombatPerformanceHUD.gd:81` | `scenes/combat/CombatScene.gd:374` | HIGH |  |
| `ultimate_fired` | `autoloads/EventBus.gd:69` | `systems/CombatMeter.gd:88` | `examples/demo_encounter_stack/MutationTracker.gd:35`<br>`scenes/combat/CombatScene.gd:3210`<br>`scenes/ui/CombatPerformanceHUD.gd:82`<br>`systems/PerformanceRewardDirector.gd:418`<br>`systems/RunGrowth.gd:63`<br>`systems/RunStats.gd:43` | `scenes/combat/CombatScene.gd:376`<br>`systems/PerformanceRewardDirector.gd:443`<br>`systems/RunStats.gd:64` | HIGH | power: float |
| `ultimate_power_granted` | `autoloads/EventBus.gd:71` | `systems/RunGrowth.gd:282` | `scenes/combat/CombatScene.gd:3216` | — | HIGH | amount: float |
| `vessel_shifted` | `autoloads/EventBus.gd:85` | `systems/VesselModifierDirector.gd:82` | `scenes/combat/CombatScene.gd:3124` | — | HIGH | class_data: Dictionary |
| `world_fate_changed` | `autoloads/EventBus.gd:119` | `autoloads/GameState.gd:773` | — | — | MEDIUM | snapshot: Dictionary |
| `world_fate_shifted` | `autoloads/EventBus.gd:105` | `autoloads/GameState.gd:863` | `systems/QuigNarrativeSystem.gd:29` | — | HIGH | new_fate_id: String, old_fate_id: String |

## Non-EventBus Signal References

Signal declarations found outside the EventBus autoload.

| Signal | File | Line | Params |
|---|---|---|---|
| `accent_fired` | `systems/SongConductor.gd` | 8 | () |
| `beat_pulse` | `systems/SongConductor.gd` | 6 | (beat_index: int, quality: String, intensity: float, song_time: float) |
| `choice_resolved` | `systems/VictoryRewardDirector.gd` | 11 | (choice_id: String, creature_data: Dictionary) |
| `combo_achieved` | `systems/MutationSynergySystem.gd` | 8 | (combo_data: Dictionary) |
| `continue_requested` | `scenes/ui/RunSpineScene.gd` | 5 | (advance_to_boss: bool) |
| `demo_completed` | `examples/NewSystemsDemo.gd` | 6 | (results: Dictionary) |
| `drop_scheduled` | `systems/CombatRunDirector.gd` | 18 | (target_time: float) |
| `ecology_state_changed` | `systems/EncounterEscalationDirector.gd` | 14 | (snapshot) |
| `encounter_generated` | `examples/demo_encounter_stack/CombatSystemIntegration.gd` | 7 | (encounter_data: Dictionary) |
| `encounter_generated` | `examples/demo_encounter_stack/EncounterGenerator.gd` | 10 | (encounter_data: Dictionary) |
| `enemy_contact` | `scenes/combat/MeleeApproach.gd` | 10 | (melee) |
| `enemy_contact` | `scenes/combat/Projectile.gd` | 8 | (projectile) |
| `event_completed` | `scenes/ui/EventScene.gd` | 3 | (outcome_payload: Dictionary) |
| `feedback_requested` | `systems/EncounterEscalationDirector.gd` | 13 | (text, color, duration) |
| `feedback_requested` | `systems/SupportEffectResolver.gd` | 10 | (text, color, duration) |
| `final_movement_reached` | `systems/SongConductor.gd` | 7 | () |
| `flash_requested` | `systems/SupportEffectResolver.gd` | 11 | (color, duration) |
| `growth_choice_selected` | `scenes/ui/GrowthChoiceIntersection.gd` | 3 | (choice_id: String) |
| `heal_requested` | `systems/SupportEffectResolver.gd` | 13 | (amount) |
| `highlight_ring_requested` | `systems/SupportEffectResolver.gd` | 16 | (lane, color, duration) |
| `impact_fx_requested` | `scenes/combat/CombatScene.gd` | 3 | (kind: StringName, world_pos: Vector2, direction: Vector2, scale_mult: float) |
| `integration_complete` | `examples/demo_encounter_stack/CombatSystemIntegration.gd` | 9 | () |
| `intervention_requested` | `systems/SupportEffectResolver.gd` | 12 | (species_id, lane, tint) |
| `level_completed` | `systems/CombatRunDirector.gd` | 16 | (level_index: int) |
| `level_started` | `systems/CombatRunDirector.gd` | 15 | (level_index: int, level_data: Dictionary) |
| `management_action_requested` | `scenes/ui/RunSpineScene.gd` | 7 | (action_id: String, payload: Dictionary) |
| `mutation_activated` | `examples/demo_encounter_stack/MutationTracker.gd` | 7 | (mutation_data: Dictionary) |
| `mutation_charge_consumed` | `examples/demo_encounter_stack/MutationTracker.gd` | 8 | (mutation_id: String, charges_remaining: int) |
| `mutation_depleted` | `examples/demo_encounter_stack/MutationTracker.gd` | 9 | (mutation_id: String) |
| `mutation_evolution` | `systems/MutationSynergySystem.gd` | 9 | (evolution_data: Dictionary) |
| `mutation_feedback_requested` | `examples/demo_encounter_stack/MutationTracker.gd` | 11 | (text: String, color: Color) |
| `mutation_synergy_detected` | `examples/demo_encounter_stack/MutationTracker.gd` | 10 | (synergy_data: Dictionary) |
| `mutation_system_ready` | `examples/demo_encounter_stack/CombatSystemIntegration.gd` | 8 | (tracker: Node) |
| `offer_ended` | `systems/PerformanceRewardDirector.gd` | 70 | () |
| `offer_ended` | `systems/VictoryRewardDirector.gd` | 10 | () |
| `offer_started` | `systems/PerformanceRewardDirector.gd` | 69 | (reward_data: Dictionary) |
| `offer_started` | `systems/VictoryRewardDirector.gd` | 9 | (creature_data: Dictionary, is_live: bool, is_dna_locked: bool, timer: float) |
| `path_node_selected` | `scenes/ui/RunSpineScene.gd` | 6 | (node_id: String) |
| `phase_changed` | `systems/EncounterEscalationDirector.gd` | 11 | (index, phase_data) |
| `player_contact` | `scenes/combat/MeleeApproach.gd` | 8 | (melee) |
| `player_contact` | `scenes/combat/Projectile.gd` | 7 | (projectile) |
| `predation_selected` | `scenes/ui/RunSpineScene.gd` | 4 | (index: int) |
| `pressure_bias_changed` | `systems/PerformanceRewardDirector.gd` | 73 | (snapshot: Dictionary) |
| `proc_feedback` | `systems/PerformanceRewardDirector.gd` | 72 | (text: String, color: Color) |
| `queue_updated` | `systems/VictoryRewardDirector.gd` | 12 | (size: int) |
| `reached_hit_zone` | `scenes/combat/MeleeApproach.gd` | 7 | (melee) |
| `reached_hit_zone` | `scenes/combat/Projectile.gd` | 6 | (projectile) |
| `resolved` | `scenes/combat/MeleeApproach.gd` | 11 | (melee, result: String) |
| `resolved` | `scenes/combat/Projectile.gd` | 9 | (projectile, result: String) |
| `reward_claimed` | `systems/PerformanceRewardDirector.gd` | 71 | (reward_data: Dictionary, source: String) |
| `run_completed` | `systems/CombatRunDirector.gd` | 19 | (success: bool) |
| `run_started` | `systems/CombatRunDirector.gd` | 14 | (run_number: int) |
| `score_changed` | `systems/RunStats.gd` | 18 | (score: int) |
| `section_changed` | `systems/SongConductor.gd` | 5 | (section_id: String, data: Dictionary) |
| `song_started` | `systems/SongConductor.gd` | 3 | (song_state: Dictionary) |
| `spawn_requested` | `systems/EncounterEscalationDirector.gd` | 12 | (lane, enemy_data) |
| `stamina_requested` | `systems/SupportEffectResolver.gd` | 14 | (amount) |
| `state_changed` | `systems/PerformanceRewardDirector.gd` | 68 | () |
| `support_charge_requested` | `systems/SupportEffectResolver.gd` | 15 | (amount) |
| `synergy_activated` | `systems/MutationSynergySystem.gd` | 6 | (synergy_data: Dictionary) |
| `synergy_deactivated` | `systems/MutationSynergySystem.gd` | 7 | (synergy_id: String) |
| `transport_state_changed` | `systems/SongConductor.gd` | 4 | (is_running: bool, song_time: float) |
| `upgrade_selected` | `scenes/ui/RunSpineScene.gd` | 3 | (index: int) |
| `void_entered` | `systems/CombatRunDirector.gd` | 17 | () |

## Fragile Signal Contracts

- **`bonded_support_triggered`** — 4 consumers (high fan-out). Changes affect many systems.
- **`boss_outcome_resolved`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`capture_offered`** — 3 emitter(s), no consumers found. Signal may go unheard.
- **`combat_ended`** — 4 consumers (high fan-out). Changes affect many systems.
- **`combat_started`** — 5 consumers (high fan-out). Changes affect many systems.
- **`combo_changed`** — 4 consumers (high fan-out). Changes affect many systems.
- **`creature_bonded`** — 6 consumers (high fan-out). Changes affect many systems.
- **`creature_eaten`** — 7 consumers (high fan-out). Changes affect many systems.
- **`enemy_defeated`** — 5 consumers (high fan-out). Changes affect many systems.
- **`player_died`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`player_dodged`** — 4 consumers (high fan-out). Changes affect many systems.
- **`player_parried`** — 7 consumers (high fan-out). Changes affect many systems.
- **`player_took_damage`** — 5 consumers (high fan-out). Changes affect many systems.
- **`projectile_missed`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`run_completed`** — 2 emitter(s), no consumers found. Signal may go unheard.
- **`song_beat_pulse`** — 4 consumers (high fan-out). Changes affect many systems.
- **`timed_attack_resolved`** — 7 consumers (high fan-out). Changes affect many systems.
- **`ultimate_fired`** — 6 consumers (high fan-out). Changes affect many systems.
- **`world_fate_changed`** — 1 emitter(s), no consumers found. Signal may go unheard.

## Curated Notes

<!-- CURATED NOTES START -->
<!-- Add human/agent notes here. Do not remove generated warning above. -->

### MEDIUM-confidence EventBus contracts

- `player_died`
  - Current scan: emitter detected at `scenes/combat/PlayerCombat.gd:984`; no consumers or disconnect references detected.
  - Interpretation: likely fire-and-forget lifecycle telemetry at present because `combat_ended` carries the active victory/defeat flow immediately after death. No `.tscn` connections are inspected by this auditor, so scene-connected listeners are unverified.
  - Contract safety: name/payload changes are caution-level. It has no payload, but the death event is semantically core and may be used by future or scene-wired failure UI.

- `capture_offered`
  - Current scan: emitters detected at `scenes/combat/CombatScene.gd:810`, `:824`, and `:3553`; no consumers or disconnect references detected.
  - Interpretation: appears fire-and-forget/future-facing around reward offer moments. Existing reward handling may be local or scene-driven, and static scan cannot prove whether `.tscn` wiring listens to it.
  - Contract safety: high risk. The `creature_data: Dictionary` payload is tied to bond/eat reward flow and DNA meaning, so changing name or payload can break capture/reward integrations even if this scan shows no consumers.

- `boss_outcome_resolved`
  - Current scan: emitter detected at `autoloads/GameState.gd:747`; no consumers or disconnect references detected.
  - Interpretation: future-facing world-state event emitted from GameState boss resolution. It may be intended for narrative, run summary, or external agent/audit listeners; no static consumer is currently present.
  - Contract safety: caution-level. The `outcome_id: String, payload: Dictionary` shape is broad, but downstream world-fate and reporting work may depend on stable keys once consumers are added.

- `run_completed`
  - Current scan: EventBus emitters detected at `scenes/combat/CombatScene.gd:4994` and `systems/CombatRunDirector.gd:154`; no EventBus consumers or disconnect references detected.
  - Interpretation: future-facing/fire-and-forget run lifecycle signal. A local non-EventBus `run_completed(success: bool)` signal also exists in `CombatRunDirector`, so current run flow may be handled locally while EventBus remains available for broader observers.
  - Contract safety: caution-level. The `success: bool` payload is small but semantically central to run completion, score closure, and post-run routing.

- `world_fate_changed`
  - Current scan: emitter detected at `autoloads/GameState.gd:773`; no consumers or disconnect references detected.
  - Interpretation: future-facing snapshot broadcast from GameState. Current live flow also has `world_fate_shifted` with a detected narrative consumer, so this Dictionary snapshot appears reserved for richer world-state observers.
  - Contract safety: caution-level to high risk. The signal carries `snapshot: Dictionary`; renaming or changing snapshot shape should wait for a documented world-fate contract.

- `combat_input_resolved`
  - Previously flagged as scanner-missed (multiline emit). As of the 16:32 scan the emitter is detected at `scenes/combat/PlayerCombat.gd:358` and confidence is now HIGH — the multiline emit scanner fix is working.
  - Contract safety: high risk. Payload order and meaning drive combat response clarity in `CombatScene`; keep name and payload stable.
<!-- CURATED NOTES END -->
