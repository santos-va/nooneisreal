extends SceneTree
var failures: int = 0
var checks: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("NPC: " + label)
func _run() -> void:
	var model = load("res://scripts/npc/NpcPopulation.gd").new()
	model.initialize(123456)
	var identity: Dictionary = model.people[0].duplicate(true)
	var other = load("res://scripts/npc/NpcPopulation.gd").new()
	other.initialize(123456)
	check(model.snapshot() == other.snapshot(), "same seed generates same identities")
	other.initialize(456789)
	check(model.people[0].appearance_seed != other.people[0].appearance_seed, "world seeds differ")
	other.initialize(123456)
	for contact: int in 12:
		model.meet(1)
	for i: int in 1000:
		model.step()
		other.step()
	check(not other.people.any(func(p: Dictionary) -> bool: return p.opportunity), "without actual support no opportunity")
	check(model.people[0].appearance_seed == identity.appearance_seed, "time cannot change appearance")
	check(model.people[0].memory.size() <= 12, "bounded memory")
	check(model.people.any(func(p: Dictionary) -> bool: return p.opportunity), "rare positive transition occurs")
	var text: String = model.meet(0)
	check(text.contains("№1") and model.people[0].trust == 1, "conversation uses persistent meeting fact")
	var path: String = "user://npc_test_save.json"
	check(model.save_to(path), "atomic save")
	check(other.load_from(path), "load save")
	check(model.snapshot() == other.snapshot(), "roundtrip equality")
	var bad: Dictionary = model.snapshot()
	bad.people[0].appearance_seed += 1
	check(not other.restore(bad), "reject identity tampering")
	bad = model.snapshot()
	bad.people[0].memory.append({"tick": -1, "kind": "meeting", "text": "bad"})
	check(not other.restore(bad), "reject invalid memory")
	bad = model.snapshot()
	bad.people[0].energy = "oops"
	check(not other.restore(bad), "reject invalid scalar")
	check(not other.restore([]), "reject invalid document")
	check(model.snapshot() == other.snapshot(), "failed load cannot partly mutate")
	var gateway = load("res://scripts/npc/NpcDecisionGateway.gd").new()
	var request: Dictionary = gateway.begin(model.people[0], 10)
	check(gateway.resolve({"npc_id": request.npc_id, "action": "walk", "fact_tick": model.tick}, 20) == "walk", "grounded proposal accepted")
	gateway.begin(model.people[0], 10)
	check(gateway.resolve({"npc_id": request.npc_id, "action": "walk", "fact_tick": model.tick}, 2000) == "rest", "timeout fallback")
	gateway.begin(model.people[0], 10)
	check(gateway.resolve({"npc_id": request.npc_id, "action": "kill", "fact_tick": model.tick}, 20) == "rest", "unlisted action rejected")
	gateway.begin(model.people[0], 10)
	check(gateway.resolve({"npc_id": request.npc_id, "action": "walk", "fact_tick": -5}, 20) == "rest", "invented fact rejected")
	DirAccess.remove_absolute(path)
	print("[npc] %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
