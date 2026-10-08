extends SceneTree
## Plan docs/Plans/2026-10-08-City-Events-Stage-1.md step 4 — the «Заплутаність» state (CityHaze, CityHazeVignette)
## in the real CityWorld (saves off) with the T8 HUD rules (06-UI-UX § «Заплутаність» поруч зі шкалою).
## Subject: while the state lasts the view narrows statically (a vignette under the HUD, no pulse; the FOV part follows
## CAMERA SHAKE), city walking/braking/tracking are slower outside a lethal pocket only, half of a resident's sentences
## fade while every option, price, quest and story line stays whole; it ends with time or food at «Шавлія», and then
## everything is exactly as before.
##   H1 haze_active()/haze_remaining();  H2 ramp, a constant plateau, the vignette layer < 19 and its strength;
##   H3 FOV 65 → 55 at the default CAMERA SHAKE, 65 at 0;  H4 walk × 0.85, braking × 0.6, tracking × 0.5 — none of it in
##   a lethal pocket, Fighter has no such field;  H5 Mira's conversation: the same options and prices as without the
##   state, the reply half gone after 2 s, «Тобі б поїсти», a quest offer and its acceptance whole, the meeting recorded;
##   H6 food: −1 token, at most the 10 s fade left, HAZE FADES;  H7 the HAZE m:ss line is the card's last;
##   H8 the lethal pocket waits;  H9 the end: FOV 65, no vignette, multipliers 1, no HAZE line.
## Literals (T5 brief § 4.2 / § 4.4, T8 spec): 90 s, ramp 3 s, fade 10 s, × 0.85 / × 0.6 / × 0.5, FOV 65 → 55, 2 s,
## layer < 19, food 1 token.
## --break=pulse|layer|forget|pocket|end are negative controls.
## Sentinel: CITY_HAZE_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_HAZE: ...".
const DURATION := 90.0
const FADE := 10.0
const WALK := 0.85
const DECEL := 0.6
const TRACK := 0.5
const FOV := 65.0
const FOV_NARROW := 55.0
const FORGET_TICKS := 120
const HUD_LAYER := 19
const FOOD := 1
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var router: Node
var world: Node
var haze: Node
var player: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_HAZE: " + label)


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


func _options(dialogue: Node) -> Array[String]:
	var labels: Array[String] = []
	for child: Node in dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			labels.append(str(child.get_meta("full_text", child.text)))
	return labels


