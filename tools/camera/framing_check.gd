extends SceneTree
## Deterministic projection measurement, with optional native captures (--capture-dir=...).
## Root serial runner: Godot --headless --path game -s ../tools/camera/framing_check.gd
## Uses production camera geometry and actual CPU-skinned hero vertices; no simulation catch-up.
var checks: int = 0
var failures: int = 0
var capture_dir: String = ""
var baseline_only: bool = false
var viewport: SubViewport
var records: Array[Dictionary] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--baseline":
			baseline_only = true
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMERA_FRAMING: " + label)

func _run() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.free_move = true
	gs.skeletal_rig = true
	gs.p1_character = "choko"
	gs.p2_character = "skea"
	gs.p2_is_cpu = true
	gs.set_stage("river")
	viewport = SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var arena: Node3D = load("res://scenes/arena/Arena.tscn").instantiate()
	viewport.add_child(arena)
	# Disable the match, CPU, water clock, VFX and yaw advancement before waiting any frames.
	arena.process_mode = Node.PROCESS_MODE_DISABLED
	arena.get_node("HUD").get("_announce").visible = false
	var a = arena.p1
	var b = arena.p2
	var camera = arena.duel_camera
	var fighter_script: GDScript = load("res://scripts/fighter/Fighter.gd")
	for fighter in [a, b]:
		fighter.state = fighter_script.State.IDLE
		fighter.skeletal._physics_process(1.0 / 60.0)
		fighter.skeletal.retarget()
	var world_vertices: Array = [_vertices(a), _vertices(b)]
	if capture_dir != "":
		check(DirAccess.make_dir_recursive_absolute(capture_dir) == OK, "capture directory")
	for dimensions: Vector2i in [Vector2i(1152, 648), Vector2i(1024, 768), Vector2i(844, 390)]:
		viewport.size = dimensions
		for is_behind: bool in [true, false]:
			camera.behind = is_behind
			gs.duel.behind = is_behind
			for separation: float in [1.0, 4.0, 6.0, 12.0, 20.0, 30.0]:
				for degrees: float in [0.0, 90.0, 180.0, 270.0]:
					var line := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(degrees))
					a.position = -line * separation * 0.5
					b.position = line * separation * 0.5
					gs.duel.reset()
					gs.duel.sync(a.position, b.position, int(separation * 10 + degrees))
					camera._presentation_line = line
					camera._lookahead = Vector3.ZERO
					camera.rotation.y = camera._target_yaw()
					camera._apply(1.0)
					# An unconstrained SpringArm puts the child here; match physics is intentionally disabled.
					camera.cam.position = Vector3(0, 0, camera.arm.spring_length)
					camera.cam.fov = 60.0
					var baseline: Array = _metrics(camera.cam, [a, b], world_vertices)
					if camera.has_method("_apply_readability") and not baseline_only:
						camera._apply_readability(1.0)
					var result: Array = _metrics(camera.cam, [a, b], world_vertices)
					var key := "%s-%s-sep%02d-angle%03d" % [dimensions, "behind" if is_behind else "side", separation, degrees]
					check(camera.cam.fov <= 60.001 and camera.cam.fov >= 37.999, key + " FOV bounds")
					if separation <= 6.0 or not is_behind:
						check(is_equal_approx(camera.cam.fov, 60.0), key + " existing near/side FOV")
					for i in 2:
						check(result[i].hero_rect.position.x >= 0 and result[i].hero_rect.end.x <= 1 and result[i].hero_rect.position.y >= 0 and result[i].hero_rect.end.y <= 1, key + " actual hero entirely framed")
						check(result[i].capsule_share <= 0.301, key + " capsule <=30%")
						if separation <= 6.0:
							# Static side@6m baseline is 14.83%, below the written 15%; do not silently
							# turn a tolerance into design acceptance. This change must not reduce it.
							check(result[i].capsule_share >= baseline[i].capsule_share - 0.00001, key + " existing near projection not reduced")
					if is_behind and separation >= 12.0 and camera.has_method("_apply_readability") and not baseline_only:
						check(result[1].hero_rect.size.y > baseline[1].hero_rect.size.y * 1.10, key + " far actual hero improves >10%")
					if degrees == 0:
						var record := {"case": key, "separation": separation, "fov": camera.cam.fov, "p1": _serial(result[0]), "p2": _serial(result[1]), "baseline_p2": _serial(baseline[1])}
						records.append(record)
						print("CAMERA_METRIC ", JSON.stringify(record))
						if capture_dir != "" and dimensions == Vector2i(1152, 648):
							await RenderingServer.frame_post_draw
							check(viewport.get_texture().get_image().save_png(capture_dir.path_join(key + ".png")) == OK, "native screenshot")
	await _tracking(camera, a, b, gs)
	if capture_dir != "":
		var report := FileAccess.open(capture_dir.path_join("projection.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify(records, "\t"))
	arena.free()
	arena = null
	a = null
	b = null
	camera = null
	viewport.free()
	viewport = null
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CAMERA_FRAMING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _serial(metric: Dictionary) -> Dictionary:
	return {"capsule_share": metric.capsule_share, "hero_share": metric.hero_rect.size.y, "hero_px": metric.hero_rect.size.y * viewport.size.y, "margin": minf(metric.hero_rect.position.x, 1.0 - metric.hero_rect.end.x)}

func _metrics(cam: Camera3D, fighters: Array, vertices: Array) -> Array:
	var result: Array = []
	var size := Vector2(viewport.size)
	for i in 2:
		var fighter = fighters[i]
		var foot := cam.unproject_position(fighter.global_position)
		var head := cam.unproject_position(fighter.global_position + Vector3.UP * 1.8)
		var rect := Rect2()
		var first := true
		for local: Vector3 in vertices[i]:
			var pixel := cam.unproject_position(fighter.global_transform * local) / size
			if first:
				rect = Rect2(pixel, Vector2.ZERO)
				first = false
			else:
				rect = rect.expand(pixel)
		result.append({"capsule_share": absf(head.y - foot.y) / size.y, "hero_rect": rect})
	return result

func _tracking(camera: Node3D, a: Node3D, b: Node3D, gs: Node) -> void:
	viewport.size = Vector2i(1152, 648)
	camera.behind = true
	gs.duel.behind = true
	a.position = Vector3(-3, 0, 0)
	b.position = Vector3(3, 0, 0)
	gs.duel.reset()
	gs.duel.sync(a.position, b.position, 0)
	camera.setup(a, b)
	camera.set_physics_process(false)
	camera.set_process(false)
	var target: float = camera._target_yaw()
	var original_axis: Vector3 = camera._presentation_line
	var control_basis: Vector3 = gs.duel.to_world(Vector2.UP, 1)
	if capture_dir != "":
		await _crossing_shot(camera, a, b, "before-crossing")
	a.position = Vector3(3, 0, 0)
	b.position = Vector3(-3, 0, 0)
	gs.duel.sync(a.position, b.position, 1)
	var expected_input: Vector3 = gs.duel.to_world(Vector2.UP, 1)
	for frame in 120:
		camera._physics_process(1.0 / 60.0)
		check(absf(angle_difference(target, camera._target_yaw())) < 0.001, "crossing preserves world camera target")
		check(camera._presentation_line.dot(original_axis) > 0.999, "crossing stable accepted axis")
		check(gs.duel.to_world(Vector2.UP, 1) == expected_input, "presentation does not overwrite simulation input")
	check(control_basis.dot(expected_input) < -0.99, "simulation input follows real crossing independently")
	if capture_dir != "":
		await _crossing_shot(camera, a, b, "after-crossing-face-visible")
	for angle in 12:
		a.forward = Vector3.RIGHT.rotated(Vector3.UP, float(angle) * PI / 6.0)
		camera._physics_process(1.0 / 60.0)
		check(absf(angle_difference(target, camera._target_yaw())) < 0.001, "hero facing alone never drives camera")
	var previous: float = camera._target_yaw()
	var swept: float = 0.0
	var previous_turn: float = camera.turn_deg()
	for frame in 720:
		var line := Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(float(frame + 1)))
		a.position = -line * 3.0
		b.position = line * 3.0
		camera._physics_process(1.0 / 60.0)
		var now: float = camera._target_yaw()
		swept += angle_difference(previous, now)
		previous = now
		var turn: float = camera.turn_deg()
		check(absf(turn) <= 3.001 and absf(turn - previous_turn) <= 0.251, "sustained orbit respects yaw velocity and acceleration")
		previous_turn = turn
	check(absf(rad_to_deg(swept)) > 719.0, "two sustained orbits accumulate without branch reset")
	var held: Vector3 = camera._presentation_line
	for distance: float in [0.1, 0.6, 0.4, 0.7]:
		a.position = Vector3.ZERO
		b.position = Vector3.FORWARD * distance
		camera._physics_process(1.0 / 60.0)
		check(camera._presentation_line == held, "coincident bearing uses hysteresis")
	b.position = Vector3.FORWARD * 0.8
	camera._physics_process(1.0 / 60.0)
	check(not camera._axis_held, "axis unlocks after exit distance")
	a.position = Vector3(-3, 0, 0)
	b.position = Vector3(3, 0, 0)
	camera._lookahead = Vector3.ZERO
	for direction: float in [1.0, 0.0, -1.0]:
		a.velocity = Vector3(12, 0, 0) * direction
		b.velocity = a.velocity
		var last: Vector3 = camera._lookahead
		for frame in 120:
			camera._physics_process(1.0 / 60.0)
			check(camera._lookahead.length() <= 0.7501, "lead bounded in world metres")
			check((camera._lookahead - last).length() <= 0.121, "lead changes smoothly on acceleration/stop/reversal")
			last = camera._lookahead
		check((camera._lookahead - Vector3.RIGHT * direction * 0.75).length() < 0.001, "lead converges or returns to zero")
	# A moving close fight must still fit after the actual bounded focus shift.
	camera._presentation_line = Vector3.RIGHT
	camera._pull = 0.0
	camera.rotation.y = camera._target_yaw()
	for direction: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		camera._lookahead = direction * 0.75
		camera._apply(1.0)
		camera.cam.position = Vector3(0, 0, camera.arm.spring_length)
		camera.cam.fov = 60.0
		for fighter: Node3D in [a, b]:
			var foot: Vector2 = camera.cam.unproject_position(fighter.global_position) / Vector2(viewport.size)
			var head: Vector2 = camera.cam.unproject_position(fighter.global_position + Vector3.UP * 1.8) / Vector2(viewport.size)
			check(absf(head.y - foot.y) <= 0.30, "moving close fight nominal body <=30%")
			check(minf(foot.x, head.x) >= 0.15 and maxf(foot.x, head.x) <= 0.85 and minf(foot.y, head.y) >= 0.0 and maxf(foot.y, head.y) <= 1.0, "moving close fight keeps margins")
	camera.behind = false
	camera._physics_process(1.0 / 60.0)
	check(camera._lookahead == Vector3.ZERO, "shared PvP retains unbiased midpoint without new lead")
	a.velocity = Vector3.ZERO
	b.velocity = Vector3.ZERO

func _crossing_shot(camera: Node3D, a: Node3D, b: Node3D, label: String) -> void:
	for fighter: Node3D in [a, b]:
		var other: Node3D = b if fighter == a else a
		fighter.forward = (other.position - fighter.position).normalized()
		fighter.skeletal._physics_process(1.0 / 60.0)
		fighter.skeletal.retarget()
	camera.rotation.y = camera._yaw
	camera._apply(1.0)
	camera.cam.position = Vector3(0, 0, camera.arm.spring_length)
	camera.cam.fov = 60.0
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(capture_dir.path_join(label + ".png")) == OK, "crossing capture")

func _vertices(fighter: Node3D) -> PackedVector3Array:
	var mesh: MeshInstance3D = fighter.skeletal.hero_mesh
	var skeleton: Skeleton3D = fighter.skeletal.hero_skeleton
	var skin: Skin = mesh.skin
	var result := PackedVector3Array()
	var world_to_fighter := fighter.global_transform.affine_inverse()
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride: int = bones.size() / vertices.size()
		for vertex in vertices.size():
			var position := Vector3.ZERO
			for influence in stride:
				var index: int = vertex * stride + influence
				var bind: int = bones[index]
				var bone: int = skeleton.find_bone(skin.get_bind_name(bind)) if skin.get_bind_name(bind) != &"" else skin.get_bind_bone(bind)
				position += skeleton.get_bone_global_pose(bone) * (skin.get_bind_pose(bind) * vertices[vertex]) * weights[index]
			result.append(world_to_fighter * (skeleton.global_transform * position))
	return result
