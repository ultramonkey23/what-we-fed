extends RefCounted

const COMBAT_DATA = preload("res://data/CombatContent.gd")

const SUPPORT_EMPTY_NAME: String = "No bond"
const SUPPORT_EMPTY_TRIGGER: String = "No support"
const RUN_BUILD_EATEN_CAPTION: String = "Eaten"
const RUN_BUILD_TENDENCY_CAPTION: String = "Tendency"
const RUN_BUILD_BOND_CAPTION: String = "Bond"
const REWARD_TAG_CREATURE: String = "Claim"
const REWARD_TAG_BONDED: String = "Bond kept"
const REWARD_TAG_EATEN: String = "Eaten"
const REWARD_TAG_PASSED: String = "Passed"
const REWARD_TITLE_PASSED: String = "Gone."
const REWARD_BODY_PASSED: String = "It leaves hungry."
const REWARD_HINT_WAIT: String = "..."
const REWARD_HINT_RESTART: String = "R re-instantiate"
const REWARD_CONTROLS_RESTART: String = "Run complete  |  R re-instantiate pattern"
const REWARD_HINT_LOCKED: String = "Bond DNA locked (LACK) | PRESS E TO EAT (GAIN LINEAGE DNA) | N pass"
const REWARD_HINT_CHOICE: String = "Choose | PRESS B TO BOND (SPEND) | PRESS E TO EAT (GAIN LINEAGE DNA) | N pass"
const REWARD_CONTROLS_LOCKED: String = "Bond DNA locked | E eat | N pass"
const REWARD_CONTROLS_CHOICE: String = "Reward choice | B bond | E eat | N pass"
const LIVE_CONTROLS_LOCKED: String = "Bond locked | E/N"
const LIVE_CONTROLS_CHOICE: String = "B bond | E eat | N pass"
const LIVE_REWARD_LOCKED_HINT_PREFIX: String = "Bond locked | E/N"
const LIVE_REWARD_CHOICE_HINT_PREFIX: String = "B/E/N"
const EAT_DNA_GAIN: float = 12.5
const BOSS_STATE_OPENING: String = "Phase I  |  Hold line"
const BOSS_STATE_FINAL: String = "Unleashed  |  No shelter"
const TITLE_SUBTITLE: String = "The hollow keeps what it learns."
const TITLE_PROMPT: String = "Press any key to initiate translation"
const TITLE_HINT: String = "H — controls  |  Ctrl+Shift+N — new admittance"
const TITLE_HELP_HEADER: String = "Survival Protocol"
const INTRO_BOND_HEADER: String = "FIRST ADMITTANCE"
const INTRO_BOND_SUBTITLE: String = "This cycle opens with one lineage tethered to your sequence. Choose the pattern that sustains your re-instantiation."
const INTRO_BOND_HINT: String = "1 / 2 / 3 — select  |  ENTER — commit sequence"
const INTRO_BOND_NEED_SELECTION: String = "Select a lineage before you descend."
const LAIR_SUBTITLE: String = "Patterns persist between re-instantiations — flag active sequence, then choose your interface ground."
const LAIR_EMPTY: String = "Archive empty.\nIntrude into the hollow and extract a lineage."
const LAIR_NOTE: String = "Selected lineage enters re-instantiated. A stronger pattern taken mid-run overwrites your active sequence."
const LAIR_DEN_LABEL: String = "Lineage archive"
const LAIR_DEN_BLURB: String = "What you harvest remembers you. One lineage can be re-instantiated as support each intrusion."
const LAIR_ACTIVE_HEAD: String = "Active sequence"
const LAIR_ACTIVE_SOLO: String = "No companion tethered for this re-instantiation.\n\nPress 1–3 to assign a lineage, or the same key again to descend alone."
const LAIR_ACTION_TRAIN_LABEL: String = "T - Deepen Sequence"
const LAIR_ACTION_RELEASE_LABEL: String = "X - Purge Archive"
const LAIR_DNA_REQUIRED: String = "DNA required: %d"
const LAIR_DNA_REFUND: String = "DNA refund: %d"
const LAIR_TRAIN_SUCCESS: String = "Bond deepens. %s is now level %d."
const LAIR_RELEASE_SUCCESS: String = "%s released. DNA reclaimed."
const ROUTE_HEADER: String = "CHOOSE YOUR GROUND"
const ROUTE_SUBTITLE: String = "Each ground changes how the hunger closes."
const DNA_ROUTE_EXP_LABEL: String = "DNA->EXP"
const DNA_ROUTE_BOND_LABEL: String = "DNA->BOND"
const RUN_PREP_HEADER: String = "CARRY CHECK"
const RUN_PREP_SUBTITLE: String = "What the hollow holds before the next leg."
const RUN_PREP_CONTROLS: String = "Space/Enter continue  |  TAB slot  A/D item  E equip  X salvage  C collar hook  |  Q route"
const RUN_PREP_NEXT_REGULAR: String = "Next: deeper song slice."
const RUN_PREP_NEXT_BOSS: String = "Next: sovereign — full song."
const RUN_SPINE_LEVEL_HEADER: String = "LEVEL COMPLETE"
const RUN_SPINE_LEVEL_SUBTITLE: String = "Choose earned evolution, tune the carry, then continue."
const RUN_SPINE_EVOLUTION_CONTROLS: String = "1/2/3 choose evolution"
const RUN_SPINE_PREDATION_HEADER: String = "PREDATION POOL"
const RUN_SPINE_PREDATION_SUBTITLE: String = "One compact feeding between legs of the run — DNA stays species-true."
const RUN_SPINE_PREDATION_CONTROLS: String = "1/2/3 commit predation  |  Q route (bond<->growth)"
const RUN_SPINE_REVIEW_HEADER: String = "CARRY LOCKED"
const RUN_SPINE_REVIEW_SUBTITLE: String = "Evolution is set for this leg. Use management hooks, then continue."
const COMBAT_CONTROLS: String = "ARROWS move  |  Space attack  |  Z parry  |  Shift dodge  |  X support  |  C apex"
const COMBAT_BOSS_CONTROLS: String = "Boss  |  ARROWS move  |  Space attack  |  Z parry  |  Shift dodge  |  X support  |  C apex"
const RUN_END_CONTROLS_VICTORY: String = "Run complete  |  R re-instantiate  |  T lair"
const RUN_END_CONTROLS_FAILURE: String = "Run broken  |  R re-instantiate  |  T recall"
const DEFAULT_DNA_PICKUP_FLAVOR: String = "The world marks the gain."
const DNA_PICKUP_FLAVOR_COOLDOWN_SECONDS: float = 2.4

