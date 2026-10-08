extends SceneTree
## Native before/after frames for plan docs/Plans/2026-10-07-Living-Body.md (steps 1–2): the real CityDistrict, the real
## Fighter / CityFighter and SkeletalRig, the production renderer. It runs unchanged on a tree without the living body
## and the new parkour moves (the base), so the same stimulus gives the «before» frames there and the «after» frames here.
##   flinch_side  — a light blow from the victim's left side (R1: Hit_Shoulder_L instead of the zone clip);
##   flinch_front — a heavy blow from the front (R1: the clip fills the hitstun);
##   getup        — a ragdoll, its settle and GETUP into the stance (R7);
##   jump         — a standing jump: take-off, apex, fall, light landing (J1–J3);
##   land_normal  — a 3.5 m drop onto the street (J3 normal: deeper squash, a hand down, dust);
##   land_heavy   — a 12 m drop onto the street (J3 heavy / P8: NinjaJump_Land, knee and hand down, dust);
## One case tick is one physics tick; every second one is saved.
##   vault        — a run and jump at a 1 m × 0.35 m wall (P1; a capture prop: the district has no such obstacle);
##   side_run     — a run and jump along the west boundary wall, the longest clean face in the district (P4);
##   shimmy       — a hang on the shipped practice ledge, then right along it (P5).
## --out=<dir> (default /tmp/nir-living-body), --case=<name> to run one case, --hero=<id> to run one hero.
## Sentinel LIVING_CAPTURE_COMPLETE images=N ticks=M failures=K.
const CASES := ["flinch_side", "flinch_front", "getup", "jump", "land_normal", "land_heavy", "vault", "side_run", "shimmy"]
const CITY_CASES := ["jump", "land_normal", "land_heavy", "vault", "side_run", "shimmy"]
const STREET := Vector3(0, 0, 20)
var folder: String = "/tmp/nir-living-body"
var selected: String = ""
var only_hero: String = ""
var world: Node3D
var camera: Camera3D
var title: Label
var trace: Array[Dictionary] = []
var saved: int = 0
var failures: int = 0
var F: GDScript
var router: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
		if argument.begins_with("--case="):
			selected = argument.trim_prefix("--case=")
		if argument.begins_with("--hero="):
			only_hero = argument.trim_prefix("--hero=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960, 640)
	await process_frame
	F = load("res://scripts/fighter/Fighter.gd")
	router = root.get_node("InputRouter")
	router.apply_profile("solo", false)
	var gs: Node = root.get_node("GameState")
	gs.skeletal_rig = true
	gs.set_free_move(true)
	gs.training_mode = false
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
	camera.fov = 40.0
	world.add_child(camera)
	camera.current = true
	var canvas := CanvasLayer.new()
	world.add_child(canvas)
	title = Label.new()
	title.position = Vector2(14, 12)
	title.add_theme_font_size_override("font_size", 17)
	canvas.add_child(title)
	await physics_frame
	for hero: String in ["choko", "skea"]:
		if not only_hero.is_empty() and hero != only_hero:
			continue
		for name: String in CASES:
			if selected.is_empty() or selected == name:
				await _case(hero, name)
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
	print("LIVING_CAPTURE_COMPLETE images=%d ticks=%d failures=%d" % [saved, trace.size(), failures])
	quit(0 if failures == 0 else 1)


func _fighter(id: String, at: Vector3, city: bool) -> Node:
	var f: Node = load("res://scenes/fighter/Fighter.tscn").instantiate()
	if city:
		f.set_script(load("res://scripts/world/CityFighter.gd"))
	f.data = load("res://data/characters/%s.tres" % id)
	world.add_child(f)
	f.global_position = at
	f.forward = Vector3.RIGHT
	return f


func _living(f: Node) -> String:
	var body = f.skeletal.get("living_body")
	if body == null:
		return "base"
	return "%s %s %.2f" % [body.mode if not body.mode.is_empty() else "—", body.clip, body.clip_time]


func _box(at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var prop := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	prop.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	prop.add_child(mesh)
	prop.collision_layer = 9
	world.add_child(prop)
	prop.global_position = at
	return prop


func _case(hero: String, name: String) -> void:
	var output: String = folder.path_join(hero + "_" + name)
	DirAccess.make_dir_recursive_absolute(output)
	var city: bool = name in CITY_CASES
	var start: Vector3 = STREET
	match name:
		"land_normal":
			start = STREET + Vector3(0, 3.5, 0)
		"land_heavy":
			start = STREET + Vector3(0, 12.0, 0)
		"vault":
			start = STREET + Vector3(-5.0, 0, 0)
		"side_run":
			start = Vector3(-31.4, 0, 9.0)
		"shimmy":
			start = Vector3(4, 0, 18.2)
	# Drops start on the street and are lifted at tick 4, so the warm-up never lands (and never raises dust) first.
	var spawn: Vector3 = STREET if name.begins_with("land_") else start
	var f: Node = _fighter(hero, spawn, city)
	var other: Node = null
	var prop: StaticBody3D = null
	if name.begins_with("flinch") or name == "getup":
		other = _fighter("choko" if hero == "skea" else "skea", start + Vector3(1.2, 0, 0), false)
		other.set_physics_process(false)
		f.opponent = other
		other.opponent = f
	if name == "vault":
		prop = _box(STREET + Vector3(0.0, 0.5, 0), Vector3(0.35, 1.0, 2.4), Color("8a6f52"))
	if city:
		f.restart_at(spawn)
	router.v_clear(1)
	router.set_view_basis(1, Vector3.FORWARD)
	await _ticks(20)
	# One loop pass = one physics tick (a physics step, then that frame's draw); a frame is saved every second tick.
	var length: int = 180
	for tick: int in 800:
		if tick >= length:
			break
		match name:
			"flinch_side", "flinch_front":
				if tick == 16:
					f.global_position = start
					f.forward = Vector3.RIGHT
					f.invulnerable_frames = 0
					f.hitstop_frames = 0
					other.global_position = start + (Vector3(0, 0, -1.2) if name == "flinch_side" else Vector3(1.2, 0, 0))
				if tick == 20:
					f.forward = Vector3.RIGHT
					f.receive_hit(other, other.data.light if name == "flinch_side" else other.data.heavy)
				length = 80
			"getup":
				if tick == 8:
					f._enter_ragdoll(Vector3(2.5, 3.0, 0.0))
				length = 520
				if tick > 60 and f.state == F.State.IDLE and f.frame_in_state > 50:
					length = tick
			"jump":
				if tick == 20:
					router.v_press(1, "jump")
				length = 140
			"land_normal", "land_heavy":
				if tick == 8:
					f.restart_at(start)
					f._set_state(F.State.JUMP)
					f.velocity = Vector3.ZERO
				length = 110 if name == "land_normal" else 150
			"vault":
				router.v_set(1, "right", tick >= 4 and tick < 120)
				if tick >= 4 and f.global_position.x >= STREET.x - 1.35 and f.state != F.State.JUMP and f.global_position.y < 0.2 and not f.has_meta("capture_jumped"):
					f.set_meta("capture_jumped", true)
					router.v_press(1, "jump")
				length = 120
			"side_run":
				router.v_set(1, "up", tick >= 4 and tick < 150)
				if tick == 40:
					router.v_press(1, "jump")
				router.v_set(1, "jump", tick >= 40 and tick < 150)
				length = 150
			"shimmy":
				router.v_set(1, "up", tick >= 4 and tick < 40)
				if tick == 8:
					router.v_press(1, "jump")
				router.v_set(1, "right", tick >= 60 and tick < 150)
				length = 160
		await physics_frame
		var subject: Vector3 = f.global_position
		var offset: Vector3 = Vector3(0.4, 1.3, 4.2)
		var look: Vector3 = subject + Vector3(0, 0.9, 0)
		match name:
			"flinch_side":
				offset = Vector3(3.0, 1.2, 1.2)
			"flinch_front":
				offset = Vector3(0.6, 1.2, 3.4)
				look = subject + Vector3(0.5, 0.9, 0)
			"getup":
				offset = Vector3(1.0, 1.6, 4.4)
			"land_normal", "land_heavy":
				subject = Vector3(start.x, 0.0, start.z)
				offset = Vector3(3.0, 0.9, -0.6)
				look = subject + Vector3(0, 0.55, 0)
			"vault":
				# A fixed side camera on the obstacle: the run comes in from the left and lands on the right.
				subject = STREET
				offset = Vector3(0.0, 1.3, 6.0)
				look = STREET + Vector3(0, 1.0, 0)
			"side_run":
				# The west boundary wall (face x = -32, normal +X) is on the hero's left; the camera stands in the street.
				offset = Vector3(4.4, 1.2, -1.6)
				look = subject + Vector3(0, 1.3, 0)
			"shimmy":
				offset = Vector3(-1.6, 1.0, 4.0)
				look = subject + Vector3(0, 1.4, 0)
		camera.position = subject + offset
		camera.look_at(look)
		var parkour: String = str(f.parkour_snapshot().get("phase", "")) if f.has_method("parkour_snapshot") else ""
		title.text = "%s | %s | tick %d | %s %s stun %d\nliving: %s" % [hero, name, tick, F.State.keys()[f.state], parkour, f.stun_frames, _living(f)]
		trace.append({"case": hero + "_" + name, "tick": tick, "state": F.State.keys()[f.state], "parkour": parkour, "living": _living(f),
			"stun": f.stun_frames, "hitstop": f.hitstop_frames, "position": [f.global_position.x, f.global_position.y, f.global_position.z],
			"velocity": [f.velocity.x, f.velocity.y, f.velocity.z], "authority_clip": f.skeletal.clip})
		await RenderingServer.frame_post_draw
		if tick % 2 == 0:
			if root.get_texture().get_image().save_png(output.path_join("%04d.png" % tick)) == OK:
				saved += 1
			else:
				failures += 1
	router.v_clear(1)
	if prop != null:
		prop.queue_free()
	if other != null:
		other.queue_free()
	f.queue_free()
	await _ticks(4)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame
