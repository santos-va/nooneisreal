extends SceneTree
## Separate durable chapters, real light/copy boundaries and one player-selected guide.
var checks: int = 0
var failures: int = 0
var city: Node3D
var ir: Node
const OLD := "user://lower_check_previous.json"
const NEW := "user://lower_check_successor.json"

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_LOWER_STORY: " + label)

func ticks(count: int = 3) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame

func move_to(point: Vector3) -> void:
	city.player.restart_at(point)
	await ticks(8)

func previous_complete(model: CityStory) -> void:
	model.accept()
	model.inspect("latch")
	model.inspect("counterweight_trace")
	model.open_shortcut()
	model.select_guide(true)
	model.complete()

func _model_checks() -> void:
	for path: String in [OLD, NEW]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var prior := CityStory.new()
	prior.setup("choko", false, OLD)
	previous_complete(prior)
	var lower := CityLowerStory.new()
	lower.setup("choko", prior, true, NEW)
	check(lower.stage() == "locked" and not lower.accept(), "in-memory prior completion cannot admit successor")
	prior.setup("choko", true, OLD)
	check(lower.stage() == "locked", "missing prior file is not a completion")
	previous_complete(prior)
	var original: String = FileAccess.get_file_as_string(OLD)
	check(prior.save_enabled and prior.save_ok and prior.guide_selected(), "durable predecessor with historical tracking selection")
	check(lower.stage() == "available" and not lower.copy_mark() and not lower.toggle_lamp(), "durable admission still requires explicit acceptance")
	check(lower.accept() and not lower.accept(), "accept successor exactly once")
	check(not lower.copy_mark() and lower.toggle_lamp() and lower.stage() == "copy", "lighting comes before copying")
	var resumed := CityLowerStory.new()
	resumed.setup("choko", prior, true, NEW)
	check(resumed.stage() == "copy" and resumed.lamp_aligned(), "lamp detent persists independently")
	check(resumed.copy_mark() and not resumed.copy_mark() and resumed.toggle_lamp(), "historical copy is distinct from present lighting")
	resumed.setup("choko", prior, true, NEW)
	check(resumed.stage() == "return" and resumed.has_copy() and not resumed.lamp_aligned(), "copied plus away roundtrip remains valid")
	check(resumed.complete() and not resumed.complete(), "return closes chapter once")
	resumed.select_guide(true)
	var saved: Dictionary = resumed.snapshot()
	var raw: String = FileAccess.get_file_as_string(NEW)
	check(FileAccess.get_file_as_string(OLD) == original, "successor commands never rewrite completed predecessor bytes")
	for mode: String in ["missing", "corrupt", "disabled", "wrong_hero", "incomplete", "failed"]:
		var other := CityStory.new()
		var path: String = OLD + "." + mode
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		if mode == "corrupt":
			FileAccess.open(path, FileAccess.WRITE).store_string("{bad")
		other.setup("skea" if mode == "wrong_hero" else "choko", mode != "disabled", path)
		if mode in ["wrong_hero", "disabled"]:
			previous_complete(other)
		if mode == "failed":
			other.restore(prior.snapshot())
			other.save_ok = false
		lower.setup("choko", other, true, NEW)
		check(lower.stage() == "locked" and not lower.lamp_aligned() and not lower.record_delivered() and not lower.has_copy(), mode + " suspends effective successor facts")
		check(not lower.journal_text().contains(lower.text("copied_fact")) and lower.current_hint() == lower.text("prior_unavailable"), mode + " explains orphan without future facts")
		check(not lower.accept() and not lower.toggle_lamp() and not lower.complete(), mode + " blocks commands")
		lower.select_guide(false)
		other.changed.emit()
		check(FileAccess.get_file_as_string(NEW) == raw, mode + " preserves orphan bytes even on prerequisite notification")
		other.free()
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	lower.setup("choko", prior, true, NEW)
	check(lower.snapshot() == saved and lower.stage() == "completed", "repair restores exact historical successor snapshot")
	lower.setup("skea", prior, true, NEW)
	check(lower.stage() == "locked", "different hero cannot borrow predecessor completion")
	lower.setup("choko", prior, false, NEW)
	var before: Dictionary = lower.snapshot()
	for bad: Variant in [null, [], {"version": "1", "heroes": {}}, {"version": 1, "heroes": {"alien": {}}}]:
		check(not lower.restore(bad) and lower.snapshot() == before, "malformed snapshot rejects atomically")
	for field: String in ["accepted", "copied", "lamp_aligned", "extra"]:
		var bad: Dictionary = saved.duplicate(true)
		if field == "accepted" or field == "copied":
			bad.heroes.choko[field] = false
		else:
			bad.heroes.choko[field] = []
		check(not lower.restore(bad) and lower.snapshot() == before, "inconsistent or untyped facts rejected " + field)
	for bad_id: Variant in [null, [], {}, 3]:
		var bad_content: Dictionary = lower.content.duplicate(true)
		bad_content.id = bad_id
		check(not CityLowerStory.valid_content(bad_content), "wrong typed content id fails closed")
	check(not CityLowerStory.valid_content({"id":"lower_mark"}), "incomplete content cannot activate")
	FileAccess.open(NEW, FileAccess.WRITE).store_string("{damaged")
	lower.setup("choko", prior, true, NEW)
	lower.accept()
	lower.toggle_lamp()
	lower.copy_mark()
	lower.complete()
	check(lower.stage() == "completed" and not lower.save_enabled and not lower.save_ok and FileAccess.get_file_as_string(NEW) == "{damaged", "corrupt successor permits session only and preserves source")
	for node: Node in [prior, lower, resumed]:
		node.free()
	DirAccess.remove_absolute(NEW)

