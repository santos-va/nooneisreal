extends SceneTree
## Plan docs/Plans/2026-10-08-City-Events-Stage-1.md step 3 — В2 «П'ять листків» (CityLeavesEvent) and the `drugs`
## content key (ContentSettings) in the real CityWorld (saves off), real interact key and the event's dialogue buttons.
## Subject: with `drugs` Off the event never starts and nothing of it stays; with Full a passer-by brings five flat
## leaves turning at a constant rate over his head; «Ні» changes nothing; «Затягнутись» starts the state and gives
## nothing; once a session; content.cfg follows BLOOD: a damaged or unknown file is never written over.
##   L1 Off: never starts (chance 1 for 3 s), try_start refuses;  L2 Full: five leaves above the head, constant turn;
##   L3 «Хто ти?»: his story, the question gone;  L4 «Ні, дякую»: progress, faces, residents' memory, state — unchanged;
##   L5 once a session;  L6 «Затягнутись»: the state starts, tokens unchanged, the gossip half gone;
##   L7 Off in the middle: the passer-by and the state are gone at once; and through the real COMFORT row from the city
##      pause (T8 06-UI-UX § «Випадки міста: COMFORT і HUD» п. 1): Off while he stands offering and the state lasts →
##      no passer-by, no leaves, no vignette, no HAZE line, the base FOV, no HAZE LIFTING;
##   L8 content.cfg: damaged and unknown files keep their bytes (session: off); a file from before the key loads as ours
##      (drugs full) and the next save adds the key and keeps the others.
## Literals: 5 leaves (Santos), once a session (T7 В2 PLACEHOLDER).
## --break=off|cfg|count|session|refuse|row are negative controls (row: a DRUGS row that never calls set_drugs_mode).
## Sentinel: CITY_LEAVES_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_LEAVES: ...".
const LEAVES := 5
const MARKET := Vector3(0.0, 0.0, 20.0)
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var router: Node
var content: Node
var world: Node
var events: Node
var progress: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_LEAVES: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _until(condition: Callable, limit: int) -> bool:
	for tick: int in limit:
		if condition.call():
			return true
		await _ticks(1)
	return condition.call()


func _tap_interact() -> void:
	var code: Key = KEY_G
	for event: InputEvent in InputMap.action_get_events(router.action_name(1, "interact")):
		if event is InputEventKey:
			code = (event as InputEventKey).physical_keycode if (event as InputEventKey).physical_keycode != KEY_NONE else (event as InputEventKey).keycode
			break
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = down
		Input.parse_input_event(key)
		Input.flush_buffered_events()
		await _ticks(1)


func _options() -> Array[String]:
	var labels: Array[String] = []
	for child: Node in events.dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			var text: String = str(child.get_meta("full_text", child.text))
			if not text.begins_with("Завершити розмову"):
				labels.append(text)
	return labels


func _press(prefix: String) -> bool:
	for child: Node in events.dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and not child.disabled and str(child.get_meta("full_text", child.text)).begins_with(prefix):
			(child as Button).pressed.emit()
			await _ticks(2)
			return true
	return false


func _clean() -> void:
	if events.active != null:
		events.abort_active("fixture")
	if events.dialogue.opened:
		events.dialogue.close()
	await _ticks(3)


func _reset_clock() -> void:
	events.session_time = 1000.0
	events.last_end_time = -INF
	events.last_alley_time = -INF


func _leaf_people() -> int:
	var count: int = 0
	for child: Node in events.get_children():
		if child is CityPasserby and not child.is_queued_for_deletion() and child.leaf_ring != null:
			count += 1
	return count


## A started leaves event with the passer-by beside the hero and his offer open through the real key.
func _offer() -> Node:
	await _clean()
	_reset_clock()
	events.leaves_count = 0   # a new session for this scenario
	if not events.try_start("leaves"):
		_check(false, "the leaves start at the market court (%s)" % events.block_reason("leaves"))
		return null
	var event: Node = events.active
	event.person.global_position = world.player.global_position + Vector3(1.4, 0.0, 0.0)
	event.person.stop()
	await _until(func() -> bool: return is_instance_valid(event) and event.phase == "offer", 60)
	await _until(func() -> bool: return events.dialogue.prompt.visible, 30)
	await _tap_interact()
	var ok: bool = is_instance_valid(event) and events.dialogue.opened and event.phase == "talk"
	_check(ok, "the real interact key opens his offer")
	return event if ok else null


