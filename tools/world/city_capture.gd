extends SceneTree
## Actual geometry audit renders. Pass -- --output=/absolute/directory.
const Layout = preload("res://scripts/world/CityLayout.gd")
var output_directory: String = "/tmp/nooneisreal-city-geometry"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_directory)
	root.size = Vector2i(1280, 960)
	var district: Node3D = (load("res://scenes/world/CityDistrict.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(district)
	var triangles: int = 0
	var meshes: Array[Node] = district.find_children("*", "MeshInstance3D", true, false)
	var visual_bounds: AABB = AABB()
	var first_mesh: bool = true
	for node: Node in meshes:
		var instance: MeshInstance3D = node as MeshInstance3D
		triangles += int(instance.mesh.get_faces().size() / 3)
		var mesh_bounds: AABB = instance.global_transform * instance.mesh.get_aabb()
		visual_bounds = mesh_bounds if first_mesh else visual_bounds.merge(mesh_bounds)
		first_mesh = false
	var metadata: Dictionary = {
		"status": "functional prototype; Function/Form/Runtime acceptance pending",
		"units": "metres; dimensions are PLACEHOLDER design",
		"geometry_source": "res://scenes/world/CityDistrict.tscn",
		"composition": ["CityLayout traversal solids", "CityArchitecture batched facade/roof/tower + structural colliders", "CityMarket batched stalls + prop colliders"],
		"layout_blocks_are_complete_composition": false,
		"bounds": Layout.district_bounds(), "spawn": Layout.spawn_position(),
		"bounds_meaning": "declared traversal envelope; decorative skyline may exceed its height",
		"rendered_geometry_bounds": visual_bounds,
		"routes": Layout.route_points(), "combat_pockets": Layout.combat_pockets(),
		"blocks": Layout.blocks(), "ramps": Layout.ramps(), "anchors": Layout.anchors(),
		"mesh_count": meshes.size(), "triangle_count": triangles,
		"passage": {"center": Vector3(20, 0, 14), "width": 4.0, "height": 4.5, "depth": 4.0},
		"collision_layers": {"ground": 1, "solids_and_rope_cover": 9},
		"new_assets": 0, "target_device_acceptance": false}
	var metadata_file: FileAccess = FileAccess.open(output_directory.path_join("plan-metadata.json"), FileAccess.WRITE)
	if metadata_file == null:
		push_error("CITY_CAPTURE could not write plan metadata")
		quit(1)
		return
	metadata_file.store_string(JSON.stringify(_json_value(metadata), "\t") + "\n")
	metadata_file.close()
	# Geometry views use the production lighting builder, with no independent tuning.
	var lighting_root: Node3D = Node3D.new()
	root.add_child(lighting_root)
	var lighting_template: Node3D = load("res://scripts/world/CityWorld.gd").new() as Node3D
	lighting_template._build_lighting()
	for child: Node in lighting_template.get_children():
		lighting_template.remove_child(child)
		lighting_root.add_child(child)
	lighting_template.free()
	var camera: Camera3D = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.far = 300
	var views: Array[Dictionary] = [
		{"id": "corner_sw", "eye": Vector3(-53, 38, 53), "target": Vector3(0, 2, 0)},
		{"id": "corner_se", "eye": Vector3(53, 38, 53), "target": Vector3(0, 2, 0)},
		{"id": "corner_nw", "eye": Vector3(-53, 38, -53), "target": Vector3(0, 2, 0)},
		{"id": "corner_ne", "eye": Vector3(53, 38, -53), "target": Vector3(0, 2, 0)},
		{"id": "street_entry", "eye": Vector3(0, 2, 26), "target": Vector3(0, 3, -20)},
		{"id": "market_close", "eye": Vector3(1.5, 2.0, 23), "target": Vector3(-8.5, 1.5, 25)},
		{"id": "canopy_underneath", "eye": Vector3(-7.8, 1.5, 24.3), "target": Vector3(-8.5, 2.7, 25)},
		{"id": "facade_close", "eye": Vector3(3, 4, 19), "target": Vector3(-10, 7, 20)},
		{"id": "roof_clocktower", "eye": Vector3(-11, 7, -15), "target": Vector3(-24, 16, -25)},
		{"id": "passage", "eye": Vector3(20, 1.7, 25), "target": Vector3(20, 2.0, 8)},
		{"id": "center_up", "eye": Vector3(0, 1.7, -16), "target": Vector3(0, 8, -20)},
		{"id": "elevation_south", "eye": Vector3(0, 12, 85), "target": Vector3(0, 12, 0), "ortho": 72.0},
		{"id": "elevation_east", "eye": Vector3(85, 12, 0), "target": Vector3(0, 12, 0), "ortho": 72.0},
		{"id": "overhead", "eye": Vector3(0, 90, 0), "target": Vector3.ZERO, "ortho": 72.0},
	]
	for view: Dictionary in views:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL if view.has("ortho") else Camera3D.PROJECTION_PERSPECTIVE
		camera.size = float(view.get("ortho", 72.0))
		camera.position = view.eye
		camera.look_at(view.target, Vector3.FORWARD if view.id == "overhead" else Vector3.UP)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var error: Error = root.get_texture().get_image().save_png(output_directory.path_join(String(view.id) + ".png"))
		if error != OK:
			push_error("CITY_CAPTURE could not save " + String(view.id))
			quit(1)
			return
	# The monochrome plan is generated from the same mesh/collider scene.
	for node: Node in district.find_children("*", "MeshInstance3D", true, false):
		var parent_name: String = String(node.get_parent().name)
		var tone: float = 0.5
		if parent_name == "Ground":
			tone = 0.88
		elif parent_name.contains("Boundary") or parent_name.contains("Parapet") or parent_name.contains("Anchor"):
			tone = 0.16
		elif parent_name.contains("Ramp"):
			tone = 0.68
		elif parent_name.contains("Tower") or parent_name.contains("Clock"):
			tone = 0.28
		elif parent_name.contains("Bridge"):
			tone = 0.38
		var gray: StandardMaterial3D = StandardMaterial3D.new()
		gray.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gray.albedo_color = Color(tone, tone, tone)
		(node as MeshInstance3D).material_override = gray
	await process_frame
	await RenderingServer.frame_post_draw
	var gray_error: Error = root.get_texture().get_image().save_png(output_directory.path_join("overhead_monochrome.png"))
	district.queue_free()
	lighting_root.queue_free()
	camera.queue_free()
	await process_frame
	# No substitute camera or lighting: this frame uses the playable CityWorld itself.
	var world: Node3D = (load("res://scenes/world/CityWorld.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame: int in 30:
		await physics_frame
	await RenderingServer.frame_post_draw
	var production_error: Error = root.get_texture().get_image().save_png(output_directory.path_join("production_player_camera.png"))
	world.player.restart_at(Vector3(20, 4, -20))
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = PI * 0.5 # Look along the actual upper route toward the bridge.
	for frame: int in 30:
		await physics_frame
	await RenderingServer.frame_post_draw
	var upper_error: Error = root.get_texture().get_image().save_png(output_directory.path_join("production_upper_route.png"))
	world.hud.set_paused(true)
	await process_frame
	await RenderingServer.frame_post_draw
	var pause_error: Error = root.get_texture().get_image().save_png(output_directory.path_join("production_pause.png"))
	world.hud.set_paused(false)
	var failed: int = int(gray_error != OK) + int(production_error != OK) + int(upper_error != OK) + int(pause_error != OK)
	world.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_CAPTURE_COMPLETE images=%d failures=%d output=%s" % [views.size() + 4, failed, output_directory])
	quit(0 if failed == 0 else 1)

func _json_value(value: Variant) -> Variant:
	if value is Vector3:
		var vector: Vector3 = value
		return [vector.x, vector.y, vector.z]
	if value is AABB:
		var bounds: AABB = value
		return {"position": _json_value(bounds.position), "size": _json_value(bounds.size)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[key] = _json_value(value[key])
		return result
	if value is Array:
		var result: Array = []
		for element: Variant in value:
			result.append(_json_value(element))
		return result
	return value
