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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
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
	var variants: Array[Dictionary] = [
		{"name": "jab", "action": "left_hand", "stage": 0},
		{"name": "cross", "action": "right_hand", "stage": 1},
		{"name": "bodyhook", "action": "left_hand", "stage": 1, "previous": "left_hand"},
		{"name": "uppercut", "action": "right_hand", "stage": 2},
		{"name": "hammer", "action": "right_hand", "stage": 2, "sequence": "right_hand>left_hand>right_hand"},
		{"name": "kick", "action": "left_leg", "stage": 0},
		{"name": "roundhouse", "action": "right_leg", "stage": 1},
		{"name": "spin", "action": "left_leg", "stage": 2},
		{"name": "lowhand", "action": "left_hand", "stage": 0, "low": true},
		{"name": "lowkick", "action": "right_leg", "stage": 0, "low": true},
		{"name": "airkick", "action": "right_leg", "stage": 0, "air": true},
	]
	for hero: String in ["choko", "skea"]:
		_make_fighter(hero)
		for variant: Dictionary in variants:
			f.current_move = limbs.resolve(f.data, variant.action, variant.stage, variant.get("previous", "left_hand"), variant.get("low", false), variant.get("air", false), "", variant.get("sequence", ""))
			f.position.y = 0.5 if variant.get("air", false) else 0.0
			f.state = actor.State.ATTACK
			for phase: String in ["windup", "contact", "recovery"]:
				f.move_frame = {"windup": int(f.current_move.startup / 2), "contact": f.current_move.startup, "recovery": f.current_move.startup + f.current_move.active + int(f.current_move.recovery * 0.6)}[phase]
				await capture("%s_%s_%s" % [hero, variant.name, phase], "%s | %s | %s | %s" % [hero, variant.name, phase, f.skeletal.state_clip(f)])
		if hero == "choko":
			f.position.y = 0.0
			f.sword_drawn = true
			for side: String in ["left", "right"]:
				f.sword_hand = side
				f.attack_sword_hand = side
				f.skeletal.sword.stow_weight = 0.0
				for stage in 3:
					f.current_move = limbs.resolve(f.data, side + "_hand", stage, "", false, false, side)
					f.move_frame = f.current_move.startup
					await capture("choko_sword_%s_%d" % [side, stage], "Choko | sword %s %d | source %s" % [side, stage, f.skeletal.state_clip(f)])
		f.free()
	world.queue_free()
	await process_frame
	root.get_node("UltMusic").queue_free()
	root.get_node("Sfx").queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("AUTHORED_COMBAT_CAPTURE_COMPLETE folder=", folder)
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
		f.animator.tick(1.0 / 60.0, f, false)
		f.skeletal._physics_process(1.0 / 60.0)
		f.skeletal._on_mannequin_updated()
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))
	if error != OK:
		push_error("Capture failed: " + filename)
		quit(1)
