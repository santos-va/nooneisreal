extends SceneTree
## Native Skea start/stop + real finite-token recovery, driven through Fighter and InputRouter.
## --fixed-fps 60 -- --out=/tmp/locomotion-sequence ; pair baseline/candidate with the same script.
var folder: String = "/tmp/locomotion-sequence"
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960, 640)
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.free_move = true
	gs.skeletal_rig = true
	gs.water = null
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("202b37")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e6edff")
	environment.environment.ambient_light_energy = 0.8
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	light.light_energy = 1.3
	world.add_child(light)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 30)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 30)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("4a5561")
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)
	for line: int in range(-20, 40):
		var stripe := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.014, 0.004, 6)
		stripe.mesh = mesh
		stripe.position = Vector3(float(line) * 0.5, 0.004, 0)
		world.add_child(stripe)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = 38
	camera.current = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 21)
	layer.add_child(title)
	var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.data = load("res://data/characters/skea.tres")
	world.add_child(f)
	f.set_physics_process(false)
	f.skeletal.set_physics_process(false)
	f.state = f.State.IDLE
	f.control_locked = false
	f.forward = Vector3.RIGHT
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	input.set_view_basis(1, Vector3.FORWARD)
	await physics_frame
	var trace: Array[String] = ["frame,phase,speed,clip,clip_time,x"]
	var clips: Dictionary = {}
	for frame: int in 240:
		await physics_frame
		if frame == 24:
			# Enter the actual missed-shot recovery authority; the registry owns the token.
			f.grapple.token = f.grapple.registry.issue(1)
			f.grapple.projectile_position = f.position + Vector3(12, 1.25, 0)
			f.grapple._flight_direction = Vector3.RIGHT
			f.grapple._begin_rewind()
		var moving: bool = (frame >= 24 and frame < 78) or (frame >= 120 and frame < 184)
		input.v_set(1, "right", moving)
		f._physics_process(1.0 / 60.0)
		f.skeletal._physics_process(1.0 / 60.0)
		f.skeletal._on_mannequin_updated()
		var speed: float = Vector2(f.velocity.x, f.velocity.z).length()
		var stage: String = "WIND ROPE + WALK" if f.grapple.recovering() else ("MOVE" if moving else "STOP / SETTLE")
		title.text = "SKEA | %s\n%.2f m/s | %s | frame %d\nFloor stripes: 0.5 m" % [stage, speed, f.skeletal.clip, frame]
		camera.position = f.position + Vector3(3.3, 2.1, 5.8)
		camera.look_at(f.position + Vector3(0, 0.95, 0))
		trace.append("%d,%s,%.5f,%s,%.5f,%.5f" % [frame, stage, speed, f.skeletal.clip, f.skeletal.clip_pos, f.position.x])
		clips[f.skeletal.clip] = true
		await process_frame
		await RenderingServer.frame_post_draw
		if frame % 2 == 0:
			var result: Error = root.get_texture().get_image().save_png(folder.path_join("frame_%04d.png" % (frame / 2)))
			if result != OK:
				quit(1)
				return
	input.v_clear(1)
	var file := FileAccess.open(folder.path_join("trace.csv"), FileAccess.WRITE)
	file.store_string("\n".join(trace))
	print("LOCOMOTION_CAPTURE_COMPLETE frames=120 clips=", clips.keys(), " folder=", folder)
	quit(0)
