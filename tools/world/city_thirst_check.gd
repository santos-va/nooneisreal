extends SceneTree
## Plan docs/Plans/2026-10-08-Thirst-Substances-Icons.md step 1 — the thirst scale (CityThirst on CityHunger's clock) and
## the water pump in the real CityWorld (saves off), Choko and then Skea, against T5's list
## (docs/GDD/2026-10-08-Thirst-Numbers.md § 11, items 1–6, 9–13; 7–8 are block 2) and the T8 HUD (06-UI-UX § «Спрага,
## стани речовин і іконки предметів» W1–W6, W13, N6).
## Subject: for every frame of city play W loses one hundredth per 12 frames on H's clock and nothing else changes it but
## water, a drink and the collapse; the body takes the worse of the two bands, never the product, for the dodge refill, the
## walk, the wall steps and the one hp tick; H = 0 or W = 0 is one collapse that lifts each scale to at least 30 and
## takes −min(tokens, 3) once; the pocket takes B and W stands in it; the pump gives W 100 for nothing, never H; without
## a water source W never moves; the save keeps W exactly and never writes over a damaged field.
##   T0 a scripted run: W fixed at 100, no clock, WATER 100%, no hint, no sound (N6);
##   T1 3000 real frames → 97.50; 60 000 / 90 000 / 108 000 frames (simulate) → 50.00 / 25.00 / 10.00; 120 000 → collapse;
##   T2 the pause, Mira's conversation, the lethal pocket and the collapse: W unchanged;
##   T3 B = max: H 60 + W 40 → 22.5 / s, × 1, wall steps; H 20 + W 40 and H 40 + W 20 → 18 / s, × 0.85, none; H 8 + W 8 →
##      15 / s, × 0.75, hp −1 % per 300 frames (not per 150), never below 40 %;
##   T4 faint + «Заплутаність» + fatigue 1.0 → Choko walks 3.21 ± 0.02 m/s (≥ 3.0, run_min_speed);
##   T5 the pump with the real interact key and pad (Y + D-pad Down): W 37 → 100, tokens −0, H not raised, the haze stays;
##      the prompt names the key; out of reach no prompt;
##   T6 drinks: the tea H +25, W +30, the haze fades; the loaf W +0; W never above 100;
##   T9 the haze starting: W bit for bit;
##   T10 the collapse: W 0 at H 80 → W 30, H 80, hp ≥ 40 %, −3; H 0 at W 70 → H 30, W 70; both on one frame → one collapse,
##       −3 once; W 0 at H 2 → H 30; the words;
##   T11 the pocket at H 80 + W 40: 22.5 / s, W stands, RETRY the same, after it W 40; the words for one scale and equal;
##   T12 the save: round trip; an old save → 100; a damaged W (10001, -1, 12.5, "abc") → not written over;
##   T13 the gate: no water source → W 100, the clock never moves it, the body takes H only, no WATER row;
##   H1 (W1) WATER under FOOD, one rectangle at 100 / 45 / 22 / 8, card 390; H2 (W2) each crossing: word, one 3 s hint,
##      thirst_cue on that frame; H3 (W3) no extra effect; H4 (W4) both within 60 ticks → one hint, one cue; H5 (W5) B 3
##      from W: HEALTH, the cue every 30 s; H6 (W6) ±1 for 20 frames → one hint; H7 FAINT by B (a merged FAINT hint
##      that starts with HUNGRY is never pushed out); H8 (W13) the pause line fits in one row.
##   S  Skea: the pump by the pad, the body band.
## Literals (T5 § 2–6, T8): 12 frames, 97.50 / 50 / 25 / 10, 3.21 m/s, wake 30, −3, tea +25 / +30, the hint and pause words.
## --break=rate|gate|pocket_clock|ignore|source are negative controls (rate 14 frames; the conversation releases the UI
## token; the clock does not see the pocket; W counted as off for the body; the gate fed a fake source).
## Sentinel: CITY_THIRST_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_THIRST: ...".
const FULL := 10000
const CHOKO_HP := 1050.0
const FLOOR := 420.0
const SAFE_POINT := Vector3(0.0, 0.0, 9.5)
const AT_PUMP := Vector3(-1.25, 0.0, 17.8)   # 0.6 m east of the spout (−1.86, 0.86, 17.8), facing it
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var router: Node
var world: Node
var hunger: Node
var thirst: Node
var player: Node
var progress: Node
var npc: Node
var sfx: Node
var drank: Array = []


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_THIRST: " + label)


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


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


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
		_send(key)
		await _ticks(1)


