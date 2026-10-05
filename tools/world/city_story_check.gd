extends SceneTree
## Real story commands, physical interactions and independent per-hero persistence.
var checks: int = 0
var failures: int = 0
var Story: GDScript
var ir: Node
var city: Node3D
const TEMP := "user://story_focused_test.json"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_STORY: " + label)

func ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame

func move_to(point: Vector3) -> void:
	city.player.restart_at(point)
	await ticks(8)

func _model_checks() -> void:
	var model = Story.new()
	model.setup("choko", false, TEMP)
	check(model.stage() == "available" and not model.save_enabled, "disk=false is read and write isolated")
	check(not model.inspect("latch") and not model.open_shortcut() and not model.complete(), "cannot skip acceptance or physical story order")
	check(model.accept() and not model.accept(), "accept exactly once")
	check(not model.guide_selected(), "accept does not steal an existing explicit guide choice")
	check(not model.inspect("unknown") and model.inspect("counterweight_trace"), "only known clues, either inspection order")
	check(not model.inspect("counterweight_trace") and not model.open_shortcut(), "duplicate clue cannot replace second clue")
	check(model.inspect("latch") and model.stage() == "mechanism", "both distinct observations unlock mechanism")
	check(not model.complete() and model.open_shortcut() and not model.open_shortcut(), "physical consequence precedes return and is idempotent")
	check(model.complete() and not model.complete(), "one chapter conclusion")
	check(not model.journal_text().contains("Спершу звільню"), "completed journal has no future-tense mechanical action")
	var saved: Dictionary = model.snapshot()
	var peer = Story.new()
	peer.setup("skea", false, TEMP)
	check(peer.restore(saved) and peer.stage() == "available", "other hero does not inherit accepted facts or gate")
	peer.hero_id = "choko"
	check(peer.stage() == "completed" and peer.shortcut_open(), "exact completed hero restores actual gate flag")
	var atomic_before: Dictionary = peer.snapshot()
	for malformed: Variant in [null, [], {"version": "1", "heroes": {}}, {"version": 1, "heroes": {"other": {}}}, {"version": 1, "heroes": {}, "position": [0,0,0]}]:
		check(not peer.restore(malformed) and peer.snapshot() == atomic_before, "malformed restoration is atomic")
	for mutation: String in ["duplicate", "unknown", "skipped", "missing_accept", "number_bool", "unknown_field"]:
		var bad: Dictionary = saved.duplicate(true)
		match mutation:
			"duplicate": bad.heroes.choko.clues = ["latch", "latch"]
			"unknown": bad.heroes.choko.clues = ["latch", "fake"]
			"skipped": bad.heroes.choko.opened = false
			"missing_accept": bad.heroes.choko.accepted = false
			"number_bool": bad.heroes.choko.completed = 1
			"unknown_field": bad.heroes.choko.position = [1,2,3]
		check(not peer.restore(bad) and peer.snapshot() == atomic_before, "reject impossible save " + mutation)
	check(not Story.valid_content({"id": "clocktower_trace"}), "missing authored objectives cannot activate story")
	for wrong_id: Variant in [[], {}]:
		var wrong_content: Dictionary = model.content.duplicate(true)
		wrong_content.id = wrong_id
		check(not Story.valid_content(wrong_content), "exact-sized wrong-type content ID fails closed")
	var invalid_content: Dictionary = model.content.duplicate(true)
	invalid_content.latch = " "
	check(not Story.valid_content(invalid_content), "blank clue content rejected")
	invalid_content = model.content.duplicate(true)
	invalid_content.script = "res://fake.gd"
	check(not Story.valid_content(invalid_content), "content has no executable extension")
	var disk = Story.new()
	var corrupt := "{broken-story-save"
	FileAccess.open(TEMP, FileAccess.WRITE).store_string(corrupt)
	disk.setup("choko", true, TEMP)
	check(not disk.save_enabled and not disk.save_ok, "corrupt source disables overwrite")
	disk.accept()
	disk.inspect("latch")
	disk.inspect("counterweight_trace")
	disk.open_shortcut()
	disk.complete()
	check(FileAccess.get_file_as_string(TEMP) == corrupt, "entire in-memory episode preserves corrupt source bytes")
	DirAccess.remove_absolute(TEMP)
	disk.setup("choko", true, TEMP)
	disk.accept()
	disk.inspect("latch")
	disk.select_guide(true)
	var resume = Story.new()
	resume.setup("choko", true, TEMP)
	check(resume.stage() == "investigating" and resume.has_clue("latch") and resume.guide_selected(), "partial stage and explicit guide resume")
	resume.setup("skea", true, TEMP)
	resume.accept()
	resume.inspect("counterweight_trace")
	disk.setup("choko", true, TEMP)
	check(disk.has_clue("latch") and not disk.has_clue("counterweight_trace"), "saving second hero preserves first hero's distinct facts")
	DirAccess.remove_absolute(TEMP)
	for node: Node in [model, peer, disk, resume]:
		node.free()

