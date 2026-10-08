extends SceneTree
## Plan docs/Plans/2026-10-08-City-Events-Stage-1.md step 2 — В1 «Там людині погано» without a fight (CityAlleyEvent)
## in the real CityWorld (saves off), Choko and Skea, real interact key presses and the event's real dialogue buttons.
## Subject: for every exit of the alley the hero leaves without a fight, loses at most min(tokens, cap_robbery) and
## only on «give» or when caught; the face is remembered per hero and «Я тебе пам'ятаю» stops the next trap; the sword
## exit is Choko's and always answers (flee or give up); the chase ends near people.
##   S1 the asker walks out of the passage to the hero, the prompt names the real interact key, «Не зараз» changes nothing;
##   S2 give: −min(8, 5), bought sashes stay, the second one closes the north mouth, the face is remembered (lost 5);
##   S3 «Я тебе пам'ятаю» with that face: no trap, no loss;  S4 Choko talks to a known face: they leave, no loss;
##   S5 Choko talks to an unknown face: refused, talk gone; run → near a resident the chase ends, no loss;
##   S6 run and stand still: caught, −min(tokens, 5);  S7 sword, give up: the face returns exactly what it took;
##   S8 sword, flee: no change;  S9 the memory survives a reload of CityProgress from disk;
##   S10 Skea: no sword exit; talk → the smile, no loss;  S11 walking away from the call: ignored, no loss.
## Literal thresholds (plan / T5 brief, never read from the event): cap 5, people radius 6 m, sword answer ≤ 2 s.
## --break=cap|memory|sword|people are negative controls.
## Sentinel: CITY_ALLEY_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_ALLEY: ...".
const CAP := 5
const SWORD_ANSWER_TICKS := 120
const ALLEY_SPOT := Vector3(16.0, 0.0, 6.0)
const INSIDE_SPOT := Vector3(20.0, 0.0, 20.0)
const NEAR_RESIDENT_10 := Vector3(23.0, 0.0, 4.0)   # resident 10's lane: x 24.5–25.5, z 0–8 (people radius 6 m)
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
		push_error("CITY_ALLEY: " + label)


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


func _reset_clock() -> void:
	events.session_time = 1000.0
	events.last_end_time = -INF
	events.last_alley_time = -INF


## A started alley with the asker already beside the hero (the walk out of the passage is S1's).
## No event, no modal, a calm hero: every scenario starts from here, even after a failed one.
func _clean() -> void:
	if events.active != null:
		events.abort_active("fixture")
	if events.dialogue.opened:
		events.dialogue.close()
	await _ticks(3)
	if events.active != null:
		events.abort_active("fixture")
		await _ticks(2)


## A started alley with the asker already beside the hero (the walk out of the passage is S1's).
func _start(face: String = "") -> Node:
	await _clean()
	world.player.restart_at(ALLEY_SPOT)
	await _ticks(30)
	_reset_clock()
	if not events.try_start("alley"):
		_check(false, "the alley starts at the alley spot (%s)" % events.block_reason("alley"))
		return null
	var event: Node = events.active
	if not face.is_empty():
		event.face_id = face
		event.known_before = progress.face_known(face)
	if mutation == "cap":
		event.cap_robbery = 100
	if mutation == "memory":
		event.face_id = ""
	if mutation == "sword":
		event.react_seconds = 1.0e9
	if mutation == "people":
		event.people_radius = 0.0
	event.asker.global_position = world.player.global_position + Vector3(1.3, 0.0, 0.0)
	event._path.clear()
	event.asker.stop()
	await _until(func() -> bool: return is_instance_valid(event) and event.phase == "ask", 60)
	return event if is_instance_valid(event) else null


func _open_ask(event: Node) -> bool:
	if not is_instance_valid(event):
		return false
	await _until(func() -> bool: return events.dialogue.prompt.visible, 30)
	await _tap_interact()
	return is_instance_valid(event) and events.dialogue.opened and event.phase == "ask"


func _to_trap(event: Node) -> bool:
	if not is_instance_valid(event) or not await _press("Піти за ним") or not is_instance_valid(event):
		return false
	event.asker.global_position = event.STAND
	event._path.clear()
	event.asker.stop()
	world.player.restart_at(INSIDE_SPOT)
	return await _until(func() -> bool: return is_instance_valid(event) and event.phase == "trap" and events.dialogue.opened, 120)


## Into the trap with `face`; null (and one red check) when any step fails.
func _trap(face: String, label: String) -> Node:
	var event: Node = await _start(face)
	var ok: bool = event != null and await _open_ask(event) and await _to_trap(event)
	_check(ok, label + " into the trap")
	return event if ok and is_instance_valid(event) else null


func _end(event: Node) -> String:
	if events.dialogue.opened:
		events.dialogue.close()
	await _until(func() -> bool: return events.active == null, 900)
	return String(events.outcomes.back()) if not events.outcomes.is_empty() else ""


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	router.apply_profile("solo", false)
	await _world(state, "choko")
	progress.earn_credits(8)
	for scenario: Callable in [_s1, _s2, _s3, _s4, _s5, _s6, _s7, _s8, _s11, _s9]:
		await scenario.call()
	await _clean()
	world.queue_free()
	await _ticks(3)
	await _world(state, "skea")
	progress.earn_credits(6)
	await _s10()
	await _clean()
	world.queue_free()
	await _ticks(3)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_ALLEY_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


