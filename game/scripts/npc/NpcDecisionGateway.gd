class_name NpcDecisionGateway
extends RefCounted
## Opt-in adapter seam: an external local backend may submit a bounded proposal.
## No networking, model installation or authority over identity/facts is implicit.
const TIMEOUT_MS: int = 1000 # PLACEHOLDER responsiveness budget.
const ACTIONS: Array[String] = ["work", "walk", "rest"]
var pending_id: String = ""
var deadline_ms: int = 0
var allowed_fact_ticks: Array[int] = []

func begin(person: Dictionary, now_ms: int) -> Dictionary:
	pending_id = str(person.id)
	deadline_ms = now_ms + TIMEOUT_MS
	allowed_fact_ticks.clear()
	for fact: Dictionary in person.memory:
		allowed_fact_ticks.append(int(fact.tick))
	return {"npc_id": pending_id, "actions": ACTIONS.duplicate(), "facts": person.memory.duplicate(true), "energy": person.energy}

func resolve(proposal: Variant, now_ms: int) -> String:
	var result: String = "rest"
	if not pending_id.is_empty() and now_ms <= deadline_ms and proposal is Dictionary:
		if proposal.get("npc_id") == pending_id and proposal.get("action") in ACTIONS and proposal.get("fact_tick") in allowed_fact_ticks:
			result = str(proposal.action)
	pending_id = ""
	allowed_fact_ticks.clear()
	return result
