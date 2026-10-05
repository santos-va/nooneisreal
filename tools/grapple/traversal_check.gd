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
	var stale_point := target_packet()
	stale_point.point = Vector3(-100, -100, -100)
	check(f.grapple.retarget(stale_point), "second parkour validates anchor and refreshes stale snapshot point")
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
	check(candidate.candidate_kind == "rope" and not candidate.reachable and candidate.rope_token == reused, "camera previews distant existing span as approach cue")
	check(is_equal_approx(candidate.contact_distance, 6.0), "cue distance uses the same physical hand-to-span measure")
	stock = f.grapple.charges
	check(f.grapple.fire(false, "grapple_parkour", candidate) == Hook.Target.NONE and not f.grapple.busy(), "far approach cue cannot prepare or launch")
	check(f.grapple.charges == stock and f.grapple.token == 0, "far approach spends nothing")
	f.position.x = 5.31
	f.grapple.fire(false, "grapple_parkour", candidate)
	check(f.grapple.attached and f.grapple._deployed_token == reused and f.grapple.charges == stock, "current hand within 0.70 m catches without shot")
	# A far cue must leave the ordinary buffered jump available.
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
	f.state = Actor.State.IDLE
	var input: Node = root.get_node("InputRouter")
	input.v_press(1, "jump")
	await physics_frame
	f._tick_ground(1.0 / 60.0, f._read_intent())
	input.v_release(1, "jump")
	check(f.velocity.y > 0.0 and f.state == Actor.State.JUMP and not f.grapple.busy(), "Space after distant rope cue remains ordinary jump")
	check(f.grapple.charges == stock, "approach jump does not issue a device")
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
	await assistance()
	await responsive_profile()
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


func assistance() -> void:
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3.ZERO
	f._wish = Vector3.RIGHT
	f.forward = Vector3.RIGHT
	first.position = Vector3(4, 7, 0)
	next.position = Vector3(-4, 7, 0)
	camera.position = Vector3(0, 4.25, 8)
	camera.look_at(Vector3(0, 4.25, 0))
	helper.setup(camera, true)
	await physics_frame
	var candidate: Dictionary = helper.capture(f, false)
	var center_axis: Vector3 = -camera.global_basis.z
	var angle: float = rad_to_deg(acos(center_axis.dot((first.position - camera.position).normalized())))
	check(angle > 10.0 and candidate.target_id == String(first.get_path()), "action assistance selects visible off-center anchor along movement")
	f._wish = Vector3.LEFT
	check(helper.capture(f, false).target_id == String(next.get_path()), "changing travel direction replaces opposite-side sticky target")
	f._wish = Vector3.RIGHT
	camera.look_at(next.position)
	helper.apply_look(Vector2(0.001, 0.0))
	check(helper.capture(f, false).target_id == String(next.get_path()), "explicit orbit overrides movement preference")
	helper.reset()
	camera.look_at(first.position)
	next.position = first.position + Vector3(0, 0, 0.05)
	candidate = helper.capture(f, false)
	var remembered: String = candidate.target_id
	first.position.z += 0.03
	next.position.z -= 0.03
	check(helper.capture(f, false, false).target_id == remembered, "small score crossover preserves visible preview target")
	next.position = Vector3(60, 7, 0)
	first.position = Vector3(4, 7, 0)
	# Three separate invalidation classes: hand obstruction, camera obstruction, range.
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.8, 0.8)
	shape.shape = box
	wall.add_child(shape)
	root.add_child(wall)
	wall.position = (f.position + Hook.HAND).lerp(first.position, 0.5)
	await physics_frame
	check(helper.capture(f, false).target_id.is_empty(), "solid world hand obstruction immediately invalidates assisted candidate")
	check(not f.grapple.line_clear(f.position + Hook.HAND, first.position), "hook and preview agree on layer-one geometry")
	wall.position = camera.position.lerp(first.position, 0.5)
	await physics_frame
	check(helper.capture(f, false).target_id.is_empty(), "camera-hidden anchor is not advertised through walls")
	wall.position = Vector3(50, 50, 50)
	await physics_frame
	check(helper.capture(f, false).target_id == String(first.get_path()), "removing obstruction restores assisted target")
	first.position = Vector3(40, 7, 0)
	check(helper.capture(f, false).target_id.is_empty(), "sticky assisted target cannot survive range invalidation")
	hang()
	wall.position = (f.position + Hook.HAND).lerp(next.position, 0.5)
	await physics_frame
	var stock: int = f.grapple.charges
	check(not f.grapple.retarget(target_packet()) and f.grapple.attached and f.grapple.charges == stock, "solid wall rejects transfer without dropping support or spending")
	f.grapple.detach()
	f.grapple.fire(false, "grapple_parkour", target_packet())
	f.grapple._launch()
	for frame: int in 40:
		f.grapple._flight(1.0 / 60.0, true)
		if f.grapple.phase != Hook.Phase.FLIGHT:
			break
	check(f.grapple.phase == Hook.Phase.MISS_REWIND and f.grapple.token != 0, "solid world collision stops projectile and keeps its token recoverable")
	wall.free()


