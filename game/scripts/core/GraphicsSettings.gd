extends Node
## Global presentation preference. The root viewport survives menu/city/duel changes.
## Owns the 3D quality profile (AUTO by default) and the window mode (DISPLAY row and the fullscreen key):
## docs/GDD/06-UI-UX.md § DISPLAY, AUTO-якість і клавіша повного екрана. Presentation only: nothing here changes
## gameplay, the input map or the simulation clock.
signal changed(profile: String)
signal display_changed(mode: String)

const SECTION := "graphics"
const DISPLAY_SECTION := "display"
## Panel order: Auto first and default. QualityProfile.ids() stays the three manual presets.
const PROFILES: Array[String] = ["auto", "low", "medium", "high"]
const DEFAULT_PROFILE := "auto"   # only while nothing is saved: a saved low/medium/high never migrates
const SAFE_PROFILE := "high"      # unreadable file or unknown saved profile: the pre-AUTO session default
const WINDOW_MODES: Array[String] = ["fullscreen", "windowed"]
const DEFAULT_WINDOW_MODE := "fullscreen"
## T2 PLACEHOLDER: a mode we just requested may still be animating (macOS opens a separate Space); a mismatch seen
## inside this window is our own transition, not the player's, and is re-requested once instead of being saved.
const WINDOW_GUARD_MS := 5000

var storage_path: String = "user://graphics.cfg"
var auto := AutoQuality.new()
var mobile_override: int = -1     # tests: 0 desktop, 1 phone; -1 reads the OS features
var scripted_override: int = -1   # tests: 0/1 forces the scripted-run rule; -1 detects headless or --script
var window_requests: int = 0      # DisplayServer window requests (headless has no real window to observe)
var save_error: Error = OK        # the last graphics.cfg write attempt, shown by the panel status
var _profile: String = DEFAULT_PROFILE
var _window_mode: String = DEFAULT_WINDOW_MODE
var _observed_mode: String = ""
var _guard_until_ms: int = 0
var _reapplied: bool = false
var _config := ConfigFile.new()
var _load_error: Error = OK
var _upscaler: int = Viewport.SCALING_3D_MODE_BILINEAR
var _seeded_pixels: int = -1
var _last_usec: int = 0
var _scripted: int = -1           # cached command-line answer of scripted_run()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	# project.godot starts in EXCLUSIVE_FULLSCREEN (no windowed first frame); only a saved WINDOWED needs a request.
	if display_switchable() and not is_headless() and _window_mode != DEFAULT_WINDOW_MODE:
		_request_window_mode()
	if not scripted_run():
		get_tree().root.size_changed.connect(_on_root_resized)


# --- quality profile -------------------------------------------------------------------------------------------

func get_profile() -> String:
	return _profile


func set_profile(value: Variant) -> bool:
	if not value is String or not PROFILES.has(value):
		return false
	_profile = value
	_apply_profile()
	changed.emit(_profile)
	return true


## The lethal-blood budget: the manual preset, or in AUTO the tier fixed when AUTO was applied (BloodFx).
func budget_profile() -> QualityProfile:
	var profile: QualityProfile = QualityProfile.make(auto.blood_tier if _profile == "auto" else _profile)
	return profile if profile != null else QualityProfile.make(SAFE_PROFILE)


func controller_active() -> bool:
	return _profile == "auto" and not scripted_run()


## Upscaler AUTO would request on this device: decided before the request (T3 § б).
func detect_upscaler() -> int:
	var device := RenderingServer.get_rendering_device()
	var metalfx := device != null and device.has_feature(RenderingDevice.SUPPORTS_METALFX_SPATIAL)
	return AutoQuality.pick_upscaler(RenderingServer.get_current_rendering_method(), device != null, metalfx)


## The upscaler that acts now: only in AUTO and only below full scale.
func active_upscaler() -> int:
	return _upscaler if _profile == "auto" and auto.scale < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR


## T8 A3 line: actual output pixels, the 3D share rounded to 5 % and the upscaler only when it really acts.
func auto_summary() -> String:
	var output: Vector2i = get_tree().root.size
	var upscaler := AutoQuality.upscaler_name(active_upscaler())
	return "Auto: 3D at %d %% of %d×%d%s. Text and controls stay sharp." % [auto.percent(), output.x, output.y,
		"" if upscaler.is_empty() else " · " + upscaler]


