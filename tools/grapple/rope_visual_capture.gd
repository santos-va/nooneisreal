extends SceneTree
## Native short/long loaded spans and actual upward-motion slack.
## --path game --script <absolute path> -- --out=/tmp/nir-rope-visuals
var folder: String = "/tmp/nir-rope-visuals"
var world: Node3D
var fighter: Node3D
var camera: Camera3D
var anchor_mesh: MeshInstance3D
var title: Label
var metadata: Array[Dictionary] = []
var Actor: GDScript
var Hook: GDScript

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1100, 1100)
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	Hook = load("res://scripts/grapple/GrappleHook.gd")
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
	environment.environment.background_color = Color("25303d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("dce8ff")
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 1.2
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("485460")
	floor_mesh.material_override = material
	world.add_child(floor_mesh)
	anchor_mesh = MeshInstance3D.new()
	var marker := SphereMesh.new()
	marker.radius = 0.10
	marker.height = 0.20
	anchor_mesh.mesh = marker
	world.add_child(anchor_mesh)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	world.add_child(camera)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(24, 24)
	title.add_theme_font_size_override("font_size", 24)
	layer.add_child(title)
	fighter = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	fighter.data = load("res://data/characters/choko.tres")
	world.add_child(fighter)
	fighter.set_physics_process(false)
	fighter.skeletal.set_physics_process(false)
	if fighter.skeletal.sword != null:
		fighter.skeletal.sword.set_physics_process(false)
	fighter.grapple.registry.set_physics_process(false)
	await physics_frame
	await sample("01_short_loaded", 2.4, Vector3(1.2, 0, 0), 40)
	await sample("02_long_loaded", 6.0, Vector3(2.5, 0, 0.4), 40)
	await sample("03_upward_slack", 4.0, Vector3(0.8, 5.0, 0.2), 10)
	var file := FileAccess.open(folder.path_join("measurements.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()
	world.queue_free()
	await process_frame
	root.get_node("Sfx").queue_free()
	root.get_node("UltMusic").queue_free()
	await create_timer(0.35).timeout
	print("ROPE_VISUAL_CAPTURE_COMPLETE captures=3 folder=", folder)
	quit(0)

func sample(filename: String, length: float, initial_velocity: Vector3, frames: int) -> void:
	var hook = fighter.grapple
	var registry = hook.registry
	registry.clear_match()
	fighter.position = Vector3(0, 1.8, 0)
	fighter.velocity = initial_velocity
	fighter._wish = Vector3.ZERO
	fighter.state = Actor.State.GRAPPLE
	var anchor: Vector3 = fighter.position + Hook.HAND + Vector3.UP * length
	anchor_mesh.position = anchor
	var token: int = registry.issue(fighter.player_index)
	registry.deploy(token, fighter.player_index, anchor, fighter.position + Hook.HAND, length)
	if hook.fire(false) != Hook.Target.ANCHOR:
		push_error("ROPE_CAPTURE: real registry attachment failed")
		quit(1)
		return
	# Real constraint drive, then the production capsule and skeletal pose pipeline.
	for frame: int in frames:
		hook.drive(1.0 / 60.0, true)
		fighter.animator.tick(1.0 / 60.0, fighter, false)
		fighter.skeletal._physics_process(1.0 / 60.0)
		fighter.skeletal._on_mannequin_updated()
		await process_frame
	var slack: float = hook.rope_length - (fighter.position + Hook.HAND).distance_to(anchor)
	if not hook.attached or (filename.ends_with("loaded") and slack > 0.02) or (filename.ends_with("slack") and slack < 0.1):
		push_error("ROPE_CAPTURE: expected tension state not reached")
		quit(1)
		return
	var center := Vector3(0, (anchor.y + fighter.position.y) * 0.5, 0)
	camera.position = center + Vector3(7, 1.3, 11)
	camera.look_at(center)
	camera.size = anchor.y - fighter.position.y + 2.2
	title.text = "%s | length %.2f m | physical slack %.3f m" % [filename, hook.rope_length, slack]
	for frame: int in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))
	if error != OK:
		push_error("ROPE_CAPTURE: image save failed")
		quit(1)
		return
	metadata.append({"name": filename, "length": hook.rope_length, "physical_slack": slack,
		"frames": frames, "fighter": str(fighter.position), "velocity": str(fighter.velocity),
		"hand": str(fighter.skeletal.hand_world("Right")), "anchor": str(anchor)})
