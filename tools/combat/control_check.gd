extends SceneTree
## Production regression: held screen input, resource debt, jump arcs and routed finishers.
var checks: int = 0
var failures: int = 0
var ir: Node
var gs: Node
var actor: GDScript
var f
var other

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBAT_CONTROL: " + label)

func clear_input() -> void:
	ir.v_clear(1)
	for action: String in ir.ACTIONS:
		ir.buffered(1, action)

func fresh(character: String) -> void:
	clear_input()
	f.data = gs.load_character(character)
	f.reset_for_round(0.0, 1)
	f.set_control(true)
	f.position = Vector3.ZERO
	f.is_cpu = false
	f.sword_drawn = true
	other.position = Vector3(8, 0, 0)
	f._wish = Vector3.RIGHT

func _run() -> void:
	await process_frame
	ir = root.get_node("InputRouter")
	gs = root.get_node("GameState")
	actor = load("res://scripts/fighter/Fighter.gd")
	gs.free_move = true
	gs.skeletal_rig = false
	gs.training_mode = true
	gs.water = load("res://scripts/core/WaveField.gd").new()
	gs.water.amplitudes = Vector3.ZERO
	var effects: GDScript = load("res://scripts/fx/Fx.gd")
	effects.enabled = false
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	other = load("res://scenes/fighter/Fighter.tscn").instantiate()
	other.player_index = 2
	root.add_child(f)
	root.add_child(other)
	f.set_physics_process(false)
	other.set_physics_process(false)
	f.opponent = other
	other.opponent = f
	fresh("choko")
	# Publish production physics yaw while a direction stays held, then vary render rotation.
	var camera = load("res://scripts/arena/DuelCamera.gd").new()
	camera.p1 = f
	camera.p2 = other
	ir.v_press(1, "up")
	for shared: bool in [false, true]:
		gs.duel.behind = not shared
		for degree in range(0, 361, 5):
			var yaw := deg_to_rad(float(degree))
			camera._yaw = yaw
			camera.rotation.y = -yaw * 0.75
			camera._publish_view_basis()
			f._read_intent()
			var view := Vector3(-sin(yaw), 0, -cos(yaw))
			check(f.wish().dot(view) > 0.9999, "held W follows physics view throughout turn %d shared=%s" % [degree, shared])
			check(absf(f.wish().length() - 1.0) < 0.0001, "turn preserves analog magnitude")
	# Replay wins over live yaw and remains valid through another turn.
	ir.apply_view_basis_packet(1, {"forward": Vector3.LEFT})
	camera._yaw = 0.0
	camera._publish_view_basis()
	f._read_intent()
	check(f.wish() == Vector3.LEFT, "recorded basis wins over live camera")
	ir.clear_recorded_view_basis(1)
	camera.free()
	clear_input()
	for character: String in ["choko", "skea"]:
		fresh(character)
		var limit: int = 5 if character == "choko" else 3
		check(f.data.dash_charges == limit, character + " requested charge capacity")
		var previous := 0.0
		for charge in limit:
			check(f._start_dash(1.0), character + " permitted charge %d" % charge)
			check(f.dash_charges_left == limit - charge - 1, "exactly one charge spent")
			check(f.dash_recharge_total > previous, "successive dashes increase rest")
			previous = f.dash_recharge_total
			f.state = actor.State.IDLE
			f.flashing = false
		var at: Vector3 = f.position
		check(not f._start_dash(1.0) and f.position == at and f.dash_charges_left == 0, "exhaustion rejects without displacement")
		f._tick_status(previous - 0.01)
		check(f.dash_charges_left == 0, "charges unavailable before rest completes")
		f._tick_status(0.02)
		check(f.dash_charges_left == limit and f.dash_recharge_left == 0.0, "rest restores capacity")
		f.reset_for_round(0, 1)
		check(f.dash_charges_left == limit and f.dash_recharge_left == 0.0, "round restores dash budget")
	# Every ground direction is a continuous, visible curved motion; downward momentum survives.
	for degree in range(0, 360, 45):
		fresh("skea")
		var direction := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(float(degree)))
		f._wish = direction
		check(f._start_flash(0.0), "directional flash starts")
		var last: Vector3 = f.position
		var peak := 0.0
		var moved_frames := 0
		for tick in f.data.flash_travel_frames:
			f._tick_flash(1.0 / 60.0)
			f._post_move()
			var step: Vector3 = f.position - last
			if step.length() > 0.001:
				moved_frames += 1
			check(step.length() < f.data.flash_distance * 0.5, "flash does not teleport")
			peak = maxf(peak, f.position.y)
			last = f.position
		var flat := Vector3(f.position.x, 0, f.position.z)
		check(flat.normalized().dot(direction) > 0.999, "all eight directions follow input")
		check(absf(flat.length() - f.data.flash_distance) < 0.01, "dash reaches configured distance")
		check(peak > 0.05 and moved_frames == f.data.flash_travel_frames, "low arc remains visible throughout travel")
	# Authored travel ends at the endpoint; recovery cannot apply displacement twice.
	for choreography: bool in [false, true]:
		fresh("skea")
		var target := Vector3(3.0, 0, 0)
		if choreography:
			f.beat_flash(target)
		else:
			f._start_flash(0.0)
			target.x = f.data.flash_distance
		var travel_frames: int = f.dash_frames_left
		for tick in travel_frames:
			f._tick_flash(1.0 / 60.0)
			f._post_move()
		for tick in 60:
			f._ground_physics(1.0 / 60.0, 0.0)
			f._post_move()
		check(Vector2(f.position.x - target.x, f.position.z - target.z).length() < 0.01, "recovery preserves authored endpoint choreography=%s" % choreography)
	for vertical: float in [-6.0, 6.0]:
		fresh("skea")
		f.position.y = 3.0
		f.velocity.y = vertical
		f._start_flash(0.0)
		for tick in f.data.flash_travel_frames:
			f._tick_flash(1.0 / 60.0)
		check((f.position.y - 3.0) * vertical > 0, "air dash preserves rise/fall direction")
		check(f.velocity.y < vertical, "air dash preserves gravity rather than hovering")
	fresh("skea")
	ir.v_press(1, "jump")
	ir.v_press(1, "dash")
	f._tick_ground(1.0 / 60.0, {"axis": 1.0, "crouch": false, "block": false})
	check(f.state == actor.State.DASH and f._flash_vertical_speed == f.data.jump_velocity, "simultaneous jump plus dash captures jump impulse")
	check(not ir.buffered(1, "jump"), "combined jump press consumed once")
	f._tick_flash(1.0 / 60.0)
	check(f.position.y > 0.0 and f.position.x > 0.0, "combined action moves up and forward together")
	fresh("skea")
	f.dash_charges_left = 0
	ir.v_press(1, "jump")
	ir.v_press(1, "dash")
	f._tick_ground(1.0 / 60.0, {"axis": 1.0, "crouch": false, "block": false})
	check(f.state == actor.State.JUMP and f.velocity.y > 0, "denied dash does not eat jump")
	fresh("choko")
	f.dash_charges_left = 0
	f.spring_frames = 100
	f.state = actor.State.JUMP
	ir.v_press(1, "dash")
	f._tick_air(1.0 / 60.0, {"axis": 0.0})
	check(f.spring_frames == 100, "denied dash does not consume Spring")
	fresh("choko")
	ir.v_press(1, "weapon_swap")
	f._try_sword_swap()
	f.dash_charges_left = 0
	ir.v_press(1, "dash")
	f._tick_sword_swap(1.0 / 60.0, {"axis": 0.0})
	check(f.state == actor.State.SWAP and f.sword_swap_frame == 1, "denied dash cannot cancel weapon recovery")
	for interruption: String in ["hit", "pull"]:
		fresh("skea")
		f._start_flash(1.0)
		f.invulnerable_frames = 0
		if interruption == "hit":
			f.receive_hit(other, other.data.light)
		else:
			f.get_pulled_to(Vector3(2, 0, 0), 12)
		check(f.state == actor.State.HITSTUN and not f.flashing and f.dash_frames_left == 0, "interrupted dash restores pushbox " + interruption)
	# All four alternating routes reach a genuinely different third trajectory on the live dispatcher.
	for character: String in ["choko", "skea"]:
		for route: Array in [["left_hand", "right_hand", "left_hand"], ["right_hand", "left_hand", "right_hand"], ["left_leg", "right_leg", "left_leg"], ["right_leg", "left_leg", "right_leg"]]:
			fresh(character)
			for index in 3:
				clear_input()
				ir.v_press(1, route[index])
				if index == 0:
					check(f._try_limb_attack(false), "route begins")
				else:
					f._normal_connected = true
					check(f._try_cancel(f.current_move), "confirmed route continues")
				check(f.chain_index == index, "route stage increments exactly once")
			var expected := "uppercut" if route[0] == "left_hand" else ("hammer" if route[0] == "right_hand" else ("spin" if route[0] == "left_leg" else "hookspin"))
			if character == "choko" and route[0] == "right_hand":
				expected = "cleave"
			check(f.current_move.anim.ends_with("_" + expected), "route selects " + expected)
			check(f.combo_route == ">".join(route), "route order preserved")
			clear_input()
			ir.v_press(1, route[1])
			f._normal_connected = true
			check(not f._try_cancel(f.current_move), "normal route rejects fourth hit")
			f._set_state(actor.State.HITSTUN)
			check(f.combo_route.is_empty() and f.chain_index == 0, "hit interruption clears route")
	clear_input()
	f.queue_free()
	other.queue_free()
	await process_frame
	gs.water = null
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("COMBAT_CONTROL_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
