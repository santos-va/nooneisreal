extends SceneTree
## Same-body-pose facial surface review; explicit diagnostics are not an authored combat sequence.
## Use native Compatibility with --audio-driver Dummy; output includes the actual shader controls.
var world: Node3D
var f: Node3D
var title: Label
var folder: String = "/tmp/nir-hero-face-capture"
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
	root.size = Vector2i(960, 720)
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
	for hero: String in ["choko", "skea"]:
		_make_fighter(hero)
		for i in 5:
			f.animator.tick(1.0 / 60.0, f, false)
			f.skeletal._physics_process(1.0 / 60.0)
			f.skeletal._on_mannequin_updated()
			await process_frame
		var sk: Skeleton3D = f.skeletal.hero_skeleton
		var hi: int = sk.find_bone("Head")
		print(hero," head bone ",hi," head ",sk.global_transform * sk.get_bone_global_pose(hi).origin)
		var focus: Vector3 = sk.global_transform * sk.get_bone_global_pose(hi).origin + Vector3(0,0.09,0)
		for shot: String in ["front_neutral", "front_focus", "front_hurt", "front_closed", "front_ko", "threequarter_neutral", "threequarter_focus", "threequarter_hurt", "threequarter_closed", "threequarter_ko"]:
			camera.position = focus + (Vector3(1.1,0,0) if shot.begins_with("front") else Vector3(1.05,0.03,-0.65))
			camera.look_at(focus)
			if shot == "body":
				camera.position = Vector3(2.7,1.8,-3.4)
				camera.look_at(Vector3(0,1,0))
			var state: String = shot.get_slice("_",1)
			var face = f.skeletal.face_presentation
			face.reset()
			f.state = actor.State.BLOCK if state == "focus" else (actor.State.HITSTUN if state == "hurt" else (actor.State.KO if state == "ko" else actor.State.IDLE))
			face.update(f,1.0/60.0,1)
			if state == "closed":
				face.closure = Vector2.ONE
				face.apply()
			print("FACE_NATIVE ",hero," ",shot," closure=",face.closure," mouth=",face.mouth_tension," brow=",face.brow_tension," mask=",f.skeletal.gear.garment.face_vertices)
			await capture(hero+"_"+shot,hero+" | same body pose / actual face atlas | "+state)
		f.free()
	world.queue_free()
	await process_frame
	root.get_node("UltMusic").queue_free()
	root.get_node("Sfx").queue_free()
	root.get_node("Music").queue_free()
	await process_frame
	var until: int = Time.get_ticks_msec() + 350
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("HERO_FACE_NATIVE_COMPLETE folder=", folder)
	quit(0)

func _make_fighter(id: String) -> void:
	f = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	f.data = load("res://data/characters/%s.tres" % id)
	world.add_child(f)
	f.set_physics_process(false)
	f.skeletal.set_physics_process(false)
	if f.skeletal.sword != null:
		f.skeletal.sword.set_physics_process(false)
	f.state = actor.State.IDLE

func capture(filename: String, caption: String) -> void:
	title.text = caption
	for index in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))
	if error != OK:
		push_error("Capture failed: " + filename)
		quit(1)
