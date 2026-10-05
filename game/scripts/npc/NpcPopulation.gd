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
var relationships: Dictionary = {}

func initialize(seed_value: int) -> void:
	world_seed = clampi(seed_value, 1, 2147483646)
	tick = 0
	community_support = 0
	people.clear()
	relationships.clear()
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

func _legacy_meet(index: int) -> String:
	var p: Dictionary = people[index]
	p.meetings = int(p.meetings) + 1
	p.trust = mini(int(p.trust) + 1, 10)
	community_support = mini(community_support + 1, 100)
	remember(index, "meeting", "Ми зустрілися в районі. Це наша зустріч №%d." % int(p.meetings), "player")
	return _legacy_dialogue(index)

func relationship(index: int, hero: String) -> Dictionary:
	if hero not in ["choko", "skea"] or index < 0 or index >= people.size():
		return {}
	if not relationships.has(hero):
		relationships[hero] = {}
	var id: String = people[index].id
	if not relationships[hero].has(id):
		relationships[hero][id] = {"trust": 0, "meetings": 0, "memory": [], "topics": []}
	return relationships[hero][id]

func meet(index: int, hero: String = "") -> String:
	# An omitted hero keeps old tooling compatible; live city always supplies its hero.
	if hero.is_empty():
		return _legacy_meet(index)
	var bond := relationship(index, hero)
	if bond.is_empty():
		return ""
	bond.meetings = mini(int(bond.meetings) + 1, 100000000)
	bond_once(index, hero, "introduction", "Ми познайомилися особисто.")
	return dialogue(index, hero)

func bond_once(index: int, hero: String, topic: String, fact: String, amount: int = 1) -> bool:
	var bond := relationship(index, hero)
	if bond.is_empty() or topic in bond.topics or bond.topics.size() >= 32:
		return false
	bond.topics.append(topic)
	bond.trust = mini(int(bond.trust) + clampi(amount, 0, 2), 10)
	bond.memory.append(fact.left(256))
	while bond.memory.size() > MEMORY_LIMIT:
		bond.memory.pop_front()
	return true

func dialogue(index: int, hero: String = "") -> String:
	if hero.is_empty():
		return _legacy_dialogue(index)
	var p: Dictionary = people[index]
	var bond := relationship(index, hero)
	var relation: String = "друзі" if int(bond.trust) >= 6 else ("довіра" if int(bond.trust) >= 3 else "знайомі")
	var lines: Array[String] = [str(p.name) + " · " + hero.capitalize(), relation + " · " + str(bond.trust) + "/10"]
	for fact: String in bond.memory:
		lines.append(fact)
	return "\n\n".join(lines)

func greet(index: int, other: int) -> Array[String]:
	if index == other or index < 0 or other < 0 or index >= people.size() or other >= people.size():
		return []
	var first: Dictionary = people[index]
	var second: Dictionary = people[other]
	remember(index, "neighbour", "Перекинувся словами з " + str(second.name) + ": зараз " + str(second.goal) + ".")
	remember(other, "neighbour", "Перекинувся словами з " + str(first.name) + ": зараз " + str(first.goal) + ".")
	return ["Привіт, " + str(second.name) + "!", "Привіт! Зараз " + str(second.goal) + "."]

func _legacy_dialogue(index: int) -> String:
	var p: Dictionary = people[index]
	var lines: Array[String] = [str(p.name) + " · " + str(p.role), "Зараз: " + str(p.goal) + "."]
	var memory: Array = p.memory
	var count: int = mini(1 + int(p.trust) / 2, 4)
	for offset: int in mini(count, memory.size()):
		lines.append(str(memory[memory.size() - 1 - offset].text))
	return "\n\n".join(lines)

func snapshot() -> Dictionary:
	return {"version": 2, "world_seed": world_seed, "tick": tick, "community_support": community_support, "people": people.duplicate(true), "relationships": relationships.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if not _integer(data.get("version"), 1, 2) or not _integer(data.get("world_seed"), 1, 2147483646) or not _integer(data.get("tick"), 0, 100000000):
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
		if not _integer(p.get("appearance_seed"), 1, 2147483646) or int(p.appearance_seed) != int(expected.people[index].appearance_seed):
			return false
		for key: String in ["id", "name", "role"]:
			if not p.get(key) is String or p[key] != expected.people[index][key]:
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
	var incoming: Variant = data.get("relationships", {}) if data.version == 2 else {}
	if not incoming is Dictionary or incoming.size() > 2:
		return false
	for hero: Variant in incoming:
		if hero not in ["choko", "skea"] or not incoming[hero] is Dictionary or incoming[hero].size() > COUNT:
			return false
		for id: Variant in incoming[hero]:
			if not id is String or not records.any(func(p: Dictionary) -> bool: return p.id == id):
				return false
			var bond: Variant = incoming[hero][id]
			if not bond is Dictionary or not _integer(bond.get("trust"), 0, 10) or not _integer(bond.get("meetings"), 0, 100000000) or not bond.get("memory") is Array or bond.memory.size() > MEMORY_LIMIT or not bond.get("topics") is Array or bond.topics.size() > 32:
				return false
			for fact: Variant in bond.memory:
				if not fact is String or fact.length() > 256:
					return false
			for topic: Variant in bond.topics:
				if not topic is String or topic.length() > 80:
					return false
	# v1 player history has no hero identity: retain it as legacy, never attribute it.
	relationships = incoming.duplicate(true)
	for residents: Dictionary in relationships.values():
		for bond: Dictionary in residents.values():
			bond.trust = int(bond.trust)
			bond.meetings = int(bond.meetings)
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
	var parser := JSON.new()
	return parser.parse(file.get_as_text()) == OK and restore(parser.data)
