extends SceneTree
## Native evidence from the production menu and district; isolated user data required.
var output_directory := "/tmp/nir-district-ui/evidence"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_directory)
	root.size = Vector2i(1280, 720)
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await _save("district_menu.png")
	menu.queue_free()
	await process_frame
	var city: Node = load("res://scripts/world/CityWorld.gd").new()
	root.add_child(city)
	for frame in 12:
		await physics_frame
	await _save("district_hud.png")
	city.hud.set_paused(true)
	await _save("district_pause.png")
	city.hud.set_paused(false)
	city.queue_free()
	await process_frame
	for singleton in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	await create_timer(0.2).timeout
	print("DISTRICT_UI_CAPTURE_COMPLETE")
	quit()

func _save(filename: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output_directory.path_join(filename)) != OK:
		push_error("Could not save " + filename)
		quit(1)
