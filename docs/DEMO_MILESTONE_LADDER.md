# WHAT WE FED — DEMO MILESTONE LADDER

## Purpose
This file defines the current prove-it ladder for **What We Fed**.

It is not a vague roadmap.
Each milestone exists to answer a specific question about whether the game is becoming a real demo-worthy project.

Use this file to decide:
- what the next patch should be
- what each patch is supposed to prove
- when the game stops being merely promising and becomes a real demo candidate

---

# Current Status

## Proven so far
The game already has:
- a real 3-lane timing combat spine
- combo/style/ultimate flow
- bond vs eat reward structure
- run growth with EXP and 1-of-3 upgrade drafts
- active bonded support
- readable support/build HUD shells
- a 4-encounter run with a real boss climax
- The Hollow Sovereign boss vertical slice

## What that means
The project is no longer just a prototype concept.
It now has a real playable spine with escalation and payoff.

But it is **not yet a demo**.

The remaining question is whether the game can support:
- enough creature variety
- enough build variety
- enough polish and flow
- enough clarity for a new player
to justify public-facing demo status.

Style note for this ladder:
- demo presentation should read as dark-cool ascendant creature power fantasy, not gore-first brutality
- influence vectors (Solo Leveling, Digimon, My Hero Academia, Ben 10) are guidance only, not copy targets

---

# Milestone 1 — First Boss Vertical Slice

## Status
Completed.

## What it proved
**Can the current run structure build toward a satisfying climax?**

## Result
Yes.

The game now has:
- boss intro
- boss HP bar
- multi-phase escalation
- boss-specific presentation
- boss defeat / run-complete payoff

This means the game can now deliver a beginning, middle, and climax instead of ending as a loose encounter chain.

---

# Milestone 2 — Creature Breadth Pass

## Status
Next major prove-it patch.

## Best Claude option
- **Opusplan** if the creature design is still uncertain
- **Sonnet** if the creature roles are already mostly decided and the work is mainly implementation

## What it should add
At minimum:
- 2 to 4 additional creatures
- distinct eat effects
- distinct bond passives
- distinct support identities now or future-facing support hooks
- encounter/reward placement that makes the creatures show up in real runs

## What it proves
**Can bond vs eat stay interesting once there are enough creatures to matter?**

## Why it matters
Right now the game proves the bond/eat concept works.
This patch must prove it can support meaningful run identity and not collapse into obvious best choices.

## Done when
- the player can build noticeably different runs
- different creatures clearly imply different styles of power
- support identity broadens beyond Ashclaw and Bond Remnant
- bond vs eat choices become less obvious and more strategic

---

# Milestone 3 — Upgrade Depth + Bond-Level Scaling

## Status
After Creature Breadth Pass.

## Best Claude option
- **Sonnet**

## What it should add
- bond-level scaling for bonded creature value
- broader upgrade pool
- stronger synergy between:
  - Flesh
  - Bond
  - Cadence
  - Survival / Instinct
- more obvious run-shaping decisions

## What it proves
**Can repeated runs create meaningfully different monsters, not just slightly different numbers?**

## Why it matters
The current run-growth system proves that growth exists.
This patch must prove that growth becomes **identity**, not just accumulation.

## Done when
- runs diverge in feel
- re-bonding the same creature has real meaning
- upgrades create stronger playstyle differences
- the player can start describing runs by build identity, not just by surviving

---

# Milestone 4 — Demo Shell

## Status
After upgrade depth is proven.

## Best Claude option
- **Sonnet**

## What it should add
- title screen
- start run flow
- controls / how to play screen or panel
- defeat flow
- victory / run-complete flow
- return-to-title flow
- basic demo structure and presentation shell

## What it proves
**Can a new player boot the game, understand the premise, complete a run, and want another one?**

## Why it matters
This is the step where the project stops feeling like “a dev build you explain live” and starts feeling like something another person can actually play.

## Done when
- the game boots cleanly
- a player can start without handholding from you
- one full run has a clean beginning, escalation, climax, and ending
- victory and defeat both feel intentional

---

# Milestone 5 — Demo Polish / Capture Pass

## Status
After the shell exists.

## Best Claude option
- **Sonnet** for implementation
- optionally **Opusplan** first if you want a capture/readability audit

## What it should add
- stronger hit feedback where needed
- better kill/death feedback
- cleaner title and victory presentation
- any final readability cleanup blocking recording/showing the game
- basic footage-worthiness polish

## What it proves
**Is the game ready to be shown, recorded, tested, and judged publicly?**

## Why it matters
A demo is not only about system completeness.
It also has to be readable, presentable, and memorable in motion.

## Done when
- the game looks intentional in short footage
- the run is understandable to an outside viewer
- combat feels satisfying on video and in play
- there are no obvious “prototype-only” presentation gaps that break the fantasy

---

# Demo Threshold

The game becomes a **real demo candidate** when all of the following are true:

- one full run lasts around **12 to 20 minutes**
- the run has:
  - onboarding
  - escalation
  - creature decisions
  - level-up choices
  - bonded support
  - a real boss climax
  - clear win / lose resolution
- at least **4 to 6 real creatures** exist
- at least **10 to 15 meaningful upgrades** exist
- combat is readable and satisfying
- the boss is memorable
- the game has a clean boot / start / end flow
- the core fantasy is obvious:
  - timing mastery
  - bond vs eat
  - mutation / growth
  - transformation fantasy and ascendant becoming
  - becoming feared
- the style read is consistent:
  - dark, mythic, premium, strange, dangerous
  - readable lanes/support under pressure
  - no bright-clean anime flattening or generic superhero gloss

If those conditions are true, the game stops being merely promising and becomes a real demo-capable slice.

---

# What Must Stay Deferred Before Demo Threshold

Do NOT prioritize these before the demo threshold unless something changes drastically:

- ranch implementation
- world-state consequence layer
- Hollow Egg implementation
- kaiju system implementation
- broader campaign map structure
- meta progression
- advanced long-term creature training layers

These are flagship multipliers.
They are not the systems that prove the game right now.

---

# Recommended Order From Here

1. Creature Breadth Pass
2. Upgrade Depth + Bond-Level Scaling
3. Demo Shell
4. Demo Polish / Capture Pass

The boss vertical slice is already done and counts as the first cleared major prove-it milestone.

---

# Practical Rule

For every major patch, ask:

## What single question is this patch supposed to answer?

If the patch does not prove something important, it is probably not the next best use of time.

---

# Current Best Next Patch

## Creature Breadth Pass

This is the next question the game must answer:

**Can bond vs eat stay compelling once the creature roster has real breadth?**
