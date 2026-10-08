class_name CityProgress
extends Node
## Declarative district objectives. No content entry may execute a script or load a resource.
signal changed
const SAVE_PATH := "user://city_progress_v1.json"
const CONTENT_PATH := "res://data/city/district.json"
const HEROES: Array[String] = ["choko", "skea"]
const EVENT_KINDS: Array[String] = ["meet", "resident", "visit", "deliver", "rope", "palette"]
## Tokens are the city's money (ADR-025 п. 3): the save bound of credits, and the faces a hero remembers from the city
## events (plan 2026-10-08-City-Events-Stage-1, step 2): face id → tokens that face took from this hero (0 = met only).
const CREDIT_LIMIT: int = 10000
const FACE_LIMIT: int = 16
var hero_id: String = "choko"
var heroes: Dictionary = {}
var quests: Array[Dictionary] = []
var palettes: Array[Dictionary] = []
var save_enabled: bool = true
var save_ok: bool = true
var save_path: String = SAVE_PATH

func setup(selected_hero: String, disk: bool = true, path: String = SAVE_PATH) -> void:
	save_path = path
	hero_id = selected_hero if selected_hero in HEROES else "choko"
	if selected_hero not in HEROES:
		save_enabled = false
		save_ok = false
	if not load_content(CONTENT_PATH):
		save_enabled = false
		save_ok = false
		push_error("District content failed validation; saving disabled.")
	if disk and FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file == null or file.get_length() > 262144 or not restore(_parse_json(file.get_as_text())):
			save_enabled = false
			save_ok = false
	_ensure_hero()

func _ensure_hero() -> void:
	if not heroes.has(hero_id):
		heroes[hero_id] = {"accepted": [], "completed": [], "events": {}, "credits": 0, "palette": "original", "owned": ["original", "mint"]}

