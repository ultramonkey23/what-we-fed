# WHAT WE FED — SONG LEVEL STRUCTURE

## Purpose

This file defines the current best model for level flow in **What We Fed**.

It exists to lock in the idea that levels are not just finite room-clearing sequences.
They are **song-duration survival performances**.

This file defines:
- how a level should function
- how pressure should rise and fall
- how enemy spawning should work
- how player skill should be rewarded
- how creature buildcraft fits into continuous survival structure

---

# 1. Core Rule

A level is a **song-duration survival sequence**—during **active combat**, timing stays honest and the performance is **not** interrupted by menus.

Enemies do **not** stop spawning when defeated.
The player is trying to:
- survive until the song ends
- kill fast enough to keep pressure manageable
- earn more growth through tempo control
- turn a weak start into late-level dominance

## Core law
### **The level should not end because the enemies are gone.**
### **The level ends because the song is over.**

This is one of the defining structural rules of the game.

## 1b Run cadence (design target)
- **One run** = **9 regular levels** + **1 boss level**.
- **Regular levels**: use an **authored segment under ~2 minutes** of the track (a slice, not the full song). After each: **reward selection** → **inventory / resource management** → next level.
- **Boss (10th encounter)**: plays to the **full song** for that fight (not the short slice), still lane-timing combat with the same truth locks.
- **No-pause** applies **inside** the active combat window for that level, not during intentional **between-level** menus.

---

# 2. Core Fantasy of a Level

The player is not just clearing rooms.

They are:
## **surviving a hostile song**

The level should feel like a performance trying to break them.

By the end of a strong run, the player should feel:
- they learned the pressure
- they adapted to the rhythm
- they accelerated through kills and buildcraft
- the battlefield started obeying their build’s tempo

A good level ends with:
### **survival turning into control**

---

# 3. Recommended First Song Length

**Note:** Section **1b** defines **regular** levels as **under ~2 minutes** of authored slice and the **boss** as a **full-track** fight. The **4 minute** arc below remains useful as a **reference tension curve** (especially for boss-scale or legacy pacing); future passes may add a dedicated sub-2-minute phase template for regular levels.

## First target duration (reference arc)
**4 minutes**

This is a recommended serious **full-track** arc length because it is long enough to show:
- early weakness
- mid-level adaptation
- power ramp
- pressure escalation
- a real climax

But short enough to remain:
- readable
- testable
- not exhausting in an early demo

---

# 4. Song Phase Structure

Each level should be structured like a track with recognizable sections.

## Phase A — Opening Bars
### Duration
0:00–0:45

### Purpose
- establish rhythm
- give the player just enough room to stabilize
- let the first build traits begin to matter

### Pressure
- lower spawn density
- mostly single-lane pressure
- occasional light two-lane pressure
- forgiving cadence

### Feeling
- exposed
- reactive
- uncertain
- hungry

---

## Phase B — Rising Verse
### Duration
0:45–1:45

### Purpose
- begin real tempo testing
- make kill speed matter
- let build quality start showing clearly

### Pressure
- more frequent spawns
- alternating lane emphasis
- occasional simultaneous pressure
- more meaningful punishment for hesitation

### Feeling
- unstable but manageable
- player starts claiming breathing room through offense

---

## Phase C — First Chorus
### Duration
1:45–2:30

### Purpose
- first major stress check
- prove whether the build is actually helping
- raise the cost of sloppy play

### Pressure
- denser lane overlap
- faster or harder enemy patterns
- more persistent threat presence
- stronger punishment for lost tempo

### Feeling
- the song is trying to overwhelm the player
- strong builds begin pushing back

---

## Phase D — Breakdown / Shift
### Duration
2:30–3:00

### Purpose
- change the pattern
- prevent autopilot
- force adaptation

### Pressure
- altered lane bias
- changed spawn rhythm
- unusual pacing
- possible fake relief followed by a sharp spike

### Feeling
- disorienting
- tense
- unstable
- “the song changed under me”

---

## Phase E — Final Chorus / Survival Peak
### Duration
3:00–4:00

### Purpose
- climax
- highest sustained pressure
- strongest build expression
- final proof of what the run became

### Pressure
- highest spawn density
- more multi-lane danger
- strongest enemy patterns
- possible elite/apex wave near the end

### Feeling
- either panic or domination
- the player proves what kind of monster they built

---

# 5. Spawn Philosophy

## Core spawn rule
Enemies spawn continuously according to the current song phase.

The player is not trying to eliminate the battlefield permanently.
The player is trying to:
- reduce pressure
- stay ahead of the flow
- create breathing room through violence
- keep tempo from collapsing

## Soft-cap rule
Enemy pressure must remain readable.

Recommended early implementation:
- max 2 active/queued enemies per lane
- max 4–5 meaningful active threats globally in the first serious version

This prevents unreadable clutter while preserving constant pressure.

## Spawn patterns should be authored
Spawns should not feel like meaningless randomness.

Each phase should define:
- spawn interval
- lane bias
- enemy type mix
- aggression curve
- occasional pressure accents