func _apply_profile() -> void:
	var root: Window = get_tree().root
	if _profile == "auto":
		_seed_auto(true, true)
	else:
		QualityProfile.make(_profile).apply_to(root)
		_upscaler = Viewport.SCALING_3D_MODE_BILINEAR


func _seed_auto(force: bool, seed_blood: bool) -> void:
	var seed_size := _seed_size()
	var pixels := seed_size.x * seed_size.y
	if force or pixels != _seeded_pixels:
		_seeded_pixels = pixels
		auto.seed_from(pixels)
		_upscaler = detect_upscaler()
	if seed_blood:
		var screen := _screen_size()
		auto.blood_tier = auto.blood_tier_for(screen.y, auto.start_scale(screen.x * screen.y))
	_apply_auto_scale()


func _apply_auto_scale() -> void:
	var root: Window = get_tree().root
	root.scaling_3d_scale = auto.scale
	root.msaa_3d = auto.msaa
	root.scaling_3d_mode = active_upscaler()
	root.anisotropic_filtering_level = QualityProfile.ANISOTROPY


## AUTO seeds from the pixels it renders: the screen in fullscreen (also before a macOS Space transition has
## resized the window), the window otherwise. Headless has neither and seeds like the old High (scale 1, MSAA 4×).
func _seed_size() -> Vector2i:
	if is_headless():
		return Vector2i.ZERO
	if _window_mode == "fullscreen" or is_mobile():
		var screen := _screen_size()
		if screen.x > 0 and screen.y > 0:
			return screen
	return get_tree().root.size


func _screen_size() -> Vector2i:
	if is_headless():
		return Vector2i.ZERO
	return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var frame_s := 0.0 if _last_usec == 0 else float(now - _last_usec) / 1.0e6
	_last_usec = now
	if not controller_active():
		return
	# Pause, menus and modal panels own the screen: AUTO holds its scale there (T8 § 3).
	var playing := not get_tree().paused and not InputRouter.ui_suppressed()
	if auto.feed(frame_s, playing):
		_apply_auto_scale()


# --- window mode -----------------------------------------------------------------------------------------------

func get_window_mode() -> String:
	return DEFAULT_WINDOW_MODE if is_mobile() else _window_mode


func display_switchable() -> bool:
	return not is_mobile()


func is_mobile() -> bool:
	return mobile_override == 1 if mobile_override >= 0 else OS.has_feature("mobile")


func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


## Headless runs and test scripts (`--script`) never run the frame-time controller nor follow window events:
## their frames are not a player's frames, and X11 without a window manager reports modes inconsistently.
func scripted_run() -> bool:
	if scripted_override >= 0:
		return scripted_override == 1
	if _scripted < 0:
		var arguments := OS.get_cmdline_args()
		_scripted = 1 if is_headless() or arguments.has("--script") or arguments.has("-s") else 0
	return _scripted == 1


## The DISPLAY row and the keys. Selecting the current mode writes nothing.
func set_window_mode(value: Variant) -> bool:
	if not display_switchable() or not value is String or not WINDOW_MODES.has(value):
		return false
	if value == _window_mode:
		return true
	_window_mode = value
	_request_window_mode()
	save_error = save_display()
	display_changed.emit(_window_mode)
	if _profile == "auto":
		_seed_auto(false, false)
	return true


func toggle_window_mode() -> bool:
	return set_window_mode("windowed" if _window_mode == "fullscreen" else "fullscreen")


## F11 any time; Alt+Enter and Ctrl+Cmd+F only while UI owns input: in play Alt is dash, F is block / left hand and
## Ctrl is detach (T8 К2). Exact modifiers; echo never toggles twice. Both UI combos are accepted on every desktop.
static func is_fullscreen_key(event: InputEventKey, ui_owns_input: bool) -> bool:
	if event == null or not event.pressed or event.echo:
		return false
	if (event.keycode == KEY_F11 or event.physical_keycode == KEY_F11) and not (event.ctrl_pressed or event.alt_pressed or event.meta_pressed):
		return true
	if not ui_owns_input:
		return false
	var enter := event.keycode in [KEY_ENTER, KEY_KP_ENTER] or event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]
	if enter and event.alt_pressed and not event.ctrl_pressed and not event.meta_pressed:
		return true
	# F by key or by position, so Ctrl+Cmd+F also works in the Ukrainian layout.
	var f := event.keycode == KEY_F or event.physical_keycode == KEY_F
	return f and event.ctrl_pressed and event.meta_pressed and not event.alt_pressed and not event.shift_pressed


