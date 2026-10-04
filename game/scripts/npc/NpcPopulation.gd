class_name NpcPopulation
extends RefCounted
## Bounded, deterministic facts. Runtime actors and text cannot mutate identity.
const COUNT: int = 12
const MEMORY_LIMIT: int = 12
const SAVE_PATH: String = "user://city_population_v1.json"
const ROLES: Array[String] = ["ремісник", "кур'єр", "торговець", "вуличний музикант"]
const NAMES: Array[String] = ["Міра", "Тарас", "Лада", "Дан", "Сол", "Ніка", "Рен", "Яра", "Лев", "Іва", "Марко", "Ася"]
var world_seed: int
var tick: int = 0
var community_support: int = 0
var people: Array[Dictionary] = []

func initialize(seed_value: int) -> void:
	world_seed = clampi(seed_value, 1, 2147483646)
	tick = 0
	community_support = 0
	people.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed
	for index: int in COUNT:
		var person: Dictionary = {"id": "resident_%02d" % index, "appearance_seed": rng.randi_range(1, 2147483646),
			"name": NAMES[index], "role": ROLES[rng.randi_range(0, ROLES.size() - 1)],
			"goal": "відпочиває", "energy": 80, "trust": 0, "opportunity": false, "memory": [], "meetings": 0}
		people.append(person)
		remember(index, "arrival", "Живу в цьому районі й працюю: " + str(person.role) + ".")

func remember(index: int, kind: String, fact: String, source: String = "district") -> void:
	var memory: Array = people[index].memory
	memory.append({"tick": tick, "kind": kind, "text": fact, "source": source})
	while memory.size() > MEMORY_LIMIT:
		memory.pop_front()

func step() -> void:
	tick += 1
	for index: int in people.size():
		var p: Dictionary = people[index]
		var phase: int = (tick + index * 2) % 24
		var next_goal: String = "працює" if phase < 10 else ("гуляє районом" if phase < 16 else "відпочиває")
		# Support is a changing fictional neighbourhood condition, independent of appearance.
		var support: int = mini(community_support / 4, 3)
		p.energy = clampi(int(p.energy) + (5 + support if next_goal == "відпочиває" else -2), 0, 100)
		if int(p.energy) < 15:
			next_goal = "відпочиває"
		if p.goal != next_goal:
			p.goal = next_goal
			remember(index, "routine", "Зараз " + next_goal + ".")
		if community_support >= 4 and not bool(p.opportunity) and (world_seed + tick * 17 + index * 131) % 997 == 0:
			p.opportunity = true
			community_support -= 4
			remember(index, "opportunity", "Скористався підтримкою району, щоб почати вчитися новому ремеслу.")

func meet(index: int) -> String:
	var p: Dictionary = people[index]
	p.meetings = int(p.meetings) + 1
	p.trust = mini(int(p.trust) + 1, 10)
	community_support = mini(community_support + 1, 100)
	remember(index, "meeting", "Ми зустрілися в районі. Це наша зустріч №%d." % int(p.meetings), "player")
	return dialogue(index)

func greet(index: int, other: int) -> Array[String]:
	if index == other or index < 0 or other < 0 or index >= people.size() or other >= people.size():
		return []
	var first: Dictionary = people[index]
	var second: Dictionary = people[other]
	remember(index, "neighbour", "Перекинувся словами з " + str(second.name) + ": зараз " + str(second.goal) + ".")
	remember(other, "neighbour", "Перекинувся словами з " + str(first.name) + ": зараз " + str(first.goal) + ".")
	return ["Привіт, " + str(second.name) + "!", "Привіт! Зараз " + str(second.goal) + "."]

func dialogue(index: int) -> String:
	var p: Dictionary = people[index]
	var lines: Array[String] = [str(p.name) + " · " + str(p.role), "Зараз: " + str(p.goal) + "."]
	var memory: Array = p.memory
	var count: int = mini(1 + int(p.trust) / 2, 4)
	for offset: int in mini(count, memory.size()):
		lines.append(str(memory[memory.size() - 1 - offset].text))
	return "\n\n".join(lines)

func snapshot() -> Dictionary:
	return {"version": 1, "world_seed": world_seed, "tick": tick, "community_support": community_support, "people": people.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if data.get("version") != 1 or not _integer(data.get("world_seed"), 1, 2147483646) or not _integer(data.get("tick"), 0, 100000000):
		return false
	if not _integer(data.get("community_support"), 0, 100):
		return false
	var records: Variant = data.get("people")
	if not records is Array or records.size() != COUNT:
		return false
	var expected := NpcPopulation.new()
	expected.initialize(int(data.world_seed))
	for index: int in COUNT:
		var p: Variant = records[index]
		if not p is Dictionary:
			return false
		for key: String in ["id", "appearance_seed", "name", "role"]:
			if p.get(key) != expected.people[index][key]:
				return false
		if p.get("goal") not in ["працює", "гуляє районом", "відпочиває"]:
			return false
		if not _integer(p.get("energy"), 0, 100) or not _integer(p.get("trust"), 0, 10) or not _integer(p.get("meetings"), 0, 100000000) or not p.get("opportunity") is bool:
			return false
		if not p.get("memory") is Array or p.memory.size() > MEMORY_LIMIT:
			return false
		for fact: Variant in p.memory:
			if not fact is Dictionary or not _integer(fact.get("tick"), 0, int(data.tick)):
				return false
			if fact.get("source") not in ["district", "player"]:
				return false
			if fact.get("kind") not in ["arrival", "routine", "meeting", "opportunity", "neighbour"] or not fact.get("text") is String or fact.text.length() > 256:
				return false
	world_seed = int(data.world_seed)
	tick = int(data.tick)
	community_support = int(data.community_support)
	people.assign(records.duplicate(true))
	for p: Dictionary in people:
		for key: String in ["appearance_seed", "energy", "trust", "meetings"]:
			p[key] = int(p[key])
		for fact: Dictionary in p.memory:
			fact.tick = int(fact.tick)
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

func save_to(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func load_from(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 262144:
		return false
	return restore(JSON.parse_string(file.get_as_text()))