const DNA_PICKUP_FLAVORS := {
	"feeding_hollow": {
		"default": [
			"The air learns your rhythm.",
			"The hollow counts that kill.",
			"Something hungry keeps pace."
		],
		"low_hp": [
			"The hollow smells blood first.",
			"Your shake feeds the place."
		],
		"high_dna": [
			"Pattern stacks. The hollow watches.",
			"You carry too much heat."
		],
		"high_support": [
			"Your bond hum rises loud.",
			"The next trigger will be seen."
		]
	},
	"pale_shelf": {
		"default": [
			"Silence tracks your efficiency.",
			"The shelf logs every clean cut.",
			"Cold air keeps the receipt."
		],
		"low_hp": [
			"Blood shows sharp in this light.",
			"The shelf likes exposed breath."
		],
		"high_dna": [
			"Too much pattern to hide now.",
			"The wind knows your shape."
		],
		"high_support": [
			"Bond charge glows through the frost.",
			"Even your support leaves a line."
		]
	},
	"drowned_cut": {
		"default": [
			"The cut pulls new pattern through.",
			"Tide answers your last strike.",
			"Current keeps what you took."
		],
		"low_hp": [
			"The water wants weak steps.",
			"One slip and the cut keeps you."
		],
		"high_dna": [
			"Your catalog drags like weight.",
			"Too much memory in one body."
		],
		"high_support": [
			"Bond charge rides like a second pulse.",
			"The echo is not only yours."
		]
	}
}

const BOSS_INTRO_LINES := {
	"feeding_hollow": "This ground does not share apex.",
	"pale_shelf": "Exposure is the law here.",
	"drowned_cut": "The cut argues current against bone."
}

