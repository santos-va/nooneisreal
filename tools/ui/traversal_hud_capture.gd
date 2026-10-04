extends SceneTree
## Two deterministic production HUD views; requires native renderer, not --headless.
var output_directory := "/tmp/nir-traversal-hud"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_directory)
	root.size = Vector2i(1280, 720)
	var state: Node = root.get_node("GameState")
	state.training_mode = true
	state.p1_character = "choko"
	state.p2_character = "skea"
	state.p2_is_cpu = false
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	arena.get_node("MatchFlow").set_physics_process(false)
	arena.p1.set_physics_process(false)
	arena.p2.set_physics_process(false)
	await process_frame
	var hud: Node = arena.get_node("HUD")
	hud.get("_announce").hide()
	arena.p1.hp_changed.emit(18.0, 100.0)
	arena.p1.dodge_stamina_changed.emit(35.0, 100.0)
	arena.p1.cooldowns_changed.emit({"skill1": 3.4, "skill2": 8.1})
	arena.p1.dash_recharge_total = 8.0
	arena.p1.dash_changed.emit(2, 4.2, 5)
	arena.p2.dodge_stamina_changed.emit(5.0, 100.0)
	await _save("battle_vitals.png")
	arena.queue_free()
	await process_frame
	var city: Node = load("res://scripts/world/CityWorld.gd").new()
	root.add_child(city)
	city.set_physics_process(false)
	city.player.set_physics_process(false)
	city.onboarding.step_index = 3
	city.onboarding.changed.emit()
	var target := Vector3(-8, 6.5, 8)
	city.player.global_position = Vector3(-6, 0, 13)
	city.camera_rig.reset_view()
	var direction: Vector3 = target - (city.player.global_position + Vector3.UP * city.camera_rig.focus_height)
	city.camera_rig.aim.yaw_offset = atan2(-direction.x, -direction.z)
	city.camera_rig.aim.pitch_offset = clampf(atan2(direction.y, Vector2(direction.x, direction.z).length()) - city.camera_rig.base_pitch, -city.camera_rig.aim.pitch_limit, city.camera_rig.aim.pitch_limit)
	city.camera_rig.aim.manual_left = 30.0
	city.player.dodge_stamina_changed.emit(65.0, 100.0)
	for frame in 8:
		await physics_frame
	city.camera_rig.set_physics_process(false)
	var candidate: Dictionary = city.camera_rig.aim.capture(city.player, false, false)
	print("TRAVERSAL_HUD_CANDIDATE ", candidate)
	if candidate.target_id.is_empty():
		push_error("Native capture requires a real visible anchor candidate")
		quit(1)
		return
	await _save("city_anchor_cue.png")
	city.queue_free()
	await process_frame
	for singleton in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	await create_timer(0.1).timeout
	print("TRAVERSAL_HUD_CAPTURE_COMPLETE")
	quit()

func _save(filename: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(output_directory.path_join(filename))
	if result != OK:
		push_error("Could not save " + filename)
		quit(1)