The player should feel:
- pressure is hostile
- but not arbitrary

---

# 6. Tempo Control

Tempo control is one of the main goals of play.

## The player is not trying to win by emptying the screen.
They are trying to win by:
- killing fast enough to create space
- keeping threat count from spiraling
- maintaining offensive momentum
- converting skill into control

## Survival alone is not the highest form of success.
A player who survives while constantly drowning in pressure should earn less than a player who survives while controlling the pace of the song.

---

# 7. EXP and Reward Philosophy

## Base rule
Survival keeps you in the song.
Skillful aggression makes you grow faster inside it.

### Good EXP sources
- enemy kills
- perfect timed attacks
- perfect parries
- style/combo milestones
- fast-kill bonuses
- streak bonuses
- section-performance bonuses
- end-of-song performance bonus

### Bad EXP sources
- passive waiting
- dragging out fights
- endless kiting
- pure turtling
- surviving with no pressure control

## Fast kill philosophy
Fast kills should be rewarded because they express:
- efficiency
- tempo ownership
- predator identity
- build quality

## End-of-song philosophy
The end of the level should grant a final reward based on:
- survival
- tempo control
- quality of performance

---

# 8. Performance Grades

A first strong thematic grading ladder should use in-world language, not generic letters.

## Recommended first grades
- **Barely Held**
- **Controlled**
- **Dominant**
- **Devouring**

### Meaning
- **Barely Held** = survived but struggled badly
- **Controlled** = survived with decent lane/tempo management
- **Dominant** = strong control over pressure and kill pace
- **Devouring** = fast, efficient, predatory, high-performance survival

This keeps evaluation aligned with the game’s tone and soul.

---

# 9. Creature Roles in Song Structure

Creatures are not just combat perks.
They are **tempo tools**.

## Main role families

### Kill-Tempo Creatures
Help delete enemies faster.
Examples:
- burst support
- timed-hit amplification
- execute-style pressure
- offensive lane hits

### Sustain-Tempo Creatures
Keep aggression alive.
Examples:
- heal on kill
- mend when pressured
- stamina recovery
- sustain through violence

### Control-Tempo Creatures
Help manage battlefield flow.
Examples:
- lane-wide damage
- pressure smoothing
- reactive support
- cleave behavior

### Precision-Tempo Creatures
Reward exact timing under constant pressure.
Examples:
- perfect-parry triggers
- perfect-attack triggers
- combo-scaled support payoff

This is how creature buildcraft becomes central to song survival.

---

# 10. Build Archetypes the Song Model Supports

The song model should naturally create runs like:

## Carrion Engine
- kill-fed sustain
- pressure becomes food
- survives through aggression

## Precision Predator
- perfect timing
- exact kill conversion
- high efficiency and tempo dominance

## Perfect Monster
- parry-focused
- punishment becomes damage
- pressure is turned back on the level

## Bonded Horror
- active support heavily shapes the run rhythm
- player and creature start feeling like one engine

## Glutton Build
- selfish consumption
- raw body scaling
- brute-force tempo control

These are the kinds of run identities the system should support.

---

# 11. Bosses in the Song Model

Bosses should become:
- special songs
- final movements
- apex survival sections
- end-of-track climaxes

A boss should not just be “another room with a stronger enemy.”
It should feel like:
- the track’s last hostile statement
- a demand that the player prove the build they created

The current boss vertical slice can still fit this model by becoming:
### the final movement of the level

---

# 12. What “More Speed” Should Mean

More speed should **not** mean:
- unreadable chaos
- pure DPS race design
- button mash pressure
- instant-death spam

More speed **should** mean:
- quicker kill conversion
- less downtime
- more meaningful pressure decisions
- stronger feeling of tempo ownership
- faster build snowball
- cleaner transition from weakness to dominance

The player should feel:
- early: “I’m barely keeping up with the song.”
- later: “The song is keeping up with me.”

---

# 13. First Playable Target Values

These are first serious target values, not final numbers.

## Song length
- 4:00 total

## Spawn pacing targets
- Opening: 1 enemy every 2.2–2.6 seconds
- Rising: 1 enemy every 1.7–2.1 seconds
- Chorus: 1 enemy every 1.2–1.6 seconds
- Breakdown: variable rhythm
- Final: 1 enemy every 0.9–1.4 seconds, with pressure caps preserved

## Threat cap
- max 4–5 meaningful threats active in first implementation

## Reward model
- base kill EXP
- small fast-kill bonus
- small streak bonus
- phase performance bonus
- end-of-song grade bonus

The first implementation should stay:
- readable
- testable
- tuneable

---

# 14. What This Model Changes

This model changes the game from:
- room clear progression
to:
- performance survival progression

From:
- finite encounter completion
to:
- continuous hostile flow management

From:
- “can I clear this?”
to:
- “can I control this song long enough to become monstrous?”

That is a major identity upgrade.

---

# 15. Final Truth

**A level in What We Fed should feel like a hostile song that keeps trying to consume the player until the player becomes strong enough, fast enough, and strange enough to consume it back.**