const BOSS_THRESHOLD_BREAK_LINES := {
	"feeding_hollow": "Break: the echo tightens.",
	"pale_shelf": "Break: the blue gets honest.",
	"drowned_cut": "Break: the bond-layer wakes louder."
}

const BOSS_THRESHOLD_FINAL_LINES := {
	"feeding_hollow": "Unleashed: the verdict is teeth now.",
	"pale_shelf": "Unleashed: no shelter in precision.",
	"drowned_cut": "Unleashed: hold line or lose shape."
}

const BOSS_STATE_OPENING_BY_REGION := {
	"feeding_hollow": "Phase I  |  Teeth test",
	"pale_shelf": "Phase I  |  Thin verdict",
	"drowned_cut": "Phase I  |  Tide test"
}

const BOSS_STATE_FINAL_BY_REGION := {
	"feeding_hollow": "Unleashed  |  Teeth law",
	"pale_shelf": "Unleashed  |  Exposed",
	"drowned_cut": "Unleashed  |  Hold shape"
}

const POST_RUN_REGION_ECHO := {
	"feeding_hollow": "The hollow remembers weight.",
	"pale_shelf": "The shelf keeps your outline.",
	"drowned_cut": "The cut keeps your wake."
}

const QUIG_REACTIVE_LINES := {
	"timing": {
		"puncture": [
			"The hollow likes that rhythm.",
			"A micro-death. Keep the count.",
			"Time thins when you strike well."
		],
		"perfect_parry": [
			"A clean rejection. Keep the space.",
			"Pattern matched. It leaves no mark.",
			"Reflected. They don't learn fast."
		],
		"perfect_timed_attack": [
			"Pattern matched. It tears better.",
			"Rhythm is the only law here.",
			"You found the seam."
		]
	},
	"tutorials": {
		"movement": [
			"Quig: \"Use the ARROW KEYS to move the Vessel. Don't be static.\"",
			"Quig: \"Navigation is survival. Move with the pulse.\""
		],
		"combat": [
			"Quig: \"SPACE to attack. Timing is everything here.\"",
			"Quig: \"Z to parry. Rejection is a predatory act.\"",
			"Quig: \"SHIFT to dodge. Own your distance.\"",
			"Quig: \"X to invoke support. Use your debt.\"",
			"Quig: \"C for Apex. Let the pattern collapse.\""
		]
	},
	"bond_eat": {
		"bond": [
			"A debt beside you. Don't let it starve.",
			"An echo stays. It will demand timing.",
			"The bond deepens. The weight is shared."
		],
		"eat": [
			"A temporary mouth. Fast gain, short memory.",
			"Folded in. The shape is yours now.",
			"Predatory gain. It doesn't need to breathe anymore."
		]
	},
	"urgency": {
		"low_hp": [
			"Your pulse is too loud. They can hear the leak.",
			"The hollow smells blood first. Patch the seam.",
			"You're thinning. Hold the line."
		],
		"sovereign_reach": [
			"The law here is changing. Adjust or dissolve.",
			"Apex presence detected. The ground arguments change.",
			"Sovereign law. No shelter in old habits."
		],
		"sovereign_low_hp": [
			"The apex is thinning. Finish the line.",
			"It bleeds like anything else. Close the wake.",
			"The law is breaking. Claim it."
		]
	},
	"world_fate": {
		"predatory_brutal": [
			"The world resonates with PREDATION. The Hollow answers force with force.",
			"The scent of blood has become the law. Brutality is rewarded."
		],
		"mythic_hopeful": [
			"The world resonates with MYTH. The echo of the bond rises.",
			"A shared memory thins the veil. The allies remember you."
		],
		"sterile_technocratic": [
			"The world resonates with LOGIC. Structural integrity prioritized.",
			"Cold air, cold patterns. Efficiency is the only metric now."
		],
		"haunted_ritual": [
			"The world resonates with SHADOW. Rituals gain persistence.",
			"The failure of others lingers here. It wants to be repeated."
		]
	},
	"ascension": {
		"success": [
			"The pattern is rewritten. Ascension confirmed.",
			"They have reached sovereign status. The Lair accepts the new law.",
			"A hybrid sovereign is born. The world notices."
		]
	}
}


