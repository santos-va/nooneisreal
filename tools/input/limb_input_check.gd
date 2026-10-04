extends SceneTree
## Physical events cover source-scoped routing, profile conflicts and UI fences.
var ir: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LIMB_INPUT: " + label)

func _button(device: int, code: int, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _trigger(device: int, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _slot(device: int, slot: int, down: bool) -> void:
	if slot < 2:
		_button(device, JOY_BUTTON_LEFT_SHOULDER if slot == 0 else JOY_BUTTON_RIGHT_SHOULDER, down)
	else:
		_trigger(device, JOY_AXIS_TRIGGER_LEFT if slot == 2 else JOY_AXIS_TRIGGER_RIGHT, 1.0 if down else 0.0)

func _run() -> void:
	ir = root.get_node("InputRouter")
	var expected_chords: Array[String] = ["skill1", "skill2", "grapple_parkour", "grapple_enemy"]
	root.get_node("GameState").free_move = true
	ir.apply_profile("solo", false)
	for pair: Array in [[KEY_Q, "grapple_enemy"], [KEY_E, "grapple_parkour"], [KEY_I, "skill2"]]:
		_key(pair[0], true)
		_expect(ir.buffered(1, pair[1]), "SOLO requested binding " + pair[1])
		for other: String in ["grapple_enemy", "grapple_parkour", "grapple", "skill2"]:
			if other != pair[1]:
				_expect(not ir.buffered(1, other), "SOLO no doubled action " + other)
		_key(pair[0], false)
	ir.apply_profile("shared", false)
	for row: Array in [[1, KEY_T, "grapple_enemy"], [1, KEY_R, "grapple_parkour"], [2, KEY_O, "grapple_enemy"], [2, KEY_I, "grapple_parkour"]]:
		_key(row[1], true)
		_expect(ir.buffered(row[0], row[2]), "SHARED distinct harpoon binding")
		_expect(not ir.buffered(row[0], "grapple"), "SHARED legacy grapple has no physical binding")
		_key(row[1], false)
	ir.apply_profile("solo", false)
	for index in range(4):
		var code: int = [KEY_J, KEY_K, KEY_M, KEY_COMMA][index]
		_key(code, true)
		_expect(ir.buffered(1, ir.LIMBS[index]), "SOLO physical limb %d" % index)
		_expect(not ir.buffered(1, "light") and not ir.buffered(1, "heavy"), "no legacy double action")
		_key(code, false)
	for prof in ["solo", "shared"]:
		ir.apply_profile(prof, false)
		var seen := {}
		for p in [1, 2]:
			_expect(InputMap.action_get_events(ir.action_name(p, "grapple")).is_empty(), "legacy grapple is virtual only")
			for action in ir.ACTIONS:
				for event in InputMap.action_get_events(ir.action_name(p, action)):
					if event is InputEventKey:
						var signature := "%d:%d" % [event.physical_keycode, event.location]
						_expect(not seen.has(signature), prof + " unique " + signature)
						seen[signature] = action
	ir.apply_profile("solo", false)
	for device in [0, 1]:
		for slot in range(4):
			var action: String = ir.LIMBS[slot]
			_slot(device, slot, true)
			_expect(ir.held(device + 1, action) and ir.buffered(device + 1, action), "pad limb %d:%d" % [device, slot])
			_expect(not ir.buffered(2 - device, action), "other device isolated")
			_button(device, JOY_BUTTON_Y, true)
			_slot(device, slot, true)
			_expect(not ir.buffered(device + 1, action), "modifier press does not repeat limb")
			if not expected_chords[slot].is_empty():
				_expect(not ir.buffered(device + 1, expected_chords[slot]), "modifier does not convert held limb")
			_slot(device, slot, false)
			_slot(device, slot, true)
			_expect(ir.buffered(device + 1, expected_chords[slot]), "chord dispatched")
			_expect(not ir.buffered(device + 1, action) and not ir.buffered(device + 1, "grapple"), "chord does not alias limb or legacy grapple")
			_button(device, JOY_BUTTON_Y, false)
			_slot(device, slot, true)
			_expect(not ir.buffered(device + 1, action), "modifier release no phantom limb")
			_slot(device, slot, false)
	_button(0, JOY_BUTTON_Y, true)
	_key(KEY_J, true)
	_expect(ir.buffered(1, "left_hand") and not ir.buffered(1, "skill1"), "keyboard ignores controller modifier")
	_key(KEY_J, false)
	_slot(1, 0, true)
	_expect(ir.buffered(2, "left_hand") and not ir.buffered(2, "skill1"), "other pad ignores modifier")
	_slot(1, 0, false)
	_button(0, JOY_BUTTON_Y, false)
	_trigger(0, JOY_AXIS_TRIGGER_LEFT, 0.54)
	_expect(not ir.buffered(1, "left_leg"), "trigger below threshold")
	_trigger(0, JOY_AXIS_TRIGGER_LEFT, 0.56)
	_expect(ir.buffered(1, "left_leg"), "trigger rising edge")
	for value in [0.54, 0.56, 0.4, 0.9]:
		_trigger(0, JOY_AXIS_TRIGGER_LEFT, value)
		_expect(not ir.buffered(1, "left_leg"), "trigger hysteresis")
	_trigger(0, JOY_AXIS_TRIGGER_LEFT, 0.0)
	var owner := Node.new()
	root.add_child(owner)
	for slot in range(4):
		_slot(0, slot, true)
		ir.acquire_ui(owner)
		paused = true
		_slot(0, slot, false)
		_slot(0, slot, true)
		paused = false
		ir.release_ui(owner)
		await physics_frame
		await process_frame
		_expect(not ir.held(1, ir.LIMBS[slot]) and not ir.buffered(1, ir.LIMBS[slot]) and not ir.just_pressed(1, ir.LIMBS[slot]), "UI held source stays fenced")
		_slot(0, slot, false)
		_slot(0, slot, true)
		_expect(ir.buffered(1, ir.LIMBS[slot]), "UI fresh source recovers")
		_slot(0, slot, false)
	# Both new keyboard actions and routed pad chords obey the same pause-neutral fence.
	for pair: Array in [[KEY_Q, "grapple_enemy"], [KEY_E, "grapple_parkour"]]:
		_key(pair[0], true)
		ir.acquire_ui(owner)
		ir.release_ui(owner)
		_expect(not ir.held(1, pair[1]) and not ir.buffered(1, pair[1]), "UI fences keyboard " + pair[1])
		_key(pair[0], false)
		_key(pair[0], true)
		_expect(ir.buffered(1, pair[1]), "fresh harpoon keyboard press after UI")
		_key(pair[0], false)
	for slot: int in [2, 3]:
		_button(0, JOY_BUTTON_Y, true)
		_slot(0, slot, true)
		ir.acquire_ui(owner)
		ir.release_ui(owner)
		_expect(not ir.held(1, expected_chords[slot]) and not ir.buffered(1, expected_chords[slot]), "UI fences harpoon pad chord")
		_slot(0, slot, false)
		_button(0, JOY_BUTTON_Y, false)
		_button(0, JOY_BUTTON_Y, true)
		_slot(0, slot, true)
		_expect(ir.buffered(1, expected_chords[slot]), "fresh harpoon trigger after UI")
		_slot(0, slot, false)
		_button(0, JOY_BUTTON_Y, false)
	_trigger(0, JOY_AXIS_RIGHT_X, 0.19)
	_expect(ir.look_axis(1) == Vector2.ZERO, "right stick radial deadzone")
	_trigger(0, JOY_AXIS_RIGHT_X, 0.8)
	_expect(ir.look_axis(1).x > 0.7 and ir.look_axis(2) == Vector2.ZERO, "look stick per-player isolation")
	ir.acquire_ui(owner)
	_expect(ir.look_axis(1) == Vector2.ZERO, "UI suppresses look")
	ir.release_ui(owner)
	_expect(ir.look_axis(1) == Vector2.ZERO, "held look stays fenced after UI")
	_trigger(0, JOY_AXIS_RIGHT_X, 0.0)
	ir.look_axis(1)
	_trigger(0, JOY_AXIS_RIGHT_Y, -0.8)
	_expect(ir.look_axis(1).y < -0.7, "neutral then fresh look recovers")
	_trigger(0, JOY_AXIS_RIGHT_Y, 0.0)
	ir.acquire_ui(owner)
	_button(0, JOY_BUTTON_Y, true)
	ir.release_ui(owner)
	_slot(0, 0, true)
	_expect(not ir.buffered(1, "skill1") and not ir.buffered(1, "left_hand"), "UI modifier needs neutral")
	_slot(0, 0, false)
	_button(0, JOY_BUTTON_Y, false)
	_slot(0, 0, true)
	_expect(ir.buffered(1, "left_hand"), "modifier neutral recovers")
	_trigger(0, JOY_AXIS_RIGHT_X, 0.8)
	Input.joy_connection_changed.emit(0, false)
	_expect(not ir.held(1, "left_hand"), "disconnect clears routed hold")
	_expect(ir.look_axis(1) == Vector2.ZERO, "disconnect fences stale look axis")
	_trigger(0, JOY_AXIS_RIGHT_X, 0.0)
	ir.look_axis(1)
	_slot(0, 0, false)
	ir.v_press(2, "light")
	_expect(ir.buffered(2, "light"), "legacy virtual CPU preserved")
	ir.v_release(2, "light")
	_expect(ir.binding_label(1, "skill1", true).contains("Y / Triangle + LB"), "help shows chord")
	_expect(ir.binding_label(1, "right_leg", false).contains("Comma"), "help shows physical comma")
	_expect(ir.binding_label(1, "grapple_enemy", true) == "Y / Triangle + RT / R2", "enemy help matches right trigger")
	_expect(ir.binding_label(1, "grapple_parkour", true) == "Y / Triangle + LT / L2", "parkour help matches left trigger")
	owner.free()
	print("LIMB_INPUT_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
