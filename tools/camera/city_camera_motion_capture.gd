extends SceneTree
## Actual CityFighter input, collision, camera approach and retreat at fixed 60 Hz.
var folder: String = "/tmp/nir-city-camera-motion"
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(960,540)
	await process_frame
	var state: Node = root.get_node("GameState")
	state.p1_character = "skea"
	state.skeletal_rig = true
	var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	city.hud.hide()
	city.player.restart_at(Vector3(-24.05,0,16.7))
	city.camera_rig.reset_view()
	var input: Node = root.get_node("InputRouter")
	input.v_clear(1)
	for settle: int in 48:
		await physics_frame
		await process_frame
	var rows: Array[String] = ["frame,z,speed,arm,lift,visibility"]
	for frame: int in 96:
		await physics_frame
		input.v_set(1,"down",frame >= 12 and frame < 36)
		input.v_set(1,"up",frame >= 48 and frame < 72)
		await process_frame
		await RenderingServer.frame_post_draw
		var rig = city.camera_rig
		rows.append("%d,%.5f,%.5f,%.5f,%.5f,%.5f" % [frame,city.player.position.z,city.player.velocity.length(),rig.arm.get_hit_length(),rig.arm.position.y,rig.proximity.visibility])
		if frame % 2 == 0:
			root.get_texture().get_image().save_png(folder.path_join("frame_%04d.png" % (frame / 2)))
	input.v_clear(1)
	var file := FileAccess.open(folder.path_join("trace.csv"),FileAccess.WRITE)
	file.store_string("\n".join(rows))
	print("CITY_CAMERA_MOTION_COMPLETE frames=48 folder=",folder)
	quit()