static func dna_status_line(species_id: String) -> String:
	var current: float = GameState.get_dna(species_id)
	
	if GameState.is_species_ever_bonded(species_id):
		var cost: float = float(GameState.get_lair_training_cost(species_id))
		if cost > 0:
			return "DNA COLLECTION: %.0f / %.0f (NEXT LEVEL)" % [current, cost]

	var threshold: float = GameState.get_effective_dna_threshold(species_id)
	var base: float = float(COMBAT_DATA.get_creature(species_id).get("dna_threshold", 0.0))
	
	var line: String = "DNA COLLECTION: %.0f / %.0f" % [current, threshold]
	if threshold > base:
		line += " (PENALTY +%.0f%%)" % (((threshold/base) - 1.0) * 100.0)
	return line


static func bond_offer_gate_line(species_id: String) -> String:
	var current: float = GameState.get_dna(species_id)
	if GameState.is_species_ever_bonded(species_id):
		return "ARCHIVE TETHER READY  |  DNA %.0f banked" % current
	var threshold: float = GameState.get_effective_dna_threshold(species_id)
	var base: float = float(COMBAT_DATA.get_creature(species_id).get("dna_threshold", 0.0))
	var line: String = "FIRST BOND COST  %.0f / %.0f DNA" % [current, threshold]
	if base > 0.0 and threshold > base:
		line += "  |  predation debt +%.0f%%" % (((threshold / base) - 1.0) * 100.0)
	return line


static func live_bond_offer_gate_line(species_id: String) -> String:
	var current: float = GameState.get_dna(species_id)
	if GameState.is_species_ever_bonded(species_id):
		return "TETHER READY  |  DNA %.0f" % current
	var threshold: float = GameState.get_effective_dna_threshold(species_id)
	return "BOND DNA  %.0f / %.0f" % [current, threshold]


static func live_dna_gate_line(current: float, threshold: float) -> String:
	return "DNA  %.0f / %.0f" % [current, threshold]


static func reward_bond_label(locked: bool) -> String:
	return "Bond  [B]  - DNA locked" if locked else "Bond  [B]"


static func reward_eat_label(_locked: bool) -> String:
	return "Eat  [E]"


static func reward_bond_body(passive_text: String) -> String:
	return "Keep it living.\n\n%s\n\nDebt beside you." % passive_text


static func reward_eat_body(effect_text: String) -> String:
	return "Take it inside.\n\n%s\n\nPower now. No DNA cost." % effect_text


static func support_trigger_line(trigger_text: String) -> String:
	return "Trigger  |  %s" % trigger_text


static func live_reward_title(display_name: String) -> String:
	return display_name


static func live_reward_hint(locked: bool, seconds_left: float) -> String:
	var prefix: String = LIVE_REWARD_LOCKED_HINT_PREFIX if locked else LIVE_REWARD_CHOICE_HINT_PREFIX
	return "%s  |  %.0fs" % [prefix, ceil(seconds_left)]


static func bond_result_body(display_name: String, bond_level: int, is_exceptional: bool = false) -> String:
	if is_exceptional:
		return "EXCEPTIONAL specimen detected. %s archive entry rewritten with elite data." % display_name
	if bond_level <= 1:
		return "%s enters beside you." % display_name
	return "The bond deepens. %s is now level %d." % [display_name, bond_level]


static func exceptional_specimen_label() -> String:
	return "EXCEPTIONAL"


static func eat_result_body() -> String:
	return "Its shape tears open inside you."


static func bond_result_quig(display_name: String) -> String:
	return "Quig: \"Keep %s close. It will demand timing soon.\"" % display_name


static func eat_result_quig(display_name: String) -> String:
	return "Quig: \"Fast gain. Hard to remember %s after.\"" % display_name


static func pass_result_quig() -> String:
	return "Quig: \"If it leaves, it tracks your route.\""


static func reward_locked_effect_body(effect_text: String) -> String:
	return "DNA short.\n\n%s" % effect_text