## A started leaves event with the passer-by standing beside the hero, offering (the conversation not opened).
func _offer_standing() -> Node:
	await _clean()
	_reset_clock()
	events.leaves_count = 0
	if not events.try_start("leaves"):
		_check(false, "the leaves start at the market court (%s)" % events.block_reason("leaves"))
		return null
	var event: Node = events.active
	event.person.global_position = world.player.global_position + Vector3(1.4, 0.0, 0.0)
	event.person.stop()
	await _until(func() -> bool: return is_instance_valid(event) and event.phase == "offer", 60)
	return event if is_instance_valid(event) and event.phase == "offer" else null


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = down
		Input.parse_input_event(key)
		Input.flush_buffered_events()
		await process_frame
		await process_frame


func _end() -> String:
	if events.dialogue.opened:
		events.dialogue.close()
	await _until(func() -> bool: return events.active == null, 900)
	return String(events.outcomes.back()) if not events.outcomes.is_empty() else ""


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	content = root.get_node("ContentSettings")
	var state: Node = root.get_node("GameState")
	var old_path: String = content.get("storage_path")
	content.call("load_settings", "user://city_leaves_content_%d.cfg" % OS.get_process_id())
	state.p1_character = "choko"
	state.set_free_move(true)
	router.apply_profile("solo", false)
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	events = world.events
	progress = world.progress
	await _ticks(20)
	progress.earn_credits(4)
	events.enable_for_test(1357)
	if mutation == "session":
		events.leaves_per_session = 99
	if mutation == "off":
		var stub_script := GDScript.new()
		stub_script.source_code = "extends Node\nfunc drugs_allowed() -> bool:\n\treturn true\n"
		stub_script.reload()
		var stub := Node.new()
		stub.set_script(stub_script)
		root.add_child(stub)
		events.content = stub   # the negative: eligibility reads a source that ignores the key
	world.player.restart_at(MARKET)
	await _ticks(40)
	await _l1()
	await _l2_l3()
	await _l4_l5()
	await _l6()
	await _l7()
	await _clean()
	world.queue_free()
	await _ticks(3)
	_l8()
	content.call("load_settings", old_path)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_LEAVES_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


## L1: Off — never starts.
func _l1() -> void:
	content.call("set_drugs_mode", "off")
	_reset_clock()
	events.leaves_count = 0
	events.start_chance = 1.0
	await _ticks(180)
	var started: bool = "leaves" in events.started
	_check(not started and _leaf_people() == 0, "Off: with chance 1 for 3 s the leaves never start (%s)" % [events.started])
	_check(not events.try_start("leaves"), "Off: try_start refuses (%s)" % events.block_reason("leaves"))
	events.start_chance = 0.0
	await _clean()
	content.call("set_drugs_mode", "full")


## L2: five leaves over the head, a constant turn; L3: «Хто ти?».
func _l2_l3() -> void:
	var event: Node = await _offer()
	if event == null:
		return
	var person: CityPasserby = event.person
	if mutation == "count":
		person.leaf_ring.get_child(0).free()
	var leaves: int = 0
	for child: Node in person.leaf_ring.get_children():
		if child.name.begins_with("Leaf"):
			leaves += 1
	_check(leaves == LEAVES, "%d flat leaves on the ring (got %d)" % [LEAVES, leaves])
	_check(person.leaf_ring.position.y > person.head_top(), "the ring is above the head (%.2f > %.2f)" % [person.leaf_ring.position.y, person.head_top()])
	var steps: Array[float] = []
	var previous: float = person.leaf_ring.rotation.y
	for tick: int in 30:
		await _ticks(1)
		steps.append(angle_difference(previous, person.leaf_ring.rotation.y))
		previous = person.leaf_ring.rotation.y
	_check(steps.max() - steps.min() < 0.0001 and steps.min() > 0.0, "the leaves turn at a constant rate, no pulse (%.5f…%.5f rad/tick)" % [steps.min(), steps.max()])
	_check(_options() == ["Ні, дякую", "Затягнутись", "Хто ти?", "Піти"], "the four choices (%s)" % [_options()])
	await _press("Хто ти?")
	_check("давно не приходить" in events.dialogue.body.text and _options() == ["Ні, дякую", "Затягнутись", "Піти"], "«Хто ти?»: his story; the question is gone (%s)" % [_options()])
	await _press("Піти")
	var outcome: String = await _end()
	_check(outcome == "leaves:left", "«Піти» ends it (%s)" % outcome)


