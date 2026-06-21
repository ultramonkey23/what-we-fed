# SIGNAL MAP

## Purpose
Generated signal-flow reference for AI agents.

## Warning
This is a static scan, not runtime proof.
Dynamic signal names or indirect connections may be missed.
When editing signal contracts, verify against source code and validation.

## Summary
- **Generated:** 2026-06-21T06:22:25Z
- **Scan root:** `C:\Users\harin\gamesdevs\What We Fed\what-we-fed`
- **Files scanned:** 130
- **Signals declared (EventBus):** 72
- **Emitters found:** 218
- **Consumers / connects found:** 138
- **Disconnect references found:** 101

## EventBus Signals

| Signal | Declared In | Emitters | Consumers / Connects | Disconnect References | Confidence | Notes |
|---|---|---|---|---|---|---|
| `attack_timing_early_resolved` | `autoloads/EventBus.gd:33` | `scenes/combat/PlayerCombat.gd:1373` | `scenes/combat/CombatScene.gd:1616` | `scenes/combat/CombatScene.gd:305` | HIGH | sector: int |
| `bonded_support_triggered` | `autoloads/EventBus.gd:137` | `systems/RunGrowth.gd:383` | `scenes/combat/CombatScene.gd:1634`<br>`systems/PerformanceRewardDirector.gd:421`<br>`systems/RunStats.gd:69` | `scenes/combat/CombatScene.gd:331`<br>`systems/PerformanceRewardDirector.gd:446`<br>`systems/RunStats.gd:98` | HIGH | species_id: String, sector: int, effect_id: String |
| `boss_outcome_resolved` | `autoloads/EventBus.gd:15` | `autoloads/GameState.gd:944` | `systems/AchievementDirector.gd:17` | — | HIGH | victory: bool, data: Dictionary |
| `boss_phase_transitioned` | `autoloads/EventBus.gd:17` | — | — | — | LOW | phase_index: int |
| `capture_offered` | `autoloads/EventBus.gd:113` | `scenes/combat/CombatScene.gd:722`<br>`scenes/combat/CombatScene.gd:733`<br>`scenes/combat/CombatScene.gd:2040` | — | — | MEDIUM | creature_data: Dictionary |
| `combat_ended` | `autoloads/EventBus.gd:7` | `scenes/combat/PlayerCombat.gd:1528`<br>`systems/CombatLifecycleDirector.gd:34` | `autoloads/GameState.gd:122`<br>`scenes/combat/CombatScene.gd:1602`<br>`systems/PerformanceRewardDirector.gd:411`<br>`systems/QuigNarrativeSystem.gd:34` | `scenes/combat/CombatScene.gd:262` | HIGH | victory: bool |
| `combat_input_resolved` | `autoloads/EventBus.gd:29` | `scenes/combat/PlayerCombat.gd:395` | `autoloads/DevHarness.gd:35`<br>`scenes/combat/CombatScene.gd:1619` | `scenes/combat/CombatScene.gd:311` | HIGH | action: String, sector: int, accepted: bool, buffered: bool, reason: String, state: String, cooldowns: Dictionary |
| `combat_started` | `autoloads/EventBus.gd:5` | `scenes/combat/ZoneManager.gd:145` | `autoloads/GameState.gd:120`<br>`systems/CombatHUDPresenter.gd:185`<br>`systems/PerformanceRewardDirector.gd:409`<br>`systems/RunGrowth.gd:55`<br>`systems/RunStats.gd:57` | `systems/CombatHUDPresenter.gd:210`<br>`systems/PerformanceRewardDirector.gd:436`<br>`systems/RunGrowth.gd:80`<br>`systems/RunStats.gd:86` | HIGH | enemy_data: Array |
| `combo_broken` | `autoloads/EventBus.gd:71` | `systems/CombatMeter.gd:149`<br>`systems/CombatMeter.gd:195` | `scenes/combat/CombatScene.gd:1621`<br>`scenes/ui/CombatPerformanceHUD.gd:83` | `scenes/combat/CombatScene.gd:315` | HIGH | combo_count: int |
| `combo_changed` | `autoloads/EventBus.gd:69` | `systems/CombatMeter.gd:44`<br>`systems/CombatMeter.gd:278` | `scenes/combat/CombatScene.gd:1597`<br>`scenes/combat/PlayerCombat.gd:433`<br>`scenes/ui/CombatPerformanceHUD.gd:80` | `scenes/combat/CombatScene.gd:252`<br>`scenes/combat/PlayerCombat.gd:149` | HIGH | count: int, tier: String |
| `creature_ascended` | `autoloads/EventBus.gd:115` | `autoloads/GameState.gd:571` | `systems/QuigNarrativeSystem.gd:36` | — | HIGH | data: Dictionary |
| `creature_bonded` | `autoloads/EventBus.gd:109` | `scenes/ui/IntroBondChoiceScene.gd:73`<br>`systems/VictoryRewardDirector.gd:81` | `autoloads/GameState.gd:116`<br>`scenes/combat/CombatScene.gd:1632`<br>`systems/QuigNarrativeSystem.gd:28`<br>`systems/RunGrowth.gd:69`<br>`systems/RunStats.gd:75` | `autoloads/GameState.gd:127`<br>`scenes/combat/CombatScene.gd:327`<br>`systems/RunGrowth.gd:94`<br>`systems/RunStats.gd:104` | HIGH | creature_data: Dictionary |
| `creature_eaten` | `autoloads/EventBus.gd:111` | `systems/VictoryRewardDirector.gd:91` | `autoloads/GameState.gd:118`<br>`systems/PerformanceRewardDirector.gd:419`<br>`systems/QuigNarrativeSystem.gd:29`<br>`systems/RunGrowth.gd:71`<br>`systems/RunStats.gd:77` | `autoloads/GameState.gd:129`<br>`systems/PerformanceRewardDirector.gd:444`<br>`systems/RunGrowth.gd:96`<br>`systems/RunStats.gd:106` | HIGH | creature_data: Dictionary |
| `creature_exp_changed` | `autoloads/EventBus.gd:127` | `systems/state/CreatureState.gd:77` | — | — | MEDIUM | species_id: String, current_exp: float, exp_to_next: float |
| `creature_leveled_up` | `autoloads/EventBus.gd:129` | `systems/state/CreatureState.gd:79` | — | — | MEDIUM | species_id: String, new_level: int |
| `dna_gained` | `autoloads/EventBus.gd:131` | `scenes/combat/CombatScene.gd:4244` | `scenes/combat/CombatScene.gd:1635`<br>`systems/RunStats.gd:79` | `scenes/combat/CombatScene.gd:333`<br>`systems/RunStats.gd:108` | HIGH | species_id: String, amount: float, total: float |
| `dna_lock_denied` | `autoloads/EventBus.gd:141` | `systems/VictoryRewardDirector.gd:68` | `scenes/combat/CombatScene.gd:1606` | `scenes/combat/CombatScene.gd:268` | HIGH | species_id: String, current: float, required: float |
| `dna_resonated` | `autoloads/EventBus.gd:93` | `scenes/combat/CombatScene.gd:3921`<br>`scenes/combat/CombatScene.gd:4258`<br>`scenes/combat/CombatScene.gd:4268`<br>`scenes/combat/CombatScene.gd:4818` | `scenes/combat/CombatScene.gd:1613` | `scenes/combat/CombatScene.gd:291` | HIGH | species_id: String, amount: float |
| `dna_routing_changed` | `autoloads/EventBus.gd:133` | `systems/RunGrowth.gd:566` | `scenes/combat/CombatScene.gd:1633` | `scenes/combat/CombatScene.gd:329` | HIGH | route_id: String, label: String |
| `enemy_attack_telegraph_cancelled` | `autoloads/EventBus.gd:65` | `scenes/combat/PlayerCombat.gd:231`<br>`systems/CombatFireDirector.gd:149` | `scenes/combat/CombatScene.gd:1627` | `scenes/combat/CombatScene.gd:297` | HIGH | enemy_id: int |
| `enemy_attack_telegraphed` | `autoloads/EventBus.gd:63` | `scenes/combat/ZoneManager.gd:267` | `scenes/combat/CombatScene.gd:1626` | `scenes/combat/CombatScene.gd:295` | HIGH | enemy_id: int, sector: int, world_pos: Vector2, windup: float |
| `enemy_bleed_changed` | `autoloads/EventBus.gd:59` | `systems/StatusDirector.gd:60` | — | — | MEDIUM | enemy_id: int, stacks: int, max_stacks: int |
| `enemy_damaged` | `autoloads/EventBus.gd:49` | `scenes/combat/ZoneManager.gd:396` | `scenes/combat/CombatScene.gd:1603`<br>`systems/RunStats.gd:61` | `scenes/combat/CombatScene.gd:264`<br>`systems/RunStats.gd:90` | HIGH | enemy_id: int, damage: float |
| `enemy_defeated` | `autoloads/EventBus.gd:51` | `systems/CombatLifecycleDirector.gd:21` | `scenes/combat/CombatScene.gd:1604`<br>`scenes/combat/CombatScene.gd:1605`<br>`systems/PerformanceRewardDirector.gd:399`<br>`systems/RunGrowth.gd:57`<br>`systems/RunStats.gd:59` | `scenes/combat/CombatScene.gd:266`<br>`systems/PerformanceRewardDirector.gd:426`<br>`systems/RunGrowth.gd:82`<br>`systems/RunStats.gd:88` | HIGH | enemy_id: int |
| `enemy_ruptured` | `autoloads/EventBus.gd:61` | `systems/SupportEffectResolver.gd:72`<br>`systems/VesselModifierDirector.gd:187` | — | — | MEDIUM | enemy_id: int, total_damage: float |
| `enemy_status_applied` | `autoloads/EventBus.gd:53` | `systems/StatusDirector.gd:65`<br>`systems/StatusDirector.gd:100` | `scenes/combat/CombatScene.gd:1638` | `scenes/combat/CombatScene.gd:337` | HIGH | enemy_id: int, status_id: String, params: Dictionary |
| `enemy_status_applied_requested` | `autoloads/EventBus.gd:57` | — | `scenes/combat/CombatScene.gd:1609` | `scenes/combat/CombatScene.gd:275` | MEDIUM | enemy_id: int, status_id: String, params: Dictionary |
| `enemy_status_cleared` | `autoloads/EventBus.gd:55` | `systems/StatusDirector.gd:71`<br>`systems/StatusDirector.gd:79`<br>`systems/StatusDirector.gd:90`<br>`systems/StatusDirector.gd:101`<br>`systems/StatusDirector.gd:104`<br>`systems/StatusDirector.gd:115`<br>…+2 | `scenes/combat/CombatScene.gd:1639` | `scenes/combat/CombatScene.gd:339` | HIGH | enemy_id: int |
| `impact_burst_requested` | `autoloads/EventBus.gd:101` | `scenes/combat/PlayerCombat.gd:1254` | `scenes/combat/CombatScene.gd:1637` | — | HIGH | profile: Dictionary, sector: int, enemy_id: int |
| `limit_breaker_triggered` | `autoloads/EventBus.gd:107` | `autoloads/GameState.gd:49` | — | — | MEDIUM | achievement_id: String |
| `mastery_context_updated` | `autoloads/EventBus.gd:145` | `scenes/combat/PlayerCombat.gd:601`<br>`scenes/combat/PlayerCombat.gd:613` | `scenes/combat/CombatScene.gd:1636` | `scenes/combat/CombatScene.gd:335` | HIGH | mastery_data: Dictionary |
| `phrase_milestone` | `autoloads/EventBus.gd:73` | `systems/CombatMeter.gd:223`<br>`systems/CombatMeter.gd:226` | `scenes/combat/CombatScene.gd:1640`<br>`systems/PerformanceRewardDirector.gd:413`<br>`systems/RunGrowth.gd:59` | `scenes/combat/CombatScene.gd:341`<br>`systems/PerformanceRewardDirector.gd:438`<br>`systems/RunGrowth.gd:84` | HIGH | count: int |
| `play_sfx` | `autoloads/EventBus.gd:87` | `scenes/combat/BondedCompanion.gd:158`<br>`scenes/combat/CombatScene.gd:3853`<br>`scenes/combat/CombatScene.gd:4806`<br>`scenes/combat/PlayerCombat.gd:1449`<br>`systems/CombatPresentationRuntime.gd:661`<br>`systems/VesselModifierDirector.gd:157`<br>…+2 | `systems/CombatAudioPlayer.gd:10` | `systems/CombatAudioPlayer.gd:15` | HIGH | sfx_id: String |
| `player_attacked` | `autoloads/EventBus.gd:21` | `scenes/combat/PlayerCombat.gd:1258`<br>`scenes/combat/PlayerCombat.gd:1344`<br>`scenes/combat/PlayerCombat.gd:1420`<br>`scenes/combat/PlayerCombat.gd:1458` | `scenes/combat/CombatScene.gd:1614`<br>`systems/CombatHUDPresenter.gd:189` | `scenes/combat/CombatScene.gd:301`<br>`systems/CombatHUDPresenter.gd:214` | HIGH | sector: int, damage: float, was_timed: bool, heading: Vector2 |
| `player_bleed_changed` | `autoloads/EventBus.gd:45` | `autoloads/GameState.gd:393`<br>`autoloads/GameState.gd:398` | `systems/CombatHUDPresenter.gd:199` | `systems/CombatHUDPresenter.gd:224` | HIGH | stacks: int, max_stacks: int |
| `player_died` | `autoloads/EventBus.gd:39` | `scenes/combat/PlayerCombat.gd:1527` | `systems/CombatRunDirector.gd:75` | — | HIGH |  |
| `player_dodged` | `autoloads/EventBus.gd:25` | `scenes/combat/PlayerCombat.gd:1109` | `scenes/combat/CombatScene.gd:1618`<br>`systems/PerformanceRewardDirector.gd:407`<br>`systems/TutorialDirector.gd:27`<br>`systems/VesselModifierDirector.gd:86` | `scenes/combat/CombatScene.gd:309`<br>`systems/PerformanceRewardDirector.gd:434`<br>`systems/TutorialDirector.gd:68` | HIGH | from_sector: int, to_sector: int, heading: Vector2 |
| `player_healed` | `autoloads/EventBus.gd:41` | `scenes/combat/CombatScene.gd:443`<br>`scenes/combat/CombatScene.gd:4191`<br>`scenes/combat/CombatScene.gd:5216`<br>`scenes/combat/PlayerCombat.gd:1239`<br>`scenes/combat/PlayerCombat.gd:1508`<br>`systems/PerformanceRewardDirector.gd:1059`<br>…+8 | `scenes/combat/CombatScene.gd:1599`<br>`systems/CombatHUDPresenter.gd:195` | `scenes/combat/CombatScene.gd:256`<br>`systems/CombatHUDPresenter.gd:220` | HIGH | amount: float |
| `player_no_stamina` | `autoloads/EventBus.gd:43` | `scenes/combat/PlayerCombat.gd:383`<br>`scenes/combat/PlayerCombat.gd:992`<br>`systems/CombatMeter.gd:79`<br>`systems/CombatMeter.gd:90` | `scenes/combat/CombatScene.gd:1620` | `scenes/combat/CombatScene.gd:313` | HIGH |  |
| `player_parried` | `autoloads/EventBus.gd:23` | `scenes/combat/PlayerCombat.gd:1068` | `autoloads/CombatFeedbackDirector.gd:29`<br>`scenes/combat/CombatScene.gd:1617`<br>`systems/PerformanceRewardDirector.gd:403`<br>`systems/QuigNarrativeSystem.gd:26`<br>`systems/RunGrowth.gd:63`<br>`systems/RunStats.gd:65`<br>…+2 | `scenes/combat/CombatScene.gd:307`<br>`systems/PerformanceRewardDirector.gd:430`<br>`systems/RunGrowth.gd:88`<br>`systems/RunStats.gd:94`<br>`systems/TutorialDirector.gd:66` | HIGH | sector: int, quality: String, reflect_damage: float, heading: Vector2 |
| `player_teleported` | `autoloads/EventBus.gd:27` | — | `scenes/combat/CombatScene.gd:1622`<br>`systems/CombatHUDPresenter.gd:187` | `scenes/combat/CombatScene.gd:317`<br>`systems/CombatHUDPresenter.gd:212` | MEDIUM | from_sector: int, to_sector: int |
| `player_took_damage` | `autoloads/EventBus.gd:37` | `scenes/combat/PlayerCombat.gd:1524` | `autoloads/CombatFeedbackDirector.gd:27`<br>`scenes/combat/BondedCompanion.gd:32`<br>`scenes/combat/CombatScene.gd:1598`<br>`systems/CombatHUDPresenter.gd:197`<br>`systems/PerformanceRewardDirector.gd:405`<br>`systems/QuigNarrativeSystem.gd:30`<br>…+3 | `scenes/combat/BondedCompanion.gd:37`<br>`scenes/combat/CombatScene.gd:254`<br>`systems/CombatHUDPresenter.gd:222`<br>`systems/PerformanceRewardDirector.gd:432`<br>`systems/RunGrowth.gd:92`<br>`systems/RunStats.gd:102`<br>…+1 | HIGH | amount: float, source_sector: int |
| `proc_feedback_requested` | `autoloads/EventBus.gd:99` | `autoloads/GameState.gd:48`<br>`autoloads/GameState.gd:421`<br>`autoloads/GameState.gd:743`<br>`autoloads/GameState.gd:840`<br>`scenes/combat/PlayerCombat.gd:219`<br>`scenes/combat/PlayerCombat.gd:223`<br>…+24 | `scenes/combat/CombatScene.gd:1607` | `scenes/combat/CombatScene.gd:272` | HIGH | text: String, color: Color |
| `projectile_fired` | `autoloads/EventBus.gd:95` | `scenes/combat/ZoneManager.gd:605`<br>`scenes/combat/ZoneManager.gd:670` | `scenes/combat/CombatScene.gd:1625`<br>`scenes/combat/PlayerCombat.gd:430`<br>`systems/TutorialDirector.gd:23` | `scenes/combat/CombatScene.gd:293`<br>`scenes/combat/PlayerCombat.gd:147`<br>`systems/TutorialDirector.gd:64` | HIGH | sector: int, enemy_id: int |
| `projectile_missed` | `autoloads/EventBus.gd:97` | `scenes/combat/ZoneManager.gd:756` | — | — | MEDIUM | sector: int, damage: float |
| `quig_narrative_triggered` | `autoloads/EventBus.gd:147` | `systems/QuigNarrativeSystem.gd:107`<br>`systems/QuigNarrativeSystem.gd:120` | `scenes/combat/CombatScene.gd:1642` | `scenes/combat/CombatScene.gd:345` | HIGH | text: String, duration: float |
| `run_completed` | `autoloads/EventBus.gd:105` | `scenes/combat/CombatScene.gd:3484`<br>`systems/CombatRunDirector.gd:153` | `systems/AchievementDirector.gd:16` | — | HIGH | victory: bool |
| `run_growth_changed` | `autoloads/EventBus.gd:121` | `systems/RunGrowth.gd:558` | `scenes/combat/CombatScene.gd:1628`<br>`scenes/ui/CombatPerformanceHUD.gd:84` | `scenes/combat/CombatScene.gd:319` | HIGH | level: int, current_exp: float, exp_to_next: float |
| `run_growth_level_resolved` | `autoloads/EventBus.gd:123` | `systems/RunGrowth.gd:433` | `scenes/combat/CombatScene.gd:1629`<br>`scenes/ui/CombatPerformanceHUD.gd:85` | `scenes/combat/CombatScene.gd:321` | HIGH | result: Dictionary |
| `run_started` | `autoloads/EventBus.gd:9` | `autoloads/GameState.gd:81`<br>`systems/CombatRunDirector.gd:72` | `systems/AchievementDirector.gd:15`<br>`systems/RunGrowth.gd:53`<br>`systems/RunStats.gd:55` | `systems/RunGrowth.gd:78`<br>`systems/RunStats.gd:84` | HIGH | run_number: int |
| `screen_flash` | `autoloads/EventBus.gd:79` | `autoloads/CombatFeedbackDirector.gd:42`<br>`autoloads/CombatFeedbackDirector.gd:45`<br>`autoloads/CombatFeedbackDirector.gd:52`<br>`autoloads/CombatFeedbackDirector.gd:60`<br>`autoloads/CombatFeedbackDirector.gd:63`<br>`autoloads/CombatFeedbackDirector.gd:68`<br>…+44 | `scenes/combat/CombatScene.gd:1610` | `scenes/combat/CombatScene.gd:281` | HIGH | color: Color, duration: float |
| `screen_shake` | `autoloads/EventBus.gd:81` | `autoloads/CombatFeedbackDirector.gd:71`<br>`scenes/combat/CombatScene.gd:2605`<br>`scenes/combat/CombatScene.gd:3314`<br>`scenes/combat/CombatScene.gd:3546`<br>`scenes/combat/CombatScene.gd:3600`<br>`scenes/combat/CombatScene.gd:3608`<br>…+5 | `scenes/combat/CombatScene.gd:1611` | `scenes/combat/CombatScene.gd:283` | HIGH | intensity: float, duration: float |
| `slow_motion` | `autoloads/EventBus.gd:85` | `autoloads/CombatFeedbackDirector.gd:75`<br>`scenes/combat/CombatScene.gd:4805`<br>`scenes/combat/PlayerCombat.gd:597` | `systems/TimeDistortionDirector.gd:28` | `systems/TimeDistortionDirector.gd:84` | HIGH | scale: float, duration: float |
| `song_beat_pulse` | `autoloads/EventBus.gd:91` | `scenes/combat/CombatScene.gd:1073`<br>`systems/SongConductor.gd:336` | `autoloads/DevHarness.gd:37`<br>`scenes/combat/CombatScene.gd:1624`<br>`scenes/combat/PlayerCombat.gd:436`<br>`scenes/combat/ZoneManager.gd:143`<br>`scenes/ui/CombatPerformanceHUD.gd:86` | `scenes/combat/CombatScene.gd:287`<br>`scenes/combat/PlayerCombat.gd:151` | HIGH | beat_index: int, intensity: float, quality: String |
| `sovereign_reached` | `autoloads/EventBus.gd:13` | `systems/CombatMeter.gd:286` | `systems/QuigNarrativeSystem.gd:32` | — | HIGH |  |
| `sovereign_threshold_reached` | `autoloads/EventBus.gd:11` | `scenes/combat/CombatScene.gd:4026` | `systems/QuigNarrativeSystem.gd:33` | — | HIGH | ratio: float |
| `stamina_changed` | `autoloads/EventBus.gd:151` | `systems/CombatMeter.gd:66` | `systems/CombatHUDPresenter.gd:191` | `systems/CombatHUDPresenter.gd:216` | HIGH | current: float, maximum: float |
| `style_changed` | `autoloads/EventBus.gd:153` | `systems/CombatMeter.gd:45`<br>`systems/CombatMeter.gd:283` | `systems/CombatHUDPresenter.gd:193` | `systems/CombatHUDPresenter.gd:218` | HIGH | score: float, tier: String |
| `support_charge_changed` | `autoloads/EventBus.gd:135` | `systems/RunGrowth.gd:562` | `scenes/combat/CombatScene.gd:1631` | `scenes/combat/CombatScene.gd:325` | HIGH | current: float, maximum: float, active_species_id: String |
| `support_manual_activation_requested` | `autoloads/EventBus.gd:139` | `scenes/combat/PlayerCombat.gd:1124` | `systems/RunGrowth.gd:73` | `systems/RunGrowth.gd:98` | HIGH | sector: int, quality: String |
| `tempo_state_entered` | `autoloads/EventBus.gd:149` | `systems/CombatRunDirector.gd:130`<br>`systems/SongConductor.gd:315` | `systems/QuigNarrativeSystem.gd:25` | — | HIGH | state_id: String |
| `tendency_growth_resolved` | `autoloads/EventBus.gd:125` | `systems/RunGrowth.gd:434` | `scenes/combat/CombatScene.gd:1630`<br>`systems/RunStats.gd:71` | `scenes/combat/CombatScene.gd:323`<br>`systems/RunStats.gd:100` | HIGH | tendency_id: String, title: String, summary: String |
| `tier_changed` | `autoloads/EventBus.gd:75` | `systems/CombatMeter.gd:273` | `scenes/combat/CombatScene.gd:1641`<br>`systems/PerformanceRewardDirector.gd:415` | `scenes/combat/CombatScene.gd:343`<br>`systems/PerformanceRewardDirector.gd:440` | HIGH | new_tier: String, old_tier: String |
| `timed_attack_resolved` | `autoloads/EventBus.gd:31` | `scenes/combat/PlayerCombat.gd:1345` | `autoloads/CombatFeedbackDirector.gd:25`<br>`scenes/combat/CombatScene.gd:1615`<br>`systems/EncounterEscalationDirector.gd:83`<br>`systems/PerformanceRewardDirector.gd:401`<br>`systems/QuigNarrativeSystem.gd:27`<br>`systems/RunGrowth.gd:61`<br>…+2 | `scenes/combat/CombatScene.gd:303`<br>`systems/EncounterEscalationDirector.gd:89`<br>`systems/PerformanceRewardDirector.gd:428`<br>`systems/RunGrowth.gd:86`<br>`systems/RunStats.gd:92` | HIGH | sector: int, quality: String, damage: float, enemy_id: int |
| `timing_ring_pressed` | `autoloads/EventBus.gd:89` | `scenes/combat/PlayerCombat.gd:285`<br>`scenes/combat/PlayerCombat.gd:321`<br>`scenes/combat/PlayerCombat.gd:355` | `scenes/combat/CombatScene.gd:1623` | `scenes/combat/CombatScene.gd:285` | HIGH | sector: int |
| `ui_shake` | `autoloads/EventBus.gd:83` | `scenes/combat/BondedCompanion.gd:159`<br>`scenes/ui/CombatPerformanceHUD.gd:442`<br>`systems/CombatHUDPresenter.gd:344`<br>`systems/CombatPresentationRuntime.gd:599` | `scenes/combat/CombatScene.gd:1612` | `scenes/combat/CombatScene.gd:289` | HIGH | intensity: float, duration: float |
| `ultimate_available` | `autoloads/EventBus.gd:155` | `systems/CombatMeter.gd:291` | `scenes/combat/CombatScene.gd:1600`<br>`scenes/ui/CombatPerformanceHUD.gd:81` | `scenes/combat/CombatScene.gd:258` | HIGH |  |
| `ultimate_fired` | `autoloads/EventBus.gd:157` | `systems/CombatMeter.gd:109` | `autoloads/CombatFeedbackDirector.gd:31`<br>`scenes/combat/CombatScene.gd:1601`<br>`scenes/ui/CombatPerformanceHUD.gd:82`<br>`systems/PerformanceRewardDirector.gd:417`<br>`systems/RunGrowth.gd:65`<br>`systems/RunStats.gd:67` | `scenes/combat/CombatScene.gd:260`<br>`systems/PerformanceRewardDirector.gd:442`<br>`systems/RunGrowth.gd:90`<br>`systems/RunStats.gd:96` | HIGH | power: float |
| `ultimate_power_granted` | `autoloads/EventBus.gd:159` | — | `scenes/combat/CombatScene.gd:1608` | `scenes/combat/CombatScene.gd:277` | MEDIUM | amount: float |
| `vessel_shifted` | `autoloads/EventBus.gd:143` | `systems/VesselModifierDirector.gd:99` | `scenes/combat/CombatScene.gd:1522` | `scenes/combat/CombatScene.gd:270` | HIGH | class_data: Dictionary |
| `world_fate_changed` | `autoloads/EventBus.gd:119` | `autoloads/GameState.gd:970` | — | — | MEDIUM | fate_snapshot: Dictionary |
| `world_fate_shifted` | `autoloads/EventBus.gd:117` | `autoloads/GameState.gd:1060` | `systems/QuigNarrativeSystem.gd:35` | — | HIGH | new_fate_id: String, old_fate_id: String |