static func format_eat_effect(effect: Dictionary) -> String:
	var effect_type: String = String(effect.get("type", ""))
	var value: float = float(effect.get("value", 0.0))
	var dna_line: String = "\n+%.0f lineage DNA" % EAT_DNA_GAIN
	match effect_type:
		"damage_flat":
			return "+%.0f permanent attack damage%s" % [value, dna_line]
		"hp_restore":
			return "restores %.0f HP immediately - no permanent bonus%s" % [value, dna_line]
		"max_hp_flat":
			return "+%.0f max HP immediately%s" % [value, dna_line]
		"support_charge":
			return "+%.0f support charge immediately%s" % [value, dna_line]
		_:
			return "fold its pattern inside%s" % dna_line


static func boss_intro_line(region_id: String, fallback: String = "APEX VERDICT") -> String:
	if BOSS_INTRO_LINES.has(region_id):
		return String(BOSS_INTRO_LINES[region_id])
	return fallback


static func boss_threshold_break_line(region_id: String) -> String:
	if BOSS_THRESHOLD_BREAK_LINES.has(region_id):
		return String(BOSS_THRESHOLD_BREAK_LINES[region_id])
	return "Break: law shifts."


static func boss_threshold_final_line(region_id: String) -> String:
	if BOSS_THRESHOLD_FINAL_LINES.has(region_id):
		return String(BOSS_THRESHOLD_FINAL_LINES[region_id])
	return "Unleashed: final push."


static func boss_state_opening(region_id: String) -> String:
	if BOSS_STATE_OPENING_BY_REGION.has(region_id):
		return String(BOSS_STATE_OPENING_BY_REGION[region_id])
	return BOSS_STATE_OPENING


static func boss_state_final(region_id: String) -> String:
	if BOSS_STATE_FINAL_BY_REGION.has(region_id):
		return String(BOSS_STATE_FINAL_BY_REGION[region_id])
	return BOSS_STATE_FINAL


static func dna_pickup_flavor(region_id: String, state_id: String, rotation: int) -> String:
	var region_pack: Dictionary = DNA_PICKUP_FLAVORS.get(region_id, {})
	if region_pack.is_empty():
		return DEFAULT_DNA_PICKUP_FLAVOR
	var selected_state: String = state_id if region_pack.has(state_id) else "default"
	var pool: Array = region_pack.get(selected_state, [])
	if pool.is_empty():
		pool = region_pack.get("default", [])
	if pool.is_empty():
		return DEFAULT_DNA_PICKUP_FLAVOR
	var idx: int = posmod(rotation, pool.size())
	return String(pool[idx])


static func post_run_summary(stats: Dictionary, region_id: String, victory: bool) -> String:
	var kills: int = int(stats.get("kills", 0))
	var bonds: int = int(stats.get("bonds", 0))
	var eats: int = int(stats.get("eats", 0))
	var passed: int = int(stats.get("passes", 0))
	var outcome: String = "Run closed." if victory else "Run broken."
	var echo: String = String(POST_RUN_REGION_ECHO.get(region_id, "The ground keeps score."))
	return "%s %d marks. %d bonds. %d folded in. %d passed. %s" % [outcome, kills, bonds, eats, passed, echo]


static func codex_entry_stub(creature_name: String, role_name: String, region_name: String, bond_hint: String, eat_hint: String) -> String:
	var lines: Array[String] = []
	lines.append("%s | %s" % [creature_name, role_name])
	lines.append("In %s, it enforces local pressure." % region_name)
	if not bond_hint.is_empty() or not eat_hint.is_empty():
		var bond_line: String = "Bond: %s." % bond_hint if not bond_hint.is_empty() else "Bond: preserve its outer pattern."
		var eat_line: String = "Eat: %s." % eat_hint if not eat_hint.is_empty() else "Eat: fold its pattern inward."
		lines.append("%s %s" % [bond_line, eat_line])
	return "\n".join(PackedStringArray(lines))


static func format_bond_passive_long(passive: Dictionary, level_mult: float) -> String:
	var value: float = float(passive.get("value", 0.0)) * level_mult

	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f flat damage added to every ultimate burst" % value
		"damage_reduction_pct":
			return "%.0f%% global damage reduction while bonded" % (value * 100.0)
		"hp_on_kill":
			return "+%.1f HP restored on every enemy kill" % value
		"parry_reflect_mult":
			return "+%.0f%% parry reflect damage while bonded" % (value * 100.0)
		"timed_damage_flat":
			return "+%.1f flat damage added to every timed attack" % value
		_:
			return "keep it beside you"


