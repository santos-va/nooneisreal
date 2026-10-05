extends SceneTree
## Native gameplay capture on actual district solids; never injects parkour metadata.
## --path game --fixed-fps 60 --script res://../tools/animation/parkour_capture.gd -- --out=/tmp/nir-parkour
var folder: String = "/tmp/nir-parkour"
var world: Node3D
var camera: Camera3D
var title: Label
var trace: Array[Dictionary] = []
var saved: int = 0
var failures: int = 0
var fixtures: bool = false
var selected_case: String = ""
var opposed: bool = false
var duration: int = 150
var foot_proof: bool = false
var measure_feet: bool = false
var check_feet: bool = false

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
		if argument == "--fixtures":
			fixtures = true
		if argument.begins_with("--case="):
			selected_case = argument.trim_prefix("--case=")
		if argument == "--opposed":
			opposed = true
		if argument == "--foot-proof":
			foot_proof = true
			measure_feet = true
		if argument == "--measure-feet":
			measure_feet = true
		if argument == "--check-feet":
			measure_feet = true
			check_feet = true
		if argument.begins_with("--ticks="):
			duration = maxi(60, int(argument.trim_prefix("--ticks=")))
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960, 640)
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.skeletal_rig = true
	gs.free_move = true
	gs.water = null
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
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
	if fixtures:
		_box(Vector3(0, -0.5, 0), Vector3(30, 1, 20), Color("465361"))
	else:
		world.add_child(load("res://scenes/world/CityDistrict.tscn").instantiate())
	camera = Camera3D.new()
	world.add_child(camera)
	camera.fov = 42
	camera.current = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(18, 16)
	title.add_theme_font_size_override("font_size", 20)
	layer.add_child(title)
	for hero: String in ["choko", "skea"]:
		await _route(hero, false)
	await _route("skea", true)
	if not fixtures:
		await _rope_route()
	await _low_hook_route()
	var output := FileAccess.open(folder.path_join("trace.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(trace, "\t") + "\n")
	output.close()
	world.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	# The audio mixer retires Ogg playback on wall time, even under --fixed-fps.
	var drain_until: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drain_until:
		await process_frame
		OS.delay_msec(1)
	print("PARKOUR_NATIVE_COMPLETE images=%d ticks=%d failures=%d" % [saved, trace.size(), failures])
	quit(0 if failures == 0 else 1)

func _box(center: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visible := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visible.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visible.material_override = material
	body.add_child(visible)
	body.position = center
	world.add_child(body)
	return body

func _route(hero: String, wall_run: bool) -> void:
	var id: String = hero + ("_wall_run" if wall_run else "_ledge_mantle")
	if not selected_case.is_empty() and selected_case != id:
		return
	var sequence: String = folder.path_join(id)
	DirAccess.make_dir_recursive_absolute(sequence)
	var height: float = 8.0 if wall_run else 2.8
	var obstacle: StaticBody3D = _box(Vector3(1.5, height * 0.5, 0), Vector3(3, height, 5), Color("857180")) if fixtures else null
	var fighter: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
	fighter.set_script(load("res://scripts/world/CityFighter.gd"))
	fighter.data = load("res://data/characters/%s.tres" % hero)
	world.add_child(fighter)
	fighter.set_physics_process(false)
	fighter.skeletal.set_physics_process(false)
	var start: Vector3 = Vector3(14, 0, 30.7) if wall_run else Vector3(4, 0, 31.4)
	fighter.restart_at(Vector3(-2.0, 0.0, 0.0) if fixtures else start)
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	input.set_view_basis(1, Vector3.FORWARD)
	input.v_clear(1)
	var phases: Dictionary = {}
	var hang_frames: int = 0
	for tick: int in duration:
		await physics_frame
		var snapshot: Dictionary = fighter.parkour_snapshot()
		var previous_phase: String = str(snapshot.get("phase", ""))
		if previous_phase == "hang":
			hang_frames += 1
		input.v_set(1, "right" if fixtures else "up", tick >= 6 and tick < 120)
		input.v_set(1, "jump", tick >= 9 and tick < 100 and (hang_frames == 0 or hang_frames > 12))
		fighter._physics_process(1.0 / 60.0)
		fighter.skeletal._physics_process(1.0 / 60.0)
		fighter.skeletal._on_mannequin_updated()
		snapshot = fighter.parkour_snapshot()
		var phase: String = str(snapshot.get("phase", ""))
		if not phase.is_empty():
			phases[phase] = true
		var motion = fighter.skeletal.parkour_motion
		title.text = "%s | tick %d\n%s | %s | grip %.3f m\nActual input / %s; Godot %s" % [id, tick, phase if not phase.is_empty() else "air / ground", motion.source_clip, motion.grip_error, "collision fixture" if fixtures else "CityDistrict", Engine.get_version_info().string]
		camera.position = fighter.position + (Vector3(-4.8, 2.5, 6.0) if fixtures else Vector3(-5.5 if opposed else 5.5, 2.0, 0.25))
		camera.look_at(fighter.position + Vector3(0, 1.1, 0))
		trace.append({"case": id, "tick": tick, "phase": phase, "position": _vec(fighter.position), "velocity": _vec(fighter.velocity), "grounded": fighter.is_on_floor(), "clip": fighter.skeletal.clip, "parkour_clip": motion.source_clip, "cycle": motion.cycle, "grip_error": motion.grip_error, "progress": snapshot.get("progress", 0.0), "left_hand": _vec(fighter.skeletal.hand_world("Left")), "right_hand": _vec(fighter.skeletal.hand_world("Right")), "left_foot": _bone(fighter, "LeftFoot"), "right_foot": _bone(fighter, "RightFoot"), "wall_point": _vec(snapshot.get("wall_point", Vector3.ZERO)), "wall_normal": _vec(snapshot.get("wall_normal", Vector3.ZERO)), "left_target": _vec(snapshot.get("left_hand", Vector3.ZERO)), "right_target": _vec(snapshot.get("right_hand", Vector3.ZERO))})
		if measure_feet:
			trace[-1]["foot_proof"] = _shoe_pilaster(fighter)
			if check_feet:
				for side: String in ["Left", "Right"]:
					var measurement: Dictionary = trace[-1].foot_proof[side]
					if measurement.samples == 0 or measurement.invalid > 0 or measurement.strict_inside > 0:
						failures += 1
						push_error("PARKOUR_SHOE %s tick%d %s inside=%d samples=%d" % [id, tick, side, measurement.strict_inside, measurement.samples])
		await process_frame
		if not foot_proof:
			await RenderingServer.frame_post_draw
		if not foot_proof and tick % 2 == 0:
			var error: Error = root.get_texture().get_image().save_png(sequence.path_join("%04d.png" % tick))
			if error == OK:
				saved += 1
			else:
				failures += 1
	for required: String in (["wall_run"] if wall_run else ["hang", "mantle"]):
		if not phases.has(required):
			push_error("PARKOUR_NATIVE missing actual phase %s in %s" % [required, id])
			failures += 1
	print("PARKOUR_NATIVE_ROUTE ", id, " phases=", phases.keys())
	input.v_clear(1)
	fighter.free()
	if obstacle != null:
		obstacle.free()
	await physics_frame

func _vec(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _rope_route() -> void:
	var id: String = "choko_hook_reel"
	if not selected_case.is_empty() and selected_case != id:
		return
	var sequence: String = folder.path_join(id)
	DirAccess.make_dir_recursive_absolute(sequence)
	var fighter: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
	fighter.set_script(load("res://scripts/world/CityFighter.gd"))
	fighter.data = load("res://data/characters/choko.tres")
	world.add_child(fighter)
	fighter.set_physics_process(false)
	fighter.skeletal.set_physics_process(false)
	fighter.restart_at(Vector3(4.5, 0, 8))
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	input.set_view_basis(1, Vector3.FORWARD)
	input.v_clear(1)
	var phases: Dictionary = {}
	var initial_length: float = 0.0
	var minimum_length: float = INF
	var released: bool = false
	for tick: int in 90:
		await physics_frame
		input.v_set(1, "right", tick >= 3 and tick < 45)
		input.v_set(1, "grapple_parkour", tick == 8)
		input.v_set(1, "jump", tick >= 30 and tick < 68)
		input.v_set(1, "block", tick == 70)
		fighter._physics_process(1.0 / 60.0)
		fighter.skeletal._physics_process(1.0 / 60.0)
		fighter.skeletal._on_mannequin_updated()
		var hook = fighter.grapple
		var phase: String = hook.Phase.keys()[hook.phase]
		phases[phase] = true
		if hook.attached:
			if initial_length == 0.0:
				initial_length = hook.rope_length
			minimum_length = minf(minimum_length, hook.rope_length)
		if tick > 70 and initial_length > 0.0 and not hook.attached:
			released = true
		title.text = "CHOKO | CITY HOOK / REEL / RELEASE | tick %d\n%s | length %.2f m | reel remaining %.2f m\nActual input / CityDistrict; Godot %s" % [tick, phase, hook.rope_length, hook.reel_remaining(), Engine.get_version_info().string]
		var focus: Vector3 = fighter.position.lerp(Vector3(8, 6.5, 8), 0.45)
		camera.position = focus + Vector3(-5.5, 2.0, 9.0)
		camera.look_at(focus)
		trace.append({"case": id, "tick": tick, "phase": phase, "position": _vec(fighter.position), "velocity": _vec(fighter.velocity), "grounded": fighter.is_on_floor(), "clip": fighter.skeletal.clip, "rope_length": hook.rope_length, "attached": hook.attached, "reel_remaining": hook.reel_remaining(), "left_hand": _vec(fighter.skeletal.hand_world("Left")), "right_hand": _vec(fighter.skeletal.hand_world("Right"))})
		await process_frame
		await RenderingServer.frame_post_draw
		if tick % 2 == 0:
			if root.get_texture().get_image().save_png(sequence.path_join("%04d.png" % tick)) == OK:
				saved += 1
			else:
				failures += 1
	if not phases.has("WINDUP") or not phases.has("FLIGHT") or not phases.has("HANG") or not released or initial_length - minimum_length < 0.5:
		push_error("PARKOUR_NATIVE hook route missed cast/contact/reel/release")
		failures += 1
	print("PARKOUR_NATIVE_ROUTE ", id, " phases=", phases.keys(), " shortening=", initial_length - minimum_length, " released=", released)
	input.v_clear(1)
	fighter.free()
	await physics_frame

func _bone(fighter: Node3D, name: String) -> Array:
	var skeleton: Skeleton3D = fighter.skeletal.hero_skeleton
	var index: int = skeleton.find_bone(name)
	return _vec(skeleton.global_transform * skeleton.get_bone_global_pose(index).origin) if index >= 0 else []

func _low_hook_route() -> void:
	# Explicit fixture matching city_hook_gear_check; not an authored district anchor.
	if selected_case != "skea_low_hook":
		return
	var id: String = "skea_low_hook"
	var sequence: String = folder.path_join(id)
	DirAccess.make_dir_recursive_absolute(sequence)
	var anchor := Marker3D.new()
	world.add_child(anchor)
	anchor.position = Vector3(0, 2, -4)
	anchor.add_to_group("grapple_anchor")
	var fighter: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
	fighter.set_script(load("res://scripts/world/CityFighter.gd"))
	fighter.data = load("res://data/characters/skea.tres")
	world.add_child(fighter)
	fighter.set_physics_process(false)
	fighter.skeletal.set_physics_process(false)
	fighter.grapple.registry.set_physics_process(false)
	fighter.grapple.registry.clear_match()
	fighter.control_locked = false
	fighter.forward = Vector3.FORWARD
	fighter.state = fighter.State.GRAPPLE
	await physics_frame
	fighter.grapple.fire(false, "grapple_parkour", {"point": anchor.position, "target_id": str(anchor.get_path())})
	var phases: Dictionary = {}
	for tick: int in 80:
		await physics_frame
		var hook = fighter.grapple
		hook.tick_regen(1.0 / 60.0, true)
		if hook.busy():
			hook.drive(1.0 / 60.0, true, tick >= 30 and tick < 70)
		fighter.animator.tick(1.0 / 60.0, fighter, false)
		fighter.skeletal._physics_process(1.0 / 60.0)
		fighter.skeletal._on_mannequin_updated()
		var phase: String = hook.Phase.keys()[hook.phase]
		phases[phase] = true
		var motion = fighter.skeletal.authored_hook
		title.text = "SKEA | LOW HOOK | tick %d\n%s / %s | grip %.3f m\nReal CityFighter hook drive; explicit low-anchor fixture" % [tick, phase, motion.source_phase, motion.grip_error]
		camera.fov = 35
		camera.position = fighter.position + Vector3(-2.4 if opposed else 2.4, 1.7, -3.4)
		camera.look_at(fighter.position + Vector3(0, 0.95, 0))
		trace.append({"case": id, "tick": tick, "phase": phase, "source_phase": motion.source_phase, "position": _vec(fighter.position), "velocity": _vec(fighter.velocity), "rope_length": hook.rope_length, "attached": hook.attached, "grip_error": motion.grip_error, "left_hand": _vec(fighter.skeletal.hand_world("Left")), "right_hand": _vec(fighter.skeletal.hand_world("Right"))})
		await process_frame
		await RenderingServer.frame_post_draw
		if tick % 2 == 0:
			if root.get_texture().get_image().save_png(sequence.path_join("%04d.png" % tick)) == OK:
				saved += 1
			else:
				failures += 1
	if not phases.has("HANG") or not fighter.grapple._responsive_traversal():
		failures += 1
		push_error("PARKOUR_NATIVE low hook missed actual city HANG")
	print("PARKOUR_NATIVE_ROUTE ", id, " phases=", phases.keys())
	fighter.grapple.registry.clear_match()
	fighter.free()
	anchor.free()
	await physics_frame

func _shoe_pilaster(fighter: Node3D) -> Dictionary:
	var skeleton: Skeleton3D = fighter.skeletal.hero_skeleton
	var poses: Array[Transform3D] = []
	for bone: int in skeleton.get_bone_count():
		poses.append(skeleton.get_bone_global_pose(bone))
	var result: Dictionary = {}
	# Exact current CityArchitecture south centre pilaster, not an infinite wall plane.
	var low := Vector3(13.89, 0.15, 30.0)
	var high := Vector3(14.11, 7.85, 30.20)
	for side: String in ["Left", "Right"]:
		var count: int = 0
		var inside: int = 0
		var invalid: int = 0
		var depth: float = 0.0
		var minimum := Vector3(INF, INF, INF)
		var maximum := Vector3(-INF, -INF, -INF)
		for influences: Array in fighter.skeletal.foot_contact.samples.get(side, []):
			var point := Vector3.ZERO
			for influence: Array in influences:
				point += (poses[influence[0]] * influence[1]) * influence[2]
			point = skeleton.global_transform * point
			count += 1
			if not point.is_finite():
				invalid += 1
				continue
			minimum = minimum.min(point)
			maximum = maximum.max(point)
			if point.x > low.x + 0.00001 and point.x < high.x - 0.00001 and point.y > low.y + 0.00001 and point.y < high.y - 0.00001 and point.z > low.z + 0.00001 and point.z < high.z - 0.00001:
				inside += 1
				depth = maxf(depth, minf(minf(point.x - low.x, high.x - point.x), minf(point.z - low.z, high.z - point.z)))
		result[side] = {"samples": count, "invalid": invalid, "strict_inside": inside, "depth": depth, "minimum": _vec(minimum), "maximum": _vec(maximum)}
	return result
