extends RefCounted

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
const REWARD_BODY_PASSED: String = "The dark keeps it."
const REWARD_HINT_WAIT: String = "..."
const REWARD_HINT_RESTART: String = "R restart run"
const REWARD_CONTROLS_RESTART: String = "Run complete  |  R restart run"
const REWARD_HINT_LOCKED: String = "DNA locked  |  N pass"
const REWARD_HINT_CHOICE: String = "Choose  |  B bond  |  E eat  |  N pass"
const REWARD_CONTROLS_LOCKED: String = "DNA locked  |  N pass"
const REWARD_CONTROLS_CHOICE: String = "Reward choice  |  B bond  |  E eat  |  N pass"
const LIVE_CONTROLS_LOCKED: String = "DNA locked  |  N pass"
const LIVE_CONTROLS_CHOICE: String = "B bond  |  E eat  |  N pass"
const LIVE_REWARD_LOCKED_HINT_PREFIX: String = "Locked | N"
const LIVE_REWARD_CHOICE_HINT_PREFIX: String = "B/E/N"
const BOSS_STATE_OPENING: String = "Phase I  |  Break 50%"
const BOSS_STATE_FINAL: String = "Unleashed  |  Final push"
const TITLE_SUBTITLE: String = "The hollow keeps what it learns."
const TITLE_PROMPT: String = "Press any key to enter"
const TITLE_HINT: String = "H - controls"
const TITLE_HELP_HEADER: String = "How to survive"
const LAIR_SUBTITLE: String = "Choose what danger enters beside you."
const LAIR_EMPTY: String = "No bonds kept.\nEnter the hollow and bring one back breathing."
const LAIR_NOTE: String = "Selected creature enters already bonded. A stronger bond taken mid-run becomes your active support."
const ROUTE_HEADER: String = "CHOOSE YOUR GROUND"
const ROUTE_SUBTITLE: String = "Each ground changes how the hunger closes."
const DNA_ROUTE_EXP_LABEL: String = "DNA->EXP"
const DNA_ROUTE_BOND_LABEL: String = "DNA->BOND"
const RUN_PREP_HEADER: String = "CARRY CHECK"
const RUN_PREP_SUBTITLE: String = "What the hollow holds before the next leg."
const RUN_PREP_CONTROLS: String = "SPACE / ENTER — continue  |  Q — DNA route (bond ↔ growth)"
const RUN_PREP_NEXT_REGULAR: String = "Next: deeper song slice."
const RUN_PREP_NEXT_BOSS: String = "Next: sovereign — full song."

static func dna_status_line(current: float, threshold: float, locked: bool) -> String:
	return "DNA  %.0f / %.0f  %s" % [current, threshold, "LOCKED" if locked else "READY"]


static func live_dna_gate_line(current: float, threshold: float) -> String:
	return "DNA  %.0f/%.0f" % [current, threshold]


static func reward_bond_label(locked: bool) -> String:
	return "Bond  [B]  - locked" if locked else "Bond  [B]"


static func reward_eat_label(locked: bool) -> String:
	return "Eat  [E]  - locked" if locked else "Eat  [E]"


static func reward_bond_body(passive_text: String) -> String:
	return "Keep it living.\n\n%s\n\nDanger beside you." % passive_text


static func reward_eat_body(effect_text: String) -> String:
	return "Take it inside.\n\n%s\n\nNeed before mercy." % effect_text


static func support_trigger_line(trigger_text: String) -> String:
	return "Trigger  |  %s" % trigger_text


static func live_reward_title(display_name: String) -> String:
	return display_name


static func live_reward_hint(locked: bool, seconds_left: float) -> String:
	var prefix: String = LIVE_REWARD_LOCKED_HINT_PREFIX if locked else LIVE_REWARD_CHOICE_HINT_PREFIX
	return "%s  |  %.0fs" % [prefix, ceil(seconds_left)]


static func bond_result_body(display_name: String, bond_level: int) -> String:
	if bond_level <= 1:
		return "%s enters beside you." % display_name
	return "The bond deepens. %s is now level %d." % [display_name, bond_level]


static func eat_result_body() -> String:
	return "Its shape tears open inside you."


static func bond_result_quig(display_name: String) -> String:
	return "Quig: \"Keep %s close. It will ask for blood later.\"" % display_name


static func eat_result_quig(display_name: String) -> String:
	return "Quig: \"Fast way to keep moving. Bad way to remember %s.\"" % display_name


static func pass_result_quig() -> String:
	return "Quig: \"If it leaves, it leaves hungry.\""


static func reward_locked_effect_body(effect_text: String) -> String:
	return "Not enough DNA.\n\n%s" % effect_text


static func format_eat_effect(effect: Dictionary) -> String:
	var effect_type: String = String(effect.get("type", ""))
	var value: float = float(effect.get("value", 0.0))
	match effect_type:
		"damage_flat":
			return "+%.0f permanent attack damage" % value
		"hp_restore":
			return "restores %.0f HP immediately - no permanent bonus" % value
		"max_hp_flat":
			return "+%.0f max HP immediately" % value
		"support_charge":
			return "+%.0f support charge immediately" % value
		_:
			return "absorb its essence"


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
	match effect_id:
		"ashclaw_strike":
			return "On perfect strike"
		"bond_remnant_mend":
			return "On damage taken"
		"gruvek_gorge":
			return "On enemy kill"
		"veilskin_phase":
			return "On perfect parry"
		"thornback_rend":
			return "On perfect strike"
		"knellspine_peal":
			return "On good timing"
		"marrowward_ward":
			return "On player dodge"
		"gorefane_maul":
			return "On ultimate"
		"hushcoil_lull":
			return "On perfect parry"
		"coldvein_expose":
			return "On perfect parry"
		"siltgrip_drag":
			return "On enemy kill"
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

	if parts.is_empty():
		return tendency_summary(tendency_id)
	return ", ".join(PackedStringArray(parts))