func _pad(button: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = down
	_send(event)


## The pad's interact: hold Y, tap D-pad Down, let Y go (InputRouter's chord).
func _pad_interact() -> void:
	_pad(JOY_BUTTON_Y, true)
	await _ticks(1)
	_pad(JOY_BUTTON_DPAD_DOWN, true)
	await _ticks(1)
	_pad(JOY_BUTTON_DPAD_DOWN, false)
	_pad(JOY_BUTTON_Y, false)
	await _ticks(1)


func _close_all() -> void:
	if npc.dialogue.opened:
		npc.dialogue.close()
	if world.lethal.active:
		world.lethal.close("abort")
	if world.hud.paused_ui:
		world.hud.set_paused(false)
	if world.haze.haze_active():
		world.haze.clear()
	player.fatigue = 0.0
	await _ticks(3)


## H, W, hp and tokens for a scenario; both scales on the shared clock, the counters fresh, the HUD re-armed.
func _level(h: int, w: int, hp: float = CHOKO_HP, tokens: int = -1) -> void:
	hunger.enable_for_test(h)
	thirst.enable_for_test(w)
	if mutation == "ignore":
		thirst.running = false   # the negative: W is not counted for the body
	hunger.city_hp = hp
	player.set_round_hp(hp)
	if tokens >= 0:
		progress.spend_credits(progress.credits())
		progress.earn_credits(tokens)
	world.hud._body_queue.clear()
	world.hud.bind_hunger(hunger)


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	sfx = root.get_node("Sfx")
	var state: Node = root.get_node("GameState")
	var content: Node = root.get_node("ContentSettings")
	var old_content: String = content.get("storage_path")
	content.call("load_settings", "user://city_thirst_content_%d.cfg" % OS.get_process_id())
	content.call("mark_notice_seen")   # the pocket opens at once (T2, T11)
	state.set_free_move(true)
	router.apply_profile("solo", false)
	await _open_world("choko")
	await _t0()
	if mutation == "rate":
		thirst.decay_frames = 14
	for scenario: Callable in [_t1, _h1, _h2, _h3, _h4, _h5, _h6, _h7, _h8, _t2, _t3, _t4, _t5, _t6, _t9, _t10, _t11, _t12, _t13]:
		await _close_all()
		await scenario.call()
	await _close_all()
	await _close_world()
	await _open_world("skea")
	await _skea()
	await _close_world()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(content.get("storage_path")))
	content.call("load_settings", old_content)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_THIRST_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


func _open_world(hero: String) -> void:
	root.get_node("GameState").p1_character = hero
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	hunger = world.hunger
	thirst = world.thirst
	player = world.player
	progress = world.progress
	npc = world.npc_director
	drank.clear()
	thirst.drank.connect(func(source: String, gained: int) -> void: drank.append([source, gained, thirst.centi]))
	await _ticks(20)
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(30)


func _close_world() -> void:
	world.queue_free()
	await _ticks(3)


## T0: a scripted run keeps W at 100 and nothing ticks; the row says WATER 100%; no hint, no sound.
func _t0() -> void:
	sfx.last_frame.erase("thirst_cue")
	_check(not thirst.running and thirst.centi == FULL and thirst.has_source(), "T0 a scripted run: W 100, no clock, the pump is there (%s, %d, %s)" % [thirst.running, thirst.centi, thirst.has_source()])
	await _ticks(120)
	_check(thirst.centi == FULL and not sfx.last_frame.has("thirst_cue") and world.hud.water_label.visible and world.hud.water_label.text == "WATER 100%", "T0 after 120 frames W is still 100; no cue; «%s»" % world.hud.water_label.text)


## T1: the rate — 3000 real frames → 97.50; the thresholds by simulate (the same per-frame step); W 0 → the collapse.
func _t1() -> void:
	_level(FULL, FULL)
	await _ticks(3000)
	_check(thirst.centi == 9750, "T1 3000 frames of exploration → 97.50 (%.2f)" % thirst.value())
	_level(FULL, FULL)
	hunger.simulate(60000)
	_check(thirst.centi == 5000 and thirst.band() == "thirsty", "T1 60 000 frames → 50.00, thirsty (%.2f, %s)" % [thirst.value(), thirst.band()])
	hunger.simulate(30000)
	_check(thirst.centi == 2500 and thirst.band() == "parched", "T1 90 000 frames → 25.00, parched (%.2f, %s)" % [thirst.value(), thirst.band()])
	hunger.simulate(18000)
	_check(thirst.centi == 1000 and thirst.band() == "faint", "T1 108 000 frames → 10.00, faint (%.2f, %s)" % [thirst.value(), thirst.band()])
	hunger.simulate(11999)
	_check(thirst.centi == 1 and hunger.collapse_phase.is_empty(), "T1 119 999 frames → 0.01, still standing (%.2f, %s)" % [thirst.value(), hunger.collapse_phase])
	hunger.simulate(1)
	_check(hunger.collapse_phase == "fall" and hunger.last_collapse_cause == "thirst", "T1 120 000 frames → the collapse from thirst (%s, %s)" % [hunger.collapse_phase, hunger.last_collapse_cause])
	await _until(func() -> bool: return hunger.collapse_phase.is_empty(), 200)