func _world(state: Node, hero: String) -> void:
	state.p1_character = hero
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
	events.enable_for_test(2468)
	events.start_chance = 0.0   # starts come from try_start only


## S1: the walk out of the passage, the prompt with the real key, «Не зараз».
func _s1() -> void:
	await _clean()
	world.player.restart_at(ALLEY_SPOT)
	await _ticks(30)
	_reset_clock()
	if not events.try_start("alley"):
		_check(false, "S1 the alley starts (%s)" % events.block_reason("alley"))
		return
	var event: Node = events.active
	var face: String = event.face_id
	var spawn: Vector3 = event.asker.global_position
	_check(spawn.x > 18.0 and spawn.x < 22.0 and spawn.z > 12.0 and spawn.z < 30.0, "S1 the asker comes from inside the passage (%s)" % spawn)
	var reached: bool = await _until(func() -> bool: return is_instance_valid(event) and event.phase == "ask", 1500)
	_check(reached and event.asker.global_position.distance_to(world.player.global_position) < 2.0, "S1 he walks out to the hero and stops beside him")
	if not reached:
		return
	await _until(func() -> bool: return events.dialogue.prompt.visible, 30)
	var key_label: String = router.binding_label(1, "interact", false)
	_check(events.dialogue.prompt.visible and events.dialogue.prompt.text.begins_with(key_label + " · "), "S1 the prompt names the real interact key (%s)" % events.dialogue.prompt.text)
	await _tap_interact()
	_check(events.dialogue.opened and _options() == ["Піти за ним", "Не зараз"], "S1 the real key opens the call; a fresh face has no «Я тебе пам'ятаю» (%s)" % [_options()])
	await _press("Не зараз")
	var outcome: String = await _end(event)
	_check(outcome == "alley:declined" and progress.credits() == 8 and not progress.face_known(face), "S1 «Не зараз»: declined, 8 tokens, the face not remembered (%s, %d)" % [outcome, progress.credits()])


## S2: give.
func _s2() -> void:
	var owned_before: Array = progress.heroes["choko"].owned.duplicate()
	var event: Node = await _trap("alley_a", "S2")
	if event == null:
		return
	var trap_options: Array[String] = _options()
	_check(trap_options == ["Віддати · %d жет." % CAP, "Говорити", "Тікати", "Вийняти меч"], "S2 the trap offers give (min(8, %d)), talk, run, sword (%s)" % [CAP, trap_options])
	_check(event.asker.knife != null and event.asker.knife.visible and event.asker.pose == "threat", "S2 the knife is out")
	await _until(func() -> bool: return is_instance_valid(event) and is_instance_valid(event.blocker) and event.blocker.global_position.distance_to(event.BLOCK) < 0.2, 240)
	var blocker_at: Vector3 = event.blocker.global_position if is_instance_valid(event) and is_instance_valid(event.blocker) else Vector3.INF
	_check(blocker_at.distance_to(event.BLOCK) < 0.2 and blocker_at.z < world.player.global_position.z, "S2 the second one stands in the north mouth behind the hero (%s)" % blocker_at)
	await _press("Віддати")
	_check(progress.credits() == 8 - CAP, "S2 give takes exactly min(8, %d): %d left" % [CAP, progress.credits()])
	_check(progress.heroes["choko"].owned == owned_before, "S2 bought sashes stay")
	_check(progress.face_lost("alley_a") == CAP, "S2 the face is remembered with what it took (%d)" % progress.face_lost("alley_a"))
	var outcome: String = await _end(event)
	var left: int = events.get_children().filter(func(n: Node) -> bool: return n is CityPasserby and not n.is_queued_for_deletion()).size()
	_check(outcome == "alley:gave" and left == 0, "S2 they leave and are gone (%s, %d left)" % [outcome, left])


## S3: «Я тебе пам'ятаю».
func _s3() -> void:
	var event: Node = await _start("alley_a")
	if not await _open_ask(event):
		_check(false, "S3 the call opens")
		return
	_check("Я тебе пам'ятаю" in _options(), "S3 the remembered face offers «Я тебе пам'ятаю» (%s)" % [_options()])
	await _press("Я тебе пам'ятаю")
	var no_blocker: bool = is_instance_valid(event) and event.blocker == null
	var outcome: String = await _end(event)
	_check(outcome == "alley:remembered" and progress.credits() == 8 - CAP and no_blocker, "S3 the trap never starts, nothing lost (%s, %d)" % [outcome, progress.credits()])


## S4: Choko talks to a known face.
func _s4() -> void:
	var event: Node = await _trap("alley_a", "S4")
	if event == null:
		return
	await _press("Говорити")
	_check(events.dialogue.opened and "Choko" in events.dialogue.body.text, "S4 Choko speaks to him")
	var outcome: String = await _end(event)
	_check(outcome == "alley:recognized" and progress.credits() == 8 - CAP, "S4 recognised: they leave, nothing lost (%s, %d)" % [outcome, progress.credits()])


