extends SceneTree
## Render actual room geometry and production lighting. Not a target-device performance test.
var output: String = "/tmp/nir-city-interiors"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("CITY_INTERIORS_CAPTURE requires a native renderer")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 900)
	var district: Node3D = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(district)
	var lighting: Node3D = load("res://scripts/world/CityWorld.gd").new()
	lighting._build_lighting()
	for child: Node in lighting.get_children():
		lighting.remove_child(child)
		root.add_child(child)
	lighting.free()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.fov = 74
	var views: Array[Dictionary] = [
		{"id": "shop_fronts", "eye": Vector3(-20, 4.2, 0.5), "target": Vector3(-20, 2.3, 15)},
		{"id": "shop_street", "eye": Vector3(-6, 3.5, 5.5), "target": Vector3(-22, 1.8, 13)},
	]
	for shop: Dictionary in CityPlaces.shops():
		views.append({"id": String(shop.id) + "_inside", "eye": shop.door + Vector3(0.15, 2.05, 1.15), "target": shop.door + Vector3(0, 1.55, 6.1)})
	for view: Dictionary in views:
		camera.position = view.eye
		camera.look_at(view.target)
		for frame: int in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var captured: Image = root.get_texture().get_image()
		if captured.is_empty() or captured.save_jpg(output.path_join(String(view.id) + ".jpg"), 0.90) != OK:
			push_error("CITY_INTERIORS_CAPTURE failed " + String(view.id))
			quit(1)
			return
	print("CITY_INTERIORS_CAPTURE_COMPLETE views=%d" % views.size())
	quit(0)
