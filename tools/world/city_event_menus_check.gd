extends SceneTree
## T8 06-UI-UX § «Випадки міста: COMFORT і HUD» п. 3, GAP 1–4 — the menus of the alley event (CityAlleyEvent) in the
## real CityWorld (saves off), Choko, with real keyboard and gamepad events where the player acts.
## Subject: for every menu of the alley — a menu the world opened takes no accept / cancel for 0.35 s and until a key
## held then is let go; Esc / B in the trap is the run its button names; the call's menu has no timer; the trap never
## offers «Віддати · 0 жет.»: with no token its first, focused exit turns the pockets out and ends the threat.
##   M1 guard: Space, pad A, Esc in the first 0.35 s of the sprung trap change nothing (tokens, menu, no chase); Enter
##      held past 0.35 s keeps the guard (A changes nothing) until it is let go; then A gives «Віддати»;
##   M2 Esc after the guard runs, as «Тікати · Esc / B» says;
##   M3 the call's menu open for 60 s: still open, «Піти за ним» works;
##   M4 no token left when the trap springs: no «Віддати», the first, focused exit «Вивернути кишені · жетонів немає»,
##      pressing it ends the alley with nothing taken; caught with no token: nothing taken, the words say so.
##   M5 (T4 audit 2026-10-08 «Інше», plan 2026-10-09 step 4) freeing the world with a menu open — the pedlar's, the
##      leaves', the alley's call, its trap — reports nothing: 0 engine errors or warnings (OS.add_logger).
## Literals (T8, never read from the code): guard 0.35 s = 21 ticks (PLACEHOLDER), the call menu 60 s, «Тікати · Esc / B».
## --break=arming|asktimer|zero are negative controls: no guard at all; the call's hidden timer running behind its open
## menu; a trap menu built before the tokens ran out and never counted again. --break=teardown replays the director's
## old order (the menu closed after the event left the tree): its engine errors are the subject (playable_check allows
## exactly those «!is_inside_tree()» lines in that one negative).
## Sentinel: CITY_EVENT_MENUS_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_EVENT_MENUS: ...".
const GUARD_TICKS := 21
const ASK_MENU_TICKS := 3600
const CAP := 5
const RUN_LABEL := "Тікати · Esc / B"
const EMPTY_LABEL := "Вивернути кишені · жетонів немає"
const ALLEY_SPOT := Vector3(16.0, 0.0, 6.0)
const INSIDE_SPOT := Vector3(20.0, 0.0, 20.0)
const NEAR_RESIDENT_10 := Vector3(23.0, 0.0, 4.0)
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var router: Node
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
		push_error("CITY_EVENT_MENUS: " + label)


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


