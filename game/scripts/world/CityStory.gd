class_name CityStory
extends Node
## A bounded episode, isolated from district errands/economy and NPC save documents.
signal changed
const SAVE_PATH := "user://city_story_v1.json"
const CONTENT_PATH := "res://data/story/clocktower_trace.json"
const HEROES: Array[String] = ["choko", "skea"]
const CLUES: Array[String] = ["latch", "counterweight_trace"]
const TEXT_KEYS: Array[String] = ["id", "title", "offer", "accept_label", "accepted", "latch", "counterweight_trace", "mechanism_hint", "opened", "complete", "memory", "before_accept", "available", "investigating", "mechanism", "return", "completed", "prompt_latch", "prompt_counterweight_trace", "prompt_mechanism", "mira_route", "taras_route", "neighbour_return", "neighbour_completed", "choko_observation", "skea_observation", "remaining_latch", "remaining_counterweight_trace"]
var hero_id: String = "choko"
var heroes: Dictionary = {}
var content: Dictionary = {}
var save_enabled: bool = true
var save_ok: bool = true
var save_path: String = SAVE_PATH

func setup(selected_hero: String, disk: bool = true, path: String = SAVE_PATH) -> void:
	heroes = {}
	content = {}
	hero_id = selected_hero if selected_hero in HEROES else "choko"
	save_path = path
	save_enabled = disk and selected_hero in HEROES
	save_ok = selected_hero in HEROES
	var source := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	var parser := JSON.new()
	if source != null and source.get_length() <= 16384 and parser.parse(source.get_as_text()) == OK and parser.data is Dictionary:
		if valid_content(parser.data):
			content = parser.data.duplicate(true)
	if content.is_empty():
		save_enabled = false
		save_ok = false
	if disk and FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		var valid := false
		if file != null and file.get_length() <= 8192:
			valid = parser.parse(file.get_as_text()) == OK and restore(parser.data)
		if not valid:
			# Keep damaged bytes intact; this visit can still run in memory.
			save_enabled = false
			save_ok = false
	_ensure_hero()

static func valid_content(data: Variant) -> bool:
	if not data is Dictionary or data.size() != TEXT_KEYS.size() or not data.get("id") is String or data.get("id") != "clocktower_trace":
		return false
	for key: String in TEXT_KEYS:
		if not data.get(key) is String or data[key].strip_edges().is_empty() or data[key].length() > 1000:
			return false
	return true

func _ensure_hero() -> void:
	if not heroes.has(hero_id):
		heroes[hero_id] = {"accepted": false, "clues": [], "opened": false, "completed": false, "guide_selected": false}

func text(key: String) -> String:
	return str(content.get(key, ""))

func stage() -> String:
	var entry: Dictionary = heroes[hero_id]
	if entry.completed:
		return "completed"
	if entry.opened:
		return "return"
	if not entry.accepted:
		return "available"
	return "mechanism" if entry.clues.size() == CLUES.size() else "investigating"

func accept() -> bool:
	if stage() != "available" or content.is_empty():
		return false
	heroes[hero_id].accepted = true
	_changed()
	return true

func inspect(id: String) -> bool:
	if stage() != "investigating" or id not in CLUES or id in heroes[hero_id].clues:
		return false
	heroes[hero_id].clues.append(id)
	_changed()
	return true

func open_shortcut() -> bool:
	if stage() != "mechanism":
		return false
	heroes[hero_id].opened = true
	_changed()
	return true

func complete() -> bool:
	if stage() != "return":
		return false
	heroes[hero_id].completed = true
	_changed()
	return true

func has_clue(id: String) -> bool:
	return id in heroes[hero_id].clues

func shortcut_open() -> bool:
	return heroes[hero_id].opened

func guide_selected() -> bool:
	return heroes[hero_id].guide_selected

func select_guide(selected: bool) -> void:
	if heroes[hero_id].guide_selected == selected:
		return
	heroes[hero_id].guide_selected = selected
	_changed()

func current_hint() -> String:
	if stage() == "investigating" and heroes[hero_id].clues.size() == 1:
		return text("remaining_counterweight_trace" if has_clue("latch") else "remaining_latch")
	return text(stage())

func summary() -> Dictionary:
	return {"title": text("title"), "hint": current_hint(), "stage": stage(), "clues": heroes[hero_id].clues.size(), "save_ok": save_ok}

func journal_text() -> String:
	var lines := PackedStringArray([text("title") + " · " + current_hint()])
	for clue: String in CLUES:
		if has_clue(clue):
			lines.append(text(clue))
	if stage() == "mechanism":
		lines.append(text(hero_id + "_observation"))
	if stage() == "completed":
		lines.append(text("complete"))
	return "\n".join(lines)

func snapshot() -> Dictionary:
	return {"version": 1, "heroes": heroes.duplicate(true)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 2 or not data.get("heroes") is Dictionary or data.heroes.size() > HEROES.size():
		return false
	var version: Variant = data.get("version")
	if not (version is int or version is float) or not is_finite(float(version)) or float(version) != 1.0:
		return false
	for hero: Variant in data.heroes:
		if not hero is String or hero not in HEROES or not data.heroes[hero] is Dictionary:
			return false
		var p: Dictionary = data.heroes[hero]
		if p.size() != 5 or not p.get("guide_selected") is bool or not p.get("accepted") is bool or not p.get("opened") is bool or not p.get("completed") is bool or not p.get("clues") is Array or p.clues.size() > 2:
			return false
		var seen: Array[String] = []
		for clue: Variant in p.clues:
			if not clue is String or clue not in CLUES or clue in seen:
				return false
			seen.append(clue)
		if (not p.accepted and (not seen.is_empty() or p.opened or p.completed)) or (p.opened and seen.size() != 2) or (p.completed and not p.opened):
			return false
	heroes = data.heroes.duplicate(true)
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
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		save_ok = false
		return false
	save_ok = DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK
	return save_ok