## Non-EventBus Signal References

Signal declarations found outside the EventBus autoload.

| Signal | File | Line | Params |
|---|---|---|---|
| `accent_fired` | `systems/SongConductor.gd` | 9 | () |
| `beat_pulse` | `systems/SongConductor.gd` | 7 | (beat_index: int, quality: String, intensity: float, song_time: float) |
| `choice_resolved` | `systems/VictoryRewardDirector.gd` | 13 | (choice_id: String, creature_data: Dictionary) |
| `continue_requested` | `scenes/ui/RunSpineScene.gd` | 6 | (advance_to_boss: bool) |
| `drop_scheduled` | `systems/CombatRunDirector.gd` | 18 | (target_time: float) |
| `ecology_state_changed` | `systems/EncounterEscalationDirector.gd` | 14 | (snapshot) |
| `encounter_generated` | `examples/demo_encounter_stack/EncounterGenerator.gd` | 10 | (encounter_data: Dictionary) |
| `enemy_contact` | `scenes/combat/ThreatBase.gd` | 11 | (threat: ThreatBase) |
| `event_completed` | `scenes/ui/EventScene.gd` | 4 | (outcome_payload: Dictionary) |
| `feedback_requested` | `systems/EncounterEscalationDirector.gd` | 13 | (text, color, duration) |
| `feedback_requested` | `systems/SupportEffectResolver.gd` | 11 | (text, color, duration) |
| `final_movement_reached` | `systems/SongConductor.gd` | 8 | () |
| `flash_requested` | `systems/SupportEffectResolver.gd` | 12 | (color, duration) |
| `growth_choice_selected` | `scenes/ui/GrowthChoiceIntersection.gd` | 4 | (choice_id: String) |
| `heal_requested` | `systems/SupportEffectResolver.gd` | 14 | (amount) |
| `highlight_ring_requested` | `systems/SupportEffectResolver.gd` | 17 | (sector, color, duration) |
| `impact_fx_requested` | `scenes/combat/CombatScene.gd` | 3 | (kind: StringName, world_pos: Vector2, direction: Vector2, scale_mult: float) |
| `intervention_requested` | `systems/SupportEffectResolver.gd` | 13 | (species_id, sector, tint) |
| `level_completed` | `systems/CombatRunDirector.gd` | 16 | (level_index: int) |
| `level_started` | `systems/CombatRunDirector.gd` | 15 | (level_index: int, level_data: Dictionary) |
| `management_action_requested` | `scenes/ui/RunSpineScene.gd` | 8 | (action_id: String, payload: Dictionary) |
| `offer_ended` | `systems/PerformanceRewardDirector.gd` | 72 | () |
| `offer_ended` | `systems/VictoryRewardDirector.gd` | 12 | () |
| `offer_started` | `systems/PerformanceRewardDirector.gd` | 71 | (reward_data: Dictionary) |
| `offer_started` | `systems/VictoryRewardDirector.gd` | 11 | (creature_data: Dictionary, is_live: bool, is_dna_locked: bool, timer: float) |
| `path_node_selected` | `scenes/ui/RunSpineScene.gd` | 7 | (node_id: String) |
| `phase_changed` | `systems/EncounterEscalationDirector.gd` | 11 | (index, phase_data) |
| `player_contact` | `scenes/combat/ThreatBase.gd` | 9 | (threat: ThreatBase) |
| `predation_selected` | `scenes/ui/RunSpineScene.gd` | 5 | (index: int) |
| `pressure_bias_changed` | `systems/PerformanceRewardDirector.gd` | 75 | (snapshot: Dictionary) |
| `proc_feedback` | `systems/PerformanceRewardDirector.gd` | 74 | (text: String, color: Color) |
| `queue_updated` | `systems/VictoryRewardDirector.gd` | 14 | (size: int) |
| `reached_hit_zone` | `scenes/combat/ThreatBase.gd` | 8 | (threat: ThreatBase) |
| `resolved` | `scenes/combat/ThreatBase.gd` | 12 | (threat: ThreatBase, result: String) |
| `reward_claimed` | `systems/PerformanceRewardDirector.gd` | 73 | (reward_data: Dictionary, source: String) |
| `run_completed` | `systems/CombatRunDirector.gd` | 19 | (success: bool) |
| `run_started` | `systems/CombatRunDirector.gd` | 14 | (run_number: int) |
| `score_changed` | `systems/RunStats.gd` | 18 | (score: int) |
| `section_changed` | `systems/SongConductor.gd` | 6 | (section_id: String, data: Dictionary) |
| `song_started` | `systems/SongConductor.gd` | 4 | (song_state: Dictionary) |
| `spawn_requested` | `systems/EncounterEscalationDirector.gd` | 12 | (angle, enemy_data) |
| `stamina_requested` | `systems/SupportEffectResolver.gd` | 15 | (amount) |
| `state_changed` | `systems/PerformanceRewardDirector.gd` | 70 | () |
| `support_charge_requested` | `systems/SupportEffectResolver.gd` | 16 | (amount) |
| `transport_state_changed` | `systems/SongConductor.gd` | 5 | (is_running: bool, song_time: float) |
| `upgrade_selected` | `scenes/ui/RunSpineScene.gd` | 4 | (index: int) |
| `void_entered` | `systems/CombatRunDirector.gd` | 17 | () |