## T2: W stands in the pause, a conversation, the pocket and the collapse.
func _t2() -> void:
	_level(8000, 8000)
	world.hud.set_paused(true)
	await _ticks(300)
	_check(thirst.centi == 8000, "T2 the pause: 300 frames, W unchanged (%d)" % thirst.centi)
	world.hud.set_paused(false)
	var shop: Dictionary = CityPlaces.shops()[0]
	player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(30)
	_level(8000, 8000)
	_check(npc.open_conversation(0), "T2 Mira talks")
	if mutation == "gate":
		router.release_ui(npc.dialogue)   # the negative: the conversation no longer stops the clock
	await _ticks(300)
	_check(thirst.centi == 8000, "T2 a conversation: 300 frames, W unchanged (%d)" % thirst.centi)
	npc.dialogue.close()
	player.restart_at(SAFE_POINT)
	await _ticks(30)
	_level(8000, 8000)
	if mutation == "pocket_clock":
		hunger.lethal = null   # the negative: the clock no longer sees the pocket
	_check(world.lethal.request_open(), "T2 the pocket opens")
	await _ticks(300)
	_check(thirst.centi == 8000, "T2 the lethal pocket: 300 frames, W unchanged (%d)" % thirst.centi)
	world.lethal.close("abort")
	hunger.lethal = world.lethal
	await _ticks(3)
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(1, 6001)   # W 60.01 → 60.00 on frame 12; H 0 on frame 18
	await _until(func() -> bool: return hunger.collapse_phase == "fall", 40)
	var during: int = thirst.centi
	await _until(func() -> bool: return hunger.collapse_phase.is_empty(), 200)
	_check(during == 6000 and thirst.centi == 6000, "T2 the collapse (from hunger): W stands through the fall and the wake (%d, %d)" % [during, thirst.centi])


## The dodge refill of one second on CityFighter's own tick (stamina 0, no wait, free control).
func _refill_per_second() -> float:
	player.set_control(true)
	player.dodge_stamina = 0.0
	player._dodge_regen_wait = 0.0
	for frame: int in 60:
		player._tick_dodge_stamina(1.0 / 60.0)
	return player.dodge_stamina


## T3: B = max(band(H), band(W)) — never the product, never W ignored, one hp tick.
func _t3() -> void:
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(FULL, FULL)
	var base_walk: float = player.speed_mult()
	for row: Array in [[6000, 4000, 1, 1.0, 22.5, true], [2000, 4000, 2, 0.85, 18.0, false], [4000, 2000, 2, 0.85, 18.0, false], [800, 800, 3, 0.75, 15.0, false]]:
		_level(int(row[0]), int(row[1]))
		var walk: float = player.speed_mult() / base_walk
		var refill: float = _refill_per_second()
		var walls: bool = player.wall_run_allowed() and player.parkour._wall_run_allowed(player)
		_check(hunger.body_band_index() == row[2] and is_equal_approx(walk, row[3]) and absf(refill - float(row[4])) < 0.01 and walls == row[5], "T3 H %d + W %d → B %d: walk × %.2f (%.4f), refill %.1f / s (%.3f), wall steps %s (%s)" % [int(row[0]) / 100, int(row[1]) / 100, row[2], row[3], walk, row[4], refill, row[5], walls])
	_level(800, 800, CHOKO_HP)
	await _ticks(150)
	var half: float = player.hp
	await _ticks(150)
	var one: float = player.hp
	await _ticks(300)
	_check(is_equal_approx(half, CHOKO_HP) and is_equal_approx(one, CHOKO_HP - 10.5) and is_equal_approx(player.hp, CHOKO_HP - 21.0), "T3 H 8 + W 8: one tick, −1 %% per 300 frames — nothing at 150, −1 %% at 300, −2 %% at 600 (%.1f → %.1f → %.1f)" % [half, one, player.hp])
	_level(1000, 1000, 625.0)
	hunger.simulate(300 * 25)
	_check(is_equal_approx(hunger.city_hp, FLOOR), "T3 faint by both: never below the 40 %% floor (%.1f)" % hunger.city_hp)
	_level(FULL, 900, 500.0)
	hunger.simulate(1500)
	_check(is_equal_approx(hunger.city_hp, 500.0 - 52.5), "T3 faint from W alone (H 100): the same drain, −5 %% in 1500 frames (%.1f)" % hunger.city_hp)
	_level(FULL, FULL, CHOKO_HP)


