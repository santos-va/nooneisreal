extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DISTRICT: " + label)
func _run() -> void:
	var model := CityProgress.new()
	model.setup("choko", false)
	model.save_enabled = false
	check(model.quests.size() == 6, "six valid declarative quests")
	check(model.quest_status("parcel") == "locked", "prerequisite prevents premature parcel")
	model.record_event("deliver", "thread_parcel")
	check(not model.heroes.choko.events.has("deliver"), "parcel cannot be delivered before acceptance")
	check(model.accept_quest("introductions"), "accept first quest")
	check(not model.complete_quest("introductions"), "cannot complete before actual objectives")
	for index: int in 3:
		model.record_event("meet", "resident_%02d" % index)
	check(model.quest_status("introductions") == "ready", "all distinct workers required")
	check(model.complete_quest("introductions"), "turn in ready quest")
	var credits: int = model.summary().credits
	check(not model.complete_quest("introductions") and model.summary().credits == credits, "repeat turn-in cannot mint currency")
	model.accept_quest("parcel")
	model.record_event("deliver", "thread_parcel")
	check(model.complete_quest("parcel"), "explicit parcel delivery completes accepted task")
	model.accept_quest("roof_walk")
	model.visit_landmark("roof_bridge")
	model.visit_landmark("clock_tower")
	check(model.complete_quest("roof_walk"), "both roof locations required")
	model.accept_quest("rope_route")
	model.record_event("rope", "anchor_0")
	model.record_event("rope", "anchor_0")
	check(model.quest_status("rope_route") == "active", "same rope anchor cannot count twice")
	model.record_event("rope", "anchor_1")
	check(model.complete_quest("rope_route"), "two actual distinct anchors complete route")
	model.accept_quest("neighbours")
	for index: int in range(3, 7):
		model.record_event("resident", "resident_%02d" % index)
	check(model.complete_quest("neighbours"), "four distinct outdoor neighbours")
	model.accept_quest("own_style")
	check(model.set_palette("mint"), "free cosmetic equipped")
	model.visit_landmark("market_court")
	check(model.complete_quest("own_style") and model.summary().completed == 6, "all six reachable without timer or fake action")
	check(model.set_palette("amber"), "earned currency buys cloth style")
	credits = model.summary().credits
	model.set_palette("amber")
	check(model.summary().credits == credits, "owned cosmetic does not charge twice")
	var completed_choko: Dictionary = model.heroes.choko.duplicate(true)
	model.hero_id = "skea"
	model._ensure_hero()
	check(model.summary().completed == 0 and model.summary().credits == 0 and model.summary().palette == "original", "second hero starts independently")
	check(not model.set_palette("plum"), "unearned paid style denied")
	model.accept_quest("introductions")
	check(model.heroes.choko == completed_choko, "second hero cannot mutate first hero")
	var other := CityProgress.new()
	other.setup("choko", false)
	other.save_enabled = false
	check(other.restore(JSON.parse_string(JSON.stringify(model.snapshot()))), "JSON progress roundtrip")
	check(other.snapshot() == model.snapshot(), "all heroes preserved by save roundtrip")
	model.save_enabled = true
	model.save_path = "user://district_progress_test_v1.json"
	check(model.persist(), "atomic progress write to disk")
	var disk_model := CityProgress.new()
	disk_model.setup("choko", true, model.save_path)
	check(disk_model.snapshot() == model.snapshot(), "actual disk resume preserves both heroes")
	var broken := FileAccess.open(model.save_path, FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	var damaged := CityProgress.new()
	damaged.setup("choko", true, model.save_path)
	damaged.accept_quest("introductions")
	check(not damaged.save_enabled and FileAccess.get_file_as_string(model.save_path) == "{broken", "damaged save retained instead of overwritten")
	DirAccess.remove_absolute(model.save_path)
	model.save_enabled = false
	disk_model.free()
	damaged.free()
	var stable: Dictionary = other.snapshot()
	for attack: int in 4:
		var bad: Dictionary = model.snapshot()
		if attack == 0:
			bad.heroes.choko.credits = -1
		elif attack == 1:
			bad.heroes.choko.completed.append("introductions")
		elif attack == 2:
			bad.heroes.choko.events.rope.append("unknown_anchor")
		else:
			bad.heroes.invented_hero = bad.heroes.choko
		check(not other.restore(bad) and other.snapshot() == stable, "malformed progress cannot partially overwrite %d" % attack)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CityProgress.CONTENT_PATH))
	for attack: int in 4:
		var bad: Dictionary = content.duplicate(true)
		if attack == 0:
			bad.quests[0]["script"] = "res://untrusted.gd"
		elif attack == 1:
			bad.quests[0].requires = ["parcel"]
		elif attack == 2:
			bad.quests[0].goals[0].count = 2
		else:
			bad.quests[0].goals[0].id = "unknown_resident"
		check(not model.configure(bad), "content whitelist rejects code/cycle/impossible goal %d" % attack)
	var population := NpcPopulation.new()
	population.initialize(123456)
	population.meet(3, "choko")
	for topic: String in ["work", "district", "route", "neighbours"]:
		population.bond_once(3, "choko", topic, "Ми поговорили про " + topic + ".", 2 if topic in ["route", "neighbours"] else 1)
	check(population.relationship(3, "choko").trust >= 6 and population.dialogue(3, "choko").contains("друзі"), "ordinary resident friendship is reachable")
	var trust: int = population.relationship(3, "choko").trust
	check(not population.bond_once(3, "choko", "work", "repeat") and population.relationship(3, "choko").trust == trust, "repeated topic cannot farm friendship")
	check(population.relationship(3, "skea").trust == 0 and population.relationship(3, "skea").memory.is_empty(), "friendship and memories isolated per hero")
	var restored := NpcPopulation.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(population.snapshot()))), "v2 relationship save roundtrip")
	var npc_path: String = "user://district_npc_test_v2.json"
	check(population.save_to(npc_path) and restored.load_from(npc_path) and restored.snapshot() == population.snapshot(), "actual v2 NPC disk roundtrip preserves hero memories")
	DirAccess.remove_absolute(npc_path)
	var legacy: Dictionary = population.snapshot()
	legacy.version = 1
	legacy.erase("relationships")
	legacy.people[3].trust = 8
	legacy.people[3].meetings = 10
	check(restored.restore(legacy), "legacy v1 accepted")
	check(restored.people[3].trust == 8 and restored.relationship(3, "choko").trust == 0 and restored.relationship(3, "skea").trust == 0, "unknown legacy hero history remains unassigned")
	model.free()
	other.free()
	print("[district-progress] %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
