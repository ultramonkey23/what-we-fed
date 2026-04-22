# Song Combat Tuning Matrix V1

Phase: v2.0 The Pulse  
Date: 2026-04-22

## Scope
- Bounded tuning pass on active profile channels only.
- No new systems, no adaptive music engine, no bespoke per-track runtime branches.
- Targets: `tricky`, `newness`, `grind_the_orbit`, `boss_1`.

## Matrix
1. `tricky`
- Intent: baseline timing-honest default with light aggression.
- `cadence_law`: unchanged baseline cadence pacing (`1.00/1.00`, final cap `0.86`).
- `lane_law`: accent burst `1.03` (slightly restrained from prior).
- `pressure_law`: accent feedback `1.17` (reduced volatility).
- `progression_law`: combo-biased expression (`combo 0.40`) with standard beat weighting.
- `conductor_contract`: `drive` at chorus `>=0.61`, `surge` at final `>=0.84`, accent threshold `0.52`.

2. `newness`
- Intent: cleaner readability and less punitive pressure for growth curve support.
- `cadence_law`: slower pressure ramp (`cycle 0.99`, `stagger 1.05`, final cap `0.90`).
- `lane_law`: accent burst `0.94` (more readable lanes).
- `pressure_law`: accent feedback `1.08` (less spike-heavy).
- `reward_emphasis_law`: slower offer decay (`0.97`) and one extra level choice (`+1`).
- `progression_law`: phrase/beat expression weighted up (`phrase 0.33`, `beat 0.13`).
- `conductor_contract`: later cadence escalation (`drive >=0.68`, `surge >=0.88`), accent threshold `0.56`.

3. `grind_the_orbit`
- Intent: high-pressure lane control test without hidden unfairness.
- `cadence_law`: faster pressure and tighter final (`cycle 0.94`, `stagger 0.97`, final cap `0.82`).
- `lane_law`: accent burst `1.10`.
- `pressure_law`: accent feedback `1.26`.
- `reward_emphasis_law`: faster offer decay (`1.03`) and one fewer level choice (`-1`).
- `progression_law`: combo-heavy mastery signal (`combo 0.43`) with lower beat bailout (`beat 0.08`).
- `conductor_contract`: earlier cadence escalation (`drive >=0.58`, `surge >=0.81`), accent threshold `0.49`.

4. `boss_1`
- Intent: stronger decree readability and escalation cadence in chorus/final.
- `cadence_law`: increased pressure (`cycle 0.98`, `stagger 0.96`) with section caps (`chorus 0.92`, `final 0.84`).
- `lane_law`: accent burst `1.08`.
- `pressure_law`: accent feedback `1.25`.
- `conductor_contract`: boss cadence windows trigger earlier (`drive >=0.56`, `surge >=0.78`), accent threshold `0.47`.
- `boss_decree_law`: explicit profile-owned `chorus` and `final` decree timing and metadata.

## Expected Runtime Outcome
- Song identity now pushes combat through bounded laws instead of scene-local conditionals.
- Cadence and accent behavior stay explicit and tuneable in one file.
- Boss section behavior remains timing-honest while being data-authored.

## Next Bounded Check
1. Playtest one full run each with `newness` and `grind_the_orbit`.
2. Log perceived lane readability vs pressure at chorus/final transitions.
3. Adjust only profile constants unless a deterministic bug is found.