## T4: the walk's floor (T5 § 3.3 МТ1): faint × «Заплутаність» × fatigue 1.0 ≥ run_min_speed for the slowest hero.
func _t4() -> void:
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(800, 800)
	player.fatigue = 1.0
	var w_before: int = thirst.centi
	world.haze.begin()
	world.haze._elapsed = 10.0   # past the 3 s ramp: the full weight
	var speed: float = player.data.walk_speed * player.speed_mult()
	_check(absf(speed - 3.21) <= 0.02 and speed >= 3.0, "T4 faint + haze + fatigue: Choko walks %.3f m/s (3.21 ± 0.02, ≥ 3.0)" % speed)
	_check(thirst.centi == w_before, "T9 (also) the haze starting leaves W as it was (%d → %d)" % [w_before, thirst.centi])
	player.fatigue = 0.0
	world.haze.clear()


## T5: the pump — real key and pad, free, W only.
func _t5() -> void:
	player.restart_at(AT_PUMP)
	player._set_forward(Vector3.LEFT)
	await _ticks(30)
	_level(6000, 3700, CHOKO_HP, 4)
	await _ticks(2)
	var prompt: String = world.hud._story_prompt
	var key_label: String = router.binding_label(1, "interact", false)
	_check(thirst.can_drink(player) and prompt == key_label + " · Drink water · free", "T5 at the spout the prompt names the real key («%s»)" % prompt)
	world.haze.begin()
	world.haze._elapsed = 10.0
	var h_before: int = hunger.centi
	drank.clear()
	await _tap_interact()
	_check(drank.size() == 1 and int(drank[0][2]) == FULL and int(drank[0][1]) == FULL - 3700, "T5 the key: W 37 → 100 (%s)" % [drank])
	_check(hunger.centi <= h_before and h_before - hunger.centi <= 1, "T5 the pump gives no H (%d → %d)" % [h_before, hunger.centi])
	_check(progress.credits() == 4, "T5 the pump takes no token (%d)" % progress.credits())
	_check(world.haze.haze_active() and world.haze.haze_remaining() > 60.0, "T5 the pump does not shorten «Заплутаність» (%.1f s left)" % world.haze.haze_remaining())
	world.haze.clear()
	thirst.set_centi(4200)
	drank.clear()
	await _pad_interact()
	_check(drank.size() == 1 and int(drank[0][2]) == FULL, "T5 the pad (Y + D-pad Down): W 42 → 100 (%s)" % [drank])
	player.restart_at(AT_PUMP + Vector3(2.5, 0.0, 0.0))
	await _ticks(20)
	_check(not thirst.can_drink(player) and not world.hud._story_prompt.ends_with("Drink water · free"), "T5 out of reach (2.5 m further): no prompt («%s»)" % world.hud._story_prompt)
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)


## T6: drinks that are food — the tea +25 H and +30 W, the loaf W +0, W never above 100.
func _t6() -> void:
	_level(6000, 4000, CHOKO_HP, 5)
	world.haze.begin()   # the haze's start lowers H (T5 § 6): put H back to 60 after it
	world.haze._elapsed = 10.0
	hunger.set_centi(6000)
	var fed: Dictionary = hunger.feed("tea")
	_check(bool(fed.ok) and hunger.centi == 8500 and thirst.centi == 7000 and world.haze.haze_remaining() <= 10.001, "T6 the tea: H +25, W +30, the haze fades (%.2f, %.2f, %.1f s)" % [hunger.value(), thirst.value(), world.haze.haze_remaining()])
	world.haze.clear()
	_level(4000, 4000, CHOKO_HP, 5)
	fed = hunger.feed("loaf")
	_check(bool(fed.ok) and hunger.centi == FULL and thirst.centi == 4000, "T6 the loaf: W +0 (%.2f)" % thirst.value())
	_level(5000, 9000, CHOKO_HP, 5)
	fed = hunger.feed("tea")
	_check(bool(fed.ok) and thirst.centi == FULL, "T6 never above 100: the tea at W 90 → 100 (%.2f)" % thirst.value())
	_level(FULL, FULL, CHOKO_HP, 5)
	_check(not bool(hunger.food_state("tea").enabled) and hunger.food_state("tea").reason == "ти ситий", "T6 the tea at H 100 and W 100: «ти ситий» (%s)" % hunger.food_state("tea").reason)
	_level(FULL, 6000, CHOKO_HP, 5)
	_check(bool(hunger.food_state("tea").enabled), "T6 the tea at H 100 but W 60: it can be had (W rises)")


