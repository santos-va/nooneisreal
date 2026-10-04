extends SceneTree
## Production dodge dispatch, resource denials, physical arc and deterministic replay.
var checks: int = 0
var failures: int = 0
var f
var gs: Node
var ir: Node
var actor: GDScript

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DODGE_STAMINA: " + label)

func fresh(hero: String) -> void:
	ir.v_clear(1)
	for action: String in ir.ACTIONS:
		ir.buffered(1, action)
	f.data = gs.load_character(hero)
	f.reset_for_round(0.0, 1)
	f.set_control(true)
	f._wish = Vector3.RIGHT

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	if code in [KEY_SHIFT, KEY_ALT]:
		event.location = KEY_LOCATION_LEFT
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func hop() -> Array:
	var trace: Array = []
	for frame in f.dodge_profile().frames:
		f._tick_dash(1.0 / 60.0)
		f._post_move()
		trace.append([f.position, f.velocity, f.dodge_stamina, f.state])
	return trace

func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	ir = root.get_node("InputRouter")
	actor = load("res://scripts/fighter/Fighter.gd")
	gs.free_move = true
	gs.skeletal_rig = false
	gs.water = load("res://scripts/core/WaveField.gd").new()
	gs.water.amplitudes = Vector3.ZERO
	ir.apply_profile("solo", false)
	load("res://scripts/fx/Fx.gd").enabled = false
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	root.add_child(f)
	f.set_physics_process(false)
	for hero: String in ["choko", "skea"]:
		fresh(hero)
		var capacity: int = floori(f.dodge_stamina_max() / f.dodge_profile().stamina_cost)
		check(capacity > f.data.dash_charges, hero + " more short dodges than signature charges")
		for attempt in capacity:
			f.position = Vector3.ZERO
			f._set_state(actor.State.IDLE)
			check(f._start_dodge(1.0), "available stamina starts hop")
			hop()
		var exhausted: float = f.dodge_stamina
		f._set_state(actor.State.IDLE)
		check(not f._start_dodge(1.0) and f.dodge_stamina == exhausted, "exhaustion is nonmutating")
		for frame in 75:
			f._tick_dodge_stamina(1.0 / 60.0)
		check(f.dodge_stamina > exhausted + f.dodge_profile().stamina_cost, "continuous regen restores usable dodge without full refill")
		for state: int in [actor.State.HITSTUN, actor.State.KO, actor.State.KNOCKDOWN, actor.State.ATTACK, actor.State.DASH]:
			fresh(hero)
			f.state = state
			check(not f._start_dodge(1.0) and f.dodge_stamina == f.dodge_stamina_max(), "invalid state preserves stamina %s" % state)
		fresh(hero)
		f.control_locked = true
		check(not f._start_dodge(1.0), "locked input denial")
		f.control_locked = false
		f.position.y = 3.0
		f._water_grounded = false
		f.state = actor.State.JUMP
		f.velocity.y = -2.0
		check(f._start_dodge(1.0) and f.velocity.y == -2.0, "air dodge keeps downward momentum")
		hop()
		f.position.y = 3.0
		f._water_grounded = false
		f.state = actor.State.JUMP
		var spent: float = f.dodge_stamina
		check(not f._start_dodge(1.0) and f.dodge_stamina == spent, "second air dodge denied without spending")
		f.reset_for_round(0.0, 1)
		check(not f.dodging and not f._dodge_air_used and f.dodge_stamina == f.dodge_stamina_max(), "round clears motion and resource")
		for direction_index in 8:
			var direction := Vector3.RIGHT.rotated(Vector3.UP, float(direction_index) * PI / 4.0)
			var first: Array = []
			for replay in 2:
				fresh(hero)
				f._wish = direction
				check(f._start_dodge(0.0), "directional dodge accepted")
				var trace: Array = hop()
				var peak: float = 0.0
				for frame: Array in trace:
					peak = maxf(peak, frame[0].y)
				check(peak > 0.1 and peak < 0.6, "short physical jump arc")
				var travel: Vector3 = Vector3(f.position.x, 0.0, f.position.z)
				check(travel.normalized().dot(direction) > 0.999 and travel.length() < 3.0, "all eight directions remain short and locked")
				check(not f.dodging and f.dash_frames_left == 0, "hop ends without stuck state")
				if replay == 0:
					first = trace
				else:
					check(first == trace, "same fixed-step input reproduces state/stamina trace")
		fresh(hero)
		key(KEY_SHIFT, true)
		f._tick_ground(1.0 / 60.0, f._read_intent())
		check(f.dodging and f.dodge_stamina < f.dodge_stamina_max() and f.dash_charges_left == f.data.dash_charges, "physical Shift uses stamina, not signature charge")
		key(KEY_SHIFT, false)
		fresh(hero)
		key(KEY_ALT, true)
		f._tick_ground(1.0 / 60.0, f._read_intent())
		check(not f.dodging and f.state == actor.State.DASH and f.dash_charges_left == f.data.dash_charges - 1 and f.dodge_stamina == f.dodge_stamina_max(), "physical Alt still reaches signature skill independently")
		key(KEY_ALT, false)
		fresh(hero)
		f._start_dodge(1.0)
		for frame in 5:
			f._tick_dash(1.0 / 60.0)
			f._post_move()
			f.animator.tick(1.0 / 60.0, f, false)
		check(f.animator.pose["forearm_l"].z > 1.4 and f.animator.pose["forearm_r"].z > 1.4, "visible guard reaches protection early in short hop")
		check(f.animator.pose["shin_l"].z < -0.45, "visible gathered knee does not lag behind short hop")
		fresh(hero)
		f.dodge_stamina = 0.0
		f.hitstop_frames = 3
		f._physics_process(1.0 / 60.0)
		check(f.dodge_stamina == 0.0, "hitstop suspends stamina clock")
		f.hitstop_frames = 0
		f.frozen_frames = 3
		f._physics_process(1.0 / 60.0)
		check(f.dodge_stamina == 0.0, "freeze suspends stamina clock")
	f.free()
	await process_frame
	for audio: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(audio).queue_free()
	await process_frame
	# Fixed-fps runs faster than wall time; let the threaded audio mixer release stopped voices.
	OS.delay_msec(100)
	await process_frame
	print("DODGE_STAMINA_COMPLETE checks=%s failures=%s" % [checks, failures])
	quit(1 if failures else 0)
