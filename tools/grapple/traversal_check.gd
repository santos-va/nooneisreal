extends SceneTree
## Finite-device traversal, camera candidates, prepared rope catch and latched input.
var checks: int = 0
var failures: int = 0
var f: Node3D
var first: Node3D
var next: Node3D
var registry: Node3D
var Actor: GDScript
var Hook: GDScript
var helper: Node
var camera: Camera3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("TRAVERSAL: " + label)

func hang() -> void:
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3.ZERO
	f._wish = Vector3.ZERO
	f.control_locked = false
	f.state = Actor.State.GRAPPLE
	first.position = Vector3(0, 9.25, 0)
	next.position = Vector3(5, 9.25, 0)
	var token: int = registry.issue(1)
	registry.deploy(token, 1, first.position, f.position + Hook.HAND, 5.0)
	f.grapple.fire(false, "grapple_parkour")

func target_packet() -> Dictionary:
	return {"point": next.position, "target_id": String(next.get_path())}

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var gs := root.get_node("GameState")
	gs.free_move = true
	gs.skeletal_rig = false
	gs.water = null
	f = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	registry = f.grapple.registry
	registry.set_physics_process(false)
	first = Node3D.new()
	first.name = "FirstAnchor"
	root.add_child(first)
	first.add_to_group("grapple_anchor")
	next = Node3D.new()
	next.name = "NextAnchor"
	root.add_child(next)
	next.add_to_group("grapple_anchor")
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	root.add_child(ground)
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	helper = load("res://scripts/core/HarpoonAim.gd").new()
	root.add_child(helper)
	helper.setup(camera, true)
	await physics_frame
	hang()
	check(f.grapple.attached, "fixture is attached through real reused rope")
	f.velocity = Vector3(2, 0, 0.5)
	var momentum: Vector3 = f.velocity
	var stock: int = f.grapple.charges
	var old_token: int = f.grapple._deployed_token
	check(f.grapple.retarget(target_packet()), "second parkour chooses a valid new anchor")
	check(f.grapple.phase == Hook.Phase.FLIGHT and f.grapple.chain_throw, "transfer skips windup into swept device flight")
	check(f.velocity.is_equal_approx(momentum), "new device never brakes or manufactures momentum")
	check(f.grapple.charges == stock - 1 and f.grapple.token != 0, "exactly one finite device issued")
	check(registry.records.has(old_token) and registry.records[old_token].users.is_empty(), "previous rope persists without a stale user")
	for frame: int in 40:
		f.grapple.drive(1.0 / 60.0, true)
		if f.grapple.phase != Hook.Phase.FLIGHT:
			break
	check(f.grapple.attached and f.grapple.anchor_point.is_equal_approx(next.position), "new support requires swept contact")
	check(absf(f.grapple.rope_length - (f.position + Hook.HAND).distance_to(next.position)) < 0.001, "only hand-to-anchor distance is deployed")
	check(registry.records.size() == 2 and f.grapple.charges == stock - 1, "contact does not double spend")
	var tokens_before: int = registry.records.size()
	check(not f.grapple.retarget(target_packet()) and registry.records.size() == tokens_before and f.grapple.attached, "same occupied anchor rejected without losing support")
	hang()
	while f.grapple.charges > 0:
		registry.issue(1)
	check(not f.grapple.retarget(target_packet()) and f.grapple.attached, "empty stock keeps old support")
	hang()
	next.position = Vector3(60, 9, 0)
	check(not f.grapple.retarget(target_packet()) and f.grapple.attached, "out-of-range target cannot consume or detach")
	check(not f.grapple.retarget({"target_id": "/root/missing", "point": Vector3.ZERO}) and f.grapple.attached, "stale target cannot detach")
	# Low-level release stays available; gameplay parkour supplies a tap latch.
	hang()
	for frame: int in 15:
		f._tick_grapple({"grapple_held": false, "jump_held": false, "axis": 0.0})
	check(f.grapple.attached and f.state == Actor.State.GRAPPLE, "parkour survives button release at gameplay boundary")
	f.grapple.drive(1.0 / 60.0, false)
	check(not f.grapple.attached, "explicit low-level release still detaches")
	# A deployed span is visible and selectable well before pickup radius.
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3(5, 0, 0)
	f._wish = Vector3.RIGHT
	first.position = Vector3(6, 8, 0)
	next.position = Vector3(40, 8, 0)
	var reused: int = registry.issue(1)
	registry.deploy(reused, 1, first.position, Vector3(6, 0, 0), 8.0)
	camera.position = Vector3(0, 4.25, 6)
	camera.look_at(Vector3(6, 4.25, 0))
	var candidate: Dictionary = helper.capture(f, false)
	check(candidate.candidate_kind == "rope" and not candidate.reachable and candidate.rope_token == reused, "camera previews existing span before 2 m pickup")
	stock = f.grapple.charges
	check(f.grapple.fire(false, "grapple_parkour", candidate) == Hook.Target.ANCHOR and f.grapple.phase == Hook.Phase.ROPE_REACH, "early activation prepares catch instead of launch")
	check(f.grapple.charges == stock and f.grapple.token == 0, "prepared catch spends nothing")
	for frame: int in 120:
		f.grapple.drive(1.0 / 60.0, true)
		if f.grapple.attached:
			break
	check(f.grapple.attached and f.grapple._deployed_token == reused and f.grapple.charges == stock, "normal travel catches prepared existing rope without shot")
	# Early reach must retain an actual buffered ground jump, not turn Space into reel.
	f.grapple.detach()
	f.position = Vector3.ZERO
	f.velocity = Vector3.DOWN
	f._wish = Vector3.ZERO
	await physics_frame
	f._ground_physics(1.0 / 60.0, 0.0)
	check(f.on_ground(), "jump fixture contacts real floor")
	camera.position = Vector3(0, 1.25, 6)
	camera.look_at(Vector3(6, 1.25, 0))
	candidate = helper.capture(f, false)
	f.grapple.fire(false, "grapple_parkour", candidate)
	f.state = Actor.State.GRAPPLE
	var input: Node = root.get_node("InputRouter")
	input.v_press(1, "jump")
	await physics_frame
	f._tick_grapple(f._read_intent())
	input.v_release(1, "jump")
	check(f.velocity.y > 0.0 and f.position.y > 0.0 and f.grapple.phase == Hook.Phase.ROPE_REACH, "Space jumps while ready to catch, without spending")
	check(f.grapple.charges == stock, "ready jump does not issue a device")
	# Reachable spans have priority even if an unrelated free anchor was snapshotted.
	f.grapple.detach()
	f.position = Vector3(5.5, 2, 0)
	f.velocity = Vector3.ZERO
	next.position = Vector3(9, 7, 0)
	check(f.grapple.fire(false, "grapple_parkour", target_packet()) == Hook.Target.ANCHOR and f.grapple._deployed_token == reused and f.grapple.charges == stock, "nearby existing rope wins over a new shot")
	input.apply_profile("solo", false)
	var release_key := InputEventKey.new()
	release_key.physical_keycode = KEY_Z
	release_key.pressed = true
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	f._tick_grapple(f._read_intent())
	check(not f.grapple.attached and f.state not in [Actor.State.GRAPPLE, Actor.State.CROUCH, Actor.State.BLOCK], "physical Z detaches before crouch or block handling")
	release_key = InputEventKey.new()
	release_key.physical_keycode = KEY_Z
	release_key.pressed = false
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	input.apply_profile("solo", false)
	f.position = Vector3.ZERO
	f.velocity = Vector3.DOWN
	f._ground_physics(1.0 / 60.0, 0.0)
	f.state = Actor.State.IDLE
	release_key = InputEventKey.new()
	release_key.physical_keycode = KEY_X
	release_key.pressed = true
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	f._tick_ground(1.0 / 60.0, f._read_intent())
	check(f.state == Actor.State.CROUCH and not f.grapple.busy(), "same physical X still crouches outside grapple")
	release_key = InputEventKey.new()
	release_key.physical_keycode = KEY_X
	release_key.pressed = false
	Input.parse_input_event(release_key)
	Input.flush_buffered_events()
	# Pad B has one router action (block); Fighter interprets its grapple context.
	input.apply_profile("solo", false)
	hang()
	var stamina_before: float = f.dodge_stamina
	var dash_before: int = f.dash_charges_left
	var pad_b := InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	f._tick_grapple(f._read_intent())
	check(not f.grapple.attached and f.state not in [Actor.State.GRAPPLE, Actor.State.BLOCK], "physical pad B releases grapple through block context")
	check(f.dodge_stamina == stamina_before and f.dash_charges_left == dash_before, "pad B detach spends neither stamina nor signature dash")
	pad_b = InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = false
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	input.apply_profile("solo", false)
	f.position = Vector3.ZERO
	f.velocity = Vector3.DOWN
	f._ground_physics(1.0 / 60.0, 0.0)
	f.state = Actor.State.IDLE
	pad_b = InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	f._tick_ground(1.0 / 60.0, f._read_intent())
	check(f.state == Actor.State.BLOCK and not f.grapple.busy(), "physical pad B keeps ordinary ground block outside grapple")
	pad_b = InputEventJoypadButton.new()
	pad_b.device = 0
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = false
	Input.parse_input_event(pad_b)
	Input.flush_buffered_events()
	registry.clear_match()
	check(f.grapple._pending_rope == 0 and not f.grapple.busy(), "match clear removes catch and attachment state")
	f.free()
	registry.free()
	first.free()
	next.free()
	camera.free()
	helper.free()
	ground.free()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 350
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("TRAVERSAL_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