## T9: the haze's start never touches W.
func _t9() -> void:
	for level: int in [6123, 900, FULL]:
		_level(8000, level)
		world.haze.begin()
		_check(thirst.centi == level, "T9 the haze starts: W %d stays %d" % [level, thirst.centi])
		world.haze.clear()


## T10: one collapse for both scales.
func _t10() -> void:
	var resume: Vector3 = world.journey.resume_position()
	for row: Array in [
			# H, W, tokens, cause, H after, W after, tokens after
			[8000, 1, 5, "thirst", 8000, 3000, 2],
			[1, 7001, 2, "hunger", 3000, 7000, 0],
			[2, 3, 5, "both", 3000, 3000, 2],
			[200, 1, 0, "thirst", 3000, 3000, 0]]:
		player.restart_at(Vector3(-6.0, 0.0, 20.0))
		await _ticks(10)
		_level(int(row[0]), int(row[1]), FLOOR, int(row[2]))
		var collapses: Array[int] = [0]
		var counter := func(_lost: int) -> void: collapses[0] += 1
		hunger.collapsed.connect(counter)
		await _until(func() -> bool: return hunger.collapse_phase == "fall", 60)
		_check(hunger.last_collapse_cause == row[3], "T10 H %.2f W %.2f → the collapse from %s (%s)" % [int(row[0]) / 100.0, int(row[1]) / 100.0, row[3], hunger.last_collapse_cause])
		await _until(func() -> bool: return hunger.collapse_phase.is_empty(), 200)
		await _ticks(2)
		hunger.collapsed.disconnect(counter)
		var at: Vector3 = player.global_position
		_check(collapses[0] == 1 and hunger.centi == row[4] and thirst.centi == row[5] and progress.credits() == row[6] and player.hp >= FLOOR - 0.001 and Vector2(at.x - resume.x, at.z - resume.z).length() < 0.5, "T10 %s: one collapse (%d), H %.2f, W %.2f, tokens %d, hp %.0f, at the safe point" % [row[3], collapses[0], hunger.value(), thirst.value(), progress.credits(), player.hp])
		var words: String = {"thirst": "You collapsed from thirst · lost %d tokens", "hunger": "You collapsed from hunger · lost %d tokens", "both": "You collapsed from hunger and thirst · lost %d tokens"}[row[3]] % (int(row[2]) - int(row[6]))
		_check(world.hud.hint_label.visible and world.hud.hint_label.text == words, "T10 the words «%s» (%s)" % [words, world.hud.hint_label.text])
	world.hud._body_queue.clear()


## T11: the lethal pocket with the city's thirst (Santos «Повний перенос»).
func _t11() -> void:
	for row: Array in [[8000, 4000, 22.5, "THIRSTY · slower stamina"], [8000, 2000, 18.0, "PARCHED · slower stamina and walk"], [4000, 4000, 22.5, "HUNGRY · THIRSTY"]]:
		player.restart_at(SAFE_POINT)
		await _ticks(30)
		_level(int(row[0]), int(row[1]), 630.0)
		if not world.lethal.request_open():
			_check(false, "T11 the pocket opens at H %d W %d" % [int(row[0]) / 100, int(row[1]) / 100])
			continue
		await _ticks(1)
		var line: String = world.lethal.hud.resources_label.text
		var width: float = world.lethal.hud.resources_label.get_minimum_size().x
		_check(line.ends_with(" · " + row[3]) and width <= 644.0, "T11 H %d W %d: the line ends «%s», %.0f ≤ 644 px (%s)" % [int(row[0]) / 100, int(row[1]) / 100, row[3], width, line])
		await _until(func() -> bool: return world.lethal.flow != null and int(world.lethal.flow.phase) == 1, 200)
		world.lethal.enemy.set_control(false)
		var frozen: int = thirst.centi
		player.dodge_stamina = 0.0
		player._dodge_regen_wait = 0.0
		await _ticks(60)
		_check(absf(player.dodge_stamina - float(row[2])) < 0.05, "T11 H %d W %d: the dodge refills %.1f in a second of the fight (%.3f)" % [int(row[0]) / 100, int(row[1]) / 100, row[2], player.dodge_stamina])
		await _ticks(120)
		_check(thirst.centi == frozen, "T11 W stands in the fight (%d → %d)" % [frozen, thirst.centi])
		player.set_round_hp(100.0)
		world.lethal.retry()
		await _ticks(2)
		var retry_hp: float = player.hp
		await _until(func() -> bool: return world.lethal.flow != null and int(world.lethal.flow.phase) == 1, 200)
		world.lethal.enemy.set_control(false)
		player.dodge_stamina = 0.0
		player._dodge_regen_wait = 0.0
		await _ticks(60)
		_check(is_equal_approx(retry_hp, 630.0) and absf(player.dodge_stamina - float(row[2])) < 0.05, "T11 RETRY: the entry hp 630 and %.1f / s again (%.0f, %.3f)" % [row[2], retry_hp, player.dodge_stamina])
		world.lethal.close("retreat")
		await _ticks(3)
		_check(thirst.centi == frozen, "T11 after the pocket W as before (%d)" % thirst.centi)
	_level(FULL, FULL, CHOKO_HP)