## _input runs before GUI (viewport.cpp:3537): a handled Alt+Enter never presses the focused button.
func _input(event: InputEvent) -> void:
	if not display_switchable() or not event is InputEventKey:
		return
	if is_fullscreen_key(event as InputEventKey, InputRouter.ui_suppressed()):
		get_viewport().set_input_as_handled()
		toggle_window_mode()


## A mode changed outside the game (the macOS green button, OS keys): the row follows and it is saved as the
## player's choice. MINIMIZED is never recorded. Returns true when a new choice was recorded.
func sync_from_window(reported: int = -1) -> bool:
	if not display_switchable():
		return false
	# Scripted runs never read the window themselves (see scripted_run); tests pass `reported` explicitly.
	if reported < 0 and scripted_run():
		return false
	var seen := _mode_name(DisplayServer.window_get_mode() if reported < 0 else reported)
	if seen.is_empty():
		return false
	if Time.get_ticks_msec() < _guard_until_ms:
		if seen != _window_mode and not _reapplied:
			_reapplied = true
			_send_window_request()
		return false
	if seen == _observed_mode:
		return false
	_observed_mode = seen
	if seen == _window_mode:
		return false
	_window_mode = seen
	save_error = save_display()
	display_changed.emit(_window_mode)
	return true


## Tests: the guard runs on wall time.
func expire_window_guard() -> void:
	_guard_until_ms = 0


static func _mode_name(mode: int) -> String:
	match mode:
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return "fullscreen"
		DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_MAXIMIZED:
			return "windowed"
	return ""


func _on_root_resized() -> void:
	sync_from_window()
	if _profile == "auto":
		_seed_auto(false, false)


func _request_window_mode() -> void:
	_observed_mode = _window_mode
	_guard_until_ms = Time.get_ticks_msec() + WINDOW_GUARD_MS
	_reapplied = false
	_send_window_request()


func _send_window_request() -> void:
	window_requests += 1
	var current := DisplayServer.window_get_mode()
	if _window_mode == "fullscreen":
		if current != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		return
	if current in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_MAXIMIZED]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if is_headless():
		return
	# Plan p. 1: WINDOWED is the 1152×648 window (project override) in screen points, centred in the work area.
	var screen := DisplayServer.window_get_current_screen()
	var base := Vector2(int(ProjectSettings.get_setting("display/window/size/window_width_override", 1152)),
		int(ProjectSettings.get_setting("display/window/size/window_height_override", 648)))
	var size := Vector2i(base * maxf(DisplayServer.screen_get_scale(screen), 1.0))
	var usable := DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x > 0 and usable.size.y > 0:
		size = size.min(usable.size)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)
	else:
		DisplayServer.window_set_size(size)


# --- persistence -----------------------------------------------------------------------------------------------

func load_settings(path: String = "") -> Error:
	if not path.is_empty():
		storage_path = path
	_config = ConfigFile.new()
	_load_error = _config.load(storage_path)
	var selected: String = DEFAULT_PROFILE
	var mode: String = DEFAULT_WINDOW_MODE
	if _load_error == ERR_FILE_NOT_FOUND:
		_load_error = OK
	elif _load_error == OK:
		var raw: Variant = _config.get_value(SECTION, "profile", DEFAULT_PROFILE)
		if raw is String and PROFILES.has(raw):
			selected = raw
		else:
			selected = SAFE_PROFILE
			_load_error = ERR_INVALID_DATA
		var raw_mode: Variant = _config.get_value(DISPLAY_SECTION, "window_mode", DEFAULT_WINDOW_MODE)
		if raw_mode is String and WINDOW_MODES.has(raw_mode):
			mode = raw_mode
		else:
			_load_error = ERR_INVALID_DATA
	else:
		selected = SAFE_PROFILE
	_window_mode = mode
	_observed_mode = mode
	set_profile(selected)
	return _load_error


func save_settings() -> Error:
	save_error = _save_value(SECTION, "profile", _profile)
	return save_error


func save_display() -> Error:
	return _save_value(DISPLAY_SECTION, "window_mode", _window_mode)


## Only the changed key is written; every other section and key survives. Invalid/future values and malformed
## files stay intact for recovery: the change applies for this session only.
func _save_value(section: String, key: String, value: Variant) -> Error:
	if _load_error != OK:
		return _load_error
	_config.set_value(section, key, value)
	var temporary_path: String = storage_path + ".tmp"
	var result: Error = _config.save(temporary_path)
	if result != OK:
		return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(storage_path))
