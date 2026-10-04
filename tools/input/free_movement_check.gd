extends SceneTree
## Real keyboard events through production Fighter; no camera transform enters gameplay.
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
