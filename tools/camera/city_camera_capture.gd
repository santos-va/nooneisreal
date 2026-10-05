extends SceneTree
var city: Node3D
var rows: Array[Dictionary] = []
var selected: Array[int] = [5, 16, 36, 56, 66]
var folder: String = "/tmp/nir-city-camera-capture"
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960, 540)
	await process_frame
	root.get_node("GameState").p1_character = "skea"
	root.get_node("GameState").skeletal_rig = true
	city = load("res://scenes/world/CityWorld.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	city.player.set_physics_process(false)
	city.hud.hide()
	var positions: Array[Vector3] = []
	for x: float in [-26.6, -20.0, -13.4]:
		for z: float in [10.0, 11.8, 12.5, 15.4, 18.8]:
			positions.append(Vector3(x, 0, z))
	positions.append_array([Vector3(0,4,-20), Vector3(-24,4,-19), Vector3(-18,4,-11)])
	var n: int = 0
	for pos: Vector3 in positions:
		for yaw: float in [0.0, PI * 0.5, PI, PI * 1.5]:
			if DisplayServer.get_name() != "headless" and n not in selected:
				n += 1
				continue
			city.player.position = pos
			city.camera_rig.reset_view()
			city.camera_rig.aim.yaw_offset = yaw
			for tick: int in 36:
				await physics_frame
				await process_frame
			var rig = city.camera_rig
			var camera: Camera3D = rig.camera
			var ray := PhysicsRayQueryParameters3D.create(camera.global_position, pos + Vector3.UP * 1.25, 1)
			ray.exclude = [city.player.get_rid()]
			ray.hit_from_inside = true
			var hit: Dictionary = city.get_world_3d().direct_space_state.intersect_ray(ray)
			var shape := PhysicsShapeQueryParameters3D.new()
			var sphere := SphereShape3D.new()
			sphere.radius = 0.05
			shape.shape = sphere
			shape.transform.origin = camera.global_position
			shape.collision_mask = 1
			shape.exclude = [city.player.get_rid()]
			var overlap: Array[Dictionary] = city.get_world_3d().direct_space_state.intersect_shape(shape)
			var row: Dictionary = {"n":n,"player":str(pos),"yaw":yaw,"camera":str(camera.global_position),"arm":rig.arm.get_hit_length(),"lift":rig.arm.position.y,"body_visibility":rig.proximity.visibility,"occluded":not hit.is_empty(),"overlap":overlap.size(),"blocker":str(hit.collider.get_path()) if not hit.is_empty() else ""}
			rows.append(row)
			if not hit.is_empty() or overlap.size()>0 or DisplayServer.get_name() != "headless":
				print(JSON.stringify(row))
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(folder.path_join("case%03d.png" % n))
			n += 1
	var file := FileAccess.open(folder.path_join("native-results.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"  "))
	print("CITY_CAMERA_CAPTURE_COMPLETE cases=", rows.size())
	quit()