func load_content(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return false
	return configure(_parse_json(file.get_as_text()))

func configure(data: Variant) -> bool:
	if not data is Dictionary or data.keys().size() != 3 or not NpcPopulation._integer(data.get("version"), 1, 1) or not data.get("quests") is Array or not data.get("palettes") is Array:
		return false
	if data.quests.size() > 24 or data.palettes.size() > 16:
		return false
	var ids: Array[String] = []
	for q: Variant in data.quests:
		if not q is Dictionary or q.keys().size() != 8:
			return false
		for key: String in ["id", "giver", "title", "description", "hint"]:
			if not q.get(key) is String or q[key].length() > 600:
				return false
		if not _safe_id(q.id) or q.id in ids or q.giver not in ["grocer", "tailor", "workshop"] or not q.get("requires") is Array or not q.get("goals") is Array or not NpcPopulation._integer(q.get("reward"), 0, 20):
			return false
		ids.append(q.id)
		if q.goals.is_empty() or q.goals.size() > 8:
			return false
		for goal: Variant in q.goals:
			if not goal is Dictionary or goal.keys().size() != 3 or goal.get("kind") not in EVENT_KINDS or not goal.get("id") is String or (goal.id != "*" and not _event_id_valid(goal.kind, goal.id)) or not NpcPopulation._integer(goal.get("count"), 1, 12):
				return false
			var maximum: int = {"meet": 12, "resident": 9, "visit": 6, "deliver": 1, "rope": 4, "palette": 4}[goal.kind]
			if int(goal.count) > maximum or (goal.id != "*" and int(goal.count) != 1):
				return false
	for q: Dictionary in data.quests:
		for required: Variant in q.requires:
			if not required is String or required not in ids or required == q.id:
				return false
	if not _dependencies_acyclic(data.quests):
		return false
	var palette_ids: Array[String] = []
	for p: Variant in data.palettes:
		if not p is Dictionary or p.keys().size() != 4 or not p.get("id") is String or not _safe_id(p.id) or p.id in palette_ids or not p.get("title") is String or p.title.length() > 80 or not p.get("color") is String or not Color.html_is_valid(p.color) or not NpcPopulation._integer(p.get("price"), 0, 20):
			return false
		palette_ids.append(p.id)
	if "original" not in palette_ids or "mint" not in palette_ids:
		return false
	quests.assign(data.quests.duplicate(true))
	palettes.assign(data.palettes.duplicate(true))
	return true

static func _parse_json(text: String) -> Variant:
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

static func _event_id_valid(kind: String, id: String) -> bool:
	if kind == "visit":
		return id in ["grocer", "tailor", "workshop", "roof_bridge", "clock_tower", "market_court"]
	if kind in ["meet", "resident"]:
		for index: int in NpcPopulation.COUNT:
			if id == "resident_%02d" % index:
				return kind == "meet" or index >= 3
		return false
	if kind == "deliver":
		return id == "thread_parcel"
	if kind == "rope":
		# Every district rope anchor counts (plan 2026-10-07-Aim-Free-Rope step 2 appends anchors; indices are stable,
		# so saves naming anchor_0…anchor_3 stay valid). The exact spelling keeps "anchor_01" from doubling anchor_1.
		var suffix := id.trim_prefix("anchor_")
		return id.begins_with("anchor_") and suffix.is_valid_int() and id == "anchor_%d" % int(suffix) \
			and int(suffix) >= 0 and int(suffix) < CityLayout.anchors().size()
	if kind == "palette":
		return id in ["original", "mint", "amber", "plum"]
	return false

static func _dependencies_acyclic(definitions: Array) -> bool:
	# Bounded topological passes avoid exponential recursion in dense mod graphs.
	var resolved: Array[String] = []
	for pass_index: int in definitions.size():
		var before: int = resolved.size()
		for q: Dictionary in definitions:
			if q.id in resolved:
				continue
			var ready: bool = true
			for dependency: String in q.requires:
				if dependency not in resolved:
					ready = false
					break
			if ready:
				resolved.append(q.id)
		if resolved.size() == definitions.size():
			return true
		if resolved.size() == before:
			return false
	return definitions.is_empty()

static func has_saved_hero(hero: String) -> bool:
	if hero not in HEROES or not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null or file.get_length() > 262144:
		return false
	var model := CityProgress.new()
	model.hero_id = hero
	var valid: bool = model.load_content(CONTENT_PATH) and model.restore(_parse_json(file.get_as_text()))
	# restore ensures the selected hero exists, so inspect the document independently.
	file.seek(0)
	var data: Variant = _parse_json(file.get_as_text())
	var present: bool = valid and data.heroes.has(hero)
	model.free()
	return present

static func _safe_id(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	for character: String in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_":
			return false
	return true

func quest(id: String) -> Dictionary:
	for q: Dictionary in quests:
		if q.id == id:
			return q
	return {}

func _count(goal: Dictionary) -> int:
	var events: Dictionary = heroes[hero_id].events
	var values: Array = events.get(goal.kind, [])
	return mini(values.size(), int(goal.count)) if goal.id == "*" else (1 if goal.id in values else 0)

func quest_status(id: String) -> String:
	var q := quest(id)
	if q.is_empty():
		return "locked"
	var profile: Dictionary = heroes[hero_id]
	if id in profile.completed:
		return "completed"
	for required: String in q.requires:
		if required not in profile.completed:
			return "locked"
	if id not in profile.accepted:
		return "available"
	for goal: Dictionary in q.goals:
		if _count(goal) < int(goal.count):
			return "active"
	return "ready"

func accept_quest(id: String) -> bool:
	if quest_status(id) != "available":
		return false
	heroes[hero_id].accepted.append(id)
	_changed()
	return true

func complete_quest(id: String) -> bool:
	if quest_status(id) != "ready":
		return false
	heroes[hero_id].completed.append(id)
	heroes[hero_id].credits += int(quest(id).reward)
	if heroes[hero_id].get("tracked_quest", null) == id:
		heroes[hero_id].erase("tracked_quest")
	_changed()
	return true

func track_quest(id: String) -> bool:
	# An absent field means automatic selection; an empty string is a saved opt-out.
	if not id.is_empty() and quest_status(id) not in ["active", "ready"]:
		return false
	var profile: Dictionary = heroes[hero_id]
	if profile.has("tracked_quest") and profile.tracked_quest == id:
		return true
	profile.tracked_quest = id
	_changed()
	return true

func track_automatically() -> void:
	if heroes[hero_id].has("tracked_quest"):
		heroes[hero_id].erase("tracked_quest")
		_changed()

func tracked_quest_id() -> String:
	var profile: Dictionary = heroes[hero_id]
	if profile.has("tracked_quest"):
		var selected: String = profile.tracked_quest
		return selected if not selected.is_empty() and quest_status(selected) in ["active", "ready"] else ""
	for q: Dictionary in quests:
		if quest_status(q.id) in ["active", "ready"]:
			return q.id
	return ""

func tracking_mode() -> String:
	var profile: Dictionary = heroes[hero_id]
	if not profile.has("tracked_quest"):
		return "auto"
	return "off" if String(profile.tracked_quest).is_empty() else "manual"

func record_event(kind: String, id: String = "") -> void:
	if kind not in EVENT_KINDS or not _event_id_valid(kind, id):
		return
	if kind == "deliver" and (id != "thread_parcel" or quest_status("parcel") != "active"):
		return
	var events: Dictionary = heroes[hero_id].events
	var values: Array = events.get(kind, [])
	if id in values or values.size() >= 64:
		return
	values.append(id)
	events[kind] = values
	_changed()

func visit_landmark(id: String) -> void:
	record_event("visit", id)

func journal() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for q: Dictionary in quests:
		var count: int = 0
		var target: int = 0
		for goal: Dictionary in q.goals:
			count += _count(goal)
			target += int(goal.count)
		entries.append({"id": q.id, "title": q.title, "description": q.description, "hint": q.hint,
			"status": quest_status(q.id), "progress": count, "target": target, "reward": int(q.reward), "tracked": q.id == tracked_quest_id()})
	return entries

func summary() -> Dictionary:
	var title: String = "Знайомство з кварталом"
	var hint: String = "Завітай до крамниць на західній вулиці: там чекають доручення."
	var selected: String = tracked_quest_id()
	if not selected.is_empty():
		var entry: Dictionary = quest(selected)
		title = entry.title
		hint = "Повернися до замовника по нагороду." if quest_status(selected) == "ready" else entry.hint
	elif tracking_mode() == "off":
		title = "Вільна прогулянка"
		hint = "Відстеження вимкнено. Обери доручення в журналі, коли захочеш повернутися до нього."
	if not quests.is_empty() and heroes[hero_id].completed.size() == quests.size():
		title = "Усі доручення кварталу завершено"
		hint = "Нагороди отримано. Можеш далі гуляти, спілкуватися із сусідами й обирати перев’язі."
	return {"hero_id": hero_id, "completed": heroes[hero_id].completed.size(), "total": quests.size(),
		"credits": int(heroes[hero_id].credits), "active_title": title, "active_hint": hint,
		"palette": heroes[hero_id].palette, "save_ok": save_ok,
		"tracked_quest_id": selected, "tracking_mode": tracking_mode()}

func set_palette(id: String) -> bool:
	for p: Dictionary in palettes:
		if p.id != id:
			continue
		var profile: Dictionary = heroes[hero_id]
		if id not in profile.owned:
			if int(profile.credits) < int(p.price):
				return false
			profile.credits -= int(p.price)
			profile.owned.append(id)
		profile.palette = id
		record_event("palette", id)
		_changed()
		return true
	return false

func credits() -> int:
	return int(heroes[hero_id].credits)

## Takes up to `amount` tokens (never below 0) and returns how many were taken. City events: a robbery, food.
func spend_credits(amount: int) -> int:
	var profile: Dictionary = heroes[hero_id]
	var taken: int = mini(maxi(amount, 0), int(profile.credits))
	if taken <= 0:
		return 0
	profile.credits = int(profile.credits) - taken
	_changed()
	return taken

## Adds up to `amount` tokens within the save bound and returns how many were added. City events: small sources.
func earn_credits(amount: int) -> int:
	var profile: Dictionary = heroes[hero_id]
	var added: int = mini(maxi(amount, 0), CREDIT_LIMIT - int(profile.credits))
	if added <= 0:
		return 0
	profile.credits = int(profile.credits) + added
	_changed()
	return added

## Food at «Шавлія» for exactly `price` tokens (plan step 5, `food_price` PLACEHOLDER). False when it cannot be paid.
func buy_food(price: int) -> bool:
	if price < 0 or credits() < price:
		return false
	if price == 0:
		return true
	return spend_credits(price) == price

func face_known(face: String) -> bool:
	return Dictionary(heroes[hero_id].get("faces", {})).has(face)

func face_lost(face: String) -> int:
	return int(Dictionary(heroes[hero_id].get("faces", {})).get(face, 0))

## The hero remembers a face from a city event; `lost` adds the tokens that face took this time.
func remember_face(face: String, lost: int = 0) -> bool:
	if not _safe_id(face) or lost < 0:
		return false
	var profile: Dictionary = heroes[hero_id]
	var faces: Dictionary = profile.get("faces", {})
	if not faces.has(face) and faces.size() >= FACE_LIMIT:
		return false
	faces[face] = mini(int(faces.get(face, 0)) + lost, CREDIT_LIMIT)
	profile.faces = faces
	_changed()
	return true

## A robber who gives up returns what his face took from this hero before (never more). Returns the tokens returned.
func refund_face(face: String) -> int:
	var lost: int = face_lost(face)
	if lost <= 0:
		return 0
	var added: int = earn_credits(lost)
	var faces: Dictionary = heroes[hero_id].faces
	faces[face] = lost - added
	_changed()
	return added

func current_palette() -> Color:
	for p: Dictionary in palettes:
		if p.id == heroes[hero_id].palette:
			return Color.html(p.color)
	return Color.WHITE

func snapshot() -> Dictionary:
	return {"version": 1, "heroes": heroes.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or not NpcPopulation._integer(data.get("version"), 1, 1) or not data.get("heroes") is Dictionary or data.heroes.size() > HEROES.size():
		return false
	for hero: Variant in data.heroes:
		if hero not in HEROES or not data.heroes[hero] is Dictionary:
			return false
		var p: Dictionary = data.heroes[hero]
		if not NpcPopulation._integer(p.get("credits"), 0, CREDIT_LIMIT) or not p.get("accepted") is Array or not p.get("completed") is Array or not p.get("owned") is Array or not p.get("events") is Dictionary or not p.get("palette") is String:
			return false
		for field: String in ["accepted", "completed"]:
			if p[field].size() > quests.size():
				return false
			var seen: Array = []
			for id: Variant in p[field]:
				if not id is String or quest(id).is_empty() or id in seen or (field == "completed" and id not in p.accepted):
					return false
				seen.append(id)
		if p.has("tracked_quest"):
			if not p.tracked_quest is String:
				return false
			if not p.tracked_quest.is_empty():
				var selected: Dictionary = quest(p.tracked_quest)
				if selected.is_empty() or p.tracked_quest not in p.accepted or p.tracked_quest in p.completed:
					return false
				for required: String in selected.requires:
					if required not in p.completed:
						return false
		if p.owned.size() > palettes.size() or p.palette not in p.owned:
			return false
		# Optional since the city events: an absent field is an old save; a present one must be exact.
		if p.has("faces"):
			if not p.faces is Dictionary or p.faces.size() > FACE_LIMIT:
				return false
			for face: Variant in p.faces:
				if not face is String or not _safe_id(face) or not NpcPopulation._integer(p.faces[face], 0, CREDIT_LIMIT):
					return false
		for id: Variant in p.owned:
			if not id is String or not palettes.any(func(v: Dictionary) -> bool: return v.id == id):
				return false
		for kind: Variant in p.events:
			if kind not in EVENT_KINDS or not p.events[kind] is Array or p.events[kind].size() > 64:
				return false
			var seen: Array = []
			for id: Variant in p.events[kind]:
				if not id is String or not _event_id_valid(kind, id) or id in seen:
					return false
				seen.append(id)
	heroes = data.heroes.duplicate(true)
	for profile: Dictionary in heroes.values():
		profile.credits = int(profile.credits)
		if profile.has("faces"):
			for face: String in profile.faces:
				profile.faces[face] = int(profile.faces[face])
	_ensure_hero()
	return true

func _changed() -> void:
	persist()
	changed.emit()

func persist() -> bool:
	if not save_enabled:
		return false
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_ok = false
		return false
	file.store_string(JSON.stringify(snapshot()))
	file.flush()
	file.close()
	save_ok = DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK
	return save_ok
