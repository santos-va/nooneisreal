extends SceneTree
## Native render review of presentation states; gameplay transition coverage lives in focused probes.
## Run with --path game --script res://../tools/animation/combat_visual_capture.gd -- --out=/tmp/nir-combat-visuals
var world: Node3D
var f: Node3D
var title: Label
var folder: String = "/tmp/nir-combat-visuals"
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
	root.size = Vector2i(1280, 900)
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
	camera.position = Vector3(3.3, 2.2, 4.8)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.fov = 35
	camera.current = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(24, 20)
	title.add_theme_font_size_override("font_size", 26)
	layer.add_child(title)
	_make_fighter("choko")
	f.state = actor.State.IDLE
	await capture("01_choko_back", "Choko | sword stored behind the back")
	camera.position = Vector3(-3.3, 2.2, 4.8)
	camera.look_at(Vector3(0, 1.0, 0))
	await capture("02_choko_back_reverse", "Choko | back mount, reverse view")
	camera.position = Vector3(3.3, 2.2, 4.8)
	camera.look_at(Vector3(0, 1.0, 0))
	f.state = actor.State.SWAP
	f.sword_swap_drawing = true
	f.sword_swap_from = "right"
	f.sword_swap_to = "right"
	f.sword_swap_frame = 12
	f.sword_drawn = true
	await capture("03_choko_draw", "Choko | drawing from the back")
	f.sword_swap_drawing = false
	f.sword_swap_to = "left"
	f.sword_swap_frame = 12
	f.sword_hand = "left"
	f.sword_form = 1
	await capture("04_choko_dust", "Choko | dissolved into particles at form contact")
	f.state = actor.State.IDLE
	f.skeletal.sword.stow_weight = 0.0
	await capture("05_choko_form", "Choko | new blade assembled in the left hand")
	f.free()
	_make_fighter("skea")
	for step in 3:
		var action: String = "left_leg" if step % 2 == 0 else "right_leg"
		f.current_move = limbs.resolve(f.data, action, step, "right_leg" if step == 2 else "left_leg", false, false)
		f.state = actor.State.ATTACK
		f.move_frame = f.current_move.startup
		await capture("06_skea_kick_%d" % step, "Skea | kick string step %d" % (step + 1))
	# Sample the same finisher from a side/front view and through recovery.
	camera.position = Vector3(4.8, 2.1, 1.5)
	camera.look_at(Vector3(0, 1.0, 0))
	f.move_frame = f.current_move.startup + 1
	await capture("06b_skea_spin_active_front", "Skea | spinning kick contact, front-side")
	f.move_frame = f.current_move.startup + f.current_move.active + f.current_move.recovery - 1
	await capture("06c_skea_spin_recovery", "Skea | finished turn, recovered guard")
	camera.position = Vector3(3.3, 2.2, 4.8)
	camera.look_at(Vector3(0, 1.0, 0))
	f.state = actor.State.ATTACK
	f.current_move = f.data.ultimate_veil
	f.move_frame = f.current_move.startup + 10
	var grimoire: GDScript = load("res://scripts/skills/GrimoireFx.gd")
	f.ult_fx = grimoire.spawn(f, f.current_move)
	await capture("07_skea_levitate", "Skea | crossed-leg levitation and writing gesture")
	f.state = actor.State.IDLE
	await capture("08_skea_levitate_idle", "Skea | mobile ultimate keeps the levitation pose")
	f.state = actor.State.ATTACK
	f.current_move = limbs.resolve(f.data, "right_hand", 2, "left_hand", false, false)
	f.move_frame = f.current_move.startup
	var wave_script: GDScript = load("res://scripts/skills/SkeaWave.gd")
	if wave_script != null:
		wave_script.spawn(f, f.current_move)
	await capture("09_skea_wave", "Skea | physical strike with purple extension")
	grimoire.cancel_owner(f)
	world.queue_free()
	await process_frame
	root.get_node("UltMusic").queue_free()
	root.get_node("Sfx").queue_free()
	await process_frame
	await create_timer(0.35).timeout
	print("COMBAT_VISUAL_CAPTURE_COMPLETE folder=", folder)
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
	for index in 4:
		f.animator.tick(1.0 / 60.0, f, false)
		f.skeletal._physics_process(1.0 / 60.0)
		f.skeletal._on_mannequin_updated()
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))
	if error != OK:
		push_error("Capture failed: " + filename)
		quit(1)
