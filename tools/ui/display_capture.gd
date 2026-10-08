extends SceneTree
## Native frames for the DISPLAY / AUTO step (docs/Plans/2026-10-07-Auto-Display-And-Quality.md, steps 4 and 6):
## the menu, the COMFORT panel with the DISPLAY row and the AUTO line, the city in AUTO and High, a close lens where
## the Bayer raster thins the hero, and a duel arena with its painted backdrop. Evidence only: no assertion beyond "every frame was written".
##   xvfb-run -a -s '-screen 0 3840x2160x24 -nolisten tcp' godot --path game --rendering-method gl_compatibility \
##     --audio-driver Dummy --fixed-fps 60 --script "$PWD/tools/ui/display_capture.gd" -- --out=DIR
## Without a window manager X11 does not resize a fullscreen window (2026-10-07-Auto-Display-And-Quality-Fix),
## so the root viewport takes the screen size itself: the frame is what a fullscreen player renders.
var out: String = "/tmp/nir-display-capture"
var failures: int = 0
var receipt: Dictionary = {"views": [], "target_device_performance": false}
var graphics: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out = argument.trim_prefix("--out=")
	_run.call_deferred()


func shot(name: String) -> void:
	for frame: int in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.is_empty() or image.save_png(out.path_join(name + ".png")) != OK:
		failures += 1
		push_error("DISPLAY_CAPTURE: could not write " + name)
		return
	receipt.views.append({"id": name, "output_pixels": [image.get_width(), image.get_height()],
		"profile": graphics.get_profile(), "scaling_3d_scale": root.scaling_3d_scale, "msaa_3d": root.msaa_3d,
		"scaling_3d_mode": root.scaling_3d_mode, "anisotropy": root.anisotropic_filtering_level,
		"auto_line": graphics.auto_summary() if graphics.get_profile() == "auto" else ""})
	print("DISPLAY_CAPTURE ", name, " ", image.get_width(), "x", image.get_height(), " profile=", graphics.get_profile(), " scale=", root.scaling_3d_scale)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("DISPLAY_CAPTURE requires native rendering")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	var screen: Vector2i = DisplayServer.screen_get_size()
	root.size = screen
	await process_frame
	graphics = root.get_node("GraphicsSettings")
	var old_path: String = graphics.storage_path
	graphics.load_settings("user://display_capture_%d.cfg" % OS.get_process_id())   # nothing saved → AUTO, FULLSCREEN
	receipt.renderer = RenderingServer.get_current_rendering_method()
	receipt.adapter = RenderingServer.get_video_adapter_name()
	receipt.engine = Engine.get_version_info()
	receipt.screen = [screen.x, screen.y]
	receipt.auto = {"start_scale": graphics.auto.scale, "ceiling": graphics.auto.ceiling, "msaa": graphics.auto.msaa,
		"blood_tier": graphics.auto.blood_tier, "detected_upscaler": graphics.detect_upscaler()}
	var menu: Control = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await shot("menu_auto")
	var launcher: Button = menu.get("_comfort_button")
	launcher.grab_focus()
	launcher.pressed.emit()
	await shot("menu_panel_auto")
	(menu.get("_comfort") as Control).call("close_panel")
	menu.queue_free()
	await process_frame
	var world: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.set("story_save_enabled", false)
	world.set("journey_save_enabled", false)
	world.set("lower_story_save_enabled", false)
	root.add_child(world)
	current_scene = world
	for frame: int in 60:
		await physics_frame
	# Pause the simulation so AUTO and High share the exact pose.
	world.process_mode = Node.PROCESS_MODE_DISABLED
	for profile: String in ["auto", "high"]:
		graphics.set_profile(profile)
		await shot("city_" + profile)
	# Close lens: the production proximity policy thins the fill with its Bayer raster, the ink line stays.
	var rig: Node = world.get("camera_rig")
	var player: Node3D = world.get("player")
	var camera: Camera3D = rig.get("camera")
	camera.global_position = player.global_position + Vector3(0.0, 1.45, 0.0) + player.global_basis.z * 0.6 + player.global_basis.x * 0.15
	camera.look_at(player.global_position + Vector3(0.0, 1.2, 0.0))
	var proximity: Variant = rig.get("proximity")
	for i: int in 4:
		proximity.call("update", camera, 1.0)
	receipt.close_lens_fill = proximity.get("fill_visibility")
	for profile: String in ["auto", "high"]:
		graphics.set_profile(profile)
		await shot("city_close_" + profile)
	world.queue_free()
	await process_frame
	# A duel arena: the painted backdrop card is the largest 3D texture on screen (with --fixed-fps 60 the pose repeats).
	root.get_node("GameState").call("set_stage", "bazaar")
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	for frame: int in 90:
		await physics_frame
	arena.process_mode = Node.PROCESS_MODE_DISABLED
	for profile: String in ["auto", "high"]:
		graphics.set_profile(profile)
		await shot("arena_" + profile)
	arena.queue_free()
	await process_frame
	graphics.load_settings(old_path)
	var file := FileAccess.open(out.path_join("receipt.json"), FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(receipt, "  "))
		file.close()
	print("DISPLAY_CAPTURE_COMPLETE images=%d failures=%d" % [receipt.views.size(), failures])
	quit(1 if failures else 0)
