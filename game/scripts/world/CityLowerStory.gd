class_name CityLowerStory
extends Node
## Successor facts are separate from the immutable first-episode save contract.
signal changed
const SAVE_PATH := "user://city_lower_story_v1.json"
const CONTENT_PATH := "res://data/story/lower_mark.json"
const HEROES: Array[String] = ["choko", "skea"]
const FIELDS: Array[String] = ["accepted", "lamp_aligned", "copied", "completed", "guide_selected"]
const TEXT_KEYS: Array[String] = ["id", "title", "offer", "accept_label", "accepted", "locked", "prior_unavailable", "available", "lighting", "copy", "return", "completed", "prompt_lamp_toward", "prompt_lamp_away", "prompt_plate", "lamp_toward", "lamp_away", "copy_retained", "unlit_plate", "copied_fact", "complete", "memory", "choko_observation", "skea_observation", "boundary"]
var previous: CityStory
var hero_id: String = "choko"
var heroes: Dictionary = {}
var content: Dictionary = {}
var save_path: String = SAVE_PATH
var save_enabled: bool = true
var save_ok: bool = true
var _hero_valid: bool = true

func setup(hero: String, predecessor: CityStory, disk: bool = true, path: String = SAVE_PATH) -> void:
	if is_instance_valid(previous) and previous.changed.is_connected(_previous_changed):
		previous.changed.disconnect(_previous_changed)
	previous = predecessor
	if is_instance_valid(previous):
		previous.changed.connect(_previous_changed)
	_hero_valid = hero in HEROES
	hero_id = hero if _hero_valid else "choko"
	heroes = {}
	content = {}
	save_path = path
	save_enabled = disk and _hero_valid
	save_ok = _hero_valid
	var parser := JSON.new()
	var source := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if source != null and source.get_length() <= 16384 and parser.parse(source.get_as_text()) == OK and valid_content(parser.data):
		content = parser.data.duplicate(true)
	else:
		save_enabled = false
		save_ok = false
	if disk and FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		var valid := false
		if file != null and file.get_length() <= 8192:
			valid = parser.parse(file.get_as_text()) == OK and restore(parser.data)
		if not valid:
			save_enabled = false
			save_ok = false
	_ensure_hero()

static func valid_content(data: Variant) -> bool:
	if not data is Dictionary or data.size() != TEXT_KEYS.size() or not data.get("id") is String or data.id != "lower_mark":
		return false
	for key: String in TEXT_KEYS:
		if not data.get(key) is String or data[key].strip_edges().is_empty() or data[key].length() > 1000:
			return false
	return true

func _ensure_hero() -> void:
	if not heroes.has(hero_id):
		heroes[hero_id] = {"accepted": false, "lamp_aligned": false, "copied": false, "completed": false, "guide_selected": false}

func prerequisite_ready() -> bool:
	return _hero_valid and is_instance_valid(previous) and previous.hero_id == hero_id and previous.save_enabled and previous.save_ok and previous.stage() == "completed"

func stage() -> String:
	if not prerequisite_ready() or content.is_empty():
		return "locked"
	var entry: Dictionary = heroes[hero_id]
	if entry.completed:
		return "completed"
	if entry.copied:
		return "return"
	if not entry.accepted:
		return "available"
	return "copy" if entry.lamp_aligned else "lighting"

func text(key: String) -> String:
	return str(content.get(key, ""))

func accept() -> bool:
	if stage() != "available":
		return false
	heroes[hero_id].accepted = true
	_changed()
	return true

func toggle_lamp() -> bool:
	if stage() not in ["lighting", "copy", "return", "completed"]:
		return false
	heroes[hero_id].lamp_aligned = not heroes[hero_id].lamp_aligned
	_changed()
	return true

func copy_mark() -> bool:
	if stage() != "copy":
		return false
	heroes[hero_id].copied = true
	_changed()
	return true

func complete() -> bool:
	if stage() != "return":
		return false
	heroes[hero_id].completed = true
	_changed()
	return true

func lamp_aligned() -> bool:
	return prerequisite_ready() and not content.is_empty() and heroes[hero_id].lamp_aligned

func has_copy() -> bool:
	return prerequisite_ready() and not content.is_empty() and heroes[hero_id].copied

func record_delivered() -> bool:
	return stage() == "completed"

func guide_selected() -> bool:
	return prerequisite_ready() and heroes[hero_id].guide_selected

func select_guide(selected: bool) -> void:
	if stage() == "locked" or heroes[hero_id].guide_selected == selected:
		return
	heroes[hero_id].guide_selected = selected
	_changed()

func current_hint() -> String:
	if stage() == "locked":
		var suspended: bool = heroes[hero_id].accepted or not is_instance_valid(previous) or previous.hero_id != hero_id or not previous.save_ok or not previous.save_enabled
		return text("prior_unavailable" if suspended else "locked")
	return text(stage())

func summary() -> Dictionary:
	return {"title": text("title"), "hint": current_hint(), "stage": stage(), "save_ok": save_ok}

func journal_text() -> String:
	if stage() == "locked":
		return text("title") + " · " + current_hint() if heroes[hero_id].accepted else ""
	var lines := PackedStringArray([text("title") + " · " + current_hint(), text("boundary")])
	if has_copy():
		lines.append(text("copied_fact"))
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
		var entry: Dictionary = data.heroes[hero]
		if entry.size() != FIELDS.size():
			return false
		for field: String in FIELDS:
			if not entry.get(field) is bool:
				return false
		if (not entry.accepted and (entry.lamp_aligned or entry.copied or entry.completed)) or (entry.completed and not entry.copied):
			return false
		# A copied observation remains valid when the lamp has subsequently turned away.
	heroes = data.heroes.duplicate(true)
	_ensure_hero()
	return true

func _previous_changed() -> void:
	# Suspend/resume only the effective view; never rewrite an orphan's saved facts.
	changed.emit()

func _changed() -> void:
	persist()
	changed.emit()

func persist() -> bool:
	if not save_enabled or not prerequisite_ready():
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
