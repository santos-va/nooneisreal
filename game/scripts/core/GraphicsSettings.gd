extends Node
## Global presentation preference. The root viewport survives menu/city/duel changes.
signal changed(profile: String)

const SECTION := "graphics"
const DEFAULT_PROFILE := "high"
var storage_path: String = "user://graphics.cfg"
var _profile: String = DEFAULT_PROFILE
var _config := ConfigFile.new()
var _load_error: Error = OK

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()

func get_profile() -> String:
	return _profile

func set_profile(value: Variant) -> bool:
	var profile: QualityProfile = QualityProfile.make(value)
	if profile == null:
		return false
	_profile = profile.id
	profile.apply_to(get_tree().root)
	changed.emit(_profile)
	return true

func load_settings(path: String = "") -> Error:
	if not path.is_empty():
		storage_path = path
	_config = ConfigFile.new()
	_load_error = _config.load(storage_path)
	var selected: String = DEFAULT_PROFILE
	if _load_error == ERR_FILE_NOT_FOUND:
		_load_error = OK
	elif _load_error == OK:
		var raw: Variant = _config.get_value(SECTION, "profile", DEFAULT_PROFILE)
		if QualityProfile.make(raw) == null:
			_load_error = ERR_INVALID_DATA
		else:
			selected = raw
	set_profile(selected)
	return _load_error

func save_settings() -> Error:
	# Invalid/future profile IDs and malformed files stay intact for recovery.
	if _load_error != OK:
		return _load_error
	_config.set_value(SECTION, "profile", _profile)
	var temporary_path: String = storage_path + ".tmp"
	var result: Error = _config.save(temporary_path)
	if result != OK:
		return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(storage_path))
