extends SceneTree
## Real device events verify UI isolation without rewriting the action map.
var ir: Node
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _pad(button: int, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _stick(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _map_snapshot() -> Dictionary:
	var result := {}
	for p in [1, 2]:
		for action in ir.ACTIONS:
			var name: String = ir.action_name(p, action)
			var events: Array = []
			for event in InputMap.action_get_events(name):
				events.append(event.as_text())
			result[name] = events
	return result

func _run() -> void:
	ir = root.get_node("InputRouter")
	root.get_node("GameState").free_move = true
	ir.apply_profile("solo", false)
	var original := _map_snapshot()
	var ui_keyboard := {}
	for action: String in ir.UI_PAD_BUTTONS:
		var keys: Array = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(event.as_text())
		ui_keyboard[action] = keys
	ir.ensure_ui_gamepad_bindings()
	ir.ensure_ui_gamepad_bindings()
	for action: String in ir.UI_PAD_BUTTONS:
		var count: int = 0
		var keys: Array = []
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.device == -1 and event.button_index == ir.UI_PAD_BUTTONS[action]:
				count += 1
			if event is InputEventKey:
				keys.append(event.as_text())
		_expect(count == 1 and keys == ui_keyboard[action], "UI binding idempotent with keyboard preserved: " + action)
		var second_pad := InputEventJoypadButton.new()
		second_pad.device = 1
		second_pad.button_index = ir.UI_PAD_BUTTONS[action]
		second_pad.pressed = true
		_expect(second_pad.is_action_pressed(action), "second controller can navigate UI: " + action)
	var pause_owner := Node.new()
	var panel_owner := Node.new()
	root.add_child(pause_owner)
	root.add_child(panel_owner)
	_key(KEY_J, true)
	_key(KEY_J, false)
	_expect(ir.buffered(1, "light"), "short tap outside UI still buffered")
	_expect(not ir.buffered(1, "light"), "buffer consumed once")
	_key(KEY_D, true)
	_expect(ir.axis(1) > 0.9, "movement before UI")
	ir.acquire_ui(pause_owner)
	ir.acquire_ui(pause_owner)
	ir.acquire_ui(panel_owner)
	_key(KEY_J, true)
	ir.v_press(2, "light")
	_expect(ir.move(1) == Vector2.ZERO and not ir.held(1, "light"), "UI suppresses held input")
	_expect(not ir.buffered(1, "light") and not ir.just_pressed(1, "light") and not ir.pressed_within(1, "light", 6), "UI suppresses all press queries")
	_expect(not ir.held(2, "light"), "virtual input cannot leak from UI")
	ir.release_ui(panel_owner)
	ir.release_ui(panel_owner)
	_expect(ir.ui_suppressed(), "nested panel release leaves pause suppression")
	ir.release_ui(pause_owner)
	_expect(not ir.ui_suppressed(), "duplicate acquisition does not require duplicate release")
	_expect(ir.move(1) == Vector2.ZERO and not ir.held(1, "light") and not ir.buffered(1, "light"), "resume fences held movement and attacks")
	await physics_frame
	await process_frame
	_expect(not ir.buffered(1, "light") and not ir.just_pressed(1, "light"), "physics polling cannot recreate UI attack")
	_key(KEY_D, false)
	_key(KEY_J, false)
	_key(KEY_D, true)
	_key(KEY_J, true)
	_expect(ir.axis(1) > 0.9 and ir.buffered(1, "light"), "release and new press recover keyboard")
	_key(KEY_D, false)
	_key(KEY_J, false)
	var dash_button: int = -1
	for event in InputMap.action_get_events("p1_dash"):
		if event is InputEventJoypadButton:
			dash_button = event.button_index
	_expect(dash_button >= 0, "existing gamepad dash binding")
	_stick(0.8)
	_pad(dash_button, true)
	ir.acquire_ui(pause_owner)
	ir.release_ui(pause_owner)
	_expect(ir.move(1) == Vector2.ZERO and not ir.held(1, "dash") and not ir.buffered(1, "dash"), "resume fences gamepad axis and dash")
	_stick(0.0)
	_pad(dash_button, false)
	_stick(0.8)
	_pad(dash_button, true)
	_expect(ir.axis(1) > 0.5 and ir.buffered(1, "dash"), "neutral and new press recover gamepad")
	_stick(0.0)
	_pad(dash_button, false)
	ir.acquire_ui(panel_owner)
	_key(KEY_J, true)
	_key(KEY_J, false)
	ir.release_ui(panel_owner)
	await physics_frame
	await process_frame
	_expect(not ir.buffered(1, "light") and not ir.just_pressed(1, "light"), "UI tap ending before resume never fires")
	_key(KEY_J, true)
	_expect(ir.buffered(1, "light"), "UI tap release does not block next fresh attack")
	_key(KEY_J, false)
	ir.v_press(2, "heavy")
	_expect(ir.buffered(2, "heavy") and ir.held(2, "heavy"), "virtual combat buffer unchanged outside UI")
	ir.v_release(2, "heavy")
	ir.acquire_ui(panel_owner)
	panel_owner.free()
	_expect(not ir.ui_suppressed(), "freed owner cannot leave input stuck")
	_expect(_map_snapshot() == original, "UI isolation preserves every input binding")
	pause_owner.free()
	print("COMFORT_INPUT_CHECK checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
