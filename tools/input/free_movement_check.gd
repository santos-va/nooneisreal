extends SceneTree
## Real keyboard events through production Fighter and recorded physics-view input.
var checks: int = 0
var failures: int = 0
var mutation: String = ""

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--break="):
			mutation = arg.trim_prefix("--break=")
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FREE_MOVEMENT: " + label)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var ir = root.get_node("InputRouter")
	gs.free_move = true
	gs.p2_is_cpu = false
	gs.skeletal_rig = false
	gs.set_stage("bazaar")
	ir.apply_profile("solo", false)
	var arena = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	for body: Node in arena.find_children("*", "CollisionObject3D", true, false):
		body.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	arena.process_mode = Node.PROCESS_MODE_DISABLED
	await physics_frame
	await process_frame
	var a = arena.p1
	var b = arena.p2
	a.control_locked = false
	b.control_locked = false
	a.is_cpu = false
	gs.duel.behind = true
	gs.duel.reset()
	a.position = Vector3(-3, 0, 0)
	b.position = Vector3(3, 0, 0)
	gs.duel.sync(a.position, b.position, 1000)
	key(KEY_W, true)
	a._read_intent()
	var before: Vector3 = a.wish()
	check(before.dot(Vector3.RIGHT) > 0.99, "solo initial W points into arena")
	b.position = Vector3(-6, 0, 0)
	gs.duel.sync(a.position, b.position, 1001)
	if mutation == "opponent_frame":
		a.is_cpu = true
	a._read_intent()
	check(a.wish().distance_to(before) < 0.00001, "held W survives foe crossing")
	a.is_cpu = false
	# A circling enemy cannot bend an already-held travel gesture either.
	for i: int in 12:
		b.position = a.position + Vector3.RIGHT.rotated(Vector3.UP, float(i) * 0.12) * 5.0
		gs.duel.sync(a.position, b.position, 1002 + i)
		a._read_intent()
		check(a.wish().distance_to(before) < 0.00001, "held W does not orbit enemy %d" % i)
	key(KEY_W, false)
	a._read_intent()
	check(a.wish() == Vector3.ZERO, "neutral releases gesture")
	key(KEY_W, true)
	a._read_intent()
	check(a.wish().distance_to(gs.duel.right) < 0.00001, "next gesture samples current continuous basis")
	key(KEY_W, false)
	a._read_intent()
	gs.duel.reset()
	a.position = Vector3(-3, 0, 0)
	b.position = Vector3(-6, 0, 0)
	gs.duel.sync(a.position, b.position, 2000)
	key(KEY_W, true)
	a._read_intent()
	check(a.wish().dot(Vector3.RIGHT) > 0.99, "new W after crossing does not chase foe behind")
	a._update_facing()
	if mutation == "facing":
		a._set_forward(b.position - a.position)
	check(a.forward.dot(a.wish()) > 0.99, "human faces travel away from foe")
	var dash_origin: Vector3 = a.position
	a._start_dash(0.0)
	for tick: int in 5:
		a._tick_dash(1.0 / 60.0)
	check(a.position.x > dash_origin.x + 0.1 and absf(a.position.z - dash_origin.z) < 0.001, "held W dash travels forward after crossing")
	a._read_intent()
	check(a.wish().distance_to(before) < 0.00001, "held movement stays forward after dash")
	a._start_move(a.data.light)
	check(a.forward.dot((b.position - a.position).normalized()) > 0.99, "explicit attack prioritizes current foe")
	# CPU keeps its opponent-relative intent and facing, independent of human latch.
	a.is_cpu = true
	a._read_intent()
	check(a.wish().distance_to(gs.duel.to_world(ir.move(1), 1)) < 0.00001, "CPU retains legacy intent basis")
	a._update_facing()
	check(a.forward.dot((b.position - a.position).normalized()) > 0.99, "CPU faces foe")
	a.is_cpu = false
	key(KEY_W, false)
	a._read_intent()
	# Straight sidestep must increase radius; legacy orbit projection would keep exactly 3 m.
	gs.duel.reset()
	a.position = Vector3(0, 0, 0)
	b.position = Vector3(3, 0, 0)
	gs.duel.sync(a.position, b.position, 3000)
	a.velocity = Vector3.ZERO
	a._set_forward(Vector3.RIGHT)
	key(KEY_D, true)
	a._read_intent()
	if mutation == "orbit":
		a.is_cpu = true
	for i: int in 15:
		a._walk_free(1.0 / 60.0)
	check(absf(a.position.x) < 0.001 and a.position.z > 0.1, "straight travel has no opponent-radius projection")
	a.is_cpu = false
	key(KEY_D, false)
	a._read_intent()
	gs.duel.behind = false
	key(KEY_D, true)
	a._read_intent()
	check(a.wish().dot(Vector3.RIGHT) > 0.99, "shared D uses screen-side simulation frame")
	key(KEY_D, false)
	a._read_intent()
	# View packets are input data sampled every physics tick, including held movement.
	gs.duel.behind = true
	gs.duel.reset()
	check(ir.set_view_basis(1, Vector3.FORWARD), "adapter accepts 90-degree view basis")
	key(KEY_W, true)
	a._read_intent()
	check(a.wish().distance_to(Vector3.FORWARD) < 0.00001, "new W follows 90-degree view")
	ir.set_view_basis(1, Vector3.LEFT)
	a._read_intent()
	check(a.wish().distance_to(Vector3.LEFT) < 0.00001, "held W follows current manual camera turn")
	key(KEY_W, false)
	a._read_intent()
	key(KEY_W, true)
	a._read_intent()
	check(a.wish().distance_to(Vector3.LEFT) < 0.00001, "next W follows 180-degree view")
	key(KEY_W, false)
	a._read_intent()
	var packet: Dictionary = ir.view_basis_packet(1)
	var camera_rotation: Vector3 = arena.duel_camera.rotation
	for yaw: float in [0.0, PI * 0.5, PI]:
		arena.duel_camera.rotation.y = yaw
		gs.duel.reset()
		check(ir.apply_view_basis_packet(1, packet), "recorded basis accepted")
		check(not ir.set_view_basis(1, Vector3.RIGHT), "live adapter cannot overwrite playback")
		ir.clear_view_basis(1)
		key(KEY_W, true)
		a._read_intent()
		check(a.wish().distance_to(Vector3.LEFT) < 0.00001, "replay movement independent of camera yaw %s" % yaw)
		key(KEY_W, false)
		a._read_intent()
	arena.duel_camera.rotation = camera_rotation
	ir.clear_recorded_view_basis(1)
	ir.set_view_basis(1, Vector3.FORWARD)
	for invalid: Vector3 in [Vector3.ZERO, Vector3.UP, Vector3(NAN, 0, 1), Vector3(INF, 0, 1)]:
		check(not ir.set_view_basis(1, invalid) and ir.view_basis(1) == Vector3.FORWARD, "degenerate packet preserves finite last basis")
	check(not ir.apply_view_basis_packet(1, {"forward": "not a vector"}) and ir.view_basis(1) == Vector3.ZERO, "malformed replay packet fails safely")
	ir.clear_recorded_view_basis(1)
	ir.set_view_basis(1, Vector3.LEFT)
	var ui_owner := Node.new()
	root.add_child(ui_owner)
	key(KEY_W, true)
	a._read_intent()
	ir.acquire_ui(ui_owner)
	a._read_intent()
	check(ir.view_basis(1) == Vector3.ZERO and a.wish() == Vector3.ZERO, "UI clears basis and held gesture")
	check(not ir.set_view_basis(1, Vector3.LEFT), "UI rejects live basis publication")
	ir.release_ui(ui_owner)
	a._read_intent()
	check(a.wish() == Vector3.ZERO, "held W cannot resume through UI")
	key(KEY_W, false)
	a._read_intent()
	# No fighter tick occurs while paused: a released/new press may arrive before resume.
	ir.set_view_basis(1, Vector3.LEFT)
	key(KEY_W, true)
	a._read_intent()
	ir.acquire_ui(ui_owner)
	key(KEY_W, false)
	ir.release_ui(ui_owner)
	ir.set_view_basis(1, Vector3.FORWARD)
	key(KEY_W, true)
	a._read_intent()
	check(a.wish() == Vector3.FORWARD, "UI clears gesture without a fighter tick before fresh press")
	key(KEY_W, false)
	a._read_intent()
	ui_owner.free()
	ir.set_view_basis(1, Vector3.LEFT)
	a.control_locked = true
	a._read_intent()
	check(ir.view_basis(1) == Vector3.ZERO, "round control lock clears basis packet")
	a.control_locked = false
	gs.duel.reset()
	key(KEY_W, true)
	a._read_intent()
	check(a.wish() == Vector3.RIGHT, "reset starts with default frame")
	key(KEY_W, false)
	a._read_intent()
	ir.set_view_basis(1, Vector3.LEFT)
	ir.apply_profile("solo", false)
	check(ir.view_basis(1) == Vector3.ZERO, "profile change clears basis")
	ir.set_view_basis(1, Vector3.LEFT)
	Input.joy_connection_changed.emit(0, false)
	check(ir.view_basis(1) == Vector3.ZERO, "disconnect clears basis")
	ir.set_view_basis(1, Vector3.LEFT)
	gs.duel.behind = false
	key(KEY_D, true)
	a._read_intent()
	check(a.wish() == Vector3.FORWARD, "shared D follows recorded screen-right")
	key(KEY_D, false)
	a._read_intent()
	gs.duel.behind = true
	a.is_cpu = true
	key(KEY_W, true)
	a._read_intent()
	check(a.wish() == gs.duel.to_world(ir.move(1), 1), "CPU ignores manual packet")
	key(KEY_W, false)
	a._read_intent()
	a.is_cpu = false
	ir.clear_view_basis(1)
	gs.free_move = false
	key(KEY_D, true)
	var intent: Dictionary = a._read_intent()
	check(intent.axis > 0.99 and a.wish() == Vector3.ZERO, "plane mode unchanged")
	key(KEY_D, false)
	arena.queue_free()
	await process_frame
	await process_frame
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("FREE_MOVEMENT_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
