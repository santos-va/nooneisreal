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
	root.get_node("GameState").free_move = true
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
			if not ir.PAD_CHORDS[slot].is_empty():
				_expect(not ir.buffered(device + 1, ir.PAD_CHORDS[slot]), "modifier does not convert held limb")
			_slot(device, slot, false)
			_slot(device, slot, true)
			if slot == 2:
				_expect(not ir.buffered(device + 1, action), "Y+LT reserved")
			else:
				_expect(ir.buffered(device + 1, ir.PAD_CHORDS[slot]), "chord dispatched")
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
	ir.acquire_ui(owner)
	_button(0, JOY_BUTTON_Y, true)
	ir.release_ui(owner)
	_slot(0, 0, true)
	_expect(not ir.buffered(1, "skill1") and not ir.buffered(1, "left_hand"), "UI modifier needs neutral")
	_slot(0, 0, false)
	_button(0, JOY_BUTTON_Y, false)
	_slot(0, 0, true)
	_expect(ir.buffered(1, "left_hand"), "modifier neutral recovers")
	Input.joy_connection_changed.emit(0, false)
	_expect(not ir.held(1, "left_hand"), "disconnect clears routed hold")
	_slot(0, 0, false)
	ir.v_press(2, "light")
	_expect(ir.buffered(2, "light"), "legacy virtual CPU preserved")
	ir.v_release(2, "light")
	_expect(ir.binding_label(1, "skill1", true).contains("Y / Triangle + LB"), "help shows chord")
	_expect(ir.binding_label(1, "right_leg", false).contains("Comma"), "help shows physical comma")
	owner.free()
	print("LIMB_INPUT_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
