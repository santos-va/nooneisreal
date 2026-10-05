extends SceneTree
## Native render review of presentation states; gameplay transition coverage lives in focused probes.
## Run with --path game --script res://../tools/animation/combat_visual_capture.gd -- --out=/tmp/nir-authored-visuals
var world: Node3D
var f: Node3D
var title: Label
var folder: String = "/tmp/nir-authored-visuals"
var actor: GDScript
var limbs: GDScript
var camera: Camera3D
var motion_only: bool = false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--motion-only":
			motion_only = true
		if arg.begins_with("--out="):
			folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(800, 600)
	await process_frame
	actor = load("res://scripts/fighter/Fighter.gd")
	limbs = load("res://scripts/fighter/LimbMoves.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
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
	var floor_mesh := MeshInstance3D.new()
	var floor_plane := PlaneMesh.new()
	floor_plane.size = Vector2(20, 20)
	floor_mesh.mesh = floor_plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("465361")
	floor_mesh.material_override = floor_material
	world.add_child(floor_mesh)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(2.7, 1.8, 3.4)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.fov = 35
	camera.current = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(24, 20)
	title.add_theme_font_size_override("font_size", 22)
	layer.add_child(title)
	var ground := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(40,1,40)
	collision.shape=box
	ground.position.y=-0.5
	ground.add_child(collision)
	world.add_child(ground)
	root.get_node("GameState").water=null
	var input: Node=root.get_node("InputRouter")
	input.apply_profile("solo",false)
	var trace: Array[String] = ["case,frame,x,y,z,vx,vy,vz,state,clip"]
	for hero: String in ["choko", "skea"]:
		for view: String in ["front", "side"]:
			f = load("res://scenes/fighter/Fighter.tscn").instantiate()
			f.data = load("res://data/characters/%s.tres" % hero)
			world.add_child(f)
			f.set_physics_process(false)
			f.skeletal.set_physics_process(false)
			f.control_locked = false
			f.state = actor.State.JUMP
			f.position = Vector3(0, 3.8, 0)
			f.velocity = Vector3(4, -2, 0)
			f.forward = Vector3.RIGHT
			input.v_clear(1)
			input.v_press(1, "right")
			var id: String = hero + "_landing_" + view
			var sequence: String = folder.path_join(id)
			DirAccess.make_dir_recursive_absolute(sequence)
			for frame: int in 50:
				await physics_frame
				f._physics_process(1.0 / 60.0)
				f.skeletal._physics_process(1.0 / 60.0)
				f.skeletal._on_mannequin_updated()
				title.text = "%s | frame %d | %s" % [id, frame, f.skeletal.clip]
				camera.position = f.position + (Vector3(5.7, 1.8, 1.5) if view == "front" else Vector3(1.5, 1.8, 5.7))
				camera.look_at(f.position + Vector3(0, 0.95, 0))
				trace.append("%s,%d,%.7f,%.7f,%.7f,%.7f,%.7f,%.7f,%d,%s" % [id, frame, f.position.x, f.position.y, f.position.z, f.velocity.x, f.velocity.y, f.velocity.z, f.state, f.skeletal.clip])
				await process_frame
				await RenderingServer.frame_post_draw
				var error: Error = root.get_texture().get_image().save_png(sequence.path_join("%04d.png" % frame))
				if error != OK:
					push_error("capture failed " + id)
					quit(1)
					return
			input.v_clear(1)
			f.free()
	var output := FileAccess.open(folder.path_join("authority-trace.csv"), FileAccess.WRITE)
	output.store_string("\n".join(trace) + "\n")
	output.close()
	world.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("LANDING_NATIVE_COMPLETE sequences=4 frames=200")
	quit(0)