## T12: the save.
func _t12() -> void:
	var path: String = "user://city_thirst_progress_%d.json" % OS.get_process_id()
	var disk: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(disk)
	disk.setup("choko", false, path)
	disk.set_hunger(4321, 777, 2468)
	var again: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(again)
	again.setup("choko", true, path)
	_check(again.save_ok and again.thirst_centi() == 2468 and again.hunger_centi() == 4321, "T12 W survives a reload exactly (%d)" % again.thirst_centi())
	again.set_thirst(1357)
	var third: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(third)
	third.setup("choko", true, path)
	_check(third.save_ok and third.thirst_centi() == 1357, "T12 set_thirst alone survives a reload (%d)" % third.thirst_centi())
	var old_save: String = "{\"version\":1,\"heroes\":{\"choko\":{\"accepted\":[],\"completed\":[],\"events\":{},\"credits\":4,\"palette\":\"original\",\"owned\":[\"original\",\"mint\"],\"hunger\":6000}}}"
	for case: Array in [["old", old_save, true], ["over", old_save.replace("\"credits\":4", "\"credits\":4,\"thirst\":10001"), false], ["negative", old_save.replace("\"credits\":4", "\"credits\":4,\"thirst\":-1"), false], ["fraction", old_save.replace("\"credits\":4", "\"credits\":4,\"thirst\":12.5"), false], ["text", old_save.replace("\"credits\":4", "\"credits\":4,\"thirst\":\"abc\""), false]]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(String(case[1]))
		file.close()
		var before := FileAccess.get_file_as_bytes(path)
		var model: Node = load("res://scripts/npc/CityProgress.gd").new()
		root.add_child(model)
		model.setup("choko", true, path)
		if bool(case[2]):
			_check(model.save_ok and model.thirst_centi() == FULL and model.hunger_centi() == 6000, "T12 an old save without W reads as 100 and stays valid")
		else:
			model.set_thirst(5000)
			_check(not model.save_ok and not model.save_enabled and FileAccess.get_file_as_bytes(path) == before, "T12 a damaged W (%s) is not written over" % case[0])
		model.queue_free()
	for node: Node in [disk, again, third]:
		node.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## T13: no water source, no thirst.
func _t13() -> void:
	var bare := Node.new()
	root.add_child(bare)
	var lone: Node = load("res://scripts/world/CityThirst.gd").new()
	bare.add_child(lone)
	lone.setup(bare, true)
	_check(not lone.running and lone.centi == FULL, "T13 setup with a running clock but no water source: thirst stays off (%s)" % lone.running)
	lone.enable_for_test(4000)
	for frame: int in 3000:
		lone.step_frame()
	_check(not lone.has_source() and not lone.running and lone.centi == FULL and lone.body_band_index() == 0, "T13 a world without a water source: W 100 after 3000 frames, no band (%s, %d)" % [lone.running, lone.centi])
	bare.queue_free()
	var pump: Node = thirst.source
	thirst.source = null
	_level(FULL, 3000)
	if mutation == "source":
		thirst.running = true   # the negative: the scale runs although there is no water source
	hunger.simulate(1200)
	await _ticks(2)
	var refill: float = _refill_per_second()
	_check(thirst.centi == FULL and hunger.body_band_index() == 0 and absf(refill - 30.0) < 0.01 and not world.hud.water_label.visible, "T13 the real world with its pump taken away: W %.2f, B %d, refill %.1f, WATER row %s" % [thirst.value(), hunger.body_band_index(), refill, world.hud.water_label.visible])
	thirst.source = pump
	_level(FULL, FULL)