## L4: «Ні, дякую» changes nothing; L5: once a session.
func _l4_l5() -> void:
	var event: Node = await _offer()
	if event == null:
		return
	var before_progress: String = JSON.stringify(progress.snapshot())
	var before_people: String = JSON.stringify(world.npc_director.population.relationships)
	var before_content: String = content.call("drugs_mode")
	if mutation == "refuse":
		events.dialogue.choice_selected.connect(func(action: String) -> void:
			if action == "refuse":
				world.haze.begin(), CONNECT_ONE_SHOT)
	await _press("Ні, дякую")
	_check(events.dialogue.opened and not ("…" in events.dialogue.body.text) and "годинникової вежі" in events.dialogue.body.text, "«Ні»: a shrug and the whole gossip")
	var outcome: String = await _end()
	_check(outcome == "leaves:refused", "«Ні» outcome (%s)" % outcome)
	_check(JSON.stringify(progress.snapshot()) == before_progress and JSON.stringify(world.npc_director.population.relationships) == before_people and content.call("drugs_mode") == before_content and not world.haze.haze_active(), "«Ні»: progress, faces, residents' memory, content and state unchanged")
	_reset_clock()
	_check(events.block_reason("leaves") == "session" and not events.try_start("leaves"), "once a session: the second offer waits (%s)" % events.block_reason("leaves"))
	await _clean()


## L6: «Затягнутись».
func _l6() -> void:
	var event: Node = await _offer()
	if event == null:
		return
	var before_progress: String = JSON.stringify(progress.snapshot())
	var before_people: String = JSON.stringify(world.npc_director.population.relationships)
	var before_content: String = content.call("drugs_mode")
	await _press("Затягнутись")
	_check(world.haze.haze_active() and world.haze.haze_remaining() > 80.0, "«Затягнутись» starts the state (%.1f s)" % world.haze.haze_remaining())
	_check("…" in events.dialogue.body.text, "the gossip heard in the state is half gone")
	var outcome: String = await _end()
	_check(outcome == "leaves:smoked" and JSON.stringify(progress.snapshot()) == before_progress and JSON.stringify(world.npc_director.population.relationships) == before_people and content.call("drugs_mode") == before_content, "«Затягнутись»: no bonus — progress (tokens, faces, events), residents' memory and content unchanged (%s)" % outcome)