func responsive_profile() -> void:
	# Identical input packets exercise the opt-in city profile and legacy duel profile.
	var launch_ticks: Array[int] = []
	var contact_ticks: Array[int] = []
	for city: bool in [false, true]:
		registry.clear_match()
		f.position = Vector3(0, 3, 0)
		f.velocity = Vector3(5, 0, 0)
		f._wish = Vector3.RIGHT
		f.control_locked = false
		first.position = Vector3(4, 9.25, 0)
		next.position = Vector3(40, 9, 0)
		f.grapple.responsive_parkour = city
		var stock: int = f.grapple.charges
		f.grapple.fire(false, "grapple_parkour", {"point": first.position, "target_id": String(first.get_path())})
		var ticks: int = 0
		while f.grapple.phase == Hook.Phase.WINDUP and ticks < 40:
			f.grapple.drive(1.0 / 60.0, true)
			ticks += 1
		launch_ticks.append(ticks)
		check(f.grapple.phase == Hook.Phase.FLIGHT and not f.grapple.attached, "profile launches without an unconfirmed tether city=%s" % city)
		check(f.grapple.charges == stock - 1 and registry.records.size() == 1, "profile launch spends exactly once city=%s" % city)
		check(is_equal_approx(f.velocity.x, 5.0 if city else 0.0), "only opted-in city windup preserves travel speed city=%s" % city)
		while f.grapple.phase == Hook.Phase.FLIGHT and ticks < 70:
			f.grapple.drive(1.0 / 60.0, true)
			ticks += 1
		contact_ticks.append(ticks)
		check(f.grapple.attached and f.grapple.charges == stock - 1, "profile confirms swept contact without spending twice city=%s" % city)
	check(launch_ticks == [30, 10], "city shot responds in 10 ticks while duel remains 30")
	check(contact_ticks[1] < contact_ticks[0], "city initial support arrives sooner on identical target")
	print("RESPONSIVE_ROPE launch_ticks=%s contact_ticks=%s" % [launch_ticks, contact_ticks])
	# City opt-in cannot accelerate an enemy shot or change its startup commitment.
	registry.clear_match()
	f.position = Vector3(0, 3, 0)
	f.velocity = Vector3(5, 0, 0)
	f.grapple.fire(true, "grapple_enemy", {"point": Vector3(0, 4.25, 10), "target_id": ""})
	for tick: int in 29:
		f.grapple.drive(1.0 / 60.0, true)
	check(f.grapple.phase == Hook.Phase.WINDUP and is_zero_approx(f.velocity.x), "city opt-in preserves enemy startup and braking")
	f.grapple.drive(1.0 / 60.0, true)
	var before: Vector3 = f.grapple.projectile_position
	f.grapple._flight(1.0 / 60.0, true)
	check(is_equal_approx(before.distance_to(f.grapple.projectile_position), 0.6), "city enemy projectile keeps 36 m/s")
	registry.clear_match()
	f.grapple.responsive_parkour = false
