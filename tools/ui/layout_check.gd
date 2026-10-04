extends SceneTree
## Real scene layout and viewport input regression. Physical DPI/gamepad tests remain separate.
## Run: godot --headless --path game --script ../tools/ui/layout_check.gd
## Negative controls: -- --break=portrait | --break=icon | --break=input

var failures: int = 0
var clicks: int = 0
var viewport: SubViewport
var mutation: String = ""


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _run() -> void:
	await process_frame
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	menu.set("settings_path", "user://layout_check_settings.cfg")
	viewport.add_child(menu)
	if mutation == "portrait":
		(menu.get("_portrait1") as TextureRect).expand_mode = TextureRect.EXPAND_KEEP_SIZE
	if mutation == "input":
		(menu.get("_p1_btn") as Button).disabled = true
	# Logical canvases produced by 16:9, 4:3 and ultrawide windows with canvas_items/expand.
	for dimensions in [Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(2134, 900)]:
		viewport.size = dimensions
		await _settle()
		var buttons: Array = menu.get("_buttons")
		_check(buttons.size() == 11, "menu contains eleven actions")
		_check("PROTOTYPE" in (menu.get("city_button") as Button).text, "city action clearly labels prototype")
		for button: Button in buttons:
			_check(_inside(button), "visible menu action: %s at %s" % [button.text, dimensions])
		for field in ["_portrait1", "_portrait2"]:
			var portrait: TextureRect = menu.get(field)
			_check(portrait.get_combined_minimum_size() == Vector2(44, 44), "portrait ignores source dimensions")
		await _activate(menu.get("_p1_btn") as Button, false)
		await _activate(menu.get("_p2_btn") as Button, true)
	await _activate(menu.get("stage_btn") as Button, false)
	await _activate(menu.get("time_btn") as Button, true)
	menu.queue_free()
	await _settle()
	var gs: Node = root.get_node("GameState")
	gs.set("p1_character", "choko")
	gs.set("p2_character", "skea")
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	viewport.add_child(arena)
	var hud: Node = arena.get_node("HUD")
	if mutation == "icon":
		var textures: Array = hud.get("_skill_textures")
		(textures[0] as TextureRect).expand_mode = TextureRect.EXPAND_KEEP_SIZE
	for dimensions in [Vector2i(1600, 900), Vector2i(1600, 1200), Vector2i(2134, 900)]:
		viewport.size = dimensions
		await _settle()
		_check_hud(hud)
		# Exercise the widest countdown text, then verify geometry after deferred container sorting.
		hud.call("_on_cooldowns", 1, {"skill1": 99.9, "skill2": 99.9})
		hud.call("_on_cooldowns", 2, {"skill1": 99.9, "skill2": 99.9})
		await _settle()
		_check_hud(hud)
	arena.queue_free()
	menu = null
	arena = null
	hud = null
	await _settle()
	viewport.queue_free()
	viewport = null
	# Retire UI/arena sound playback before engine shutdown, while the audio mixer still runs.
	# Merely quitting leaves active playback to be released after the resource leak report.
	for singleton in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	# Fixed-FPS SceneTree timers can finish before the mixer has any real time to retire playback.
	# Pump deferred destruction for 200 monotonic milliseconds and yield CPU to the mixer.
	var drain_until_ms: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://layout_check_settings.cfg"))
	print("UI_LAYOUT %s (%d failures; mutation=%s)" % ["PASS" if failures == 0 else "FAIL", failures, mutation])
	quit(0 if failures == 0 else 1)


func _check_hud(hud: Node) -> void:
	var timer: Label = hud.get("_timer")
	_check(_inside(timer), "timer remains in viewport")
	var hp: Dictionary = hud.get("_hp")
	var meter: Dictionary = hud.get("_meter")
	var names: Dictionary = hud.get("_names")
	var cool: Dictionary = hud.get("_cool")
	for idx in [1, 2]:
		for control: Control in [hp[idx], meter[idx], names[idx]]:
			_check(_inside(control), "HUD player %d %s remains in viewport" % [idx, control.get_class()])
		var bar: ProgressBar = hp[idx]
		_check(bar.size.x > 250, "HP bar retains readable width")
		_check(not bar.get_global_rect().intersects(timer.get_global_rect()), "HP avoids timer")
		for label: Label in cool[idx]:
			_check(_inside(label), "cooldown remains in viewport")
	var textures: Array = hud.get("_skill_textures")
	_check(textures.size() == 4, "both characters have two skill icons")
	for icon: TextureRect in textures:
		_check(_inside(icon), "skill icon remains in viewport")
		_check(icon.size.x >= 28 and icon.size.x < 100, "skill icon has bounded readable size")
	var left: Control = (names[1] as Control).get_parent().get_parent()
	var right: Control = (names[2] as Control).get_parent().get_parent()
	_check(_inside(left) and _inside(right), "entire player resource panels fit")
	_check(left.get_global_rect().end.x <= timer.get_global_rect().position.x, "P1 resources avoid timer")
	_check(right.get_global_rect().position.x >= timer.get_global_rect().end.x, "P2 resources avoid timer")


func _activate(button: Button, keyboard: bool) -> void:
	if not _inside(button):
		_check(false, "input target must be visible before sending an event")
		return
	clicks = 0
	var before: String = button.text
	button.pressed.connect(_pressed)
	if keyboard:
		button.grab_focus()
		for down in [true, false]:
			var key := InputEventKey.new()
			key.keycode = KEY_ENTER
			key.pressed = down
			viewport.push_input(key, true)
			await process_frame
	else:
		var point := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		viewport.push_input(motion, true)
		await process_frame
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.position = point
			event.global_position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
			event.pressed = down
			viewport.push_input(event, true)
			await process_frame
	_check(clicks == 1, "viewport %s activates %s exactly once" % ["keyboard" if keyboard else "mouse", before])
	_check(before != button.text, "actual selection changes after input")
	button.pressed.disconnect(_pressed)


func _pressed() -> void:
	clicks += 1


func _inside(control: Control) -> bool:
	return control.is_visible_in_tree() and viewport.get_visible_rect().grow(0.5).encloses(control.get_global_rect())


func _settle() -> void:
	for frame in 8:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("UI_LAYOUT: " + message)
