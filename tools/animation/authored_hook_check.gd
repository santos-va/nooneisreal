extends SceneTree
## Actual hook drive sequences; --capture=/absolute/path adds native every-frame proof.
var checks: int = 0
var failures: int = 0
var folder: String = ""
var baseline: bool = false
var only_scenario: String = ""
var maximum_grip_error: float = 0.0
var world: Node3D
var f: Node3D
var anchor: Node3D
var other: Node3D
var actor: GDScript
var hook: GDScript
var camera: Camera3D
var title: Label
var trace: FileAccess
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("AUTHORED_HOOK: " + label)
func authority() -> Array:
	return [f.transform, f.velocity, f.state, f.meter, f.grapple.phase, f.grapple.token, f.grapple._deployed_token, f.grapple.rope_length, f.grapple.charges, f.grapple.recovery_progress, f.grapple.registry.records.duplicate(true)]
func render_tick(hero: String, scenario: String, frame: int) -> void:
	var before: Array = authority()
	var reel_before: float = 0.0 if baseline else f.skeletal.authored_hook.reel_cycle
	var previous_length: float = 0.0 if baseline else f.skeletal.authored_hook._previous_length
	var previous_phase: int = -1 if baseline else f.skeletal.authored_hook._phase
	seed(9371)
	var expected: int = randi()
	seed(9371)
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	f.skeletal.retarget()
	check(randi() == expected, "presentation leaves RNG unchanged")
	check(before == authority(), "presentation leaves rope and fighter authority unchanged")
	if not baseline:
		check(not f.skeletal.uses_procedural_motion(), "authored hook replaces capsule fallback")
		var motion = f.skeletal.authored_hook
		if f.state == actor.State.GRAPPLE:
			check(not motion.source_clip.is_empty(), "active phase has licensed authored source")
		check(is_finite(motion.grip_error), "finite grip solve")
		maximum_grip_error = maxf(maximum_grip_error, motion.grip_error)
		if f.grapple.phase == hook.Phase.HANG and previous_phase == hook.Phase.HANG:
			var expected_cycle: float = reel_before + maxf(0.0, previous_length - f.grapple.rope_length) / (0.65 if f.grapple._responsive_traversal() else f.grapple.reel_distance)
			check(absf(motion.reel_cycle - expected_cycle) < 0.00001, "regrip cycle follows real shortening only")
		check(motion.grip_error < 0.04, "%s/%s/%d actual hero reaches physical span within 4 cm: %.4f" % [hero, scenario, frame, motion.grip_error])
	var sk: Skeleton3D = f.skeletal.hero_skeleton
	for side: String in ["Left", "Right"]:
		for pair: Array in [[side + "Arm", side + "ForeArm"], [side + "ForeArm", side + "Hand"]]:
			var a: int = sk.find_bone(pair[0])
			var b: int = sk.find_bone(pair[1])
			var actual: float = sk.get_bone_global_pose(a).origin.distance_to(sk.get_bone_global_pose(b).origin)
			var rest: float = sk.get_bone_global_rest(a).origin.distance_to(sk.get_bone_global_rest(b).origin)
			check(absf(actual - rest) < 0.01, "arm segments retain actual hero length")
	if frame == 20:
		var poses: Array = []
		for bone: int in sk.get_bone_count():
			poses.append(sk.get_bone_pose(bone))
		f.frozen_frames = 3
		f.skeletal._physics_process(1.0 / 60.0)
		f.skeletal._on_mannequin_updated()
		for bone: int in sk.get_bone_count():
			check(poses[bone] == sk.get_bone_pose(bone), "freeze holds hero drawing")
		f.frozen_frames = 0
	if trace != null:
		trace.store_csv_line(PackedStringArray([hero, scenario, str(frame), str(f.position), str(f.velocity), str(f.state), str(f.grapple.phase), str(f.grapple.rope_length), str(f.grapple.charges), str(f.grapple.token), str(f.grapple._deployed_token)]))
	if not folder.is_empty():
		camera.position = f.position + Vector3(3.5, 2.0, 4.2)
		camera.look_at(f.position + Vector3(0, 1, 0))
		title.text = "%s · %s · frame %d" % [hero, scenario, frame]
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("%s_%s_%03d.png" % [hero, scenario, frame]))
func run() -> void:
	await process_frame
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			folder = arg.trim_prefix("--capture=")
		if arg.begins_with("--scenario="):
			only_scenario = arg.trim_prefix("--scenario=")
		if arg == "--baseline":
			baseline = true
	root.get_node("Sfx")._players.clear() # This deterministic motion probe does not exercise audio playback.
	actor = load("res://scripts/fighter/Fighter.gd")
	hook = load("res://scripts/grapple/GrappleHook.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	root.get_node("GameState").water = null
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	anchor = Node3D.new()
	anchor.name = "HookAnchor"
	world.add_child(anchor)
	anchor.add_to_group("grapple_anchor")
	other = Node3D.new()
	other.name = "TransferAnchor"
	world.add_child(other)
	other.add_to_group("grapple_anchor")
	if not folder.is_empty():
		DirAccess.make_dir_recursive_absolute(folder)
		trace = FileAccess.open(folder.path_join("authority.csv"), FileAccess.WRITE)
		root.size = Vector2i(800, 600)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("24303e")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_energy = 0.7
		world.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, -35, 0)
		world.add_child(light)
		var mesh := MeshInstance3D.new()
		mesh.mesh = PlaneMesh.new()
		mesh.mesh.size = Vector2(100, 100)
		world.add_child(mesh)
		camera = Camera3D.new()
		world.add_child(camera)
		camera.current = true
		camera.fov = 38
		var layer := CanvasLayer.new()
		root.add_child(layer)
		title = Label.new()
		title.position = Vector2(15, 15)
		layer.add_child(title)
	for hero: String in ["choko", "skea"]:
		for scenario: String in ["high", "low", "catch", "transfer", "miss"]:
			if not only_scenario.is_empty() and scenario != only_scenario:
				continue
			f = load("res://scenes/fighter/Fighter.tscn").instantiate()
			f.data = load("res://data/characters/%s.tres" % hero)
			world.add_child(f)
			f.set_physics_process(false)
			f.skeletal.set_physics_process(false)
			f.grapple.registry.set_physics_process(false)
			f.grapple.registry.clear_match()
			if f.skeletal.sword != null:
				f.skeletal.sword.set_physics_process(false)
			f.control_locked = false
			f.forward = Vector3(0, 0, -1)
			f.state = actor.State.GRAPPLE
			anchor.position = Vector3(0, 6, -3) if scenario != "low" else Vector3(0, 2.0, -4)
			other.position = Vector3(4, 7, -2)
			await physics_frame
			if scenario in ["catch", "transfer"]:
				f.position.y = 2.0
				anchor.position = Vector3(0, 6, 0)
				var token: int = f.grapple.registry.issue(1)
				f.grapple.registry.deploy(token, 1, anchor.position, f.position + hook.HAND, (f.position + hook.HAND).distance_to(anchor.position))
				f.grapple.fire(false, "grapple_parkour")
			else:
				var point: Vector3 = Vector3(30, 3, 0) if scenario == "miss" else anchor.position
				f.grapple.fire(false, "grapple_parkour", {"point": point, "target_id": "" if scenario == "miss" else str(anchor.get_path())})
			var seen: Dictionary = {}
			for frame: int in 108:
				if scenario == "transfer" and frame == 30:
					check(f.grapple.retarget({"point": other.position, "target_id": str(other.get_path())}), "real transfer accepted")
				if frame == 90:
					f.grapple.detach()
					f.state = actor.State.JUMP if not f.on_ground() else actor.State.IDLE
				f.grapple.tick_regen(1.0 / 60.0, f.state == actor.State.GRAPPLE)
				if f.grapple.busy():
					f.grapple.drive(1.0 / 60.0, true, frame >= 40 and frame < 78)
				if not f.grapple.busy() and f.state == actor.State.GRAPPLE:
					f.state = actor.State.IDLE if f.on_ground() else actor.State.JUMP
				seen[f.grapple.phase] = true
				await render_tick(hero, scenario, frame)
			check(seen.has(hook.Phase.HANG) if scenario != "miss" else not seen.has(hook.Phase.HANG), hero + scenario + " real contact versus miss coverage")
			if scenario == "miss" and folder.is_empty():
				# Native capture is a bounded rewind segment; this guard follows it to completion.
				for tail_frame: int in 600:
					f.grapple.tick_regen(1.0 / 60.0, false)
					var before_tail: Array = authority()
					f.animator.tick(1.0 / 60.0, f, false)
					f.skeletal._physics_process(1.0 / 60.0)
					f.skeletal.retarget()
					check(before_tail == authority(), "rewind-tail presentation preserves authority")
					if not f.grapple.busy():
						break
				check(not f.grapple.busy() and f.grapple.token == 0 and f.grapple.charges == f.grapple.max_charges, "actual rewind completes with conserved token")
				for settle_frame: int in 14:
					f.skeletal._physics_process(1.0 / 60.0)
					f.skeletal.retarget()
				if not baseline:
					check(f.skeletal.authored_hook.source_phase == "idle" and f.skeletal.authored_hook._grips.is_empty(), "completed rewind releases visual hands and source")
			f.grapple.registry.clear_match()
			f.free()
	for voice: AudioStreamPlayer in root.get_node("Sfx")._players:
		voice.stop()
		voice.stream = null
	root.get_node("Sfx")._cache.clear()
	world.free()
	await process_frame
	await process_frame
	if trace != null:
		trace.close()
	print("HOOK_MAX_GRIP_ERROR %.6f m" % maximum_grip_error)
	print("AUTHORED_HOOK_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
