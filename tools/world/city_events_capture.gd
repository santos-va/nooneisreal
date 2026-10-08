extends SceneTree
## Frames of the city events, stage 1 (plan docs/Plans/2026-10-08-City-Events-Stage-1.md, steps 2–4) from the playable
## CityWorld with its own camera, light and HUD — no substitute camera. Needs a renderer (xvfb + gl_compatibility):
##   alley_trap.png   — the southeast passage: the knife, the second one in the north mouth, the trap's choices;
##   alley_view.png   — the same moment without the dialogue (the frame the camera holds in the passage);
##   alley_mouth.png  — the ordinary follow camera at that moment: the second one in the north mouth;
##   leaves.png       — the passer-by with five leaves over his head beside the hero at the market court;
##   haze_off.png / haze_on.png — the same pose without and with the static vignette (plateau).
## Pass -- --output=/absolute/directory. Prints CITY_EVENTS_CAPTURE_COMPLETE frames=N on success.
var output_directory: String = "/tmp/nooneisreal-city-events"
var frames: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	_run.call_deferred()


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _until_phase(event: Node, phase: String) -> void:
	for tick: int in 300:
		if not is_instance_valid(event) or event.phase == phase:
			return
		await _ticks(1)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output_directory.path_join(name + ".png")
	if image != null and image.save_png(path) == OK:
		frames += 1
		print("CITY_EVENTS_CAPTURE frame=%s size=%dx%d" % [path, image.get_width(), image.get_height()])
	else:
		push_error("CITY_EVENTS_CAPTURE could not save " + path)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_directory)
	await process_frame
	var state: Node = root.get_node("GameState")
	state.p1_character = "choko"
	state.set_free_move(true)
	root.get_node("InputRouter").apply_profile("solo", false)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	var events: Node = world.events
	await _ticks(30)
	world.progress.earn_credits(8)
	events.enable_for_test(97531)
	events.start_chance = 0.0
	events.session_time = 1000.0

	# The alley trap.
	world.player.restart_at(Vector3(16.0, 0.0, 6.0))
	await _ticks(30)
	if events.try_start("alley"):
		var event: Node = events.active
		event.asker.global_position = world.player.global_position + Vector3(1.3, 0.0, 0.0)
		event._path.clear()
		event.asker.stop()
		await _ticks(10)
		event.open_ask()
		await _ticks(2)
		event.choose("follow")
		event.asker.global_position = event.STAND
		event._path.clear()
		event.asker.stop()
		world.player.restart_at(Vector3(20.0, 0.0, 20.5))
		for tick: int in 240:
			await _ticks(1)
			if event.phase == "trap" and is_instance_valid(event.blocker) and not event.blocker.walking() and event._blocker_path.is_empty():
				break
		await _ticks(30)
		await _shot("alley_trap")
		events.dialogue.panel.hide()
		await _ticks(2)
		await _shot("alley_view")
		# The ordinary follow camera (yaw 0 looks north from behind the hero): the second one in the north mouth.
		world.camera_rig.end_conversation()
		world.camera_rig.reset_view()
		await _ticks(20)
		await _shot("alley_mouth")
		events.dialogue.panel.show()
		events.abort_active("capture")
		await _ticks(3)

	# The five leaves.
	events.session_time = 2000.0
	events.last_end_time = -INF
	world.player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(40)
	world.camera_rig.reset_view()
	if events.try_start("leaves"):
		var leaves: Node = events.active
		leaves.person.global_position = world.player.global_position + Vector3(0.7, 0.0, -2.0)
		leaves.person.stop()
		leaves.person.face(world.player.global_position)
		await _until_phase(leaves, "offer")
		await _ticks(10)
		await _shot("leaves")
		events.abort_active("capture")
		await _ticks(3)

	# The vignette: the same pose without and with the state.
	world.player.restart_at(Vector3(0.0, 0.0, 26.0))
	await _ticks(40)
	world.camera_rig.reset_view()
	await _ticks(30)
	await _shot("haze_off")
	world.haze.begin()
	await _ticks(int(4.0 * 60.0))
	await _shot("haze_on")
	world.haze.clear()

	world.queue_free()
	await _ticks(3)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_EVENTS_CAPTURE_COMPLETE frames=%d" % frames)
	quit(0 if frames == 6 else 1)
