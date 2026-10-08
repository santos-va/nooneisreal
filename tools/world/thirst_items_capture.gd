extends SceneTree
## Frames of plan docs/Plans/2026-10-08-Thirst-Substances-Icons.md steps 1–3 for T8 and T6, from the playable CityWorld
## with its own camera, light and HUD. Needs a renderer (xvfb + gl_compatibility), as city_events_capture.gd:
##   card_plain.png   — the status card at FOOD 100 % / WATER 100 % (the WATER row under FOOD);
##   card_states.png  — FOOD 45 % HUNGRY, WATER 22 % PARCHED, HEALTH, the effects line STRENGTH · VITAMINS, TIPSY last;
##   counter.png      — Mira's counter with item icons 32 px left of the text (rows without a cell: the stand-in);
##   vendor.png       — the street pedlar's offer: beer and cigarette with their icons;
##   comfort.png      — COMFORT & CONTROLS with the new DRUGS, ALCOHOL & TOBACCO row;
##   pump.png         — the hero at the water pump on the edge of the market court, its prompt on the bottom line.
## Pass -- --output=/absolute/directory. Prints THIRST_ITEMS_CAPTURE_COMPLETE frames=N on success.
var output_directory: String = "/tmp/nooneisreal-thirst-items"
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


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output_directory.path_join(name + ".png")
	if image != null and image.save_png(path) == OK:
		frames += 1
		print("THIRST_ITEMS_CAPTURE frame=%s size=%dx%d" % [path, image.get_width(), image.get_height()])
	else:
		push_error("THIRST_ITEMS_CAPTURE could not save " + path)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_directory)
	await process_frame
	var state: Node = root.get_node("GameState")
	var content: Node = root.get_node("ContentSettings")
	var old_content: String = content.get("storage_path")
	content.call("load_settings", "user://thirst_items_capture_%d.cfg" % OS.get_process_id())
	content.call("set_drugs_mode", "full")
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
	world.onboarding.skip()
	await _ticks(30)
	world.progress.earn_credits(6)

	# The card: plain, then with every row.
	world.player.restart_at(Vector3(0.0, 0.0, 26.0))
	await _ticks(40)
	world.camera_rig.reset_view()
	world.hunger.enable_for_test(10000)
	world.thirst.enable_for_test(10000)
	world.hud._body_queue.clear()
	world.hud.bind_hunger(world.hunger)
	await _ticks(20)
	await _shot("card_plain")
	world.hunger.enable_for_test(3000)
	world.hunger.feed("eggs")
	world.hunger.feed("pickled_apples")
	world.hunger.set_centi(4500)
	world.thirst.enable_for_test(2200)
	world.hunger.city_hp = 800.0
	world.player.set_round_hp(800.0)
	world.substances.begin("tipsy")
	world.hud._body_queue.clear()
	world.hud.bind_hunger(world.hunger)
	await _ticks(20)
	await _shot("card_states")
	world.substances.clear()

	# Mira's counter.
	var shop: Dictionary = CityPlaces.shops()[0]
	world.player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(30)
	world.hunger.enable_for_test(4000)
	world.thirst.enable_for_test(6000)
	world.npc_director.open_conversation(0)
	await _ticks(10)
	for child: Node in world.npc_director.dialogue.choices_box.get_children():
		if child is Button and str(child.get_meta("full_text", "")).begins_with("Поїсти"):
			child.pressed.emit()
	await _ticks(20)
	await _shot("counter")
	world.npc_director.dialogue.close()
	await _ticks(5)

	# The pedlar.
	world.player.restart_at(Vector3(0.0, 0.0, 20.0))
	world.hunger.enable_for_test(8000)
	world.thirst.enable_for_test(8000)
	await _ticks(30)
	world.camera_rig.reset_view()
	var events: Node = world.events
	events.enable_for_test(13579)
	events.start_chance = 0.0
	events.session_time = 1000.0
	events.last_end_time = -INF
	if events.try_start("vendor"):
		var pedlar: Node = events.active
		pedlar.person.global_position = world.player.global_position + Vector3(0.7, 0.0, -1.6)
		pedlar.person.stop()
		pedlar.person.face(world.player.global_position)
		for tick: int in 120:
			if pedlar.phase == "offer":
				break
			await _ticks(1)
		pedlar.open_offer()
		await _ticks(20)
		await _shot("vendor")
		events.abort_active("capture")
		await _ticks(3)

	# COMFORT with the new DRUGS row.
	world.hud.set_paused(true)
	await _ticks(2)
	world.hud.comfort_button.pressed.emit()
	await _ticks(10)
	world.hud.comfort.drugs_choice.grab_focus()
	await _ticks(10)
	await _shot("comfort")
	world.hud.set_paused(false)
	await _ticks(5)

	# The pump.
	world.player.restart_at(Vector3(-0.4, 0.0, 19.6))
	await _ticks(10)
	world.player._set_forward(Vector3(-0.7, 0.0, -0.7).normalized())
	world.camera_rig.reset_view()
	await _ticks(10)
	world.player.restart_at(Vector3(-1.25, 0.0, 17.8))
	world.player._set_forward(Vector3.LEFT)
	await _ticks(40)
	await _shot("pump")

	world.queue_free()
	await _ticks(3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(content.get("storage_path")))
	content.call("load_settings", old_content)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("THIRST_ITEMS_CAPTURE_COMPLETE frames=%d" % frames)
	quit(0 if frames == 6 else 1)
