extends SceneTree
## Run with --rendering-method gl_compatibility. Pixel proof, not a headless substitute.
var failures: int = 0
var checks: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_CAMERA_RENDERER: " + label)
func shot() -> Image:
	for frame: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func difference(a: Image, b: Image) -> float:
	var total: float = 0.0
	for y: int in range(0, a.get_height(), 2):
		for x: int in range(0, a.get_width(), 2):
			total += absf(a.get_pixel(x,y).get_luminance() - b.get_pixel(x,y).get_luminance())
	return total / float(a.get_width() * a.get_height() / 4)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("CITY_CAMERA_RENDERER requires native pixels")
		quit(2)
		return
	root.size = Vector2i(480,360)
	await process_frame
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.15
	world.add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(2.8,2.5,4.0)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-35,0)
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 20.0
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10,10)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.55
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.6,0.6,0.6)
	floor_mesh.material_override = floor_material
	world.add_child(floor_mesh)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/toon.gdshader")
	material.set_shader_parameter("albedo", Color(1,0,0))
	mesh.material_override = material
	world.add_child(mesh)
	var solid := await shot()
	mesh.transparency = 1.0
	var native_transparency := await shot()
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		check(difference(solid,native_transparency) < 0.0001, "GeometryInstance transparency is ignored in Compatibility; fallback is necessary")
	mesh.transparency = 0.0
	material.set_shader_parameter("camera_visibility",0.0)
	var hidden_with_shadow := await shot()
	check(difference(solid,hidden_with_shadow) > 0.003, "local opaque discard visibly removes the near body")
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var hidden_without_shadow := await shot()
	var shadow_delta: float = difference(hidden_with_shadow,hidden_without_shadow)
	check(shadow_delta > 0.0002, "near-body policy preserves a measurable world shadow")
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	material.set_shader_parameter("camera_visibility",1.0)
	var restored := await shot()
	check(difference(solid,restored) < 0.0001, "default visibility restores exact native pixels")
	print("CITY_CAMERA_RENDERER_TRACE renderer=", RenderingServer.get_current_rendering_method(), " hide_delta=",difference(solid,hidden_with_shadow)," shadow_delta=",shadow_delta)
	print("CITY_CAMERA_RENDERER_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