func _press(dialogue: Node, prefix: String) -> bool:
	for child: Node in dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and not child.disabled and str(child.get_meta("full_text", child.text)).begins_with(prefix):
			(child as Button).pressed.emit()
			await _ticks(2)
			return true
	return false


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	var comfort: Node = root.get_node("ComfortSettings")
	var content: Node = root.get_node("ContentSettings")
	var old_comfort: String = comfort.get("storage_path")
	var old_content: String = content.get("storage_path")
	comfort.call("load_settings", "user://city_haze_comfort_%d.cfg" % OS.get_process_id())
	content.call("load_settings", "user://city_haze_content_%d.cfg" % OS.get_process_id())
	content.call("mark_notice_seen")   # the pocket would open straight away if it were allowed (H8)
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
	haze = world.haze
	player = world.player
	await _ticks(20)
	world.progress.earn_credits(3)
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(30)
	if mutation == "pulse":
		haze.ramp_in_seconds = 1000.0
	if mutation == "layer":
		world.haze_vignette.layer = 25
	if mutation == "forget":
		haze.forget_delay_seconds = 1.0e9
	if mutation == "pocket":
		world.haze = null   # the pocket entry no longer asks about the state
	if mutation == "end":
		haze.process_mode = Node.PROCESS_MODE_DISABLED

	# H1–H3 --------------------------------------------------------------------------------------------------------
	_check(not haze.haze_active() and haze.haze_remaining() == 0.0 and world.camera_rig.camera.fov == FOV, "H1 no state at first; FOV %.0f" % FOV)
	var base_speed: float = player.speed_mult()
	haze.begin()
	_check(haze.haze_active() and is_equal_approx(haze.haze_remaining(), DURATION), "H1 begin: active, %.0f s left (%.2f)" % [DURATION, haze.haze_remaining()])
	await _ticks(2)
	var early: float = haze.weight()
	await _ticks(int(3.0 * 60.0) + 2)
	var samples: Array[float] = []
	var shades: Array[float] = []
	var fovs: Array[float] = []
	for tick: int in 60:
		await _ticks(1)
		samples.append(haze.weight())
		shades.append(world.haze_vignette.strength())
		fovs.append(world.camera_rig.camera.fov)
	_check(early > 0.0 and early < 0.1, "H2 the view narrows over the ramp, not at once (weight %.3f after 2 ticks)" % early)
	_check(samples.min() == 1.0 and samples.max() == 1.0 and shades.min() == shades.max() and fovs.min() == fovs.max(), "H2 the plateau is static: weight %.3f…%.3f, shade %.3f…%.3f, FOV %.2f…%.2f" % [samples.min(), samples.max(), shades.min(), shades.max(), fovs.min(), fovs.max()])
	_check(world.haze_vignette.layer < HUD_LAYER and world.haze_vignette.layer < world.hud.layer, "H2 the vignette lies under every HUD (layer %d < %d)" % [world.haze_vignette.layer, HUD_LAYER])
	_check(world.haze_vignette.rect.visible and is_equal_approx(world.haze_vignette.strength(), 1.0), "H2 the vignette shows at full strength on the plateau")
	_check(is_equal_approx(world.camera_rig.camera.fov, FOV_NARROW), "H3 FOV %.0f → %.0f at the default CAMERA SHAKE (%.2f)" % [FOV, FOV_NARROW, world.camera_rig.camera.fov])
	comfort.call("set_value", "shake", 0.0)
	await _ticks(2)
	_check(is_equal_approx(world.camera_rig.camera.fov, FOV) and world.haze_vignette.rect.visible, "H3 CAMERA SHAKE 0: no FOV change, the static vignette stays (%.2f)" % world.camera_rig.camera.fov)
	comfort.call("set_value", "shake", 0.5)
	await _ticks(2)

	# H4 ------------------------------------------------------------------------------------------------------------
	_check(is_equal_approx(player.speed_mult(), base_speed * WALK), "H4 walking × %.2f (%.4f of %.4f)" % [WALK, player.speed_mult(), base_speed])
	player.velocity = Vector3(5.0, 0.0, 0.0)
	player._walk_physics(1.0 / 60.0, 0.0, 0.0)
	var braked: float = 5.0 - Vector2(player.velocity.x, player.velocity.z).length()
	_check(is_equal_approx(braked, player.data.ground_decel * DECEL / 60.0), "H4 braking × %.1f (%.4f m/s in a tick)" % [DECEL, braked])
	player._start_move(player.data.light, "light")
	_check(is_equal_approx(player._track_left, deg_to_rad(player.data.light.tracking_deg) * TRACK), "H4 attack tracking × %.1f" % TRACK)
	player.lethal_pocket = true
	player._start_move(player.data.light, "light")
	var pocket_track: float = player._track_left
	_check(is_equal_approx(player.speed_mult(), base_speed) and is_equal_approx(pocket_track, deg_to_rad(player.data.light.tracking_deg)), "H4 inside a lethal pocket nothing is scaled")
	player.lethal_pocket = false
	var duel_fields: Array = (load("res://scripts/fighter/Fighter.gd") as Script).get_script_property_list().map(func(p: Dictionary) -> String: return p.name)
	_check(not ("haze" in duel_fields), "H4 Fighter (the duel) has no haze field")
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(20)

	# H5–H7: Mira -------------------------------------------------------------------------------------------------------
	var npc: Node = world.npc_director
	var shop: Dictionary = CityPlaces.shops()[0]
	player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(40)
	var clear_options: Array[String] = []
	var saved_remaining: float = haze._remaining
	haze._remaining = 0.0   # a moment without the state, for the comparison
	if npc.open_conversation(0):
		clear_options = _options(npc.dialogue)
		npc.dialogue.close()
	await _ticks(2)
	haze._remaining = saved_remaining
	_check(not clear_options.is_empty(), "H5 Mira can be talked to at her counter")
	_check(npc.open_conversation(0), "H5 Mira talks to a hazy hero")
	var full: String = npc.dialogue.body.text
	var reply: String = npc.current_fallback
	var hazy_options: Array[String] = _options(npc.dialogue)
	_check(hazy_options == clear_options, "H5 every option and price is bit for bit as without the state (%s)" % [hazy_options])
	_check(("Поїсти · %d жет." % FOOD) in hazy_options, "H5 «Шавлія» offers food for %d token" % FOOD)
	_check("«Тобі б поїсти»." in full and reply in full, "H5 Mira: «Тобі б поїсти»; the reply is first shown whole")
	await _ticks(FORGET_TICKS + 4)
	var faded: String = npc.dialogue.body.text
	var sentences: PackedStringArray = CityHaze.split_sentences(reply)
	var kept: int = 0
	for sentence: String in sentences:
		if sentence in faded:
			kept += 1
	var gone: int = sentences.size() - kept
	print("CITY_HAZE_INFO reply «%s» → «%s»" % [reply, faded.get_slice("\n\n", 1)])
	_check(faded != full and gone >= sentences.size() / 2 and gone <= (sentences.size() + 1) / 2 and "…" in faded, "H5 after 2 s half of the reply's %d sentences fade (%d gone)" % [sentences.size(), gone])
	_check(faded.begins_with(full.get_slice("\n\n", 0)) and "«Тобі б поїсти»." in faded, "H5 the name line and Mira's hint never fade")
	var quest_label: String = ""
	for label: String in hazy_options:
		if label.begins_with("Доручення: "):
			quest_label = label
			break
	if not quest_label.is_empty():
		var quest: Dictionary = {}
		for q: Dictionary in world.progress.quests:
			if "Доручення: " + str(q.title) == quest_label:
				quest = q
		await _press(npc.dialogue, quest_label)
		await _ticks(FORGET_TICKS + 4)
		_check(str(quest.description) in npc.dialogue.body.text and str(quest.hint) in npc.dialogue.body.text, "H5 a quest offer stays whole in the state")
		await _press(npc.dialogue, "Беруся за справу")
		await _ticks(FORGET_TICKS + 4)
		_check(world.progress.quest_status(str(quest.id)) == "active" and str(quest.hint) in npc.dialogue.body.text, "H5 accepting works and its hint stays whole (%s)" % world.progress.quest_status(str(quest.id)))
	else:
		_check(false, "H5 Mira offers a quest to test")
	_check("resident_00" in Array(world.progress.heroes["choko"].events.get("meet", [])), "H5 the meeting is recorded as always")
	var line: Label = world.hud.haze_label
	var column: Node = line.get_parent()
	_check(line.visible and line.text.begins_with("HAZE ") and column.get_child(column.get_child_count() - 1) == line, "H7 the HAZE m:ss line is the card's last (%s)" % line.text)
	var credits: int = world.progress.credits()
	await _press(npc.dialogue, "Поїсти")
	_check(world.progress.credits() == credits - FOOD and haze.haze_remaining() <= FADE + 0.001 and haze.haze_active(), "H6 food: −%d token, at most the %.0f s fade left (%.2f)" % [FOOD, FADE, haze.haze_remaining()])
	_check(world.hud.get("_haze_fades_left") > 0.0, "H6 the end of the state is announced: HAZE FADES")
	npc.dialogue.close()
	await _ticks(3)
	_check(world.hud.hint_label.visible and world.hud.hint_label.text == "HAZE FADES", "H6 HAZE FADES on the bottom line (%s)" % world.hud.hint_label.text)

	# H8: the lethal pocket waits --------------------------------------------------------------------------------------
	player.restart_at(Vector3(0.0, 0.0, 9.5))
	await _ticks(30)
	var lethal: Node = world.lethal
	var key := InputEventKey.new()
	for event: InputEvent in InputMap.action_get_events(router.action_name(1, "interact")):
		if event is InputEventKey:
			key.keycode = (event as InputEventKey).keycode
			key.physical_keycode = (event as InputEventKey).physical_keycode
			break
	for down: bool in [true, false]:
		key.pressed = down
		Input.parse_input_event(key.duplicate())
		Input.flush_buffered_events()
		await _ticks(1)
	await _ticks(3)
	_check(haze.haze_active() and not lethal.active, "H8 a hazy hero cannot open the lethal pocket")
	if lethal.active:
		lethal.close("abort")
		await _ticks(3)

	# H9: the end ---------------------------------------------------------------------------------------------------------
	await _until(func() -> bool: return not haze.haze_active(), int((FADE + 1.0) * 60.0))
	await _ticks(2)
	_check(not haze.haze_active() and world.camera_rig.camera.fov == FOV and not world.haze_vignette.rect.visible, "H9 the state ends: FOV %.0f exactly, no vignette (%.3f)" % [FOV, world.camera_rig.camera.fov])
	_check(player.speed_mult() == base_speed and not world.hud.haze_label.visible, "H9 walking as before; no HAZE line")

	world.queue_free()
	await _ticks(3)
	for path: String in [comfort.get("storage_path"), content.get("storage_path")]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	comfort.call("load_settings", old_comfort)
	content.call("load_settings", old_content)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_HAZE_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