## S5: Choko talks to an unknown face, then runs to the people.
func _s5() -> void:
	var event: Node = await _trap("alley_c", "S5")
	if event == null:
		return
	await _press("Говорити")
	_check(events.dialogue.opened and not ("Говорити" in _options()) and "Тікати" in _options(), "S5 the unknown face refuses talk; talk is gone, the other exits stay (%s)" % [_options()])
	await _press("Тікати")
	_check(is_instance_valid(event) and event.phase == "chase" and not events.dialogue.opened, "S5 running starts the chase")
	world.player.restart_at(NEAR_RESIDENT_10)
	var escaped: bool = await _until(func() -> bool: return not is_instance_valid(event) or event.phase != "chase", 60)
	var outcome: String = await _end(event)
	_check(escaped and outcome == "alley:escaped" and progress.credits() == 8 - CAP, "S5 near a resident the chase ends within 1 s, nothing lost (%s, %d)" % [outcome, progress.credits()])


## S6: run and stand still — caught.
func _s6() -> void:
	progress.earn_credits(5)
	var event: Node = await _trap("alley_b", "S6")
	if event == null:
		return
	var before: int = progress.credits()
	await _press("Тікати")
	await _until(func() -> bool: return not is_instance_valid(event) or event.phase == "told", 300)
	var caught: bool = is_instance_valid(event) and event.pending_outcome == "caught"
	_check(caught and progress.credits() == before - mini(before, CAP), "S6 caught standing still: −min(%d, %d) → %d" % [before, CAP, progress.credits()])
	var outcome: String = await _end(event)
	_check(outcome == "alley:caught", "S6 outcome caught (%s)" % outcome)


## S7: the sword — they give up and the face returns what it took.
func _s7() -> void:
	var lost: int = progress.face_lost("alley_a")
	var event: Node = await _trap("alley_a", "S7")
	if event == null:
		return
	event.surrender_chance = 1.0
	var before: int = progress.credits()
	await _press("Вийняти меч")
	var answered: bool = await _until(func() -> bool: return is_instance_valid(event) and event.reaction != "", SWORD_ANSWER_TICKS)
	_check(answered and event.reaction == "surrender", "S7 the robbers answer the sword within %d ticks" % SWORD_ANSWER_TICKS)
	await _ticks(60)
	_check(world.player.sword_drawn, "S7 Choko's sword is drawn")
	_check(lost == CAP and progress.credits() == before + lost and progress.face_lost("alley_a") == 0, "S7 the face returns exactly what it took: lost %d, %d → %d" % [lost, before, progress.credits()])
	var outcome: String = await _end(event)
	_check(outcome == "alley:surrendered", "S7 outcome surrendered (%s)" % outcome)


## S8: the sword — they flee.
func _s8() -> void:
	var event: Node = await _trap("alley_b", "S8")
	if event == null:
		return
	event.surrender_chance = 0.0
	var before: int = progress.credits()
	await _press("Вийняти меч")
	var answered: bool = await _until(func() -> bool: return is_instance_valid(event) and event.reaction != "", SWORD_ANSWER_TICKS)
	var outcome: String = await _end(event)
	_check(answered and outcome == "alley:fled" and progress.credits() == before, "S8 they flee, nothing changes (%s, %d → %d)" % [outcome, before, progress.credits()])


## S11: walking away from the call.
func _s11() -> void:
	var event: Node = await _start("alley_b")
	if event == null:
		return
	var before: int = progress.credits()
	world.player.restart_at(ALLEY_SPOT + Vector3(-12.0, 0.0, 0.0))
	await _until(func() -> bool: return not is_instance_valid(event) or event.phase == "leave", 120)
	var outcome: String = await _end(event)
	_check(outcome == "alley:ignored" and progress.credits() == before, "S11 walking away ignores the call, nothing lost (%s)" % outcome)


## S9: the memory survives a reload.
func _s9() -> void:
	var path: String = "user://city_alley_progress_%d.json" % OS.get_process_id()
	var disk: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(disk)
	disk.setup("choko", false, path)
	disk.remember_face("alley_b", 3)
	var again: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(again)
	again.setup("choko", true, path)
	_check(again.save_ok and again.face_known("alley_b") and again.face_lost("alley_b") == 3 and not again.face_known("alley_c"), "S9 the remembered face and its loss survive a reload")
	disk.queue_free()
	again.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## S10: Skea — no sword exit; talk → the smile.
func _s10() -> void:
	var event: Node = await _trap("alley_a", "S10 Skea")
	if event == null:
		return
	_check(not ("Вийняти меч" in _options()) and "Говорити" in _options(), "S10 Skea has no sword exit (%s)" % [_options()])
	await _press("Говорити")
	_check(events.dialogue.opened and "посмішка ширшає" in events.dialogue.body.text.to_lower(), "S10 Skea says nothing; the smile widens")
	var outcome: String = await _end(event)
	_check(outcome == "alley:smile" and progress.credits() == 6, "S10 they back off, nothing lost (%s, %d)" % [outcome, progress.credits()])