## H1 (W1): WATER under FOOD in the status card, one rectangle, the card's width.
func _h1() -> void:
	var hud: Node = world.hud
	var rects: Array[Rect2] = []
	var words: Array[String] = []
	for level: int in [FULL, 4500, 2200, 800]:
		_level(FULL, level)
		await _ticks(2)
		rects.append(hud.water_label.get_global_rect())
		words.append(hud.water_label.text)
	var card: Rect2 = hud._status_card.get_global_rect()
	var food: Rect2 = hud.food_bar.get_global_rect()
	_check(card.encloses(rects[0]) and rects[0].position.y >= food.end.y and rects.all(func(r: Rect2) -> bool: return r == rects[0]), "H1 WATER in the card under the FOOD bar, one rectangle at 100 / 45 / 22 / 8 (%s, food bar ends %.1f)" % [rects, food.end.y])
	_check(words == ["WATER 100%", "WATER 45% · THIRSTY", "WATER 22% · PARCHED", "WATER 8% · FAINT"], "H1 the words (%s)" % [words])
	# T8: 390 after the onboarding, 400 while its objective (minimum 380) shows — WATER never widens it.
	var expected: float = 400.0 if hud.objective_label.visible else 390.0
	_check(absf(card.size.x - expected) < 0.5, "H1 the card keeps %.0f wide (%.1f)" % [expected, card.size.x])
	_check(hud.water_bar.framed and hud.health_label.visible, "H1 FAINT from W: the bar gets its frame; HEALTH shows (H 100, full hp)")
	_level(FULL, FULL)


## One crossing on the real clock from `start`: [the hint shown, the cue frame or -1].
func _cross_water(start: int) -> Array:
	_level(FULL, start)
	sfx.last_frame.erase("thirst_cue")
	await _until(func() -> bool: return thirst.centi <= start - 1, 20)
	await _ticks(1)
	return [world.hud.hint_label.text if world.hud.hint_label.visible else "", int(sfx.last_frame.get("thirst_cue", -1))]


## H2 (W2): each band downwards with H 100 — the word, one hint for 3 s, thirst_cue on that frame.
func _h2() -> void:
	for row: Array in [[5001, "THIRSTY · stamina recovers slower · water: the pump on the market square, free"], [2501, "PARCHED · slower walk, no wall steps · drink soon"], [1001, "FAINT · health drains · at 0 you collapse and lose tokens · water: the pump, free"]]:
		var seen: Array = await _cross_water(int(row[0]))
		_check(seen[0] == row[1] and int(seen[1]) > 0, "H2 crossing %d: «%s», thirst_cue on frame %d" % [(int(row[0]) - 1) / 100, seen[0], seen[1]])
	await _ticks(int(3.0 * 60.0) + 4)
	_check(not world.hud.hint_label.visible or not world.hud.hint_label.text.begins_with("FAINT ·"), "H2 the hint goes after 3 s («%s»)" % world.hud.hint_label.text)
	_level(FULL, FULL)


## H3 (W3): H 45, then W crosses 50 — B stays 1: «no extra effect yet»; the refill does not change.
func _h3() -> void:
	_level(4500, 5001)
	var before: float = hunger.dodge_regen_multiplier()
	await _until(func() -> bool: return thirst.centi <= 5000, 20)
	await _ticks(1)
	_check(world.hud.hint_label.text == "THIRSTY · no extra effect yet · water: the pump on the market square, free" and is_equal_approx(hunger.dodge_regen_multiplier(), before), "H3 «%s», refill × %.2f → × %.2f" % [world.hud.hint_label.text, before, hunger.dodge_regen_multiplier()])
	_level(FULL, FULL)


## H4 (W4): H and W cross 50 within 60 ticks — one hint, one cue.
func _h4() -> void:
	_level(5001, 5004)
	sfx.last_frame.erase("hunger_cue")
	sfx.last_frame.erase("thirst_cue")
	await _until(func() -> bool: return hunger.centi <= 5000 and thirst.centi <= 5000, 60)
	await _ticks(1)
	var queue: Array = world.hud._body_queue
	_check(queue.size() == 1 and world.hud.hint_label.text == "HUNGRY · THIRSTY · stamina recovers slower · food: «Шавлія» · water: the pump, free", "H4 one hint «%s» (%d in the queue)" % [world.hud.hint_label.text, queue.size()])
	_check(sfx.last_frame.has("hunger_cue") and not sfx.last_frame.has("thirst_cue"), "H4 one cue (hunger %s, thirst %s)" % [sfx.last_frame.get("hunger_cue", -1), sfx.last_frame.get("thirst_cue", -1)])
	_level(FULL, FULL)


