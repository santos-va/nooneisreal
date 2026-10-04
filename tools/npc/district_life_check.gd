extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("DISTRICT_LIFE: " + label)
func ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame
		await process_frame
func capture(path: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(path) == OK, "native screenshot " + path)
func _run() -> void:
	await process_frame
	root.size = Vector2i(1280, 960)
	root.get_node("GameState").skeletal_rig = true
	var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	var director = city.npc_director
	var progress: CityProgress = city.progress
	director.save_enabled = false
	progress.save_enabled = false
	progress.heroes.clear()
	progress.hero_id = "choko"
	progress._ensure_hero()
	director.population.initialize(123456)
	director.active_radius = 80.0
	director._refresh_actors()
	await ticks(8)
	check(director.actors.size() == 12, "bounded population includes stores and streets")
	for shop: Dictionary in CityPlaces.shops():
		var index: int = shop.npc_index
		var worker: CityNpcActor = director.actors[index]
		check(worker.global_position.distance_to(shop.worker) < 0.01 and worker.work_kind == shop.id, "worker belongs to actual interior " + str(shop.id))
		var visual: NpcAppearance = worker.visual
		var before: float = visual._arms[0].rotation.x
		await ticks(20)
		check(absf(visual._arms[0].rotation.x - before) > 0.01, "visible work gesture " + str(shop.id))
		city.player.global_position = shop.visit
		await ticks(2)
		check(director.find_nearest() == index, "worker reachable across counter " + str(shop.id))
		director.open_conversation(index)
		check(director.dialogue.opened and root.get_node("InputRouter").ui_suppressed(), "choice dialogue owns focus " + str(shop.id))
		director._choose("topic:work")
		check(director.population.relationship(index, "choko").trust == 2, "dialogue changes only selected hero bond")
		if index == 0:
			director._choose("offer:introductions")
			check(director.dialogue.body.text.contains("трьома"), "quest briefing includes actual objective")
			director._choose("accept:introductions")
			await capture("/tmp/district-grocer-dialogue.png")
		director.dialogue.close()
	check(progress.quest_status("introductions") == "ready", "meeting actual workers advances quest")
	director.open_conversation(0)
	director._choose("turn:introductions")
	check(progress.summary().credits == 3, "NPC turn-in grants explicit reward")
	director._choose("accept:parcel")
	director.dialogue.close()
	director.open_conversation(1)
	director._choose("parcel")
	check(progress.quest_status("parcel") == "ready", "tailor receives actual accepted parcel")
	var material: Material = city.player.skeletal.hero_mesh.material_override
	var original_albedo: Variant = material.get_shader_parameter("albedo")
	director._choose("styles")
	await capture("/tmp/district-tailor-choices.png")
	director._choose("palette:mint")
	director.dialogue.close()
	await ticks(5)
	check(city.cosmetics.visible and city.cosmetics.cloth.albedo_color == progress.current_palette(), "chosen cloth visible on actual hero")
	check(material.get_shader_parameter("albedo") == original_albedo, "skin eyes and original outfit material untouched")
	city.player.global_position = CityLayout.spawn_position()
	city.camera_rig.reset_view()
	await ticks(10)
	await capture("/tmp/district-player-style.png")
	# Gate facts through the same modal choices used by the player.
	progress.accept_quest("roof_walk")
	for place: Dictionary in CityPlaces.landmarks():
		if place.id in ["roof_bridge", "clock_tower"]:
			city.player.global_position = place.position
			await ticks(2)
	check(progress.quest_status("roof_walk") == "ready", "physical roof visits feed progress")
	director.open_conversation(2)
	director._choose("turn:roof_walk")
	director.dialogue.close()
	progress.accept_quest("neighbours")
	for index: int in range(3, 7):
		director.open_conversation(index)
		director.dialogue.close()
	director.open_conversation(1)
	director._choose("turn:neighbours")
	director.dialogue.close()
	director.open_conversation(3)
	for action: String in ["topic:work", "topic:district", "topic:route", "topic:neighbours"]:
		director._choose(action)
	check(director.population.relationship(3, "choko").trust >= 6, "normal neighbour can become friend through actual choice routes")
	check(director.population.relationship(3, "skea").trust == 0, "other hero has no borrowed friendship")
	director.dialogue.close()
	city.queue_free()
	await ticks(90)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	await ticks(3)
	print("[district-life] %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