static func format_bond_passive_short(passive: Dictionary, level_mult: float) -> String:
	var value: float = float(passive.get("value", 0.0)) * level_mult

	match passive.get("type", ""):
		"damage_on_ultimate":
			return "+%.0f ult dmg" % value
		"damage_reduction_pct":
			return "%.0f%% def" % (value * 100.0)
		"hp_on_kill":
			return "+%.1f hp/kill" % value
		"parry_reflect_mult":
			return "+%.0f%% parry" % (value * 100.0)
		"timed_damage_flat":
			return "+%.1f timed dmg" % value
		_:
			return "--"


static func support_ready_label(display_name: String) -> String:
	return "%s READY" % display_name.to_upper()


static func trigger_hint(effect_id: String) -> String:
	# Fallback when creature data has no hud_trigger_hint; keep compact for HUD.
	match effect_id:
		"ashclaw_strike":
			return "Parry/timed: expose"
		"bond_remnant_mend":
			return "Hit when charged"
		"gruvek_gorge":
			return "Kill: gorge all"
		"veilskin_phase":
			return "Perf.parry: phase"
		"thornback_rend":
			return "Perf.timed: rend"
		"knellspine_peal":
			return "Good+perf.timed"
		"marrowward_ward":
			return "Dodge: bone ward"
		"gorefane_maul":
			return "Ultimate: maul"
		"hushcoil_lull":
			return "Perf.parry: hush"
		"coldvein_expose":
			return "Perf.parry: seam"
		"siltgrip_drag":
			return "Kill: heal+rend"
		_:
			return "On rhythm"


static func tendency_summary(tendency_id: String) -> String:
	match tendency_id:
		"aggression":
			return "Attack +2"
		"cadence":
			return "Good timing +12% + charge"
		"guard":
			return "Max HP +10"
		"bond":
			return "Bond charge +20"
		_:
			return ""


static func tendency_level_up_summary(result: Dictionary) -> String:
	var tendency_id: String = String(result.get("tendency_id", ""))
	var changes: Array = result.get("changes", [])
	if changes.is_empty():
		return tendency_summary(tendency_id)

	var parts: Array[String] = []
	for change in changes:
		var change_type: String = String(change.get("type", ""))
		match change_type:
			"base_damage_flat":
				parts.append("base damage +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"max_hp_flat":
				parts.append("max HP +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"defense_flat":
				parts.append("defense +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"heal_now":
				var heal_value: float = float(change.get("applied_value", 0.0))
				if heal_value > 0.0:
					parts.append("pulse heal +%d" % int(round(heal_value)))
			"good_timed_bonus_damage_per_level":
				parts.append("good timing payoff +%d%%" % int(round(float(change.get("applied_value", 0.0)) * 100.0)))
			"support_charge_gain_mult_per_level":
				parts.append("support gain +%d%%" % int(round(float(change.get("applied_value", 0.0)) * 100.0)))
			"support_charge_now":
				parts.append("charge +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"stat_vitality":
				parts.append("Flesh +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"stat_power":
				parts.append("Maw +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"stat_carapace":
				parts.append("Bone +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"stat_endurance":
				parts.append("Lung +%d" % int(round(float(change.get("applied_value", 0.0)))))
			"stat_swiftness":
				parts.append("Nerve +%.2f" % float(change.get("applied_value", 0.0)))
			"stat_luck":
				parts.append("Omen +%.2f" % float(change.get("applied_value", 0.0)))
			"stat_potential":
				parts.append("Hollow +%.2f" % float(change.get("applied_value", 0.0)))
			"stat_intelligence":
				parts.append("Eye +%.2f" % float(change.get("applied_value", 0.0)))
			"stat_adaptability":
				parts.append("Form +%.2f" % float(change.get("applied_value", 0.0)))

	if parts.is_empty():
		return tendency_summary(tendency_id)
	return ", ".join(PackedStringArray(parts))