## H5 (W5): B 3 from W with H 100 — HEALTH shows; one 30 s repeat of the cue.
func _h5() -> void:
	_level(FULL, 800)
	await _ticks(2)
	_check(world.hud.health_label.visible, "H5 B 3 from W: HEALTH shows at full hp")
	world.hud._faint_cue_left = 0.05
	var last: int = int(sfx.last_frame.get("thirst_cue", -1))
	await _ticks(6)
	_check(int(sfx.last_frame.get("thirst_cue", -1)) != last and world.hud._faint_cue_left > 29.0, "H5 FAINT repeats the cue every 30 s")
	_level(FULL, FULL)


## H6 (W6): W ±1 around 50 for 20 frames — one hint.
func _h6() -> void:
	var seen: Array = await _cross_water(5001)
	var hints: int = 1 if int(seen[1]) > 0 else 0
	var last: int = int(seen[1])
	for tick: int in 20:
		thirst.set_centi(5001 if tick % 2 == 0 else 4999)
		await _ticks(1)
		if int(sfx.last_frame.get("thirst_cue", -1)) != last:
			hints += 1
			last = int(sfx.last_frame.get("thirst_cue", -1))
	_check(hints == 1, "H6 ±1 around 50 for 20 frames: one hint, one cue (%d)" % hints)
	_level(FULL, FULL)


## H7: FAINT by B, not by the text — a merged hint «HUNGRY · FAINT …» (B 3) is never pushed out (neither by newer
## hints nor by HAZE LIFTING, which does push a hint that is not FAINT).
func _h7() -> void:
	_level(5001, 1004)
	await _until(func() -> bool: return hunger.centi <= 5000 and thirst.centi <= 1000, 80)
	await _ticks(1)
	var merged: String = "HUNGRY · FAINT · health drains · at 0 you collapse and lose tokens · food: «Шавлія» · water: the pump, free"
	_check(world.hud.hint_label.text == merged, "H7 the merged hint «%s»" % world.hud.hint_label.text)
	world.hud.push_body_hint("TEST · a newer hint", 3.0)
	world.hud.push_body_hint("TEST · and another", 3.0)
	world.hud._haze_fades_left = 2.0
	await _ticks(2)
	_check(world.hud.hint_label.text == merged, "H7 B 3: the merged FAINT hint stays in front of newer hints and HAZE LIFTING («%s»)" % world.hud.hint_label.text)
	world.hud._body_queue.clear()
	world.hud.push_body_hint("THIRSTY · no extra effect yet · water: the pump on the market square, free", 3.0, false, "water", 1)
	world.hud._haze_fades_left = 2.0
	await _ticks(2)
	_check(world.hud.hint_label.text == "HAZE LIFTING · Steps and view come back", "H7 a hint that is not FAINT yields to HAZE LIFTING («%s»)" % world.hud.hint_label.text)
	world.hud._haze_fades_left = 0.0
	world.hud._body_queue.clear()
	_level(FULL, FULL)


## H8 (W13): the pause help names food and water in one row of the 1000 px column.
func _h8() -> void:
	var line: String = ""
	for row: String in world.hud.exploration_help().split("\n"):
		if "Water: the pump" in row:
			line = row
	var font: Font = world.hud.resource_label.get_theme_font("font")
	var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	_check(not line.is_empty() and line.ends_with("Food: «Шавлія» · Water: the pump") and width <= 1000.0, "H8 the pause line «%s» is %.1f ≤ 1000 px" % [line, width])


## S: Skea — the pump by the pad, the body band from W.
func _skea() -> void:
	_check(player.data.id == "skea" and thirst.has_source(), "S Skea's city has the pump")
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(FULL, FULL)
	var base_walk: float = player.speed_mult()
	_level(FULL, 2000)
	_check(hunger.body_band_index() == 2 and is_equal_approx(player.speed_mult() / base_walk, 0.85) and not player.wall_run_allowed(), "S Skea at W 20: B 2, walk × 0.85, no wall steps")
	player.restart_at(AT_PUMP)
	player._set_forward(Vector3.LEFT)
	await _ticks(30)
	_level(FULL, 3700, 900.0, 2)
	drank.clear()
	await _pad_interact()
	_check(drank.size() == 1 and int(drank[0][2]) == FULL and progress.credits() == 2, "S Skea drinks by the pad: W → 100, tokens 2 (%s)" % [drank])