func _run() -> void:
	await process_frame
	Story = load("res://scripts/world/CityStory.gd")
	ir = root.get_node("InputRouter")
	_model_checks()
	var gs := root.get_node("GameState")
	gs.skeletal_rig = false
	gs.p1_character = "choko"
	city = load("res://scenes/world/CityWorld.tscn").instantiate()
	city.story_save_enabled = true
	city.story_save_path = TEMP + ".world"
	if FileAccess.file_exists(city.story_save_path):
		DirAccess.remove_absolute(city.story_save_path)
	city.journey_save_enabled = false
	root.add_child(city)
	current_scene = city
	city.npc_director.save_enabled = false
	city.progress.save_enabled = false
	await ticks(10)
	var story = city.story
	var director = city.npc_director
	var progress = city.progress
	progress.heroes.clear()
	progress._ensure_hero()
	city.hud._refresh_progress()
	check(city.hud._story_leads() and city.story_target().id == "story_lada", "new player immediately sees Lada objective")
	progress.accept_quest("roof_walk")
	city.hud._track_quest("roof_walk")
	check(not city.hud._story_leads() and progress.tracked_quest_id() == "roof_walk", "manual legacy quest retains guide")
	city.hud._track_quest("")
	check(not city.hud._story_leads() and progress.tracking_mode() == "off", "explicit guide off preserved")
	await move_to(CityPlaces.worker_positions().workshop + Vector3(1.05,0,0))
	director._refresh_actors()
	check(director.open_conversation(2), "actual near Lada dialogue opens")
	director._choose("story:accept")
	check(story.stage() == "available", "accept callback needs the actual offer page")
	director._choose("story:offer")
	var foreign := Node.new()
	root.add_child(foreign)
	ir.acquire_ui(foreign)
	director._choose("story:accept")
	check(story.stage() == "available", "nested foreign UI owner prevents story acceptance")
	ir.release_ui(foreign)
	director._choose("story:accept")
	check(story.stage() == "investigating" and not city.hud._story_leads(), "explicit acceptance works without resurrecting saved guide off")
	director.dialogue.close()
	city.hud._track_story()
	check(city.hud._story_leads() and story.guide_selected(), "journal explicitly selects story guidance")
	var points: Dictionary = city.district.maintenance.story_points()
	var latch: Vector3 = points.clue_a.global_position
	await move_to(Vector3(latch.x-0.75,4,latch.z))
	check(city.can_inspect_story("latch"), "actual exterior latch reachable at hand height")
	ir.acquire_ui(foreign)
	check(not city.interact_story("latch") and not story.has_clue("latch"), "menu blocks physical clue")
	ir.release_ui(foreign)
	# A real additional wall must occlude the same reachable marker.
	var wall := StaticBody3D.new()
	wall.position = (city.player.global_position + Vector3.UP*1.1 + latch)*0.5
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1,1.0,1.0)
	shape.shape = box
	wall.add_child(shape)
	city.add_child(wall)
	await ticks(2)
	check(not city.interact_story("latch"), "real mask1 obstruction prevents inspection through wall")
	wall.free()
	await ticks(2)
	check(city.interact_story("latch") and story.has_clue("latch"), "physical latch awards one observed fact")
	check(not city.interact_story("counterweight_trace"), "inspection modal consumes the input edge")
	city.story_dialogue.close()
	check(not city.interact_story("counterweight_trace"), "other side of closed court is not remotely inspectable")
	check(not story.open_shortcut(), "one clue cannot unlock shortcut")
	var trace: Vector3 = points.clue_b.global_position
	await move_to(Vector3(trace.x+0.75,4,trace.z))
	check(city.interact_story("counterweight_trace") and story.stage() == "mechanism", "physical inner guide completes distinct observations")
	city.story_dialogue.close()
	var lever: Vector3 = points.mechanism.global_position
	await move_to(Vector3(lever.x+0.75,4,lever.z))
	check(city.interact_story("mechanism") and story.stage() == "return", "real inner lever unlocks after both clues")
	check(city.district.maintenance.story_shortcut_open(), "story state moves physical gate")
	city.story_dialogue.close()
	city.restart_exploration()
	await ticks(4)
	check(story.stage() == "return" and city.district.maintenance.story_shortcut_open(), "restart walk keeps story consequence")
	await move_to(CityPlaces.worker_positions().workshop + Vector3(1.05,0,0))
	director._refresh_actors()
	check(director.open_conversation(2), "return to actual Lada")
	director._choose("story:complete")
	check(story.stage() == "completed", "Lada closes chapter only after open consequence")
	var bond: Dictionary = director.population.relationship(2,"choko")
	check("story_clocktower_trace" in bond.topics, "completion creates once-only hero memory")
	var before: Dictionary = bond.duplicate(true)
	director._sync_story_memory()
	check(before == director.population.relationship(2,"choko"), "reloading completion cannot duplicate bond reward")
	check(progress.quest_status("roof_walk") == "active" and int(progress.summary().credits) == 0, "story does not complete errands or award their credits")
	director.dialogue.close()
	var actual_story = director.story
	for mode: String in ["corrupt", "write_failure", "disabled"]:
		var unsafe = Story.new()
		var path: String = TEMP + ".corrupt" if mode == "corrupt" else "user://absent_story_directory/nested/story.json"
		if mode == "corrupt":
			FileAccess.open(path, FileAccess.WRITE).store_string("{damaged")
		unsafe.setup("skea", mode != "disabled", path)
		unsafe.accept()
		unsafe.inspect("latch")
		unsafe.inspect("counterweight_trace")
		unsafe.open_shortcut()
		unsafe.complete()
		check(unsafe.stage() == "completed" and (not unsafe.save_enabled or not unsafe.save_ok), mode + " permits only in-memory completion")
		director.story = unsafe
		var prior: Dictionary = director.population.relationship(2,"skea").duplicate(true)
		director._sync_story_memory()
		check(prior == director.population.relationship(2,"skea"), mode + " cannot persist a future NPC fact")
		if mode == "corrupt":
			check(FileAccess.get_file_as_string(path) == "{damaged", "NPC repair preserves corrupt story bytes too")
			DirAccess.remove_absolute(path)
		unsafe.free()
	director.story = actual_story
	DirAccess.remove_absolute(city.story_save_path)
	foreign.free()
	city.queue_free()
	await ticks(3)
	for singleton: String in ["Sfx","UltMusic","Music"]:
		root.get_node(singleton).queue_free()
	await process_frame
	var until: int = Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_STORY_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
