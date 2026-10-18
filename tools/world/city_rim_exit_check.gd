extends SceneTree
## T6 RED (docs/Audit/2026-10-15-T6-Geometry-Fix-Acceptance.md § 5): the barrel on trestles of the west z 25 stall stood
## 0.62 m off SouthWestRear; a hero who stepped off its back rested on its rim with no key out of it (Choko 0 of 18 ways,
## T6 stuck_probe.gd), only RESTART. The barrel moved 0.13 m toward the counter (CityMarket._stall_goods, «trestle»).
## Subject: a hero who steps off the barrel's back (−x) at any point across it ends on the floor or on its top — and if he
## rests on its rim, S, A or D take him to the floor or the top (T6's К7-а п. 4 for this step: «обід без виходу — RED»).
## Both heroes, real keys, T6's stuck_probe.gd rule: stand on the top 0.40 m inside the side's edge, W over the side 40
## ticks, let go 30; on a rim, one way 90 ticks and let go 40, the walk redone for every way (no teleport into the rim).
## top: ≤ RIM under the top; floor: ≤ RIM over the floor; rim: between them and touching the barrel.
## --break=<m> is a negative control, one form each of «a rim behind the barrel with no key out»: old (the barrel back at
## its place on e7b3603, 0.13 m toward SouthWestRear: T1's literal), wall (the barrel where it is, a 2.2 m wall brought to
## 0.62 m off its back), near (the barrel 0.074 m toward SouthWestRear: 0.68 m off it, just under the capsule's 0.70 —
## one point of three already has no way out). 0.20 m (0.55 m off it) is no form: S and A lead out there. Sentinel
## CITY_RIM_EXIT_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_RIM_EXIT: ...".
const BREAKS := ["old", "wall", "near"]
const KEY := "CityMarket@(-8.93, 0.86, 24.34)"   # tools/world/city_tidy_check.gd STEP_PROPS: the barrel on trestles
const SIDE := Vector3(-1, 0, 0)                  # its back, toward SouthWestRear
const ACROSS: Array[float] = [-0.33, 0.0, 0.33]  # T6 stuck_probe.gd cases trestle_w25 (0) and trestle_w25_k33 (0.33)
const RIM: float = 0.05                          # T6 К7-а п. 2 (city_tidy_check STEP_RIM)
const WAYS: Array = [["S", KEY_S], ["A", KEY_A], ["D", KEY_D]]
var mutation := "none"
var checks: int = 0
var failures: int = 0
var world: Node3D
var space: PhysicsDirectSpaceState3D
var held: Dictionary = {}


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_RIM_EXIT: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	if bool(held.get(code, false)) == down:
		return
	held[code] = down
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _release_all() -> void:
	for code: Key in held.keys():
		_key(code, false)


func _box_of(body: StaticBody3D) -> AABB:
	var box := AABB()
	for child: Node in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null or shape.disabled:
			continue
		var wb: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
		box = wb if box.size == Vector3.ZERO else box.merge(wb)
	return box


## The body whose box centre (x, z) and top match the key to 1 cm (T6's _find).
func _find(key: String) -> StaticBody3D:
	var module: String = key.get_slice("@", 0)
	var nums: PackedStringArray = key.get_slice("(", 1).trim_suffix(")").split(",")
	var want := Vector3(float(nums[0]), float(nums[1]), float(nums[2]))
	for node: Node in world.district.find_children("*", "StaticBody3D", true, false):
		var b := node as StaticBody3D
		var path: PackedStringArray = String(world.district.get_path_to(b)).split("/")
		if path.size() < 2 or path[0] != module:
			continue
		var box := _box_of(b)
		if box.size == Vector3.ZERO:
			continue
		var c := box.get_center()
		if absf(c.x - want.x) < 0.011 and absf(c.z - want.z) < 0.011 and absf(box.end.y - want.y) < 0.011:
			return b
	return null


func _touches(at: Vector3) -> Array[String]:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.37
	cap.height = 1.84
	q.shape = cap
	q.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, 0.9, 0))
	q.collision_mask = 1
	q.exclude = [world.player.get_rid()]
	var names: Array[String] = []
	for hit: Dictionary in space.intersect_shape(q, 12):
		var n := hit.collider as Node
		if n != null:
			names.append(String(n.name))
	return names


