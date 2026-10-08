extends SceneTree
## Plan docs/Plans/2026-10-08-City-Events-Stage-1.md step 5 — tokens as the city's money (ADR-025 п. 3): CityProgress
## spends, earns, sells food at «Шавлія» for `food_price` and keeps the faces of the city events; saves stay exact.
## Subject: for every change of tokens: never below 0 and never above 10000; food costs exactly its price and needs it;
## the only stage-1 source (a robber who gives up) returns at most what that face took; a save round-trips, an old save
## loads, and a damaged save is never written over.
##   E1 spend / earn bounds;  E2 buy_food;  E3 Mira's menu in the real CityWorld: the price, «бракує», −1 token;
##   E4 a save round trip with faces;  E5 a save from before the faces;  E6 four damaged saves keep their bytes;
##   E7 refunds: at most what was taken, once, within 10000.
## Literals: food 1 token (T5 brief § 4.3), the save bound 10000 (CityProgress restore), faces ≤ 16.
## --break=price|save|refund are negative controls.
## Sentinel: CITY_ECONOMY_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_ECONOMY: ...".
const FOOD := 1
const LIMIT := 10000
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var Progress: GDScript


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_ECONOMY: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _model(path: String, disk: bool) -> Node:
	var model: Node = Progress.new()
	root.add_child(model)
	model.setup("choko", disk, path)
	return model


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _run() -> void:
	await process_frame
	Progress = load("res://scripts/npc/CityProgress.gd")
	var path: String = "user://city_economy_%d.json" % OS.get_process_id()

	# E1, E2 -------------------------------------------------------------------------------------------------------
	var model: Node = _model(path, false)
	model.save_enabled = false
	model.earn_credits(3)
	_check(model.spend_credits(5) == 3 and model.credits() == 0, "E1 spending more than there is takes what there is (0 left)")
	_check(model.spend_credits(2) == 0 and model.credits() == 0 and model.spend_credits(-4) == 0, "E1 never below 0; a negative spend does nothing")
	_check(model.earn_credits(LIMIT - 1) == LIMIT - 1 and model.earn_credits(5) == 1 and model.credits() == LIMIT and model.earn_credits(1) == 0, "E1 never above %d" % LIMIT)
	model.spend_credits(LIMIT)
	_check(not model.buy_food(FOOD) and model.credits() == 0, "E2 no tokens, no food")
	model.earn_credits(2)
	_check(model.buy_food(FOOD) and model.credits() == 2 - FOOD and not model.buy_food(-1), "E2 food costs exactly %d; a negative price is refused" % FOOD)

	# E7 ------------------------------------------------------------------------------------------------------------
	model.spend_credits(LIMIT)
	model.remember_face("alley_a", 5)
	_check(model.refund_face("alley_a") == 5 and model.credits() == 5 and model.face_lost("alley_a") == 0, "E7 a refund returns exactly what the face took")
	if mutation == "refund":
		model.heroes["choko"].faces["alley_a"] = 99   # a stale record that forgot the refund
	_check(model.refund_face("alley_a") == 0 and model.credits() == 5, "E7 a second refund returns nothing")
	model.spend_credits(LIMIT)
	model.earn_credits(LIMIT - 2)
	model.remember_face("alley_b", 5)
	_check(model.refund_face("alley_b") == 2 and model.credits() == LIMIT and model.face_lost("alley_b") == 3, "E7 a refund stays within %d and keeps the rest owed" % LIMIT)
	var faces_ok: bool = true
	for index: int in 20:
		var ok: bool = model.remember_face("face_%02d" % index, 0)
		if index < 14 and not ok:
			faces_ok = false
		if index >= 14 and ok:
			faces_ok = false
	_check(faces_ok and model.heroes["choko"].faces.size() == 16 and not model.remember_face("Bad-Id", 1), "E7 at most 16 faces; ids are safe")
	model.queue_free()

	# E4, E5 ---------------------------------------------------------------------------------------------------------
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	model = _model(path, true)
	model.earn_credits(7)
	model.spend_credits(2)
	model.remember_face("alley_c", 2)
	var again: Node = _model(path, true)
	_check(again.save_ok and again.credits() == 5 and again.face_lost("alley_c") == 2, "E4 tokens and faces survive a reload")
	model.queue_free()
	again.queue_free()
	_write(path, JSON.stringify({"version": 1, "heroes": {"choko": {"accepted": [], "completed": [], "events": {}, "credits": 4, "palette": "original", "owned": ["original", "mint"]}}}))
	var old: Node = _model(path, true)
	_check(old.save_ok and old.save_enabled and old.credits() == 4 and not old.face_known("alley_a"), "E5 a save from before the faces loads")
	old.remember_face("alley_a", 1)
	_check(FileAccess.get_file_as_string(path).contains("\"faces\""), "E5 the next save writes the faces")
	old.queue_free()

	# E6 --------------------------------------------------------------------------------------------------------------
	var base: Dictionary = {"accepted": [], "completed": [], "events": {}, "credits": 4, "palette": "original", "owned": ["original", "mint"]}
	var damaged: Array = []
	for faces: Variant in [{"alley_a": -1}, ["alley_a"], {"Bad-Id": 1}]:
		var profile: Dictionary = base.duplicate(true)
		profile["faces"] = faces
		damaged.append(JSON.stringify({"version": 1, "heroes": {"choko": profile}}))
	var rich: Dictionary = base.duplicate(true)
	rich["credits"] = LIMIT + 1
	damaged.append(JSON.stringify({"version": 1, "heroes": {"choko": rich}}))
	var printing: bool = Engine.print_error_messages
	for text: String in damaged:
		_write(path, text)
		var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
		Engine.print_error_messages = false
		var broken: Node = _model(path, true)
		Engine.print_error_messages = printing
		_check(not broken.save_ok and not broken.save_enabled, "E6 a damaged save is recognised (%s)" % text.substr(0, 60))
		if mutation == "save":
			broken.save_enabled = true
		broken.earn_credits(3)
		broken.spend_credits(1)
		broken.remember_face("alley_a", 1)
		_check(FileAccess.get_file_as_bytes(path) == before, "E6 its bytes stay for recovery")
		broken.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# E3: Mira's menu ----------------------------------------------------------------------------------------------------
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
	await _ticks(20)
	if mutation == "price":
		world.npc_director.food_price = 2
	var shop: Dictionary = CityPlaces.shops()[0]
	world.player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(40)
	var npc: Node = world.npc_director
	_check(npc.open_conversation(0), "E3 Mira can be talked to")
	var label: String = ""
	var enabled: bool = false
	for child: Node in npc.dialogue.choices_box.get_children():
		if child is Button and str(child.get_meta("full_text", child.text)).begins_with("Поїсти"):
			label = str(child.get_meta("full_text", child.text))
			enabled = not child.disabled
	_check(label == "Поїсти · %d жет. · бракує %d жет." % [FOOD, FOOD] and not enabled, "E3 with 0 tokens the food is shown with what is missing and cannot be bought (%s)" % label)
	npc.dialogue.close()
	world.progress.earn_credits(3)
	await _ticks(2)
	npc.open_conversation(0)
	var bought: bool = false
	for child: Node in npc.dialogue.choices_box.get_children():
		if child is Button and str(child.get_meta("full_text", child.text)) == "Поїсти · %d жет." % FOOD and not child.disabled:
			(child as Button).pressed.emit()
			bought = true
			break
	await _ticks(2)
	_check(bought and world.progress.credits() == 3 - FOOD and "Смачного." in npc.dialogue.body.text, "E3 Mira sells food for %d token (%d left)" % [FOOD, world.progress.credits()])
	var others: bool = false
	npc.dialogue.close()
	await _ticks(2)
	world.player.restart_at(Vector3(CityPlaces.shops()[1].worker.x, 0.0, CityPlaces.shops()[1].service.z))
	await _ticks(40)
	if npc.open_conversation(1):
		for child: Node in npc.dialogue.choices_box.get_children():
			if child is Button and str(child.get_meta("full_text", child.text)).begins_with("Поїсти"):
				others = true
		npc.dialogue.close()
	_check(not others, "E3 food is sold at «Шавлія» only")
	world.queue_free()
	await _ticks(3)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_ECONOMY_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