func _run() -> void:
	await process_frame
	ir = root.get_node("InputRouter")
	_model_checks()
	var gs := root.get_node("GameState")
	gs.skeletal_rig = false
	gs.p1_character = "choko"
	city = load("res://scenes/world/CityWorld.tscn").instantiate()
	city.story_save_path = OLD
	city.lower_story_save_path = NEW
	city.journey_save_enabled = false
	root.add_child(city)
	current_scene = city
	city.npc_director.save_enabled = false
	city.progress.save_enabled = false
	await ticks(10)
	var lower: CityLowerStory = city.lower_story
	var director = city.npc_director
	var gallery: CityLowerGallery = city.district.lower_gallery
	var original: String = FileAccess.get_file_as_string(OLD)
	city.progress.heroes.clear()
	city.progress._ensure_hero()
	city.hud._refresh_progress()
	check(city.active_episode() == lower and city.hud._story_leads() and city.story_target().id == "lower_lada", "one automatic objective becomes next chapter at Lada")
	city.progress.accept_quest("roof_walk")
	city.hud._track_quest("roof_walk")
	check(not city.hud._story_leads(), "manual errand beats new episode")
	city.hud._track_quest("")
	await move_to(CityPlaces.worker_positions().workshop + Vector3(1.05,0,0))
	director._refresh_actors()
	check(director.open_conversation(2), "actual Lada opens successor conversation")
	director._choose("lower:accept")
	check(lower.stage() == "available", "stale accept without offer rejected")
	director._choose("lower:offer")
	director._choose("lower:hint")
	director._choose("lower:accept")
	check(lower.stage() == "available", "leaving offer invalidates stale accept")
	director._choose("lower:offer")
	var foreign := Node.new()
	root.add_child(foreign)
	ir.acquire_ui(foreign)
	director._choose("lower:accept")
	check(lower.stage() == "available", "foreign UI owner blocks successor command")
	ir.release_ui(foreign)
	director._choose("lower:accept")
	check(lower.stage() == "lighting" and not city.hud._story_leads(), "accept retains explicit guide off")
	director.dialogue.close()
	city.hud._track_story()
	check(city.hud._story_leads() and city.progress.tracking_mode() == "auto", "explicit lower tracking returns persisted choice to automatic")
	# An orphan selection cannot resurrect over a newer global manual/off choice.
	for selected: String in ["", "roof_walk"]:
		city.story.save_ok = false
		city.story.changed.emit()
		var orphan: String = FileAccess.get_file_as_string(NEW)
		city.hud._track_quest(selected)
		var progress_snapshot: Dictionary = city.progress.snapshot()
		check(FileAccess.get_file_as_string(NEW) == orphan, "changing guide preserves suspended raw successor")
		city.story.save_ok = true
		city.story.changed.emit()
		lower.setup("choko", city.story, true, NEW)
		city.progress.restore(progress_snapshot)
		city.hud._refresh_progress()
		check(not city.hud._story_leads(), "restored orphan cannot override persisted manual/off choice")
		city.hud._track_story()
		check(city.hud._story_leads(), "explicit story selection resumes after manual/off")
	var points: Dictionary = gallery.lower_points()
	await move_to(points.plate.global_position + Vector3(-0.75,-1.25,0))
	check(city.interact_story("lower_plate") and not lower.has_copy(), "unlit physical plate cannot grant copy")
	city.story_dialogue.close()
	await move_to(points.lamp.global_position + Vector3(0,-1.15,-0.8))
	check(city.interact_story("lower_lamp") and lower.lamp_aligned() and gallery.lamp_aligned(), "actual near lamp interaction rotates detent and light")
	city.story_dialogue.close()
	await move_to(points.plate.global_position + Vector3(-0.75,-1.25,0))
	var light: SpotLight3D = gallery._spot
	var basis: Basis = light.basis
	light.rotate_y(PI)
	check(city.interact_story("lower_plate") and not lower.has_copy(), "actual wrong light orientation blocks copy despite aligned detent")
	city.story_dialogue.close()
	light.basis = basis
	var wall := StaticBody3D.new()
	wall.position = Vector3(-12.4,5.45,-14.2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.15,1,1)
	shape.shape = box
	wall.add_child(shape)
	city.add_child(wall)
	await ticks(2)
	check(city.interact_story("lower_plate") and not lower.has_copy(), "real obstruction of lamp beam prevents copy")
	city.story_dialogue.close()
	wall.free()
	await ticks(2)
	check(city.interact_story("lower_plate") and lower.has_copy() and lower.stage() == "return", "lit actual plate awards one historical copy")
	check(not city.interact_story("lower_lamp"), "inspection modal blocks second physical interaction")
	city.story_dialogue.close()
	await move_to(points.lamp.global_position + Vector3(0,-1.15,-0.8))
	check(city.interact_story("lower_lamp") and lower.has_copy() and not lower.lamp_aligned(), "turning lamp away retains acquired copy")
	city.story_dialogue.close()
	check(not gallery._record.visible, "workshop copy absent before actual return")
	await move_to(CityPlaces.worker_positions().workshop + Vector3(1.05,0,0))
	director._refresh_actors()
	check(director.open_conversation(2), "physical return to Lada")
	director._choose("lower:complete")
	check(lower.stage() == "completed" and gallery._record.visible, "Lada completion displays actual workshop copy")
	var bond: Dictionary = director.population.relationship(2,"choko").duplicate(true)
	check("story_lower_mark" in bond.topics, "durable completion creates story memory")
	director._sync_lower_memory()
	check(director.population.relationship(2,"choko") == bond, "memory is duplicate safe")
	check(FileAccess.get_file_as_string(OLD) == original and city.story.guide_selected(), "whole new chapter and tracking preserve old file and selected flag")
	director.dialogue.close()
	city.story.save_ok = false
	city.story.changed.emit()
	check(not gallery._record.visible and not gallery.lamp_aligned() and not city.hud._story_leads(), "failed predecessor suspends physical consequences immediately")
	director.open_conversation(2)
	director._choose("memory")
	check(director.dialogue.body.text.contains("Збережені спогади") and director.dialogue.body.text.contains(lower.text("prior_unavailable")), "historical NPC memory is labelled while successor suspended")
	director.dialogue.close()
	city.story.save_ok = true
	city.story.changed.emit()
	for mode: String in ["corrupt", "failed", "disabled"]:
		var unsafe := CityLowerStory.new()
		var path: String = NEW + ".bad" if mode == "corrupt" else "user://absent_lower_dir/save.json"
		if mode == "corrupt":
			FileAccess.open(path, FileAccess.WRITE).store_string("{bad")
		unsafe.setup("choko", city.story, mode != "disabled", path)
		unsafe.accept()
		unsafe.toggle_lamp()
		unsafe.copy_mark()
		unsafe.complete()
		director.lower_story = unsafe
		check(unsafe.stage() == "completed" and (not unsafe.save_enabled or not unsafe.save_ok), mode + " only completes in memory")
		# Remove the existing test topic before invoking the negative repair.
		var relationship: Dictionary = director.population.relationship(2,"choko")
		relationship.topics.erase("story_lower_mark")
		var old_bond: Dictionary = relationship.duplicate(true)
		director._sync_lower_memory()
		check(director.population.relationship(2,"choko") == old_bond, mode + " cannot create durable NPC fact")
		unsafe.free()
	director.lower_story = lower
	foreign.free()
	city.queue_free()
	await ticks()
	for singleton: String in ["Sfx","UltMusic","Music"]:
		root.get_node(singleton).queue_free()
	await process_frame
	var until: int = Time.get_ticks_msec()+350
	while Time.get_ticks_msec()<until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_LOWER_STORY_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
