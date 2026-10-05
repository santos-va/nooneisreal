extends SceneTree
## Independent live viewport and hostile persisted-value checks; no production edits.
var checks: int = 0
var failures: int = 0
var mutation: String = ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("T4_GRAPHICS: " + label)

func run() -> void:
	await process_frame
	var settings: Node = root.get_node("GraphicsSettings")
	var original_path: String = settings.storage_path
	var original_profile: String = settings.get_profile()
	var path: String = "user://t4-graphics-%d.cfg" % OS.get_process_id()
	var original_time_scale: float = Engine.time_scale
	var original_ticks: int = Engine.physics_ticks_per_second
	# Expected public values are frozen from the approved profile table, not read
	# back from QualityProfile.make(), which is the system being checked.
	for row: Array in [["low", 0.75, Viewport.MSAA_DISABLED], ["medium", 0.85, Viewport.MSAA_2X], ["high", 1.0, Viewport.MSAA_4X]]:
		check(settings.set_profile(row[0]), "known profile accepted")
		if mutation == "apply":
			root.scaling_3d_scale = 1.0
			root.msaa_3d = Viewport.MSAA_4X
		check(is_equal_approx(root.scaling_3d_scale, float(row[1])) and root.msaa_3d == int(row[2]), "live viewport receives " + str(row[0]))
		check(Engine.time_scale == original_time_scale and Engine.physics_ticks_per_second == original_ticks, "graphics preserves simulation clock")
	settings.set_profile("medium")
	for bad: Variant in [null, false, 0, 0.75, [], {}, "future", "HIGH", ""]:
		check(not settings.set_profile(bad), "invalid runtime profile rejected")
		check(settings.get_profile() == "medium" and is_equal_approx(root.scaling_3d_scale, 0.85) and root.msaa_3d == Viewport.MSAA_2X, "invalid runtime value is atomic")
	for bad: Variant in [false, 1, 0.75, [], {"profile":"low"}, "future"]:
		var config := ConfigFile.new()
		config.set_value("graphics", "profile", bad)
		check(config.save(path) == OK, "hostile valid-syntax fixture saved")
		var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
		check(settings.load_settings(path) == ERR_INVALID_DATA, "hostile persisted type rejected")
		check(settings.get_profile() == "high" and is_equal_approx(root.scaling_3d_scale, 1.0) and root.msaa_3d == Viewport.MSAA_4X, "invalid disk value has live safe fallback")
		settings.set_profile("low")
		check(settings.save_settings() == ERR_INVALID_DATA, "invalid source stays write-protected")
		check(FileAccess.get_file_as_bytes(path) == before, "invalid bytes preserved after attempted save")
	var config := ConfigFile.new()
	config.set_value("graphics", "profile", "low")
	config.set_value("future_section", "opaque", {"version":17,"payload":["preserve",3]})
	check(config.save(path) == OK and settings.load_settings(path) == OK, "valid config recovers from prior rejection")
	settings.set_profile("medium")
	check(settings.save_settings() == OK, "recovered valid source saves")
	var restored := ConfigFile.new()
	check(restored.load(path) == OK and restored.get_value("graphics","profile") == "medium", "selected profile persists")
	check(restored.get_value("future_section","opaque") == {"version":17,"payload":["preserve",3]}, "unowned config section survives")
	paused = true
	check(settings.set_profile("low") and paused and is_equal_approx(root.scaling_3d_scale,0.75), "paused settings apply without resuming game")
	paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	settings.load_settings(original_path)
	settings.set_profile(original_profile)
	await process_frame
	print("T4_GRAPHICS_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
