extends SceneTree
## Production district guidance at two physical window sizes, with real target resolution.
var output_directory := "/tmp/nir-continuity-ui/evidence"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_directory)
	root.size = Vector2i(1280, 720)
	var city: Node = load("res://scripts/world/CityWorld.gd").new()
	root.add_child(city)
	city.progress.save_enabled = false
	city.npc_director.save_enabled = false
	city.journey.save_enabled = false
	city.progress.accept_quest("introductions")
	city.progress.accept_quest("roof_walk")
	city.progress.track_quest("introductions")
	for frame in 8:
		await physics_frame
	city.set_physics_process(false)
	city.player.set_physics_process(false)
	city.camera_rig.set_physics_process(false)
	var camera: Camera3D = root.get_camera_3d()
	var target: Dictionary = CityQuestTargets.resolve(city.progress, city.npc_director, city.player.global_position)
	camera.look_at(target.position)
	city.hud._refresh_quest_guide()
	await _save("quest_front_720.png")
	camera.look_at(camera.global_position - (target.position - camera.global_position))
	city.hud._refresh_quest_guide()
	await _save("quest_behind_720.png")
	city.progress.track_quest("roof_walk")
	target = CityQuestTargets.resolve(city.progress, city.npc_director, city.player.global_position)
	camera.look_at(target.position)
	city.hud._refresh_quest_guide()
	await _save("quest_roof_720.png")
	city.hud.set_paused(true)
	city.hud.quest_buttons["roof_walk"].grab_focus()
	await _save("quest_journal_720.png")
	root.size = Vector2i(960, 540)
	await _save("quest_journal_540.png")
	city.hud.set_paused(false)
	city.hud._refresh_quest_guide()
	await _save("quest_roof_540.png")
	city.queue_free()
	await process_frame
	for singleton in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	await create_timer(0.2).timeout
	print("QUEST_JOURNAL_CAPTURE_COMPLETE views=6")
	quit()

func _save(filename: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output_directory.path_join(filename)) != OK:
		push_error("Could not save " + filename)
		quit(1)