func _state(body: StaticBody3D, top: float) -> String:
	var y: float = world.player.global_position.y
	if y >= top - RIM:
		return "top"
	if y <= RIM:
		return "floor"
	return "rim" if _touches(world.player.global_position).has(String(body.name)) else "between"


func _face(dir: Vector3) -> void:
	world.player._set_forward(dir)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-dir.x, -dir.z)


func _open_world(hero: String) -> void:
	root.get_node("GameState").p1_character = hero
	root.get_node("InputRouter").apply_profile("solo", false)
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	if world.events != null and world.events.has_method("enable_for_test"):
		world.events.enable_for_test(2468)
		world.events.start_chance = 0.0
	await _ticks(40)
	world.onboarding.skip()
	space = world.get_world_3d().direct_space_state


func _close_world() -> void:
	_release_all()
	world.queue_free()
	current_scene = null
	await _ticks(3)


func _break_scene(body: StaticBody3D) -> void:
	match mutation:
		"old":
			body.global_position.x -= 0.13
		"near":
			body.global_position.x -= 0.074
		"wall":
			var box := _box_of(body)
			var wall := StaticBody3D.new()
			wall.name = "NegativeWall"
			wall.collision_layer = 1 | 8
			wall.collision_mask = 0
			var shape := CollisionShape3D.new()
			var cube := BoxShape3D.new()
			cube.size = Vector3(0.2, 2.2, box.size.z + 0.6)
			shape.shape = cube
			wall.add_child(shape)
			world.district.add_child(wall)
			wall.global_position = Vector3(box.position.x - 0.62 - 0.1, 1.1, box.get_center().z)


## Stand 0.40 m inside the back edge at `k` across, W over it 40 ticks, let go 30: the hero's state there.
func _step_off(body: StaticBody3D, box: AABB, k: float) -> String:
	var p: Node3D = world.player
	var lateral := Vector3(-SIDE.z, 0, SIDE.x)
	var c := box.get_center()
	var start := Vector3(c.x, box.end.y + 0.03, c.z) + SIDE * maxf(absf(box.size.dot(SIDE)) * 0.5 - 0.40, 0.0) + lateral * (k * absf(box.size.dot(lateral)))
	_release_all()
	world.ropes.clear_match()
	p.restart_at(start)
	_face(SIDE)
	await _ticks(15)
	_key(KEY_W, true)
	await _ticks(40)
	_release_all()
	await _ticks(30)
	return _state(body, box.end.y)


func _run() -> void:
	await process_frame
	if mutation != "none" and not mutation in BREAKS:
		push_error("CITY_RIM_EXIT: unknown --break=" + mutation)
		quit(2)
		return
	root.get_node("GameState").set_free_move(true)
	for hero: String in ["choko", "skea"]:
		await _open_world(hero)
		var body := _find(KEY)
		_check(body != null and body.name == "TrestleBarrel", "%s the barrel on trestles stands at %s" % [hero, KEY])
		if body == null:
			await _close_world()
			continue
		_break_scene(body)
		await _ticks(2)
		var box := _box_of(body)
		for k: float in ACROSS:
			var first: String = await _step_off(body, box, k)
			var ways: Array[String] = []
			var out := first == "top" or first == "floor"
			if not out:
				for way: Array in WAYS:
					var before: String = await _step_off(body, box, k)
					if before == "top" or before == "floor":
						ways.append("%s:%s" % [way[0], before])
						out = true
						continue
					_key(way[1], true)
					await _ticks(90)
					_release_all()
					await _ticks(40)
					var after := _state(body, box.end.y)
					ways.append("%s:%s>%s" % [way[0], before, after])
					out = out or after == "top" or after == "floor"
			var at: Vector3 = world.player.global_position
			print("CITY_RIM_EXIT_INFO %s k=%+.2f step_off=%s ways=%s at=(%.2f, %.2f, %.2f)" % [hero, k, first, ways, at.x, at.y, at.z])
			_check(out, "%s k=%+.2f: off the barrel's back the hero ends on the floor or its top, or S/A/D take him there (stepped off: %s; %s)" % [hero, k, first, ways])
		await _close_world()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_RIM_EXIT_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
