extends SceneTree
## Native pixel evidence. Optional old shader is loaded only into fixture materials.
var output_directory: String = "/tmp/nooneisreal-quality"
var baseline_shader_path: String = ""
var images: int = 0
var failures: int = 0
var receipt: Dictionary = {"views": [], "target_device_performance": false}

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
		elif argument.begins_with("--baseline-shader="):
			baseline_shader_path = argument.trim_prefix("--baseline-shader=")
	_run.call_deferred()

func shot(name: String) -> void:
	for frame: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.is_empty() or image.save_png(output_directory.path_join(name + ".png")) != OK:
		failures += 1
		return
	images += 1
	receipt.views.append({"id": name, "output_pixels": [image.get_width(), image.get_height()],
		"applied_3d_scale": root.scaling_3d_scale, "applied_msaa_enum": root.msaa_3d,
		"configured_3d_pixel_fraction": root.scaling_3d_scale * root.scaling_3d_scale,
		"visible_objects": root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
		"visible_draw_calls": root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"visible_primitives": root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)})

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("QUALITY_CAPTURE requires native rendering")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_directory)
	root.size = Vector2i(1280, 960)
	receipt.renderer = RenderingServer.get_current_rendering_method()
	receipt.device = RenderingServer.get_video_adapter_name()
	receipt.engine = Engine.get_version_info()
	var settings: Node = root.get_node("GraphicsSettings")
	var initial_profile: String = settings.get_profile()
	var candidate: Shader = load("res://shaders/city_surface.gdshader")
	var baseline: Shader
	if not baseline_shader_path.is_empty():
		baseline = Shader.new()
		baseline.code = FileAccess.get_file_as_string(baseline_shader_path)
		if baseline.code.is_empty():
			push_error("QUALITY_CAPTURE missing baseline shader")
			quit(2)
			return
	var district: Node3D = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(district)
	var lighting_template: Node3D = load("res://scripts/world/CityWorld.gd").new()
	lighting_template._build_lighting()
	var lighting := Node3D.new()
	root.add_child(lighting)
	for child: Node in lighting_template.get_children():
		lighting_template.remove_child(child)
		lighting.add_child(child)
	lighting_template.free()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.far = 300.0
	var views: Array[Dictionary] = [
		{"id": "street_entry", "eye": Vector3(0, 2, 26), "target": Vector3(0, 3, -20)},
		{"id": "facade_close", "eye": Vector3(3, 4, 19), "target": Vector3(-10, 7, 20)},
		{"id": "market_close", "eye": Vector3(1.5, 2, 23), "target": Vector3(-8.5, 1.5, 25)},
		{"id": "canopy_underneath", "eye": Vector3(-7.8, 1.5, 24.3), "target": Vector3(-8.5, 2.7, 25)}]
	var materials: Array[ShaderMaterial] = []
	for node: Node in district.find_children("*", "GeometryInstance3D", true, false):
		var material: Material = node.get("material_override")
		if material is ShaderMaterial and material.shader == candidate and not materials.has(material):
			materials.append(material)
	for profile: String in QualityProfile.ids():
		settings.set_profile(profile)
		for view: Dictionary in views:
			camera.position = view.eye
			camera.look_at(view.target)
			await shot(profile + "_" + view.id)
	settings.set_profile("high")
	if baseline != null:
		for material: ShaderMaterial in materials:
			material.shader = baseline
		for view: Dictionary in views:
			camera.position = view.eye
			camera.look_at(view.target)
			await shot("baseline_" + view.id)
		for material: ShaderMaterial in materials:
			material.shader = candidate
	district.queue_free()
	await process_frame
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(100, 100)
	plane.mesh = mesh
	root.add_child(plane)
	var palette: Dictionary = CityMaterials.palette()
	var probes: Array[Dictionary] = [
		{"id": "cloth_near", "material": "cloth_cream", "eye": Vector3(0, 0.20, 0.16)},
		{"id": "cloth_grazing", "material": "cloth_cream", "eye": Vector3(0.25, 0.10, 1.4)},
		{"id": "wood_near", "material": "wood", "eye": Vector3(0, 0.60, 0.40)},
		{"id": "wood_grazing", "material": "wood", "eye": Vector3(1.5, 0.24, 8)}]
	for probe: Dictionary in probes:
		var material: ShaderMaterial = palette[probe.material]
		plane.material_override = material
		camera.position = probe.eye
		camera.look_at(Vector3.ZERO)
		await shot("high_" + probe.id)
		if baseline != null:
			material.shader = baseline
			await shot("baseline_" + probe.id)
			material.shader = candidate
	# Tiny actual camera pan, keeping shader animation and geometry fixed.
	plane.material_override = palette.cloth_cream
	for frame: int in 8:
		camera.position = Vector3(0.25 + frame * 0.0008, 0.10, 1.4)
		camera.look_at(Vector3(frame * 0.0008, 0, 0))
		await shot("cloth_pan_%02d" % frame)
		if baseline != null:
			(palette.cloth_cream as ShaderMaterial).shader = baseline
			await shot("baseline_cloth_pan_%02d" % frame)
			(palette.cloth_cream as ShaderMaterial).shader = candidate
	plane.queue_free()
	lighting.queue_free()
	camera.queue_free()
	await process_frame
	var world: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	for frame: int in 30:
		await physics_frame
	# Pause simulation so profile comparisons share the exact actor and camera pose.
	world.process_mode = Node.PROCESS_MODE_DISABLED
	for profile: String in ["high", "low"]:
		settings.set_profile(profile)
		await shot(profile + "_production_player_camera")
	world.process_mode = Node.PROCESS_MODE_INHERIT
	world.player.restart_at(Vector3(20, 4, -20))
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = PI * 0.5
	for frame: int in 30:
		await physics_frame
	world.process_mode = Node.PROCESS_MODE_DISABLED
	for profile: String in ["high", "low"]:
		settings.set_profile(profile)
		await shot(profile + "_production_upper_route")
	world.queue_free()
	await process_frame
	settings.set_profile(initial_profile)
	var file := FileAccess.open(output_directory.path_join("receipt.json"), FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(receipt, "\t") + "\n")
		file.close()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	for frame: int in 10:
		await process_frame
	print("QUALITY_CAPTURE_COMPLETE images=%d failures=%d" % [images, failures])
	quit(1 if failures else 0)
