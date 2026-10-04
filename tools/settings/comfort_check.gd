extends SceneTree

var failures: int = 0
var checks: int = 0
var settings: Node
var test_path: String = "user://comfort_check_%s.cfg" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _run() -> void:
	var script: Script = load("res://scripts/core/ComfortSettings.gd")
	settings = script.new()
	settings.storage_path = test_path
	root.add_child(settings)
	var master_bus: int = AudioServer.get_bus_index("Master")
	var master_effects: int = AudioServer.get_bus_effect_count(master_bus)
	var limiter: AudioEffect = AudioServer.get_bus_effect(master_bus, master_effects - 1)
	_check(limiter is AudioEffectHardLimiter, "final Master effect is hard limiter")
	_check(is_equal_approx(limiter.get("ceiling_db"), -1.0), "Master ceiling -1 dB")
	settings._ensure_master_limiter()
	_check(AudioServer.get_bus_effect_count(master_bus) == master_effects, "Master limiter initialization idempotent")
	var sfx_bus: int = AudioServer.get_bus_index("SFX")
	var original_effects: int = AudioServer.get_bus_effect_count(sfx_bus)
	_check(AudioServer.get_bus_send(sfx_bus) == "Master", "SFX routing preserved")
	_check(AudioServer.get_bus_send(AudioServer.get_bus_index("Music")) == "Master", "Music routing preserved")
	_check(original_effects == 2, "SFX compressor and limiter exist before preferences")
	_check(AudioServer.get_bus_effect(sfx_bus, 0) is AudioEffectCompressor, "compressor retained")
	_check(AudioServer.get_bus_effect(sfx_bus, 1) is AudioEffectLimiter, "limiter retained")
	_check(is_equal_approx(settings.get_value("master"), 0.8), "missing file gets defaults")
	_check(not FileAccess.file_exists(test_path), "load never writes missing file")
	_check(not settings.set_value("master", NAN), "reject NaN")
	_check(not settings.set_value("master", INF), "reject infinity")
	_check(not settings.set_value("unknown", 0.4), "reject unknown key")
	settings.set_value("sfx", -3.0)
	_check(settings.get_value("sfx") == 0.0 and AudioServer.is_bus_mute(sfx_bus), "zero gain is true mute")
	settings.set_value("sfx", 2.0)
	_check(settings.get_value("sfx") == 1.0 and not AudioServer.is_bus_mute(sfx_bus), "upper clamp unmutes")
	settings.set_value("music", 0.25)
	_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.25), "music uses bus gain")
	_check(settings.save_settings() == OK, "atomic save succeeds")
	var cfg := ConfigFile.new()
	_check(cfg.load(test_path) == OK, "saved cfg parses")
	cfg.set_value("bindings", "future_key", "untouched")
	cfg.set_value("comfort", "future_gain", 42)
	cfg.set_value("comfort", "master", "bad type")
	cfg.set_value("comfort", "shake", 3.0)
	cfg.set_value("comfort", "music", -1.0)
	cfg.save(test_path)
	_check(settings.load_settings() == OK, "valid config reload")
	_check(is_equal_approx(settings.get_value("master"), 0.8), "invalid typed value defaults")
	_check(settings.get_value("shake") == 1.0 and settings.get_value("music") == 0.0, "file values clamp")
	settings.reset_defaults()
	_check(settings.save_settings() == OK, "reset and save")
	cfg.load(test_path)
	_check(cfg.get_value("bindings", "future_key") == "untouched", "unknown section preserved")
	_check(cfg.get_value("comfort", "future_gain") == 42, "unknown comfort key preserved")
	_check(AudioServer.get_bus_effect_count(sfx_bus) == original_effects, "no duplicate/lost effects")
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("[broken\nthis is not config")
	file.close()
	var corrupt: String = FileAccess.get_file_as_string(test_path)
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var corrupt_error: Error = settings.load_settings()
	Engine.print_error_messages = previous_errors
	_check(corrupt_error == ERR_PARSE_ERROR, "corrupt config rejected with parse error")
	settings.set_value("master", 0.1)
	_check(settings.save_settings() != OK, "corrupt file cannot be overwritten")
	_check(FileAccess.get_file_as_string(test_path) == corrupt, "corrupt bytes preserved")
	if corrupt_error == ERR_PARSE_ERROR and FileAccess.get_file_as_string(test_path) == corrupt:
		print("EXPECTED_CORRUPT_CONFIG_REJECTED")
	settings.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	var real_settings: Node = root.get_node("ComfortSettings")
	real_settings.load_settings()
	print("COMFORT_CHECK_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
