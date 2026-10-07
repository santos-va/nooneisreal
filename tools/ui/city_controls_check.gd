extends SceneTree
## Plan docs/Plans/2026-10-07-First-Enemy-Lethal-Fight.md step 0 (T8 spec, docs/GDD/06-UI-UX.md "Відомі
## розриви"): real keyboard and gamepad events in the production CityWorld, no action-map rewrites.
##   A. A sealed press (skill / ultimate / enemy hook) is reported once per press from any state, the
##      bottom hint explains it for ~2 s, not more often than its interval, the pause help names it,
##      and nothing starts in the fighter.
##   B. COMFORT & CONTROLS opens from the city pause; the city HUD stays the only pause owner; closing
##      returns to the same pause with focus on the launcher; sound and graphics apply as in the menu.
## Literal thresholds of the spec (never read from CityHud): hint within 3 physics ticks, still shown
## at 1.8 s, gone by 2.4 s; no second hint within 4 s of the first; shown again by 9 s.
## --break=signal|interval|comfort|focus are negative controls.
## Sentinel: CITY_CONTROLS_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_CONTROLS: ...".
const HINT_WITHIN_TICKS: int = 3
const HINT_STILL_AT: float = 1.8
const HINT_GONE_BY: float = 2.4
const NO_REPEAT_WITHIN: float = 4.0
const REPEAT_BY: float = 9.0
const SEALED_TEXT: String = "SKILLS SEALED IN THE CITY"
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var sealed: Array[String] = []
var router: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_CONTROLS: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	_send(event)


func _tap_key(code: Key) -> void:
	_key(code, true)
	await _ticks(1)
	_key(code, false)


