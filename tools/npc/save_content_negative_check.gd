extends SceneTree
## Independent adversarial validation: reject malformed payloads without partial mutation.
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("T4_NEGATIVE %s=%s" % [label, ok])
	if not ok:
		failures += 1
		push_error(label)
func _run() -> void:
	var Model = load("res://scripts/npc/CityProgress.gd")
	var Population = load("res://scripts/npc/NpcPopulation.gd")
	var m = Model.new()
	m.setup("choko", false)
	m.save_enabled = false
	m.accept_quest("introductions")
	var stable: Dictionary = m.snapshot()
	for n in 9:
		var bad: Dictionary = stable.duplicate(true)
		match n:
			0: bad.heroes.choko.credits = NAN
			1: bad.heroes.choko.completed = ["parcel"]
			2: bad.heroes.choko.events = {"visit": ["res://fake.tscn"]}
			3: bad.heroes.choko.events = {"meet": ["resident_99"]}
			4: bad.heroes.choko.events = {"rope": ["anchor_0", "anchor_0"]}
			5: bad.heroes.choko.owned = ["original", "unregistered"]
			6: bad.heroes.choko.palette = "mint"; bad.heroes.choko.owned = ["original"]
			7: bad.heroes.choko.accepted = ["introductions", "introductions"]
			8: bad.heroes["unknown"] = bad.heroes.choko.duplicate(true)
		check(not m.restore(bad) and m.snapshot() == stable, "invalid progress preserves prior state %d" % n)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Model.CONTENT_PATH))
	var stable_content: Array = m.quests.duplicate(true)
	for n in 8:
		var bad: Dictionary = content.duplicate(true)
		match n:
			0: bad.quests[0].goals[0]["script"] = "res://execute.gd"
			1: bad.quests[0].goals[0].kind = "call"
			2: bad.quests[0].goals[0].id = "../resident_00"
			3: bad.quests[0].requires = ["parcel"]
			4: bad.quests[0].goals[0].count = 2
			5: bad.quests[3].goals[0].count = 5
			6: bad.palettes[0]["resource"] = "res://untrusted.tres"
			7: bad.quests[1].id = bad.quests[0].id
		check(not m.configure(bad) and m.quests == stable_content, "invalid declarative content rejected atomically %d" % n)
	var dense: Dictionary = content.duplicate(true)
	dense.quests.clear()
	for index in 24:
		var q: Dictionary = content.quests[0].duplicate(true)
		q.id = "q%02d" % index
		q.requires = []
		for later in range(index+1,24):
			q.requires.append("q%02d" % later)
		dense.quests.append(q)
	var begin: int = Time.get_ticks_usec()
	check(m.configure(dense), "dense acyclic 24-node content graph accepted")
	var dense_saved: Array = m.quests.duplicate(true)
	dense.quests[23].requires = ["q00"]
	check(not m.configure(dense) and m.quests == dense_saved, "dense graph cycle rejected atomically")
	print("T4_NEGATIVE dense_graph_total_usec=%d" % (Time.get_ticks_usec()-begin))
	var p = Population.new()
	p.initialize(812341)
	p.meet(0,"choko")
	p.bond_once(0,"choko","work","Ми поговорили.")
	var saved: Dictionary = p.snapshot()
	check(p.restore(JSON.parse_string(JSON.stringify(saved))), "independent JSON v2 roundtrip")
	for n in 3:
		var bad: Dictionary = saved.duplicate(true)
		match n:
			0: bad.relationships.choko.resident_00.trust = -1
			1: bad.relationships.choko.resident_00.memory = [{"script":"bad"}]
			2: bad.relationships.choko["resident_99"] = bad.relationships.choko.resident_00
		check(not p.restore(bad) and p.snapshot() == saved, "invalid relationship cannot partially overwrite %d" % n)
	m.free()
	print("T4_NEGATIVE_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
