extends SceneTree
## Real viewport UI input; root serial runner owns engine execution.
var failures := 0
var viewport: SubViewport
var mutation := ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var preferences: Node = root.get_node("ComfortSettings")
	var old_path: String = preferences.get("storage_path")
	preferences.call("load_settings", "user://comfort_ui_%d.cfg" % OS.get_process_id())
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	viewport.add_child(menu)
	await _settle()
	var launcher: Button = menu.get("_comfort_button")
	await _click(launcher)
	var modal: Control = menu.get("_comfort")
	_check(modal.visible, "mouse opens settings")
	if mutation == "footer":
		(menu.get("_foot") as Label).add_theme_font_size_override("font_size", 8)
	if mutation == "focus":
		(modal.get("controls_label") as Label).focus_mode = Control.FOCUS_NONE
	if mutation == "bounds":
		(modal.get("panel") as Control).custom_minimum_size.x = 3000
	for dimensions in [Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(1948, 900)]:
		viewport.size = dimensions
		await _settle()
		_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses((modal.get("panel") as Control).get_global_rect()), "modal fits canvas")
		var footer: Label = menu.get("_foot")
		var width := footer.get_theme_font("font").get_string_size(footer.text, HORIZONTAL_ALIGNMENT_LEFT, -1, footer.get_theme_font_size("font_size")).x
		_check(width <= footer.size.x, "compact footer actually fits without clipping")
	for physical_scale in [648.0 / 900.0, 768.0 / 1200.0, 390.0 / 900.0]:
		_check((menu.get("_foot") as Label).get_theme_font_size("font_size") * physical_scale >= 13.8, "footer physical font floor")
		_check((modal.get("controls_label") as Label).get_theme_font_size("font_size") * physical_scale >= 13.8, "controls physical font floor")
	var slider: HSlider = modal.get("sliders")["master"]
	slider.grab_focus()
	var before := slider.value
	await _key(KEY_LEFT)
	_check(slider.value < before, "keyboard changes focused slider")
	_check(is_equal_approx(float(preferences.call("get_value", "master")), slider.value / 100.0), "slider applies preference live")
	var saved_config := ConfigFile.new()
	_check(saved_config.load(preferences.get("storage_path")) == OK and is_equal_approx(float(saved_config.get_value("comfort", "master", -1)), slider.value / 100.0), "slider preference persisted")
	(modal.get("restore_button") as Button).grab_focus()
	await _key(KEY_ENTER)
	_check(is_equal_approx(slider.value, 80.0) and is_equal_approx(float(preferences.call("get_value", "master")), 0.8), "restore button resets live UI and preference")
	var help: Label = modal.get("controls_label")
	_check("Crouch: D-pad Down" in help.text, "help names actual crouch controller binding")
	_check(help.focus_mode == Control.FOCUS_ALL, "controls help is focusable")
	(modal.get("restore_button") as Button).grab_focus()
	await _key(KEY_TAB)
	_check(help.has_focus(), "Tab reaches controls from restore defaults")
	await _settle()
	var scroll: ScrollContainer = modal.get("scroll")
	scroll.scroll_vertical = 0
	await _settle()
	for i in 100:
		if scroll.scroll_vertical >= scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page - 2:
			break
		await _pad(JOY_BUTTON_DPAD_DOWN)
	_check(scroll.scroll_vertical >= scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page - 2, "controller can reach last controls line")
	await _key(KEY_ESCAPE)
	_check(not modal.visible and launcher.has_focus(), "Escape returns focus to menu invoker")
	await _pad(JOY_BUTTON_A)
	_check(modal.visible, "controller accept reopens settings")
	await _pad(JOY_BUTTON_B)
	_check(not modal.visible and launcher.has_focus(), "controller cancel closes without activating underlying button")
	menu.queue_free()
	await _settle()
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	viewport.add_child(arena)
	await _settle()
	var saved_shake: float = preferences.call("get_value", "shake")
	for camera_name in ["camera", "duel_camera"]:
		var controller: Node = arena.get(camera_name)
		if controller == null:
			continue
		controller.call("setup", arena.get("p1"), arena.get("p2"))
		preferences.call("set_value", "shake", 1.0)
		controller.call("shake", 0.7)
		controller.call("_process", 0.016)
		var lens: Camera3D = controller.get("cam")
		_check(absf(lens.h_offset) + absf(lens.v_offset) > 0.00001, camera_name + " positive shake is wired")
		preferences.call("set_value", "shake", 0.0)
		controller.call("_process", 0.016)
		_check(lens.h_offset == 0.0 and lens.v_offset == 0.0, camera_name + " setting zero clears active shake")
	preferences.call("set_value", "shake", saved_shake)
	var hud: Node = arena.get_node("HUD")
	await _key(KEY_ESCAPE)
	_check(paused and bool(hud.get("_paused")), "actual Escape pauses arena")
	launcher = hud.get("_comfort_button")
	await _click(launcher)
	modal = hud.get("_comfort")
	_check(modal.visible and paused, "pause settings stays paused")
	await _key(KEY_ESCAPE)
	_check(not modal.visible and paused and launcher.has_focus(), "first Escape closes child only and restores pause focus")
	await _key(KEY_ESCAPE)
	_check(not paused, "second Escape resumes")
	arena.queue_free()
	await _settle()
	viewport.queue_free()
	preferences.call("load_settings", old_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://comfort_ui_%d.cfg" % OS.get_process_id()))
	for singleton in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("COMFORT_UI %s (%d failures; mutation=%s)" % ["PASS" if failures == 0 else "FAIL", failures, mutation])
	quit(0 if failures == 0 else 1)

func _settle() -> void:
	for i in 4:
		await process_frame

func _key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()

func _pad(button: JoyButton) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()

func _click(button: Button) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await _settle()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event, true)
		await _settle()

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("COMFORT_UI: " + description)
