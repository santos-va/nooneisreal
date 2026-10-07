extends SceneTree
## DISPLAY / AUTO / fullscreen key (docs/GDD/06-UI-UX.md § DISPLAY, AUTO-якість і клавіша повного екрана; plan
## docs/Plans/2026-10-07-Auto-Display-And-Quality.md step 4). Headless has no real window (window_get_mode is the
## MINIMIZED stub), so this run checks decisions, persistence, the keys through the real input pipeline, a live
## fight and the AUTO policy. Real window transitions are native-only (xvfb, Santos's Mac).
## --break=cfg|combat_key|migrate|headless_controller|upscaler must each go red.
var checks: int = 0
var failures: int = 0
var mutation: String = ""
var graphics: Node
var router: Node
var state: Node
var _original_path: String = ""
var _original_profile: String = ""
var _paths: Array[String] = []
# Scripts that read autoloads are loaded at run time, like the other fixtures do.
var F: GDScript
var MF: GDScript
var BloodScript: GDScript
var PanelScript: GDScript
const MODES_HELD: Array[String] = ["dash", "block", "grapple_detach", "left_hand"]


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DISPLAY_AUTO: " + label)


func _path(tag: String) -> String:
	var path := "user://display_auto_%s_%d.cfg" % [tag, OS.get_process_id()]
	_paths.append(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return path


func _bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _cfg(path: String) -> ConfigFile:
	var config := ConfigFile.new()
	config.load(path)
	return config


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _ticks(count: int) -> void:
	for i: int in count:
		await physics_frame


func _key(code: Key, down: bool, mods: Dictionary = {}, echo: bool = false, location: KeyLocation = KEY_LOCATION_UNSPECIFIED, physical: Key = KEY_NONE) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code if physical == KEY_NONE else physical
	event.pressed = down
	event.echo = echo
	event.location = location
	event.alt_pressed = bool(mods.get("alt", false))
	event.ctrl_pressed = bool(mods.get("ctrl", false))
	event.meta_pressed = bool(mods.get("meta", false))
	event.shift_pressed = bool(mods.get("shift", false))
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Holds a combination down (keys pressed in order), `release` lets go in reverse order.
func _press(combo: String) -> void:
	match combo:
		"alt":
			_key(KEY_ALT, true, {"alt": true}, false, KEY_LOCATION_LEFT)
		"alt_enter":
			_key(KEY_ALT, true, {"alt": true}, false, KEY_LOCATION_LEFT)
			_key(KEY_ENTER, true, {"alt": true})
		"f11":
			_key(KEY_F11, true)
		"f":
			_key(KEY_F, true)
		"ctrl_f":
			_key(KEY_CTRL, true, {"ctrl": true}, false, KEY_LOCATION_LEFT)
			_key(KEY_F, true, {"ctrl": true})
		"ctrl_cmd_f":
			_key(KEY_CTRL, true, {"ctrl": true}, false, KEY_LOCATION_LEFT)
			_key(KEY_META, true, {"ctrl": true, "meta": true}, false, KEY_LOCATION_LEFT)
			_key(KEY_F, true, {"ctrl": true, "meta": true})


func _release(combo: String) -> void:
	match combo:
		"alt":
			_key(KEY_ALT, false, {}, false, KEY_LOCATION_LEFT)
		"alt_enter":
			_key(KEY_ENTER, false, {"alt": true})
			_key(KEY_ALT, false, {}, false, KEY_LOCATION_LEFT)
		"f11":
			_key(KEY_F11, false)
		"f":
			_key(KEY_F, false)
		"ctrl_f":
			_key(KEY_F, false, {"ctrl": true})
			_key(KEY_CTRL, false, {}, false, KEY_LOCATION_LEFT)
		"ctrl_cmd_f":
			_key(KEY_F, false, {"ctrl": true, "meta": true})
			_key(KEY_META, false, {"ctrl": true}, false, KEY_LOCATION_LEFT)
			_key(KEY_CTRL, false, {}, false, KEY_LOCATION_LEFT)


func _held() -> Dictionary:
	var result := {}
	for action: String in MODES_HELD:
		result[action] = router.held(1, action)
	return result


func _run() -> void:
	await process_frame
	graphics = root.get_node("GraphicsSettings")
	router = root.get_node("InputRouter")
	state = root.get_node("GameState")
	F = load("res://scripts/fighter/Fighter.gd")
	MF = load("res://scripts/arena/MatchFlow.gd")
	BloodScript = load("res://scripts/fx/BloodFx.gd")
	PanelScript = load("res://scripts/ui/ComfortPanel.gd")
	_original_path = graphics.storage_path
	_original_profile = graphics.get_profile()
	await _persistence()
	await _external_sync()
	await _key_classifier()
	await _auto_policy()
	await _auto_runtime()
	await _menu_and_panel()
	await _fight_keys()
	await _phone()
	# Leave the shared autoload as found.
	graphics.mobile_override = -1
	graphics.scripted_override = -1
	graphics.load_settings(_original_path)
	graphics.set_profile(_original_profile)
	for path: String in _paths:
		for suffix: String in ["", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	for singleton: String in ["Sfx", "UltMusic"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	await _frames(4)
	print("DISPLAY_AUTO_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


# --- A. persistence ---------------------------------------------------------------------------------------------
func _persistence() -> void:
	var fresh := _path("fresh")
	check(graphics.load_settings(fresh) == OK, "missing file loads")
	check(graphics.get_profile() == "auto" and graphics.get_window_mode() == "fullscreen", "nothing saved → AUTO and FULLSCREEN")
	check(not FileAccess.file_exists(fresh), "loading never creates the file")
	var requests: int = graphics.window_requests
	check(graphics.set_window_mode("windowed"), "WINDOWED accepted")
	check(graphics.get_window_mode() == "windowed" and graphics.window_requests == requests + 1, "WINDOWED is requested from the DisplayServer once")
	var saved := _cfg(fresh)
	check(saved.get_value("display", "window_mode", "") == "windowed", "choice is written to [display] window_mode")
	check(not saved.has_section_key("graphics", "profile"), "a display change does not write a profile (AUTO stays implicit)")
	var before := _bytes(fresh)
	check(graphics.set_window_mode("windowed") and _bytes(fresh) == before and graphics.window_requests == requests + 1, "selecting the current mode writes and requests nothing")
	for bad: Variant in [null, 1, true, "Fullscreen", "", "exclusive", ["windowed"]]:
		check(not graphics.set_window_mode(bad) and graphics.get_window_mode() == "windowed", "invalid window mode rejected: " + str(bad))
	graphics.set_window_mode("fullscreen")
	graphics.set_window_mode("windowed")
	check(graphics.load_settings(fresh) == OK and graphics.get_window_mode() == "windowed", "saved WINDOWED round-trips")
	# A saved manual preset never migrates to AUTO, and a display write leaves it alone.
	for row: Array in [["high", 1.0, Viewport.MSAA_4X], ["low", 0.75, Viewport.MSAA_DISABLED]]:
		var legacy := _path("legacy_" + str(row[0]))
		_write(legacy, "[graphics]\n\nprofile=\"%s\"\n" % row[0])
		check(graphics.load_settings(legacy) == OK, "legacy profile file loads: " + str(row[0]))
		if mutation == "migrate":
			graphics.set_profile("auto")
			graphics.save_settings()
		check(graphics.get_profile() == row[0], "saved %s stays %s (no AUTO migration)" % [row[0], row[0]])
		check(is_equal_approx(root.scaling_3d_scale, float(row[1])) and root.msaa_3d == int(row[2]), "saved %s applies its own scale and MSAA" % row[0])
		graphics.toggle_window_mode()
		var after := _cfg(legacy)
		check(after.get_value("graphics", "profile", "") == row[0] and after.get_value("display", "window_mode", "") == "windowed", "a key toggle keeps profile=%s and adds the display key" % row[0])
	var auto_saved := _path("auto_saved")
	_write(auto_saved, "[graphics]\n\nprofile=\"auto\"\n\n[display]\n\nwindow_mode=\"fullscreen\"\n")
	check(graphics.load_settings(auto_saved) == OK and graphics.get_profile() == "auto" and graphics.get_window_mode() == "fullscreen", "explicitly saved AUTO loads")
	# Unowned sections and keys survive a display save.
	var keep := _path("keep")
	_write(keep, "[graphics]\n\nprofile=\"medium\"\nfuture=\"keep\"\n\n[other]\n\npreserve=42\n")
	graphics.load_settings(keep)
	graphics.set_window_mode("windowed")
	var kept := _cfg(keep)
	check(kept.get_value("graphics", "future", "") == "keep" and kept.get_value("other", "preserve", 0) == 42 and kept.get_value("graphics", "profile", "") == "medium", "unowned keys survive a display write")
	# Damaged bytes are never written over (06-UI-UX § 1, like the profile).
	var damaged := _path("damaged")
	_write(damaged, "[display\nwindow_mode = = windowed\n[[")
	var damaged_bytes := _bytes(damaged)
	var previous_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var parse_error: Error = graphics.load_settings(damaged)
	Engine.print_error_messages = previous_errors
	check(parse_error != OK, "malformed file reported (%d)" % parse_error)
	check(graphics.get_profile() == "high" and graphics.get_window_mode() == "fullscreen", "malformed file → session High and FULLSCREEN")
	if mutation == "cfg":
		graphics.set("_load_error", OK)   # a save path that forgets the guard
	check(graphics.set_window_mode("windowed") and graphics.get_window_mode() == "windowed", "a damaged file still lets the session switch")
	check(graphics.save_error != OK, "the failed write is reported to the panel")
	graphics.toggle_window_mode()
	graphics.set_profile("low")
	graphics.save_settings()
	check(_bytes(damaged) == damaged_bytes, "malformed bytes preserved after mode, key and profile changes")
	# Hostile values with valid syntax: the readable half applies, nothing is written.
	for hostile: Array in [["low", "\"borderless\""], ["low", "1"], ["low", "true"], ["low", "[\"windowed\"]"]]:
		var file := _path("hostile")
		_write(file, "[graphics]\n\nprofile=\"%s\"\n\n[display]\n\nwindow_mode=%s\n" % hostile)
		var hostile_bytes := _bytes(file)
		check(graphics.load_settings(file) == ERR_INVALID_DATA, "unknown window_mode rejected: " + str(hostile[1]))
		check(graphics.get_profile() == "low" and graphics.get_window_mode() == "fullscreen", "readable profile applies, unknown mode → FULLSCREEN: " + str(hostile[1]))
		graphics.toggle_window_mode()
		check(_bytes(file) == hostile_bytes, "unknown window_mode bytes preserved: " + str(hostile[1]))
	var unknown_profile := _path("unknown_profile")
	_write(unknown_profile, "[graphics]\n\nprofile=\"ultra\"\n\n[display]\n\nwindow_mode=\"windowed\"\n")
	var unknown_bytes := _bytes(unknown_profile)
	check(graphics.load_settings(unknown_profile) == ERR_INVALID_DATA and graphics.get_profile() == "high" and graphics.get_window_mode() == "windowed", "unknown profile → session High, readable WINDOWED applies")
	graphics.toggle_window_mode()
	check(_bytes(unknown_profile) == unknown_bytes, "unknown profile bytes preserved")
	graphics.load_settings(_path("after_persistence"))


# --- B. a mode changed outside the game ------------------------------------------------------------------------
func _external_sync() -> void:
	var file := _path("sync")
	graphics.load_settings(file)
	graphics.set_window_mode("windowed")
	graphics.expire_window_guard()
	check(graphics.sync_from_window(DisplayServer.WINDOW_MODE_FULLSCREEN) and graphics.get_window_mode() == "fullscreen", "green button (FULLSCREEN) is followed")
	check(_cfg(file).get_value("display", "window_mode", "") == "fullscreen", "an outside change is saved as the player's choice")
	check(not graphics.sync_from_window(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN), "EXCLUSIVE after FULLSCREEN is the same choice")
	var before := _bytes(file)
	check(not graphics.sync_from_window(DisplayServer.WINDOW_MODE_MINIMIZED) and graphics.get_window_mode() == "fullscreen" and _bytes(file) == before, "MINIMIZED is never recorded")
	check(graphics.sync_from_window(DisplayServer.WINDOW_MODE_MAXIMIZED) and _cfg(file).get_value("display", "window_mode", "") == "windowed", "leaving fullscreen to a framed window is recorded as WINDOWED")
	check(not graphics.sync_from_window(), "a scripted run never reads the window on its own: nothing recorded")
	graphics.scripted_override = 0
	check(not graphics.sync_from_window(), "headless reports the MINIMIZED stub: nothing recorded")
	graphics.scripted_override = -1
	# Our own request may still be animating: a mismatch inside the guard is re-requested once, never saved.
	graphics.set_window_mode("fullscreen")
	var requests: int = graphics.window_requests
	before = _bytes(file)
	check(not graphics.sync_from_window(DisplayServer.WINDOW_MODE_WINDOWED) and graphics.get_window_mode() == "fullscreen" and _bytes(file) == before, "a mismatch during our own transition is not saved")
	check(graphics.window_requests == requests + 1, "…and is re-requested once")
	graphics.sync_from_window(DisplayServer.WINDOW_MODE_WINDOWED)
	check(graphics.window_requests == requests + 1, "…and only once")
	graphics.expire_window_guard()
	check(graphics.sync_from_window(DisplayServer.WINDOW_MODE_WINDOWED) and graphics.get_window_mode() == "windowed", "after the guard the same change is the player's")


# --- C. which key presses toggle -------------------------------------------------------------------------------
func _key_event(code: Key, mods: Dictionary = {}, pressed: bool = true, echo: bool = false, physical: Key = KEY_NONE) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code if physical == KEY_NONE else physical
	event.pressed = pressed
	event.echo = echo
	event.alt_pressed = bool(mods.get("alt", false))
	event.ctrl_pressed = bool(mods.get("ctrl", false))
	event.meta_pressed = bool(mods.get("meta", false))
	event.shift_pressed = bool(mods.get("shift", false))
	return event


func _key_classifier() -> void:
	var gs: GDScript = graphics.get_script()
	var cases: Array = [
		["F11 in play", _key_event(KEY_F11), false, true],
		["F11 in a menu", _key_event(KEY_F11), true, true],
		["Shift+F11", _key_event(KEY_F11, {"shift": true}), false, true],
		["Ctrl+F11", _key_event(KEY_F11, {"ctrl": true}), true, false],
		["Alt+F11", _key_event(KEY_F11, {"alt": true}), true, false],
		["Cmd+F11", _key_event(KEY_F11, {"meta": true}), true, false],
		["F11 echo", _key_event(KEY_F11, {}, true, true), true, false],
		["F11 release", _key_event(KEY_F11, {}, false), true, false],
		["Alt+Enter in a menu", _key_event(KEY_ENTER, {"alt": true}), true, true],
		["Alt+KP Enter in a menu", _key_event(KEY_KP_ENTER, {"alt": true}), true, true],
		["Alt+Enter in play", _key_event(KEY_ENTER, {"alt": true}), false, false],
		["Ctrl+Alt+Enter", _key_event(KEY_ENTER, {"alt": true, "ctrl": true}), true, false],
		["Cmd+Alt+Enter", _key_event(KEY_ENTER, {"alt": true, "meta": true}), true, false],
		["Enter alone", _key_event(KEY_ENTER), true, false],
		["Ctrl+Cmd+F in a menu", _key_event(KEY_F, {"ctrl": true, "meta": true}), true, true],
		["Ctrl+Cmd+F by position (Ukrainian layout)", _key_event(KEY_A, {"ctrl": true, "meta": true}, true, false, KEY_F), true, true],
		["Ctrl+Cmd+F in play", _key_event(KEY_F, {"ctrl": true, "meta": true}), false, false],
		["Ctrl+Cmd+Shift+F", _key_event(KEY_F, {"ctrl": true, "meta": true, "shift": true}), true, false],
		["Ctrl+Cmd+Alt+F", _key_event(KEY_F, {"ctrl": true, "meta": true, "alt": true}), true, false],
		["Cmd+F", _key_event(KEY_F, {"meta": true}), true, false],
		["Ctrl+F", _key_event(KEY_F, {"ctrl": true}), true, false],
		["F alone", _key_event(KEY_F), true, false],
	]
	for row: Array in cases:
		check(bool(gs.call("is_fullscreen_key", row[1], row[2])) == bool(row[3]), "key rule: %s → %s" % [row[0], "toggle" if row[3] else "nothing"])


# --- D. AUTO policy (pure) -------------------------------------------------------------------------------------
func _auto_policy() -> void:
	var policy := AutoQuality.new()
	for row: Array in [[Vector2i(1280, 720), 1.0], [Vector2i(1920, 1080), 1.0], [Vector2i(2560, 1440), 0.85], [Vector2i(3024, 1964), 0.67], [Vector2i(3840, 2160), 0.67], [Vector2i(5120, 2880), 0.5], [Vector2i(7680, 4320), 0.5], [Vector2i.ZERO, 1.0]]:
		var size: Vector2i = row[0]
		check(is_equal_approx(policy.start_scale(size.x * size.y), float(row[1])), "start scale for %s = %.2f" % [size, row[1]])
	check(absf(policy.ceiling_for(7680 * 4320) - 0.5) < 0.002 and is_equal_approx(policy.ceiling_for(3840 * 2160), 1.0) and absf(policy.ceiling_for(5120 * 2880) - 0.75) < 0.002, "internal 3D ceiling 8.3 Mpx: 8K 0.5, 5K 0.75, 4K 1.0")
	for row: Array in [[Vector2i(1920, 1080), Viewport.MSAA_4X], [Vector2i(2560, 1440), Viewport.MSAA_2X], [Vector2i(7680, 4320), Viewport.MSAA_2X]]:
		var size: Vector2i = row[0]
		policy.seed_from(size.x * size.y)
		check(policy.msaa == int(row[1]), "start MSAA for %s" % size)
	# Controller on 4K: 0.67 start.
	policy.seed_from(3840 * 2160)
	var changed := false
	for i: int in 63:   # 1.89 s of 30 ms frames
		changed = policy.feed(0.030, true) or changed
	check(not changed and is_equal_approx(policy.scale, 0.67), "slow frames under 2 s change nothing")
	for i: int in 5:
		changed = policy.feed(0.030, true) or changed
	check(changed and is_equal_approx(policy.scale, 0.62), "2 s of slow frames step down 0.05 (%.3f)" % policy.scale)
	changed = false
	for i: int in 90:   # 2.7 s more: still inside the 3 s gap
		changed = policy.feed(0.030, true) or changed
	check(not changed, "no second change within 3 s")
	for i: int in 12:
		changed = policy.feed(0.030, true) or changed
	check(changed and is_equal_approx(policy.scale, 0.57), "the next step comes only after 3 s")
	changed = false
	for i: int in 600:   # alternating long/short: no 2 s run and no 5 s run
		changed = policy.feed(0.030 if i % 2 == 0 else 0.010, true) or changed
	check(not changed, "hysteresis: alternating frames never move the scale")
	for i: int in 700:   # 10 s in the middle band (between 80 % and 100 % of the target)
		changed = policy.feed(0.0145, true) or changed
	check(not changed, "frames between 80 % and 100 % of the target hold the scale")
	for i: int in 510:   # 5.1 s of fast frames
		changed = policy.feed(0.010, true) or changed
	check(changed and is_equal_approx(policy.scale, 0.62), "5 s of fast frames step up 0.05 (%.3f)" % policy.scale)
	changed = false
	for i: int in 60:
		policy.feed(0.030, true)
	for i: int in 300:
		changed = policy.feed(0.030, false) or changed
	for i: int in 60:
		changed = policy.feed(0.030, true) or changed
	check(not changed, "pause and menus reset the slow run (1.8 s + paused + 1.8 s ≠ 2 s)")
	policy.feed(0.0145, true)   # one ordinary frame ends that slow run
	check(not policy.feed(5.0, true) and is_equal_approx(policy.scale, 0.62), "one 5 s loading hitch is not a slow trend")
	var steps := 0
	for i: int in 9:
		if policy.feed(0.3, true):
			steps = i + 1
	check(steps > 0 and steps <= 9, "a steady 3 FPS still steps down (after %d frames)" % steps)
	for i: int in 3000:
		policy.feed(0.050, true)
	check(is_equal_approx(policy.scale, 0.5), "never below the 0.5 floor")
	policy.seed_from(7680 * 4320)
	for i: int in 3000:
		policy.feed(0.005, true)
	check(policy.scale <= 0.501, "8K never rises above the internal ceiling (%.3f)" % policy.scale)
	policy.seed_from(1920 * 1080)
	for i: int in 3000:
		policy.feed(0.005, true)
	check(is_equal_approx(policy.scale, 1.0), "1080p never rises above 1.0")
	# Blood budget from the start level.
	for row: Array in [[720, 1.0, "low"], [768, 1.0, "low"], [900, 1.0, "medium"], [1080, 1.0, "high"], [1440, 0.85, "high"], [1964, 0.67, "high"], [4320, 0.5, "high"], [0, 1.0, "high"]]:
		check(policy.blood_tier_for(int(row[0]), float(row[1])) == row[2], "blood tier for %d rows at %.2f = %s" % row)
	# Upscaler choice is decided from availability; temporal modes never appear.
	var temporal: Array[int] = [Viewport.SCALING_3D_MODE_FSR2, Viewport.SCALING_3D_MODE_METALFX_TEMPORAL]
	for method: String in ["forward_plus", "mobile", "gl_compatibility"]:
		for device: bool in [false, true]:
			for metalfx: bool in [false, true]:
				var mode: int = AutoQuality.pick_upscaler(method, device, metalfx)
				var expected := Viewport.SCALING_3D_MODE_BILINEAR
				if device and method != "gl_compatibility":
					if metalfx:
						expected = Viewport.SCALING_3D_MODE_METALFX_SPATIAL
					elif method == "forward_plus":
						expected = Viewport.SCALING_3D_MODE_FSR
				check(mode == expected and not temporal.has(mode), "upscaler for %s rd=%s metalfx=%s → %d" % [method, device, metalfx, mode])


# --- D'. AUTO in this (headless) run ---------------------------------------------------------------------------
func _auto_runtime() -> void:
	graphics.load_settings(_path("runtime"))
	check(graphics.get_profile() == "auto", "runtime starts in AUTO")
	check(is_equal_approx(root.scaling_3d_scale, 1.0) and root.msaa_3d == Viewport.MSAA_4X, "headless AUTO seeds like the old High (no screen pixels)")
	if mutation == "upscaler":
		graphics.set("_upscaler", Viewport.SCALING_3D_MODE_METALFX_SPATIAL)   # trusting a request nobody checked
		graphics.auto.scale = 0.67
		graphics.call("_apply_auto_scale")
	check(RenderingServer.get_rendering_device() != null or graphics.detect_upscaler() == Viewport.SCALING_3D_MODE_BILINEAR, "no rendering device → bilinear is detected")
	check(root.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and graphics.active_upscaler() == Viewport.SCALING_3D_MODE_BILINEAR, "headless AUTO requests bilinear, never an unavailable upscaler")
	var line: String = graphics.auto_summary()
	print("DISPLAY_AUTO_TRACE headless_auto line=\"%s\" scale=%.2f msaa=%d mode=%d rd=%s" % [line, root.scaling_3d_scale, root.msaa_3d, root.scaling_3d_mode, RenderingServer.get_rendering_device() != null])
	check(RegEx.create_from_string("^Auto: 3D at [0-9]+ % of [0-9]+×[0-9]+\\. Text and controls stay sharp\\.$").search(line) != null, "AUTO line has the T8 shape without an upscaler: " + line)
	graphics.set_profile("auto")
	# The label names an upscaler only while it acts.
	graphics.set("_upscaler", Viewport.SCALING_3D_MODE_FSR)
	graphics.auto.scale = 0.67
	check(graphics.auto_summary().contains("3D at 65 %") and graphics.auto_summary().contains(" · FSR."), "an acting FSR is named, 0.67 rounds to 65 %")
	graphics.auto.scale = 1.0
	check(not graphics.auto_summary().contains("FSR"), "at full scale the upscaler is not named")
	graphics.auto.scale = 0.67
	graphics.call("_apply_auto_scale")
	check(root.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR, "AUTO below full scale requests its upscaler")
	graphics.set_profile("high")
	check(root.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and graphics.active_upscaler() == Viewport.SCALING_3D_MODE_BILINEAR, "manual High drops the upscaler")
	for profile: String in ["auto", "low", "medium", "high"]:
		graphics.set_profile(profile)
		check(root.anisotropic_filtering_level == Viewport.ANISOTROPY_16X, "16× anisotropy on the root viewport in " + profile)
	check(int(ProjectSettings.get_setting("rendering/textures/default_filters/anisotropic_filtering_level")) == 4, "project default anisotropy is 16×")
	# Blood: AUTO uses its start tier; manual presets keep their own; the controller never moves it.
	graphics.set_profile("auto")
	check(graphics.budget_profile().id == "high" and (BloodScript.call("profile") as QualityProfile).id == "high", "headless AUTO blood budget = High")
	for profile: String in ["low", "medium", "high"]:
		graphics.set_profile(profile)
		check((BloodScript.call("profile") as QualityProfile).id == profile, "BloodFx follows manual " + profile)
	graphics.set_profile("auto")
	var tier: String = graphics.auto.blood_tier
	for i: int in 400:
		graphics.auto.feed(0.050, true)
	check(graphics.auto.blood_tier == tier, "the frame-time controller never changes the blood budget")
	# Headless: the controller is off and frames never move the scale.
	graphics.set_profile("auto")
	if mutation == "headless_controller":
		graphics.scripted_override = 0
	check(not graphics.controller_active(), "headless AUTO runs no frame-time controller")
	var changes: int = graphics.auto.changes
	var scale: float = root.scaling_3d_scale
	await _frames(150)
	check(graphics.auto.changes == changes and is_equal_approx(root.scaling_3d_scale, scale), "150 headless frames leave the scale alone")
	graphics.scripted_override = 0
	check(graphics.controller_active(), "outside scripted runs AUTO does run the controller (the rule, not something else, turns it off)")
	graphics.set_profile("medium")
	check(not graphics.controller_active(), "manual presets never run the controller")
	graphics.scripted_override = -1


# --- E. menu, panel and the keys there -------------------------------------------------------------------------
func _menu_and_panel() -> void:
	var file := _path("panel")
	graphics.load_settings(file)
	var comfort: Node = root.get_node("ComfortSettings")
	var old_comfort: String = comfort.storage_path
	comfort.load_settings(_path("panel_comfort"))
	root.size = Vector2i(1600, 900)
	root.gui_embed_subwindows = true
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await _frames(4)
	var launcher: Button = menu.get("_comfort_button")
	launcher.grab_focus()
	var modal: Control = menu.get("_comfort")
	# Alt+Enter in the menu toggles and does not press the focused launcher.
	var requests: int = graphics.window_requests
	_press("alt_enter")
	_release("alt_enter")
	await _frames(3)
	check(graphics.get_window_mode() == "windowed" and graphics.window_requests == requests + 1, "Alt+Enter in the menu toggles once")
	check(not modal.visible and launcher.has_focus(), "Alt+Enter does not press the focused button")
	# F11 with key repeat: one press, one toggle.
	requests = graphics.window_requests
	_key(KEY_F11, true)
	_key(KEY_F11, true, {}, true)
	_key(KEY_F11, true, {}, true)
	_key(KEY_F11, false)
	await _frames(2)
	check(graphics.get_window_mode() == "fullscreen" and graphics.window_requests == requests + 1, "held F11 (echo) toggles once")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await _frames(3)
	check(modal.visible, "Enter opens the panel")
	check(modal.display_choice != null, "DISPLAY row exists on desktop")
	var focus: Array = modal.get("_focus_order")
	check(not focus.is_empty() and focus[0] == modal.display_choice and focus[1] == modal.quality_choice, "DISPLAY is the first focus stop, above GRAPHICS QUALITY")
	check((modal.sliders["master"] as HSlider).has_focus(), "focus still opens on MASTER")
	check(modal.display_choice.focus_neighbor_top == modal.display_choice.get_path_to(modal.back_button) and modal.back_button.focus_neighbor_bottom == modal.back_button.get_path_to(modal.display_choice), "ring: BACK ↔ DISPLAY")
	check(modal.display_choice.selected == 0, "row shows FULLSCREEN")
	var help: String = modal.controls_label.text
	check(help.contains("WINDOW\n") and help.contains("F11 anytime"), "controls help has the WINDOW block")
	_key(KEY_UP, true)
	_key(KEY_UP, false)
	await _frames(2)
	_key(KEY_UP, true)
	_key(KEY_UP, false)
	await _frames(2)
	check(modal.display_choice.has_focus(), "keyboard reaches DISPLAY: ↑↑ from MASTER")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await _frames(3)
	var popup: PopupMenu = modal.display_choice.get_popup()
	check(popup.visible, "Enter opens the DISPLAY list")
	_key(KEY_DOWN, true)
	_key(KEY_DOWN, false)
	await _frames(2)
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await _frames(3)
	check(graphics.get_window_mode() == "windowed" and modal.display_choice.selected == 1, "keyboard selects WINDOWED")
	check(_cfg(file).get_value("display", "window_mode", "") == "windowed", "row choice is saved")
	check(modal.visible and modal.display_choice.has_focus(), "panel stays open with focus on DISPLAY")
	_key(KEY_F11, true)
	_key(KEY_F11, false)
	await _frames(2)
	check(modal.display_choice.selected == 0 and graphics.get_window_mode() == "fullscreen", "F11 while the panel is open updates the row at once")
	_press("alt_enter")
	_release("alt_enter")
	await _frames(3)
	check(graphics.get_window_mode() == "windowed" and modal.display_choice.selected == 1 and not popup.visible, "Alt+Enter in the panel toggles without opening the focused list")
	# AUTO line under the quality list.
	var quality_help: Label = modal.get("quality_help")
	check(graphics.get_profile() == "auto" and quality_help.text.begins_with("Auto: 3D at ") and quality_help.text.ends_with("Text and controls stay sharp."), "AUTO line under the list: " + quality_help.text)
	modal.quality_choice.select(1)
	modal.quality_choice.item_selected.emit(1)
	check(graphics.get_profile() == "low" and quality_help.text == "Applies immediately. Text and controls stay sharp.", "manual presets keep the old line")
	check(_cfg(file).get_value("display", "window_mode", "") == "windowed" and _cfg(file).get_value("graphics", "profile", "") == "low", "profile and display keys live side by side")
	modal.close_panel()
	menu.queue_free()
	await _frames(4)
	comfort.load_settings(old_comfort)


# --- F. the keys in a running fight ----------------------------------------------------------------------------
func _fight_keys() -> void:
	var file := _path("fight")
	graphics.load_settings(file)
	graphics.set_window_mode("windowed")   # a file with a known display choice
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	var flow: Node = arena.get_node("MatchFlow")
	var p1: Node = arena.get("p1")
	var p2: Node = arena.get("p2")
	if p2.get("_brain") != null:
		p2._brain.process_mode = Node.PROCESS_MODE_DISABLED
	for i: int in 300:
		if int(flow.get("phase")) == MF.Phase.FIGHT:
			break
		await physics_frame
	await _ticks(10)
	check(int(flow.get("phase")) == MF.Phase.FIGHT and not paused and not router.ui_suppressed(), "the fight is running and no UI owns input")
	for profile: String in ["solo", "shared"]:
		router.apply_profile(profile, false)
		await _ticks(2)
		# What each combination does with the fullscreen code in place versus its keys alone.
		var pairs: Array = [["alt_enter", "alt"], ["ctrl_cmd_f", "ctrl_f"]]
		for pair: Array in pairs:
			_press(pair[1])
			var alone := _held()
			_release(pair[1])
			await _ticks(3)
			var before := _bytes(file)
			var requests: int = graphics.window_requests
			_press(pair[0])
			if mutation == "combat_key" and pair[0] == "alt_enter":
				graphics.toggle_window_mode()   # as if the key ignored who owns input
			var combo := _held()
			_release(pair[0])
			await _ticks(3)
			print("DISPLAY_AUTO_TRACE fight=%s combo=%s held=%s alone=%s held_alone=%s" % [profile, pair[0], combo, pair[1], alone])
			check(combo == alone, "%s %s holds exactly what %s holds: %s vs %s" % [profile, pair[0], pair[1], combo, alone])
			check(graphics.get_window_mode() == "windowed" and graphics.window_requests == requests and _bytes(file) == before, "%s %s in a fight leaves the window and the file alone" % [profile, pair[0]])
		var any_alone := false
		for value: Variant in (_held() as Dictionary).values():
			any_alone = any_alone or bool(value)
		var requests: int = graphics.window_requests
		_press("f11")
		var during := _held()
		_release("f11")
		await _ticks(3)
		var none := true
		for value: Variant in during.values():
			none = none and not bool(value)
		check(not any_alone and none, "%s F11 in a fight holds no dash, block, detach or hand: %s" % [profile, during])
		check(graphics.get_window_mode() == "fullscreen" and graphics.window_requests == requests + 1, "%s F11 in a fight toggles once" % profile)
		graphics.set_window_mode("windowed")
	# The fighter really blocks with Ctrl+Cmd+F held, just like with F (SOLO: F is block).
	router.apply_profile("solo", false)
	await _ticks(20)
	var states := {}
	for combo: String in ["f", "ctrl_cmd_f"]:
		_press(combo)
		await _ticks(6)
		states[combo] = int(p1.get("state"))
		_release(combo)
		await _ticks(20)
	print("DISPLAY_AUTO_TRACE fighter_state F=%d ctrl_cmd_f=%d (BLOCK=%d)" % [states["f"], states["ctrl_cmd_f"], F.State.BLOCK])
	check(states["f"] == F.State.BLOCK and states["ctrl_cmd_f"] == states["f"], "P1 blocks with Ctrl+Cmd+F exactly as with F (states %s)" % states)
	_press("f11")
	await _ticks(6)
	var f11_state := int(p1.get("state"))
	_release("f11")
	await _ticks(6)
	check(f11_state != F.State.BLOCK and f11_state != F.State.DASH, "F11 does not make P1 block or dash (state %d)" % f11_state)
	check(not paused and not router.ui_suppressed(), "no key opened the pause")
	arena.queue_free()
	await _frames(4)
	router.apply_profile("solo", false)


# --- G. phone: no DISPLAY row, no keys, saved mode ignored -----------------------------------------------------
func _phone() -> void:
	var file := _path("phone")
	_write(file, "[display]\n\nwindow_mode=\"windowed\"\n")
	graphics.mobile_override = 1
	graphics.load_settings(file)
	check(graphics.get_window_mode() == "fullscreen", "a phone ignores a saved WINDOWED")
	check(not graphics.set_window_mode("windowed") and not graphics.display_switchable(), "a phone cannot switch")
	var requests: int = graphics.window_requests
	_key(KEY_F11, true)
	_key(KEY_F11, false)
	await _frames(2)
	check(graphics.window_requests == requests, "F11 does nothing on a phone")
	var panel: Control = PanelScript.new()
	root.add_child(panel)
	await _frames(2)
	var focus: Array = panel.get("_focus_order")
	check(panel.get("display_choice") == null and focus[0] == panel.get("quality_choice"), "no DISPLAY row on a phone; GRAPHICS QUALITY is first")
	panel.call("show_panel", null, "")
	await _frames(2)
	check(not (panel.get("controls_label") as Label).text.contains("WINDOW\n"), "no WINDOW help on a phone")
	panel.call("close_panel")
	panel.queue_free()
	await _frames(2)
	graphics.mobile_override = -1
