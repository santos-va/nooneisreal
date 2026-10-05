extends SceneTree
const Appearance = preload("res://scripts/npc/NpcAppearance.gd")
var output := OS.get_environment("NPC_CAPTURE_DIR")
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	if output.is_empty(): output = "/tmp/npc-appearance"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 800)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("303340")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c6d1de")
	env.ambient_light_energy = 0.45
	environment.environment = env
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	light.light_energy = 0.65
	stage.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("535763")
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	var residents: Array[Node3D] = []
	for i in 12:
		var resident := Appearance.build({"appearance_seed": i+40})
		stage.add_child(resident)
		resident.position = Vector3((i % 6 - 2.5) * 1.65, 0, (i / 6) * 3.0)
		resident.set_motion(0.0, 0.0)
		residents.append(resident)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.fov = 38.0
	camera.position = Vector3(0, 5.4, -11)
	camera.look_at(Vector3(0, 0.9, 1.5))
	await shot("lineup_front")
	camera.position = Vector3(9, 5, 9)
	camera.look_at(Vector3(0, 1, 1.5))
	await shot("lineup_back")
	for i in 3:
		for j in 12: residents[j].visible = j == i
		var at := residents[i].position
		camera.fov = 43.0
		camera.position = at + Vector3(1.9, 1.8, -3.1)
		camera.look_at(at + Vector3(0, 1.15, 0))
		residents[i].set_work(["grocer", "tailor", "workshop"][i], 0.4)
		await shot("worker_%d" % i)
		if residents[i].has_method("presentation_event"):
			residents[i].presentation_event("greet")
			residents[i].set_motion(0, 0.35)
			await shot("greet_%d" % i)
			if i == 0:
				for event in ["greet", "listen", "talk", "agree", "goodbye"]:
					residents[i].set_motion(0,0)
					residents[i].presentation_event(event)
					for moment in [.35, .8, 1.6]:
						residents[i].set_motion(0,moment)
						residents[i].set_work("grocer",moment)
						await shot("gesture_%s_%03d" % [event,int(moment*100)])
	print("NPC_APPEARANCE_CAPTURE_COMPLETE")
	quit()
func shot(label: String) -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
