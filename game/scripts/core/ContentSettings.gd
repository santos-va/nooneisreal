extends Node
## Content and flash preferences (ADR-024 п. 7; plan 2026-10-07-First-Enemy-Lethal-Fight step 4, T8 spec):
##   blood       full | muted | ink | off — how a lethal fight shows blood (a sparring never shows any);
##   notice_seen the blood card before the first lethal fight was confirmed;
##   hit_flash   full | reduced — the white body flash and the hit light at half strength.
## Stored apart from comfort and graphics in user://content.cfg. A damaged file or an unknown value is never
## overwritten: this session falls back to blood "ink", hit flash "reduced" and an unseen card, and saving refuses
## so the original bytes stay for recovery. Presentation only — nothing here touches the fight.
signal changed(key: String, value: Variant)

const SECTION := "content"
const BLOOD_MODES: Array[String] = ["full", "muted", "ink", "off"]
const HIT_FLASH_MODES: Array[String] = ["full", "reduced"]
## Santos's word (ADR-024 п. 7): Full by default — PLACEHOLDER until the rating rows are grounded (plan step 7).
const DEFAULT_BLOOD := "full"
const DEFAULT_HIT_FLASH := "full"
## The fallback of an unreadable file: the most restrained presentation for this session.
const DAMAGED_BLOOD := "ink"
const DAMAGED_HIT_FLASH := "reduced"
## T8: Reduced keeps the white flash's time and brightness and the hit light at ≤ half of Full.
const REDUCED_FLASH_SCALE := 0.5
var storage_path: String = "user://content.cfg"
var _blood: String = DEFAULT_BLOOD
var _hit_flash: String = DEFAULT_HIT_FLASH
var _notice_seen: bool = false
var _config := ConfigFile.new()
var _load_error: Error = OK


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()


func blood_mode() -> String:
	return _blood


func hit_flash() -> String:
	return _hit_flash


## 1.0 for Full, REDUCED_FLASH_SCALE for Reduced: multiplies the flash time, its whiteness and the hit light.
func hit_flash_scale() -> float:
	return REDUCED_FLASH_SCALE if _hit_flash == "reduced" else 1.0


func notice_seen() -> bool:
	return _notice_seen


## False for the session when the file could not be read (and was left alone).
func storage_ok() -> bool:
	return _load_error == OK


func set_blood_mode(value: Variant) -> bool:
	if not value is String or not BLOOD_MODES.has(value):
		return false
	_blood = value
	changed.emit("blood", _blood)
	return true


func set_hit_flash(value: Variant) -> bool:
	if not value is String or not HIT_FLASH_MODES.has(value):
		return false
	_hit_flash = value
	changed.emit("hit_flash", _hit_flash)
	return true


func mark_notice_seen() -> void:
	_notice_seen = true
	changed.emit("notice_seen", true)


func load_settings(path: String = "") -> Error:
	if not path.is_empty():
		storage_path = path
	_config = ConfigFile.new()
	_load_error = _config.load(storage_path)
	var blood: String = DEFAULT_BLOOD
	var flash: String = DEFAULT_HIT_FLASH
	var seen := false
	if _load_error == ERR_FILE_NOT_FOUND:
		_load_error = OK
	elif _load_error == OK:
		# Our own file always carries all three keys; anything else (garbage ConfigFile still parses, a hand edit, a
		# future layout) is kept untouched rather than read as "defaults" and saved over.
		for key: String in ["blood", "hit_flash", "notice_seen"]:
			if not _config.has_section_key(SECTION, key):
				_load_error = ERR_INVALID_DATA
	if _load_error == OK and FileAccess.file_exists(storage_path):
		var raw_blood: Variant = _config.get_value(SECTION, "blood", DEFAULT_BLOOD)
		var raw_flash: Variant = _config.get_value(SECTION, "hit_flash", DEFAULT_HIT_FLASH)
		var raw_seen: Variant = _config.get_value(SECTION, "notice_seen", false)
		if not (raw_blood is String and BLOOD_MODES.has(raw_blood)) or not (raw_flash is String and HIT_FLASH_MODES.has(raw_flash)) or not raw_seen is bool:
			_load_error = ERR_INVALID_DATA   # an unknown / future value: keep the file, not the guess
		else:
			blood = raw_blood
			flash = raw_flash
			seen = raw_seen
	if _load_error != OK:
		blood = DAMAGED_BLOOD
		flash = DAMAGED_HIT_FLASH
		seen = false
	_blood = blood
	_hit_flash = flash
	_notice_seen = seen
	changed.emit("blood", _blood)
	changed.emit("hit_flash", _hit_flash)
	changed.emit("notice_seen", _notice_seen)
	return _load_error


func save_settings() -> Error:
	# Never replace an unreadable or unknown file with this session's values. Keep unknown keys/sections.
	if _load_error != OK:
		return _load_error
	_config.set_value(SECTION, "blood", _blood)
	_config.set_value(SECTION, "hit_flash", _hit_flash)
	_config.set_value(SECTION, "notice_seen", _notice_seen)
	var temporary_path: String = storage_path + ".tmp"
	var result: Error = _config.save(temporary_path)
	if result != OK:
		return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(storage_path))
