extends SceneTree
## Persistence and live root viewport checks, without touching player preferences.
var checks: int = 0
var failures: int = 0
var test_path: String = "user://graphics_check_%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("GRAPHICS_CHECK: " + label)

func _run() -> void:
	var settings: Node = load("res://scripts/core/GraphicsSettings.gd").new()
	settings.storage_path = test_path
	root.add_child(settings)
	check(settings.get_profile() == "high", "missing settings retain current High default")
	check(root.msaa_3d == Viewport.MSAA_4X and is_equal_approx(root.scaling_3d_scale, 1.0), "default matches prior project rendering")
	check(not FileAccess.file_exists(test_path), "load does not create a file")
	var ids: Array[String] = QualityProfile.ids()
	ids.clear()
	check(QualityProfile.ids().size() == 3, "profile IDs cannot be mutated by consumers")
	var profile: QualityProfile = QualityProfile.make("high")
	profile.render_scale = 0.1
	check(is_equal_approx(QualityProfile.make("high").render_scale, 1.0), "profile resources are independent")
	var scales: Array[float] = [0.75, 0.85, 1.0]
	var samples: Array[int] = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X]
	for cycle: int in 3:
		for index: int in 3:
			var id: String = QualityProfile.ids()[index]
			check(settings.set_profile(id), "valid selection " + id)
			check(settings.get_profile() == id and is_equal_approx(root.scaling_3d_scale, scales[index]) and root.msaa_3d == samples[index], "selection really applies to viewport " + id)
	check(settings.set_profile("low"), "select low before invalid values")
	for invalid: Variant in [null, 1, 0.5, true, [], {}, "ultra", "HIGH", ""]:
		check(not settings.set_profile(invalid), "reject invalid selection " + str(invalid))
		check(settings.get_profile() == "low" and root.msaa_3d == Viewport.MSAA_DISABLED, "invalid selection leaves active profile untouched")
	check(settings.save_settings() == OK, "atomic save")
	check(settings.set_profile("high") and settings.load_settings() == OK and settings.get_profile() == "low", "saved selection round-trips")
	var config := ConfigFile.new()
	config.load(test_path)
	config.set_value("graphics", "future", "keep")
	config.set_value("other", "preserve", 42)
	config.save(test_path)
	check(settings.load_settings() == OK and settings.save_settings() == OK, "unknown fields allow save")
	config.load(test_path)
	check(config.get_value("graphics", "future") == "keep" and config.get_value("other", "preserve") == 42, "unknown fields preserved")
	for invalid: Variant in ["future_profile", 2, true, ["low"], {"id": "low"}]:
		config.set_value("graphics", "profile", invalid)
		config.save(test_path)
		var original: String = FileAccess.get_file_as_string(test_path)
		check(settings.load_settings() == ERR_INVALID_DATA, "invalid persisted schema rejected")
		check(settings.get_profile() == "high" and root.msaa_3d == Viewport.MSAA_4X, "invalid persisted schema uses safe session default")
		settings.set_profile("medium")
		check(settings.save_settings() == ERR_INVALID_DATA and FileAccess.get_file_as_string(test_path) == original, "invalid bytes remain recoverable after session change")
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("[malformed\nnot a config")
	file.close()
	var original: String = FileAccess.get_file_as_string(test_path)
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var parse_error: Error = settings.load_settings()
	Engine.print_error_messages = previous_errors
	check(parse_error == ERR_PARSE_ERROR, "malformed config reported")
	check(settings.save_settings() == ERR_PARSE_ERROR and FileAccess.get_file_as_string(test_path) == original, "malformed bytes preserved")
	settings.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	root.get_node("GraphicsSettings").set_profile("high")
	print("GRAPHICS_CHECK_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
