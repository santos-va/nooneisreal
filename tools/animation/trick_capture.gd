extends SceneTree
## Actual CityFighter/InputRouter trick capture on the production district.
## Starts each short route at a declared station; never injects parkour metadata.
var folder: String = "/tmp/nir-tricks"
var selected: String = ""
var side_view: bool = false
var drawn_hand: String = ""
var kicks_only: bool = false
var world: Node3D
var camera: Camera3D
var title: Label
var trace: Array[Dictionary] = []
var saved: int = 0
var failures: int = 0
var Actor: GDScript
var skin_cache: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
		if argument.begins_with("--case="):
			selected = argument.trim_prefix("--case=")
		if argument == "--drawn-left":
			drawn_hand = "left"
		if argument == "--drawn-right":
			drawn_hand = "right"
		if argument == "--kicks":
			kicks_only = true
		if argument == "--side":
			side_view = true
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960, 640)
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	var gs: Node = root.get_node("GameState")
	gs.skeletal_rig = true
	gs.free_move = true
	gs.water = null
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	world.add_child(load("res://scenes/world/CityDistrict.tscn").instantiate())
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("24303e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dce8ff")
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.3
	world.add_child(light)
	camera = Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	camera.current = true
	var canvas := CanvasLayer.new()
	world.add_child(canvas)
	title = Label.new()
	title.position = Vector2(14, 12)
	title.add_theme_font_size_override("font_size", 18)
	canvas.add_child(title)
	for hero: String in ["choko", "skea"]:
		for phase: String in ["wall_kick", "landing_roll"]:
			if kicks_only and phase != "wall_kick":
				continue
			if selected.is_empty() or selected == hero + "_" + phase:
				await route(hero, phase)
	var file := FileAccess.open(folder.path_join("trace.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(trace, "\t") + "\n")
	file.close()
	world.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("TRICK_NATIVE_COMPLETE images=%d ticks=%d failures=%d" % [saved, trace.size(), failures])
	quit(0 if failures == 0 else 1)

func route(hero: String, required: String) -> void:
	var id: String = hero + "_" + required
	var output: String = folder.path_join(id)
	DirAccess.make_dir_recursive_absolute(output)
	var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.set_script(load("res://scripts/world/CityFighter.gd"))
	f.data = load("res://data/characters/%s.tres" % hero)
	world.add_child(f)
	f.set_physics_process(false)
	f.skeletal.set_physics_process(false)
	f.restart_at(Vector3(4, 0, 31.4) if required == "wall_kick" else Vector3(0, 3, 20))
	if not drawn_hand.is_empty() and f.skeletal.sword != null:
		f.sword_drawn = true
		f.sword_hand = drawn_hand
		f.skeletal.sword.stow_weight = 0.0
	if required == "landing_roll":
		f.state = Actor.State.JUMP
		f.velocity = Vector3(4, -2, 0)
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	input.set_view_basis(1, Vector3.FORWARD)
	input.v_clear(1)
	var hang_ticks: int = 0
	var observed: bool = false
	var end_tick: int = 135
	for tick: int in 150:
		await physics_frame
		var previous: Dictionary = f.parkour_snapshot()
		if str(previous.get("phase", "")) == "hang":
			hang_ticks += 1
		if required == "wall_kick":
			input.v_set(1, "up", tick >= 6 and hang_ticks == 0)
			input.v_set(1, "down", hang_ticks >= 10)
			input.v_set(1, "jump", (tick >= 9 and hang_ticks == 0) or hang_ticks >= 10)
		else:
			input.v_set(1, "right", true)
			input.v_set(1, "crouch", true)
		f._physics_process(1.0 / 60.0)
		f.skeletal._physics_process(1.0 / 60.0)
		f.skeletal._on_mannequin_updated()
		var snapshot: Dictionary = f.parkour_snapshot()
		var phase: String = str(snapshot.get("phase", ""))
		if phase == required:
			observed = true
			end_tick = tick + 18
		var motion = f.skeletal.parkour_motion
		title.text = "%s | tick %d | %s\nActual InputRouter / CityDistrict | station start\n%s  progress %.2f | %s view" % [hero, tick, phase if not phase.is_empty() else "air / ground", motion.source_clip, float(snapshot.get("progress", 0.0)), "side" if side_view else "three-quarter"]
		var offset: Vector3 = Vector3(0, 1.5, 6) if required == "landing_roll" else Vector3(6, 1.8, 0)
		if not side_view:
			offset = offset + Vector3(-3, 0.4, 0) if required == "landing_roll" else Vector3(-5, 3.0, 0.25)
		camera.position = f.position + offset
		camera.look_at(f.position + Vector3(0, 0.95, 0))
		trace.append({"case": id, "tick": tick, "phase": phase, "source":motion.source_clip, "progress": snapshot.get("progress", 0.0), "position":vec(f.position), "velocity":vec(f.velocity), "grounded":f.is_on_floor(), "floor_point":vec(snapshot.get("floor_point", Vector3.ZERO))})
		if phase == required:
			trace[-1]["skin"] = measure_skin(f, snapshot)
		await process_frame
		await RenderingServer.frame_post_draw
		if tick % 3 == 0:
			if root.get_texture().get_image().save_png(output.path_join("%04d.png" % tick)) == OK:
				saved += 1
			else:
				failures += 1
		if observed and tick >= end_tick:
			break
	if not observed:
		failures += 1
		push_error("TRICK_NATIVE missing actual phase " + id)
	print("TRICK_NATIVE_ROUTE ", id, " observed=", observed)
	input.v_clear(1)
	f.free()

func vec(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func measure_skin(f, snapshot: Dictionary) -> Dictionary:
	var sk: Skeleton3D = f.skeletal.hero_skeleton
	var mesh: MeshInstance3D = f.skeletal.hero_mesh
	if not skin_cache.has(f.get_instance_id()):
		var vertices: Array = []
		for surface: int in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var stride: int = bones.size() / points.size()
			for vertex: int in points.size():
				var influences: Array = []
				for index: int in stride:
					var offset: int = vertex * stride + index
					if weights[offset] <= 0.0:
						continue
					var bind: int = bones[offset]
					var bone: int = sk.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
					influences.append([bone, mesh.skin.get_bind_pose(bind) * points[vertex], weights[offset]])
				vertices.append(influences)
		skin_cache[f.get_instance_id()] = vertices
	var poses: Array[Transform3D] = []
	for bone: int in sk.get_bone_count():
		poses.append(sk.global_transform * sk.get_bone_global_pose(bone))
	var minimum: float = INF
	var wall_minimum: float = INF
	var invalid: int = 0
	var count: int = 0
	for influences: Array in skin_cache[f.get_instance_id()]:
		var point := Vector3.ZERO
		for influence: Array in influences:
			point += (poses[influence[0]] * influence[1]) * influence[2]
		count += 1
		if not point.is_finite():
			invalid += 1
		minimum = minf(minimum, (point - Vector3(snapshot.floor_point)).dot(Vector3(snapshot.floor_normal)))
		wall_minimum = minf(wall_minimum, (point - Vector3(snapshot.wall_point)).dot(Vector3(snapshot.wall_normal)))
	if count == 0 or invalid > 0:
		failures += 1
		push_error("TRICK_NATIVE invalid full skin measurement")
	var accessory_minimum: float = INF
	var accessory_vertices: int = 0
	var holders: Array = [f.skeletal.gear]
	if f.skeletal.sword != null:
		holders.append(f.skeletal.sword)
	for holder: Node3D in holders:
		for part: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
			if not part.is_visible_in_tree() or part.mesh == null:
				continue
			for vertex: Vector3 in part.mesh.get_faces():
				var point: Vector3 = part.global_transform * vertex
				accessory_minimum = minf(accessory_minimum, (point - Vector3(snapshot.floor_point)).dot(Vector3(snapshot.floor_normal)))
				accessory_vertices += 1
	if snapshot.phase == "landing_roll" and (accessory_vertices == 0 or accessory_minimum < -0.006 or minimum < -0.006):
		failures += 1
		push_error("TRICK_NATIVE visible support penetrates the real floor")
	return {"vertices":count, "invalid":invalid, "floor_minimum":minimum, "wall_plane_minimum":wall_minimum, "accessory_minimum":accessory_minimum, "accessory_vertices":accessory_vertices, "sword_drawn":f.sword_drawn, "sword_hand":f.sword_hand}