## Fragile Signal Contracts

- **`capture_offered`** — 3 emitter(s), no consumers found. Signal may go unheard.
- **`combat_ended`** — 4 consumers (high fan-out). Changes affect many systems.
- **`combat_started`** — 5 consumers (high fan-out). Changes affect many systems.
- **`creature_bonded`** — 5 consumers (high fan-out). Changes affect many systems.
- **`creature_eaten`** — 5 consumers (high fan-out). Changes affect many systems.
- **`creature_exp_changed`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`creature_leveled_up`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`enemy_bleed_changed`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`enemy_defeated`** — 5 consumers (high fan-out). Changes affect many systems.
- **`enemy_ruptured`** — 2 emitter(s), no consumers found. Signal may go unheard.
- **`enemy_status_applied_requested`** — 1 consumer(s), no emitters found. Consumer may never fire.
- **`limit_breaker_triggered`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`player_dodged`** — 4 consumers (high fan-out). Changes affect many systems.
- **`player_parried`** — 8 consumers (high fan-out). Changes affect many systems.
- **`player_teleported`** — 2 consumer(s), no emitters found. Consumer may never fire.
- **`player_took_damage`** — 9 consumers (high fan-out). Changes affect many systems.
- **`projectile_missed`** — 1 emitter(s), no consumers found. Signal may go unheard.
- **`song_beat_pulse`** — 5 consumers (high fan-out). Changes affect many systems.
- **`timed_attack_resolved`** — 8 consumers (high fan-out). Changes affect many systems.
- **`ultimate_fired`** — 6 consumers (high fan-out). Changes affect many systems.
- **`ultimate_power_granted`** — 1 consumer(s), no emitters found. Consumer may never fire.
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