## L7: Off in the middle removes the event and the state. Plan 2026-10-08-Thirst-Substances-Icons step 2 (T5 М6): no
## offer starts while a state lasts, so the state begins after the passer-by is already offering.
func _l7() -> void:
	world.haze.clear()
	var event: Node = await _offer()
	if event == null:
		return
	world.haze.begin()
	_check(world.haze.haze_active(), "the state lasts (begun mid-offer)")
	content.call("set_drugs_mode", "off")
	await _ticks(2)
	_check(events.active == null and _leaf_people() == 0 and String(events.outcomes.back()) == "leaves:abort_content", "Off in the middle: the passer-by and his leaves are gone at once (%s)" % events.outcomes.back())
	_check(not world.haze.haze_active() and not world.haze_vignette.rect.visible, "Off clears the state and its vignette")
	content.call("set_drugs_mode", "full")
	# The same through the row: the city pause → COMFORT & CONTROLS → DRUGS Off, real keys, while he stands offering.
	world.haze.clear()
	var standing: Node = await _offer_standing()
	if standing == null:
		_check(false, "L7 row: the passer-by stands offering")
		return
	world.haze.begin()
	await _ticks(200)   # past the ramp-in: a narrowed FOV to be put back
	var base_fov: float = world.haze.base_fov
	_check(world.haze.haze_active() and world.camera_rig.camera.fov < base_fov - 0.5 and world.hud.haze_label.visible, "L7 row: the state lasts, the FOV narrowed (%.2f), HAZE line shown" % world.camera_rig.camera.fov)
	await _key(KEY_ESCAPE)
	var hud: Node = world.hud
	_check(hud.paused_ui, "L7 row: Esc opens the city pause")
	hud.comfort_button.pressed.emit()
	await process_frame
	var panel: Control = hud.comfort
	if mutation == "row":
		for connection: Dictionary in panel.drugs_choice.item_selected.get_connections():
			panel.drugs_choice.item_selected.disconnect(connection.callable)
	panel.drugs_choice.grab_focus()
	await _key(KEY_ENTER)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	_check(panel.visible and panel.drugs_choice.selected == 1, "L7 row: DRUGS shows Off")
	await _key(KEY_ESCAPE)   # COMFORT → the pause
	await _key(KEY_ESCAPE)   # the pause → the city
	await _ticks(3)
	_check(not hud.paused_ui and events.active == null and _leaf_people() == 0 and String(events.outcomes.back()) == "leaves:abort_content", "L7 row: Off in COMFORT removes the standing passer-by and his leaves (%s)" % events.outcomes.back())
	_check(not world.haze.haze_active() and not world.haze_vignette.rect.visible and not world.hud.haze_label.visible and is_equal_approx(world.camera_rig.camera.fov, base_fov), "L7 row: no state, no vignette, no HAZE line, FOV back to %.1f (%.2f)" % [base_fov, world.camera_rig.camera.fov])
	_check(not (world.hud.hint_label.visible and world.hud.hint_label.text.begins_with("HAZE LIFTING")), "L7 row: Off is not a fade — no HAZE LIFTING")
	_reset_clock()
	_check(not events.try_start("leaves"), "L7 row: with Off the event does not start again (%s)" % events.block_reason("leaves"))
	content.call("set_drugs_mode", "full")


## L8: content.cfg like BLOOD.
func _l8() -> void:
	var path: String = "user://city_leaves_cfg_%d.cfg" % OS.get_process_id()
	var cases: Array = [["damaged", "[broken\nnot a content config"],
		["unknown", "[content]\nblood=\"full\"\nhit_flash=\"full\"\nnotice_seen=false\ndrugs=\"maybe\"\n"]]
	for case: Array in cases:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(case[1])
		file.close()
		var before: PackedByteArray = FileAccess.get_file_as_bytes(path)
		var printing: bool = Engine.print_error_messages
		Engine.print_error_messages = false   # the engine's own parse error is the expected outcome here
		var error: int = content.call("load_settings", path)
		Engine.print_error_messages = printing
		_check(error != OK and content.call("drugs_mode") == "off" and not content.call("drugs_allowed"), "%s content.cfg: this session the event is off" % case[0])
		content.call("set_drugs_mode", "full")
		if mutation == "cfg":
			content.set("_load_error", OK)
		content.call("save_settings")
		_check(FileAccess.get_file_as_bytes(path) == before, "%s content.cfg keeps its bytes for recovery" % case[0])
	var old := FileAccess.open(path, FileAccess.WRITE)
	old.store_string("[content]\nblood=\"muted\"\nhit_flash=\"full\"\nnotice_seen=true\n")
	old.close()
	var loaded: int = content.call("load_settings", path)
	_check(loaded == OK and content.call("drugs_mode") == "full" and content.call("blood_mode") == "muted", "a file from before the key is ours: drugs full, blood kept")
	content.call("set_drugs_mode", "off")
	var saved: int = content.call("save_settings")
	var reread := ConfigFile.new()
	_check(saved == OK and reread.load(path) == OK and reread.get_value("content", "drugs", "") == "off" and reread.get_value("content", "blood", "") == "muted" and reread.get_value("content", "notice_seen", false) == true, "the next save adds drugs and keeps the other keys")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
