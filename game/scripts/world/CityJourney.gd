class_name CityJourney
extends Node
## Named safe places only: the save never supplies world coordinates or runtime motion.
signal changed
const SAVE_PATH := "user://city_journey_v1.json"
const HEROES: Array[String] = ["choko", "skea"]
# PLACEHOLDER traversal comfort thresholds, unrelated to combat frame data.
@export var activation_radius: float = 1.6
@export var activation_height: float = 0.25
@export var stable_seconds: float = 0.5
var hero_id: String = "choko"
var heroes: Dictionary = {}
var save_path: String = SAVE_PATH
var save_enabled: bool = true
var save_ok: bool = true
var _candidate: String = ""
var _stable_time: float = 0.0

static func checkpoints() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "spawn", "title": "Вхід до кварталу", "position": CityLayout.spawn_position()}]
	for place: Dictionary in CityPlaces.landmarks():
		result.append({"id": place.id, "title": place.title, "position": place.position})
	return result

static func place(id: String) -> Dictionary:
	for entry: Dictionary in checkpoints():
		if entry.id == id:
			return entry
	return {}

func setup(selected_hero: String, disk: bool = true, path: String = SAVE_PATH) -> void:
	heroes = {}
	_candidate = ""
	_stable_time = 0.0
	save_path = path
	save_enabled = disk
	save_ok = selected_hero in HEROES
	hero_id = selected_hero if save_ok else "choko"
	if not save_ok:
		save_enabled = false
	if disk and FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		var valid: bool = false
		if file != null and file.get_length() <= 4096:
			var json := JSON.new()
			valid = json.parse(file.get_as_text()) == OK and restore(json.data)
		if not valid:
			# Preserve the original bytes for recovery; exploration still works in memory.
			save_enabled = false
			save_ok = false

func checkpoint_id() -> String:
	return heroes.get(hero_id, "spawn")

func title() -> String:
	return place(checkpoint_id()).title

func resume_position() -> Vector3:
	return place(checkpoint_id()).position

func observe(player: CityFighter, delta: float) -> void:
	var next: String = ""
	if player.is_on_floor() and absf(player.velocity.y) < 0.1 and player.state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK] and not player.grapple.busy() and not player.grapple.attached:
		for entry: Dictionary in checkpoints():
			var offset: Vector3 = player.global_position - Vector3(entry.position)
			if absf(offset.y) <= activation_height and Vector2(offset.x, offset.z).length() <= activation_radius:
				next = entry.id
				break
	if next != _candidate:
		_candidate = next
		_stable_time = 0.0
	if next.is_empty():
		return
	_stable_time += maxf(delta, 0.0)
	if _stable_time >= stable_seconds and next != checkpoint_id():
		heroes[hero_id] = next
		persist()
		changed.emit()

func restart_walk() -> void:
	heroes[hero_id] = "spawn"
	_candidate = ""
	_stable_time = 0.0
	persist()
	changed.emit()

func snapshot() -> Dictionary:
	return {"version": 1, "heroes": heroes.duplicate()}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 2:
		return false
	var version: Variant = data.get("version")
	if not (version is int or version is float) or not is_finite(float(version)) or float(version) != 1.0 or not data.get("heroes") is Dictionary or data.heroes.size() > HEROES.size():
		return false
	# Validate the entire document before changing either hero's current checkpoint.
	for hero: Variant in data.heroes:
		if not hero is String or hero not in HEROES or not data.heroes[hero] is String or place(data.heroes[hero]).is_empty():
			return false
	heroes = data.heroes.duplicate()
	return true

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
