extends SceneTree
## Native real-city cue before input and gameplay result after input.
var folder: String = "/workspace/nir-rope-contact-capture"
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			folder = argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1280,720)
	await process_frame
	var state: Node = root.get_node("GameState")
	state.p1_character = "skea"
	state.skeletal_rig = true
	var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	city.player.set_physics_process(false)
	var rows: Array[Dictionary] = []
	for distance: float in [3.0, 0.69]:
		city.player.grapple.registry.clear_match()
		city.player.restart_at(Vector3(0,0,distance))
		city.player.set_physics_process(false)
		city.camera_rig.reset_view()
		var registry: Node = city.player.grapple.registry
		var token: int = registry.issue(1)
		registry.deploy(token, 1, Vector3(0,8,0), Vector3.ZERO, 8.0)
		for frame: int in 36:
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		var name: String = "far" if distance > 1.0 else "near"
		root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
		var intent: Dictionary = city.camera_rig.aim.capture(city.player, false, false)
		if intent.get("candidate_kind", "") != "rope":
			push_error("ROPE_CONTACT_CAPTURE fixture must visibly target the deployed rope")
			quit(1)
			return
		var stock: int = city.player.grapple.charges
		city.player.grapple.fire(false, "grapple_parkour", intent)
		rows.append({"case": name, "physical_hand_distance": distance, "cue": city.hud._aim_cue.text,
			"candidate": intent.get("candidate_kind", ""), "reachable": intent.get("reachable", false),
			"phase_after_press": city.player.grapple.phase, "attached": city.player.grapple.attached,
			"stock_before": stock, "stock_after": city.player.grapple.charges})
	var output := FileAccess.open(folder.path_join("results.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(rows,"\t"))
	print("ROPE_CONTACT_CAPTURE_COMPLETE cases=2 folder=",folder)
	quit()
