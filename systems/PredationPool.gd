extends RefCounted

## Between-level DNA / creature offers (v1). Structural only — not live combat rewards.

const COMBAT_DATA = preload("res://data/CombatContent.gd")

const KIND_DEEPEN: String = "deepen_bond"
const KIND_TITHE: String = "flesh_tithe"
const KIND_SUPPORT: String = "support_reserve"
const KIND_MUTATION: String = "mutation_stitch"


static func _creature_name(species_id: String) -> String:
	if species_id.is_empty():
		return "?"
	var c: Dictionary = COMBAT_DATA.get_creature(species_id)
	if c.is_empty():
		return species_id
	return String(c.get("display_name", species_id))


static func _threshold_for(species_id: String) -> float:
	var c: Dictionary = COMBAT_DATA.get_creature(species_id)
	return maxf(1.0, float(c.get("dna_threshold", 8.0)))


static func build_offers(max_offers: int = 3) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if max_offers <= 0:
		return out

	# 1) Deepen an existing bond (same DNA vocabulary as live bond gate).
	var deepen_order: Array[Dictionary] = []
	var act: Dictionary = GameState.get_active_bonded_creature()
	if not act.is_empty():
		deepen_order.append(act)
	for creature in GameState.roster:
		var rid: String = String(creature.get("species_id", ""))
		if not act.is_empty() and rid == String(act.get("species_id", "")):
			continue
		deepen_order.append(creature)
	for creature in deepen_order:
		var sid: String = String(creature.get("species_id", ""))
		if sid.is_empty():
			continue
		var bl: int = int(creature.get("bond_level", 1))
		if bl >= 5:
			continue
		var th: float = _threshold_for(sid)
		if not GameState.has_dna_for(sid, th):
			continue
		var nm: String = _creature_name(sid)
		out.append({
			"predation_kind": KIND_DEEPEN,
			"species_id": sid,
			"dna_cost": th,
			"tag": "BOND",
			"title": "%s — deepen pact" % nm,
			"summary": (
				"Spend %.0f %s DNA to raise bond (L%d → L%d). Their instincts stay beside you."
				% [th, nm, bl, min(bl + 1, 5)]
			),
		})
		break

	if out.size() >= max_offers:
		return out.slice(0, max_offers)

	# 2) Stitch eaten work — restore mutation charges using that species' DNA trail.
	for mut in GameState.active_mutations:
		var mid: String = String(mut.get("id", ""))
		if mid.is_empty():
			continue
		var src: String = String(mut.get("source_species_id", ""))
		if src.is_empty():
			continue
		var effect: Dictionary = mut.get("effect", {})
		var cap: int = int(effect.get("charges", 0))
		var cur: int = int(mut.get("current_charges", 0))
		if cap <= 0 or cur >= cap:
			continue
		var th2: float = _threshold_for(src)
		var cost: float = maxf(4.0, float(int(ceil(th2 * 0.28))))
		if not GameState.has_dna_for(src, cost):
			continue
		var mname: String = String(mut.get("display_name", mid))
		var nm2: String = _creature_name(src)
		out.append({
			"predation_kind": KIND_MUTATION,
			"species_id": src,
			"mutation_id": mid,
			"dna_cost": cost,
			"tag": "INNER WORK",
			"title": "%s — stitch %s" % [nm2, mname],
			"summary": (
				"Spend %.0f %s DNA to restore inner charges (now %d / %d)."
				% [cost, nm2, cur, cap]
			),
		})
		break

	if out.size() >= max_offers:
		return out.slice(0, max_offers)

	# 3) Reinforce support charge from the active bond's species reservoir.
	var active: Dictionary = GameState.get_active_bonded_creature()
	var aid: String = String(active.get("species_id", ""))
	if not aid.is_empty():
		var scost: float = 5.0
		if GameState.has_dna_for(aid, scost):
			var nm3: String = _creature_name(aid)
			out.append({
				"predation_kind": KIND_SUPPORT,
				"species_id": aid,
				"dna_cost": scost,
				"tag": "SUPPORT",
				"title": "%s — lend voltage" % nm3,
				"summary": (
					"Spend %.0f %s DNA to pour charge into the bond layer (+38 support charge)."
					% [scost, nm3]
				),
			})

	if out.size() >= max_offers:
		return out.slice(0, max_offers)

	# 4) Flesh tithe — convert stored DNA into body (no bond required on that species).
	var best_sid: String = ""
	var best_amt: float = -1.0
	for k in GameState.dna_by_species.keys():
		var sid3: String = String(k)
		var amt: float = GameState.get_dna(sid3)
		if amt > best_amt:
			best_amt = amt
			best_sid = sid3
	if not best_sid.is_empty():
		var th3: float = _threshold_for(best_sid)
		var tcost: float = clampf(float(int(ceil(th3 * 0.38))), 5.0, 18.0)
		if GameState.has_dna_for(best_sid, tcost):
			var nm4: String = _creature_name(best_sid)
			var pct: int = 22
			out.append({
				"predation_kind": KIND_TITHE,
				"species_id": best_sid,
				"dna_cost": tcost,
				"tag": "BODY",
				"title": "%s — flesh tithe" % nm4,
				"summary": (
					"Spend %.0f %s DNA; their trace mends you (~%d%% max HP)."
					% [tcost, nm4, pct]
				),
			})

	return out.slice(0, max_offers)


static func apply_choice(choice: Dictionary, run_growth: Node) -> bool:
	var kind: String = String(choice.get("predation_kind", ""))
	var sid: String = String(choice.get("species_id", ""))
	var cost: float = float(choice.get("dna_cost", 0.0))
	if kind.is_empty() or sid.is_empty() or cost <= 0.0:
		return false
	if not GameState.has_dna_for(sid, cost):
		return false

	match kind:
		KIND_DEEPEN:
			var th: float = _threshold_for(sid)
			if cost + 0.001 < th:
				return false
			var bonded: Dictionary = GameState.get_bonded_creature(sid)
			if bonded.is_empty():
				return false
			if int(bonded.get("bond_level", 1)) >= 5:
				return false
			if not GameState.has_method("deepen_lair_bond"):
				return false
			var updated: Dictionary = GameState.deepen_lair_bond(sid, 1)
			if updated.is_empty():
				return false
			GameState.spend_dna(sid, cost)
			return true
		KIND_TITHE:
			GameState.spend_dna(sid, cost)
			var heal: float = GameState.player_max_hp * 0.22
			GameState.heal_player(heal)
			return true
		KIND_SUPPORT:
			GameState.spend_dna(sid, cost)
			if run_growth != null and is_instance_valid(run_growth) and run_growth.has_method("gain_reward_support_charge"):
				run_growth.call("gain_reward_support_charge", 38.0)
			return true
		KIND_MUTATION:
			var mid: String = String(choice.get("mutation_id", ""))
			if mid.is_empty():
				return false
			GameState.spend_dna(sid, cost)
			var cap2: int = 0
			for m in GameState.active_mutations:
				if String(m.get("id", "")) != mid:
					continue
				var eff: Dictionary = m.get("effect", {})
				cap2 = int(eff.get("charges", 0))
				break
			var restore: int = maxi(1, int(ceil(cap2 * 0.4))) if cap2 > 0 else 3
			GameState.restore_mutation_charges(mid, restore)
			return true
		_:
			return false
