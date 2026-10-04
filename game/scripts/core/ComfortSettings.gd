extends Node
## Presentation preferences only. Existing audio routing/effects stay owned by audio services.

signal changed(key: String, value: float)

const DEFAULTS: Dictionary = {"master": 0.8, "sfx": 0.8, "music": 0.6, "shake": 0.5}
const BUSES: Dictionary = {"master": "Master", "sfx": "SFX", "music": "Music"}
const SECTION := "comfort"
var storage_path: String = "user://comfort.cfg"
var _values: Dictionary = DEFAULTS.duplicate()
var _config := ConfigFile.new()
var _load_error: Error = OK


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_master_limiter()
	load_settings()


func get_value(key: String) -> float:
	return float(_values.get(key, 0.0))


func set_value(key: String, value: float) -> bool:
	if not DEFAULTS.has(key) or not is_finite(value):
		return false
	var bounded: float = clampf(value, 0.0, 1.0)
	_values[key] = bounded
	_apply_bus(key)
	changed.emit(key, bounded)
	return true


func reset_defaults() -> void:
	for key: String in DEFAULTS:
		set_value(key, DEFAULTS[key])


func load_settings(path: String = "") -> Error:
	if not path.is_empty():
		storage_path = path
	_config = ConfigFile.new()
	_values = DEFAULTS.duplicate()
	_load_error = _config.load(storage_path)
	if _load_error == ERR_FILE_NOT_FOUND:
		_load_error = OK
	elif _load_error == OK:
		for key: String in DEFAULTS:
			var raw: Variant = _config.get_value(SECTION, key, DEFAULTS[key])
			if (raw is float or raw is int) and is_finite(float(raw)):
				_values[key] = clampf(float(raw), 0.0, 1.0)
	for key: String in DEFAULTS:
		_apply_bus(key)
		changed.emit(key, _values[key])
	return _load_error


func save_settings() -> Error:
	# Never replace an unreadable existing file with defaults. Keep unknown keys/sections.
	if _load_error != OK:
		return _load_error
	for key: String in DEFAULTS:
		_config.set_value(SECTION, key, _values[key])
	var temporary_path: String = storage_path + ".tmp"
	var result: Error = _config.save(temporary_path)
	if result != OK:
		return result
	result = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(storage_path))
	return result


func _apply_bus(key: String) -> void:
	if not BUSES.has(key):
		return
	var bus: int = AudioServer.get_bus_index(BUSES[key])
	if bus < 0:
		return
	var gain: float = get_value(key)
	AudioServer.set_bus_mute(bus, gain == 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(gain) if gain > 0.0 else -80.0)


func _ensure_master_limiter() -> void:
	# Godot 4.7 HardLimiter protects the summed SFX + Music output at full sliders.
	# Keep every pre-existing effect; repeated service initialization adds no duplicate.
	var master: int = AudioServer.get_bus_index("Master")
	for index: int in AudioServer.get_bus_effect_count(master):
		var effect: AudioEffect = AudioServer.get_bus_effect(master, index)
		if effect is AudioEffectHardLimiter and effect.resource_name == "ComfortOutputLimiter":
			return
	var limiter := AudioEffectHardLimiter.new()
	limiter.resource_name = "ComfortOutputLimiter"
	limiter.ceiling_db = -1.0
	limiter.pre_gain_db = 0.0
	limiter.release = 0.1
	AudioServer.add_bus_effect(master, limiter)