func _pad(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	_send(event)


func _tap_pad(button: JoyButton) -> void:
	_pad(button, true)
	await _ticks(1)
	_pad(button, false)


## Ticks until the hint line shows the sealed text, up to `limit`; -1 if it never does.
func _hint_after(hud: Node, limit: int) -> int:
	for tick: int in limit + 1:
		if hud.hint_label.visible and SEALED_TEXT in hud.hint_label.text:
			return tick
		await _ticks(1)
	return -1


func _hint_shown(hud: Node) -> bool:
	return hud.hint_label.visible and SEALED_TEXT in hud.hint_label.text


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	var comfort_settings: Node = root.get_node("ComfortSettings")
	var graphics: Node = root.get_node("GraphicsSettings")
	var old_comfort_path: String = comfort_settings.get("storage_path")
	var old_graphics_path: String = graphics.get("storage_path")
	var old_profile: String = graphics.call("get_profile")
	comfort_settings.call("load_settings", "user://city_controls_comfort_%d.cfg" % OS.get_process_id())
	graphics.call("load_settings", "user://city_controls_graphics_%d.cfg" % OS.get_process_id())
	graphics.call("set_profile", "high")
	state.set_free_move(true)
	router.apply_profile("solo", false)
	state.p1_character = "choko"
	# The shared first row keeps the whole pause inside the canvas (same sizes as city_onboarding_check).
	var frame := SubViewport.new()
	frame.size = Vector2i(1600, 900)
	root.add_child(frame)
	var lone: Node = load("res://scripts/world/CityHud.gd").new()
	lone.setup(CityOnboarding.new())
	frame.add_child(lone)
	await _ticks(2)
	lone.set_paused(true)
	for dimensions: Vector2i in [Vector2i(1600, 900), Vector2i(2134, 900), Vector2i(1600, 1200)]:
		frame.size = dimensions
		await process_frame
		await process_frame
		for control: Control in [lone.resume_button, lone.comfort_button, lone.skip_button, lone.restart_button, lone.exit_button]:
			_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(control.get_global_rect()), "pause control %s %s fits %s" % [control.text, control.get_global_rect(), dimensions])
	lone.set_paused(false)
	frame.queue_free()
	await _ticks(2)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	var hero: Node = world.player
	var hud: Node = world.hud
	hero.sealed_action.connect(func(action: String): sealed.append(action))
	if mutation == "signal":
		for connection: Dictionary in hero.sealed_action.get_connections():
			if connection.callable.get_object() == hud:
				hero.sealed_action.disconnect(connection.callable)
	await _ticks(40)
	_check(not router.ui_suppressed() and not paused, "city starts in free exploration")

	# --- A. sealed skills -------------------------------------------------------------------------
	var help: String = hud.exploration_help()
	_check("Sealed in the city" in help and "fights only" in help, "pause help names the sealed skills")
	for action: String in ["skill1", "skill2", "ultimate", "grapple_enemy"]:
		_check(router.binding_label(1, action, false) in help.get_slice("Sealed in the city", 1), "help line carries the real key of " + action)
	var meter_before: float = hero.meter
	var cooldowns_before: Dictionary = hero.cooldowns.duplicate()
	await _tap_key(KEY_U) # SOLO skill1
	var shown_at: int = await _hint_after(hud, HINT_WITHIN_TICKS)
	_check(shown_at >= 0, "keyboard skill press shows the sealed hint within %d ticks (got %d)" % [HINT_WITHIN_TICKS, shown_at])
	_check(sealed == ["skill1"], "one keyboard press reports exactly one sealed skill1 (%s)" % [sealed])
	_check(hero.current_move == null and hero.state in [1, 2] and is_equal_approx(hero.meter, meter_before) and hero.cooldowns == cooldowns_before, "sealed press starts nothing in the fighter")
	var elapsed: float = float(maxi(shown_at, 0) + 1) / 60.0
	await _ticks(int(round((HINT_STILL_AT - elapsed) * 60.0)))
	_check(_hint_shown(hud), "hint still shown at %.1f s" % HINT_STILL_AT)
	await _ticks(int(round((HINT_GONE_BY - HINT_STILL_AT) * 60.0)))
	_check(not _hint_shown(hud), "hint gone by %.1f s" % HINT_GONE_BY)
	if mutation == "interval":
		hud.set("_sealed_since", INF) # Negative control: an interval of zero.
	await _ticks(int(round((3.0 - HINT_GONE_BY) * 60.0)))
	await _tap_key(KEY_Q) # SOLO enemy hook, 3 s after the first hint
	var repeated: int = await _hint_after(hud, 30)
	_check(repeated < 0, "no second hint within %.0f s of the first (shown after %d ticks)" % [NO_REPEAT_WITHIN, repeated])
	_check(sealed == ["skill1", "grapple_enemy"], "the throttled press is still consumed and reported once (%s)" % [sealed])
	await _ticks(int(round((REPEAT_BY - 3.0 - 0.6) * 60.0)))
	await _tap_pad(JOY_BUTTON_DPAD_UP) # pad ultimate
	_check(await _hint_after(hud, HINT_WITHIN_TICKS) >= 0, "gamepad ultimate shows the hint again by %.0f s" % REPEAT_BY)
	_check(sealed.size() == 3 and sealed[2] == "ultimate", "gamepad D-pad Up reports ultimate (%s)" % [sealed])
	_pad(JOY_BUTTON_Y, true)
	await _ticks(1)
	await _tap_pad(JOY_BUTTON_LEFT_SHOULDER)
	_pad(JOY_BUTTON_Y, false)
	await _ticks(2)
	_check(sealed.size() == 4 and sealed[3] == "skill1", "gamepad chord Y + LB reports skill1 (%s)" % [sealed])
	await _tap_key(KEY_SPACE)
	await _ticks(8)
	var airborne: bool = not hero.is_on_floor()
	await _tap_key(KEY_I) # SOLO skill2 in the air
	await _ticks(2)
	_check(airborne and sealed.size() == 5 and sealed[4] == "skill2", "a press in the air is reported too (airborne %s, %s)" % [airborne, sealed])
	await _ticks(90)

	# --- B. COMFORT & CONTROLS in the city pause --------------------------------------------------
	await _tap_key(KEY_ESCAPE)
	await _ticks(2)
	_check(hud.paused_ui and paused and router.ui_suppressed() and hud.resume_button.has_focus(), "Escape pauses the city with focus on RESUME")
	_check(not _hint_shown(hud), "the sealed hint never shows over the pause")
	_key(KEY_RIGHT, true)
	await process_frame
	_key(KEY_RIGHT, false)
	await process_frame
	_check(hud.comfort_button.has_focus(), "Right moves focus from RESUME to COMFORT & CONTROLS")
	if mutation == "comfort":
		for connection: Dictionary in hud.comfort_button.pressed.get_connections():
			hud.comfort_button.pressed.disconnect(connection.callable)
	_key(KEY_ENTER, true)
	await process_frame
	_key(KEY_ENTER, false)
	await _ticks(2)
	var modal: Control = hud.comfort
	_check(modal.visible and not hud.pause_panel.visible, "Enter opens COMFORT & CONTROLS over a hidden pause panel")
	_check(hud.paused_ui and paused and router.ui_suppressed(), "the city HUD stays the only pause owner while the modal is open")
	_check("Sealed in the city" in (modal.get("controls_label") as Label).text, "modal controls show the city help, sealed line included")
	var master: HSlider = modal.get("sliders")["master"]
	_check(master.has_focus(), "modal focuses its first slider")
	var volume_before: float = float(comfort_settings.call("get_value", "master"))
	var bus_before: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	_key(KEY_LEFT, true)
	await process_frame
	_key(KEY_LEFT, false)
	await process_frame
	var volume_after: float = float(comfort_settings.call("get_value", "master"))
	var bus_db: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	_check(volume_after < volume_before and bus_db < bus_before, "keyboard Left lowers master volume live (%.2f -> %.2f, bus %.2f -> %.2f dB)" % [volume_before, volume_after, bus_before, bus_db])
	var scale_before: float = root.scaling_3d_scale
	var quality: OptionButton = modal.get("quality_choice")
	quality.select(0)
	quality.item_selected.emit(0)
	_check(graphics.call("get_profile") == "low" and root.scaling_3d_scale != scale_before, "choosing Low applies to the city viewport at once (scale %.2f -> %.2f)" % [scale_before, root.scaling_3d_scale])
	if mutation == "focus":
		hud.comfort.closed.disconnect(Callable(hud, "_on_comfort_closed"))
	_key(KEY_ESCAPE, true)
	await process_frame
	_key(KEY_ESCAPE, false)
	await _ticks(2)
	_check(not modal.visible and hud.pause_panel.visible and hud.comfort_button.has_focus(), "Escape closes the modal back to the same pause with focus on its launcher")
	_check(hud.paused_ui and paused and router.ui_suppressed(), "closing the modal does not resume the city")
	await _tap_pad(JOY_BUTTON_A)
	await _ticks(2)
	_check(modal.visible, "pad A on the launcher reopens the modal")
	await _tap_pad(JOY_BUTTON_B)
	await _ticks(2)
	_check(not modal.visible and hud.pause_panel.visible and hud.comfort_button.has_focus() and paused, "pad B closes it back to the pause")
	await _tap_key(KEY_ESCAPE)
	await _ticks(2)
	_check(not hud.paused_ui and not paused and not router.ui_suppressed(), "Escape from the pause resumes and releases input")
	await _tap_key(KEY_ESCAPE)
	await _ticks(1)
	hud.comfort_button.grab_focus()
	await _tap_pad(JOY_BUTTON_A)
	await _ticks(2)
	_check(modal.visible and paused, "modal open again before leaving the pause")
	hud.set_paused(false) # Any leave path (resume, skip, restart, exit) goes through set_paused(false).
	await _ticks(2)
	_check(not modal.visible and not paused and not router.ui_suppressed(), "leaving the pause by any path closes the modal and releases every input owner")

	# Restore user settings untouched.
	graphics.call("set_profile", old_profile)
	for path: String in [comfort_settings.get("storage_path"), graphics.get("storage_path")]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	comfort_settings.set("storage_path", old_comfort_path)
	graphics.set("storage_path", old_graphics_path)
	world.queue_free()
	await _ticks(2)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_CONTROLS_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