func _key(code: Key, down: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.physical_keycode = code
	key.pressed = down
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await _ticks(1)


func _pad(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await _ticks(1)


func _tap_interact() -> void:
	var code: Key = KEY_G
	for event: InputEvent in InputMap.action_get_events(router.action_name(1, "interact")):
		if event is InputEventKey:
			code = (event as InputEventKey).physical_keycode if (event as InputEventKey).physical_keycode != KEY_NONE else (event as InputEventKey).keycode
			break
	await _key(code, true)
	await _key(code, false)


func _options() -> Array[String]:
	var labels: Array[String] = []
	for child: Node in events.dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and not child.has_meta("close"):
			labels.append(str(child.get_meta("full_text", child.text)))
	return labels


func _close_label() -> String:
	for child: Node in events.dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.has_meta("close"):
			return str(child.get_meta("full_text", child.text))
	return ""


func _focused() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return str(owner.get_meta("full_text", owner.text)) if owner is Button else ""


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
	if events.active != null:
		events.abort_active("fixture")
		await _ticks(2)


func _end() -> String:
	if events.dialogue.opened:
		events.dialogue.close()
	await _until(func() -> bool: return events.active == null, 900)
	return String(events.outcomes.back()) if not events.outcomes.is_empty() else ""


## A started alley with `face`, the asker beside the hero and his call open through the real interact key.
func _ask(face: String) -> Node:
	await _clean()
	world.player.restart_at(ALLEY_SPOT)
	await _ticks(30)
	events.session_time = 1000.0
	events.last_end_time = -INF
	events.last_alley_time = -INF
	if not events.try_start("alley"):
		_check(false, "the alley starts (%s)" % events.block_reason("alley"))
		return null
	var event: Node = events.active
	event.face_id = face
	event.known_before = progress.face_known(face)
	event.asker.global_position = world.player.global_position + Vector3(1.3, 0.0, 0.0)
	event._path.clear()
	event.asker.stop()
	await _until(func() -> bool: return is_instance_valid(event) and event.phase == "ask", 60)
	await _until(func() -> bool: return events.dialogue.prompt.visible, 30)
	await _tap_interact()
	var ok: bool = is_instance_valid(event) and event.phase == "ask" and events.dialogue.opened
	_check(ok, "the real interact key opens the call (%s)" % face)
	return event if ok else null


## «Піти за ним» and into the trap; the trap springs by itself (the world opens its menu).
func _spring(event: Node) -> bool:
	if not is_instance_valid(event) or not await _press("Піти за ним") or not is_instance_valid(event):
		return false
	event.asker.global_position = event.STAND
	event._path.clear()
	event.asker.stop()
	world.player.restart_at(INSIDE_SPOT)
	var sprung: bool = await _until(func() -> bool: return is_instance_valid(event) and event.phase == "trap" and events.dialogue.opened, 120)
	if sprung and mutation == "arming":
		events.dialogue._guard_left = 0.0   # the negative: no guard at all
		events.dialogue._guard_hold = false
	return sprung


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	router.apply_profile("solo", false)
	state.p1_character = "choko"
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
	events.enable_for_test(9753)
	events.start_chance = 0.0
	progress.earn_credits(10)
	await _m1_m2()
	await _m3()
	await _m4()
	await _clean()
	world.queue_free()
	await _ticks(3)
	await _m5()
	print("CITY_EVENT_MENUS_INFO engine frames %d of the 12000 the battery allows" % Engine.get_process_frames())
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_EVENT_MENUS_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


## M1–M2: the guard on the menu the world opened (GAP 2) and Esc / B as the run (GAP 1).
func _m1_m2() -> void:
	var event: Node = await _ask("alley_a")
	if event == null or not await _spring(event):
		_check(false, "M1 into the trap")
		return
	var before: int = progress.credits()
	_check(_close_label() == RUN_LABEL and not ("Тікати" in _options()) and _focused() == "Віддати · %d жет." % mini(before, CAP), "M1 the trap: «%s» is the close button, no separate run, focus on «Віддати» (%s · %s · %s)" % [RUN_LABEL, _options(), _close_label(), _focused()])
	await _key(KEY_SPACE, true)
	await _key(KEY_SPACE, false)
	await _pad(JOY_BUTTON_A, true)
	await _pad(JOY_BUTTON_A, false)
	await _key(KEY_ESCAPE, true)
	await _key(KEY_ESCAPE, false)
	_check(progress.credits() == before and is_instance_valid(event) and event.phase == "trap" and events.dialogue.opened, "M1 Space, A and Esc in the first %d ticks change nothing: tokens %d → %d, still the trap" % [GUARD_TICKS, before, progress.credits()])
	await _key(KEY_ENTER, true)   # held past the 0.35 s …
	await _ticks(GUARD_TICKS + 10)
	await _pad(JOY_BUTTON_A, true)
	await _pad(JOY_BUTTON_A, false)
	_check(progress.credits() == before and is_instance_valid(event) and event.phase == "trap", "M1 a key held past 0.35 s keeps the guard: A changes nothing (%d)" % progress.credits())
	await _key(KEY_ENTER, false)  # … let go: the guard ends
	await _ticks(2)
	await _pad(JOY_BUTTON_A, true)
	await _pad(JOY_BUTTON_A, false)
	await _ticks(2)
	_check(progress.credits() == before - mini(before, CAP), "M1 A after the guard gives «Віддати»: %d → %d" % [before, progress.credits()])
	var outcome: String = await _end()
	_check(outcome == "alley:gave", "M1 outcome gave (%s)" % outcome)
	progress.earn_credits(5)
	var again: Node = await _ask("alley_b")
	if again == null or not await _spring(again):
		_check(false, "M2 into the trap")
		return
	await _ticks(GUARD_TICKS + 4)
	await _key(KEY_ESCAPE, true)
	await _key(KEY_ESCAPE, false)
	_check(is_instance_valid(again) and again.phase == "chase" and not events.dialogue.opened, "M2 Esc after the guard runs, as «%s» says" % RUN_LABEL)
	world.player.restart_at(NEAR_RESIDENT_10)
	await _end()


## M3: the call's menu has no timer (GAP 3).
func _m3() -> void:
	var event: Node = await _ask("alley_c")
	if event == null:
		return
	for tick: int in ASK_MENU_TICKS:
		if mutation == "asktimer" and is_instance_valid(event):
			event.phase_time += 1.0 / 60.0   # the negative: the hidden timer keeps running behind the open menu
		await _ticks(1)
	var alive: bool = is_instance_valid(event)
	_check(alive and event.phase == "ask" and events.dialogue.opened and "Піти за ним" in _options(), "M3 after 60 s the call's menu is still open (%s, %s)" % [event.phase if alive else "gone", _options()])
	await _press("Піти за ним")
	alive = is_instance_valid(event)
	_check(alive and event.phase == "lead", "M3 «Піти за ним» still works after 60 s (%s)" % (event.phase if alive else "gone"))
	await _end()


## M4: no token left when the trap springs (GAP 4).
func _m4() -> void:
	if progress.credits() == 0:
		progress.earn_credits(1)   # the alley needs a token to start
	var event: Node = await _ask("alley_c")
	if event == null:
		return
	if mutation == "zero":
		await _spring(event)        # the negative: built while the tokens were there, never counted again
		progress.spend_credits(progress.credits())
	else:
		progress.spend_credits(progress.credits())   # spent on the way (food, a fall): nothing left
		await _spring(event)
	var labels: Array[String] = _options()
	var stale: bool = labels.any(func(label: String) -> bool: return label.begins_with("Віддати"))
	_check(progress.credits() == 0 and not stale and not labels.is_empty() and labels[0] == EMPTY_LABEL and _focused() == EMPTY_LABEL, "M4 with 0 tokens there is no «Віддати · N жет.»; the first, focused exit turns the pockets out (%s, focus %s)" % [labels, _focused()])
	await _press("Вивернути кишені")
	var outcome: String = await _end()
	_check(outcome == "alley:empty" and progress.credits() == 0, "M4 the pockets turned out end the threat: nothing taken (%s, %d)" % [outcome, progress.credits()])
	progress.earn_credits(1)
	var chased: Node = await _ask("alley_c")
	if chased == null or not await _spring(chased):
		_check(false, "M4 into the second trap")
		return
	progress.spend_credits(progress.credits())
	await _press("Тікати")
	await _until(func() -> bool: return not is_instance_valid(chased) or chased.phase == "told", 300)
	var alive: bool = is_instance_valid(chased)
	_check(alive and chased.pending_outcome == "caught" and chased.robbed == 0 and "порожньо" in events.dialogue.body.text, "M4 caught with no token: nothing taken (%s)" % (events.dialogue.body.text if events.dialogue.opened else "—"))
	await _end()


## Every error and warning the engine reports while it is attached (OS.add_logger), for M5.
class EngineReports extends Logger:
	var lines: Array[String] = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		lines.append("%s:%d %s %s" % [file.get_file(), line, code, rationale])

	func _log_message(_message: String, _error: bool) -> void:
		pass


## A fresh world for M5 (saves off, the director on with no random starts, tokens for the alley).
func _open_city() -> void:
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
	events.enable_for_test(9753)
	events.start_chance = 0.0
	progress.earn_credits(10)


## The pedlar's or the leaves' offer opened through the real interact key at the market court.
func _offer(id: String) -> Node:
	world.player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(30)
	events.session_time = 1000.0
	events.last_end_time = -INF
	events.leaves_count = 0
	events.vendor_count = 0
	if not events.try_start(id):
		_check(false, "M5 the %s starts at the market court (%s)" % [id, events.block_reason(id)])
		return null
	var event: Node = events.active
	event.person.global_position = world.player.global_position + Vector3(1.4, 0.0, 0.0)
	event.person.stop()
	await _until(func() -> bool: return is_instance_valid(event) and event.phase == "offer" and events.dialogue.prompt.visible, 90)
	await _tap_interact()
	var ok: bool = is_instance_valid(event) and events.dialogue.opened and event.phase == "talk"
	_check(ok, "M5 the real interact key opens the %s's menu" % id)
	return event if ok else null


## M5 (T4 audit 2026-10-08 «Інше»; plan 2026-10-09 step 4): the world freed with an event's menu open reports nothing —
## the pedlar's offer, the leaves' offer, the alley's call and its trap. The engine's own reports are counted from the
## free to three frames after (and an ERROR printed then is red in playable_check as well). --break=teardown replays
## the order before the fix: the menu closed after the event and its people have left the tree, the event still running
## — on the dialogue's tree_exiting, the director's first child and so the last to leave before the director's own
## _exit_tree (children leave last-added first; a node is out of the tree once its own exit has run).
func _m5() -> void:
	var content: Node = root.get_node("ContentSettings")
	var old_content: String = content.get("storage_path")
	content.call("load_settings", "user://city_event_menus_content_%d.cfg" % OS.get_process_id())
	content.call("mark_notice_seen")
	content.call("set_drugs_mode", "full")
	for spec: Array in [["vendor", "talk"], ["leaves", "talk"], ["alley", "ask"], ["alley", "trap"]]:
		await _open_city()
		var event: Node = null
		if spec[0] == "alley":
			event = await _ask("alley_c")
			if event != null and spec[1] == "trap" and not await _spring(event):
				_check(false, "M5 into the trap")
				event = null
		else:
			event = await _offer(spec[0])
		var open: bool = event != null and is_instance_valid(event) and event.phase == spec[1] and events.dialogue.opened
		_check(open, "M5 the %s menu (%s) is open before the world goes" % [spec[0], spec[1]])
		if mutation == "teardown":
			var dialogue: Node = events.dialogue
			var replay := func() -> void:
				if dialogue.opened:
					dialogue.close()
			dialogue.tree_exiting.connect(replay, CONNECT_ONE_SHOT)
		var reports := EngineReports.new()
		OS.add_logger(reports)
		world.queue_free()
		await _ticks(3)
		OS.remove_logger(reports)
		_check(open and reports.lines.is_empty(), "M5 the world freed with the %s menu open (%s): %d engine reports %s" % [spec[0], spec[1], reports.lines.size(), reports.lines])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(content.get("storage_path")))
	content.call("load_settings", old_content)
