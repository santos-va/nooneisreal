extends SceneTree
## Plan docs/Plans/2026-10-08-Survival-Hunger.md step 4 — the hunger scale (CityHunger) in the real CityWorld (saves off),
## Choko, against T5's list (docs/GDD/2026-10-08-Hunger-Numbers.md § 9), Santos's «Повний перенос» (ADR-025 п. 4) and the
## T8 HUD (06-UI-UX § «Шкала голоду в HUD міста»).
## Subject: for every frame of city play H loses one hundredth per 18 frames and nothing else changes it except food,
## the state and the collapse; the clock stands in the pause, a conversation and the pocket; each band's body effects are
## exact and the floor holds; H = 0 always ends at the safe point with H 30, hp ≥ 40 % and −min(tokens, 3); the pocket
## takes the city hp (≥ the floor), the band's refill and walk, and RETRY gives the entry hp back; Mira's crust only on
## its condition; the save keeps H exactly, an old save reads as 100, a damaged one is never written over.
##   K0 a scripted run: H fixed at 100, no clock, no hint, no sound (T8 N5);
##   K1 3000 frames of exploration → 98.34 (real frames); 90 000 → 50.00 (simulate = the same per-frame step);
##   K2 the pause, Mira's conversation and the lethal pocket: 300 frames each, H unchanged;
##   K3 per band (60 / 40 / 20 / 8): walk × 1 / 1 / 0.85 / 0.75, dodge refill 30 / 22.5 / 18 / 15 per s, wall steps
##      yes / yes / no / no (CityFighter and CityParkourMotor);
##   K4 hp: faint −1 % every 300 frames down to 40 % and never below; below the floor neither drain nor rise; sated +1 %
##      per 360 frames, hungry per 720, famished stands;
##   K5 H = 0: the KO presentation, the dark, the safe point, H 30, −min(tokens, 3) (5 → 2; 2 → 0), hp ≥ 40 %, the hint;
##   K6 the state: H 100 → 45, 15 → 11, 5 → 5; a renewal does not lower it again;
##   K7 the pocket at H 40 and 60: entry hp = city hp (≥ floor), refill 22.5 / 30 per s, H stands, RETRY → entry hp,
##      after the pocket the city hp; the pocket's HUD word;
##   K8 the crust: only with 0 tokens and H ≤ 25, then not for 15 min of hunger time; reasons in words;
##   K9 Mira's counter: first when hungry, three foods with gain / result / price, the tea in the state fades it (10 s),
##      the loaf does not; focus kept; «ти ситий» at 100; ui_confirm;
##   K10 the save: round trip; an old save → 100; a damaged H (10001, -1, 12.5, "abc") → not written over;
##   K11 HUD: FOOD in the status card, one rectangle at 100 / 45 / 22 / 8; a crossing → word, one 3 s hint, hunger_cue on
##      that frame; ±1 around a threshold for 20 frames → one hint; HEALTH only below max or in FAINT; FAINT repeats the
##      cue; the pocket hides the card.
## Literals (T5 § 2–6, T8): 18 frames, 98.34 / 50.00, thresholds 50 / 25 / 10, × 0.75 / 0.6 / 0.5, × 0.85 / 0.75, 1 % per
## 360 / 720 / 300 frames, floor 40 %, H 30, −3, haze 20 / 45 / 11, food +25 / 1, +60 / 2, +30 / 0, crust ≤ 25 and 54 000
## frames, hysteresis +5.
## --break=rate|gate|pocket_clock|floor|collapse|haze|retry|crust are negative controls.
## Sentinel: CITY_HUNGER_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_HUNGER: ...".
const FULL := 10000
const CHOKO_HP := 1050.0
const FLOOR := 420.0
const SAFE_POINT := Vector3(0.0, 0.0, 9.5)
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var router: Node
var world: Node
var hunger: Node
var player: Node
var progress: Node
var npc: Node
var sfx: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_HUNGER: " + label)


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


func _labels() -> Array[String]:
	var labels: Array[String] = []
	for child: Node in npc.dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and not child.has_meta("close"):
			labels.append(str(child.get_meta("full_text", child.text)))
	return labels


func _button(prefix: String) -> Button:
	for child: Node in npc.dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and str(child.get_meta("full_text", child.text)).begins_with(prefix):
			return child
	return null


func _press(prefix: String) -> bool:
	var button: Button = _button(prefix)
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	await _ticks(2)
	return true


func _focused() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return str(owner.get_meta("full_text", owner.text)) if owner is Button else ""


func _close_all() -> void:
	if npc.dialogue.opened:
		npc.dialogue.close()
	if world.lethal.active:
		world.lethal.close("abort")
	if world.hud.paused_ui:
		world.hud.set_paused(false)
	if world.haze.haze_active():
		world.haze.clear()
	await _ticks(3)


## Level, hp and tokens for a scenario; the clock running (enable_for_test), the counters fresh.
func _level(level: int, hp: float = CHOKO_HP, tokens: int = -1) -> void:
	hunger.enable_for_test(level)
	hunger.city_hp = hp
	player.set_round_hp(hp)
	if tokens >= 0:
		progress.spend_credits(progress.credits())
		progress.earn_credits(tokens)
	# The level was set, not crossed: the HUD arms only the thresholds above it and forgets older hints.
	world.hud._body_queue.clear()
	world.hud.bind_hunger(hunger)


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	sfx = root.get_node("Sfx")
	var state: Node = root.get_node("GameState")
	var content: Node = root.get_node("ContentSettings")
	var old_content: String = content.get("storage_path")
	content.call("load_settings", "user://city_hunger_content_%d.cfg" % OS.get_process_id())
	content.call("mark_notice_seen")   # the pocket opens at once (K2, K7)
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
	hunger = world.hunger
	player = world.player
	progress = world.progress
	npc = world.npc_director
	await _ticks(20)
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(30)
	await _k0()
	if mutation == "rate":
		hunger.decay_frames = 20
	if mutation == "floor":
		hunger.hp_floor_ratio = 0.0
	if mutation == "collapse":
		hunger.collapse_tokens = 0
	if mutation == "haze":
		hunger.haze_cap = FULL
	if mutation == "crust":
		hunger.crust_max_h = FULL
	for scenario: Callable in [_k1, _k11, _k2, _k3, _k4, _k5, _k6, _k7, _k8, _k9, _k10]:
		await _close_all()
		await scenario.call()
	await _close_all()
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
	print("CITY_HUNGER_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


## K0: a scripted run keeps H at 100 and nothing ticks; no hint, no sound.
func _k0() -> void:
	sfx.last_frame.erase("hunger_cue")
	_check(not hunger.running and hunger.centi == FULL, "K0 a scripted run starts with H 100 and no clock (%s, %d)" % [hunger.running, hunger.centi])
	await _ticks(120)
	_check(hunger.centi == FULL and not sfx.last_frame.has("hunger_cue") and world.hud.food_label.text == "FOOD 100%", "K0 after 120 frames H is still 100; no cue; «%s»" % world.hud.food_label.text)


## K1: the clock — 3000 real frames → 98.34; 90 000 frames of the same step → 50.00.
func _k1() -> void:
	_level(FULL)
	await _ticks(3000)
	_check(hunger.centi == 9834, "K1 3000 frames of exploration → 98.34 (%.2f)" % hunger.value())
	_level(FULL)
	hunger.simulate(90000)
	_check(hunger.centi == 5000 and hunger.band() == "hungry", "K1 90 000 frames → 50.00, hungry (%.2f, %s)" % [hunger.value(), hunger.band()])


## K2: the clock stands in the pause, a conversation and the pocket.
func _k2() -> void:
	_level(8000)
	world.hud.set_paused(true)
	await _ticks(300)
	_check(hunger.centi == 8000, "K2 the pause: 300 frames, H unchanged (%d)" % hunger.centi)
	world.hud.set_paused(false)
	_level(8000)
	var shop: Dictionary = CityPlaces.shops()[0]
	player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(30)
	_level(8000)
	_check(npc.open_conversation(0), "K2 Mira talks")
	if mutation == "gate":
		router.release_ui(npc.dialogue)   # the negative: the conversation no longer stops the clock
	await _ticks(300)
	_check(hunger.centi == 8000, "K2 a conversation: 300 frames, H unchanged (%d)" % hunger.centi)
	npc.dialogue.close()
	player.restart_at(SAFE_POINT)
	await _ticks(30)
	_level(8000)
	if mutation == "pocket_clock":
		hunger.lethal = null   # the negative: the clock no longer sees the pocket
	_check(world.lethal.request_open(), "K2 the pocket opens")
	await _ticks(300)
	_check(hunger.centi == 8000, "K2 the lethal pocket: 300 frames, H unchanged (%d)" % hunger.centi)
	world.lethal.close("abort")
	hunger.lethal = world.lethal
	await _ticks(3)


## The dodge refill of one second on CityFighter's own tick (stamina 0, no wait, free control).
func _refill_per_second() -> float:
	player.set_control(true)
	player.dodge_stamina = 0.0
	player._dodge_regen_wait = 0.0
	for frame: int in 60:
		player._tick_dodge_stamina(1.0 / 60.0)
	return player.dodge_stamina


## K3: the bands' body effects.
func _k3() -> void:
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(FULL)
	var base_walk: float = player.speed_mult()
	var rows: Array = [[6000, "sated", 1.0, 30.0, true], [4000, "hungry", 1.0, 22.5, true], [2000, "famished", 0.85, 18.0, false], [800, "faint", 0.75, 15.0, false]]
	for row: Array in rows:
		_level(int(row[0]))
		var walk: float = player.speed_mult() / base_walk
		var refill: float = _refill_per_second()
		var walls: bool = player.wall_run_allowed() and player.parkour._wall_run_allowed(player)
		_check(hunger.band() == row[1] and is_equal_approx(walk, row[2]) and absf(refill - float(row[3])) < 0.01 and walls == row[4], "K3 H %d → %s: walk × %.2f (%.4f), refill %.1f / s (%.3f), wall steps %s (%s)" % [int(row[0]) / 100, row[1], row[2], walk, row[3], refill, row[4], walls])
	_check(not ("hunger" in (load("res://scripts/fighter/Fighter.gd") as Script).get_script_property_list().map(func(p: Dictionary) -> String: return p.name)), "K3 Fighter (the duel) has no hunger field")


## K4: hp in the city by band; the floor.
func _k4() -> void:
	_level(800, CHOKO_HP)
	await _ticks(300)
	_check(is_equal_approx(player.hp, CHOKO_HP - 10.5) and is_equal_approx(hunger.city_hp, CHOKO_HP - 10.5), "K4 faint: −1 %% after 300 real frames (%.1f)" % player.hp)
	# 625 is not a whole number of 10.5 steps above the floor: the last step must stop at 420, not at 415.
	_level(1000, 625.0)
	hunger.simulate(300 * 21)
	_check(is_equal_approx(hunger.city_hp, FLOOR) and hunger.band() == "faint", "K4 faint: 21 ticks take 625 down to the 40 %% floor exactly, never past it (%.1f)" % hunger.city_hp)
	hunger.simulate(300 * 8)
	_check(is_equal_approx(hunger.city_hp, FLOOR), "K4 faint: never below the floor (%.1f, H %.2f)" % [hunger.city_hp, hunger.value()])
	_level(900, 300.0)
	hunger.simulate(300 * 4)
	_check(is_equal_approx(hunger.city_hp, 300.0), "K4 below the floor: no drain and no rise to it (%.1f)" % hunger.city_hp)
	_level(9000, 500.0)
	hunger.simulate(360)
	_check(is_equal_approx(hunger.city_hp, 510.5), "K4 sated: +1 %% per 360 frames (%.1f)" % hunger.city_hp)
	_level(4000, 500.0)
	hunger.simulate(719)
	var before: float = hunger.city_hp
	hunger.simulate(1)
	_check(is_equal_approx(before, 500.0) and is_equal_approx(hunger.city_hp, 510.5), "K4 hungry: +1 %% per 720 frames, not before (%.1f → %.1f)" % [before, hunger.city_hp])
	_level(2000, 500.0)
	hunger.simulate(1500)
	_check(is_equal_approx(hunger.city_hp, 500.0), "K4 famished: hp stands (%.1f)" % hunger.city_hp)
	player.restart_at(Vector3(0.0, 0.0, 20.0))   # restart_at refills hp; the city's value must stand
	await _ticks(2)
	_check(is_equal_approx(player.hp, 500.0), "K4 a restart refills nothing: the city hp stands (%.1f)" % player.hp)
	_level(FULL, CHOKO_HP)
	await _ticks(2)


## K5: H = 0 — the collapse.
func _k5() -> void:
	var resume: Vector3 = world.journey.resume_position()
	player.restart_at(Vector3(-6.0, 0.0, 20.0))
	await _ticks(10)
	_level(1, FLOOR, 5)
	await _until(func() -> bool: return hunger.collapse_phase == "fall", 40)
	_check(hunger.collapse_phase == "fall" and player.control_locked and int(player.state) == _state("KO") and is_equal_approx(player.hp, FLOOR), "K5 H 0: the body drops (KO presentation, control locked, hp untouched %.0f)" % player.hp)
	await _ticks(75)
	_check(hunger.veil() > 0.5 and world.hud.collapse_veil.visible, "K5 the screen goes dark (%.2f)" % hunger.veil())
	await _until(func() -> bool: return hunger.collapse_phase == "wake", 60)
	var at: Vector3 = player.global_position
	_check(Vector2(at.x - resume.x, at.z - resume.z).length() < 0.5, "K5 the hero wakes at the last safe point %s (%s)" % [resume, at])
	_check(hunger.centi == 3000 and progress.credits() == 2 and player.hp >= FLOOR - 0.001 and hunger.city_hp >= FLOOR - 0.001, "K5 H 30, −min(5, 3) → 2 tokens, hp ≥ 40 %% (%.2f, %d, %.0f)" % [hunger.value(), progress.credits(), player.hp])
	await _until(func() -> bool: return hunger.collapse_phase.is_empty(), 60)
	await _ticks(2)
	_check(not player.control_locked and world.hud.hint_label.visible and world.hud.hint_label.text == "You collapsed from hunger · lost 3 tokens", "K5 control back; «%s»" % world.hud.hint_label.text)
	_level(1, CHOKO_HP, 2)
	await _until(func() -> bool: return hunger.collapse_phase == "wake", 200)
	_check(progress.credits() == 0 and hunger.centi == 3000 and is_equal_approx(player.hp, CHOKO_HP), "K5 with 2 tokens: −2 → 0; full hp stays full (%d, %.0f)" % [progress.credits(), player.hp])
	await _until(func() -> bool: return hunger.collapse_phase.is_empty(), 60)


func _state(state_name: String) -> int:
	return int((load("res://scripts/fighter/Fighter.gd") as GDScript).get_script_constant_map()["State"][state_name])


## K6: «Заплутаність» on its start.
func _k6() -> void:
	for pair: Array in [[FULL, 4500], [1500, 1100], [500, 500], [6500, 4500], [3000, 1100]]:
		_level(int(pair[0]))
		world.haze.begin()
		_check(hunger.centi == int(pair[1]), "K6 the state starts: H %.0f → %.0f (%.2f)" % [int(pair[0]) / 100.0, int(pair[1]) / 100.0, hunger.value()])
		world.haze.clear()
	_level(FULL)
	world.haze.begin()
	hunger.set_centi(4000)
	world.haze.begin()   # a renewal while it lasts
	_check(hunger.centi == 4000, "K6 a renewal does not lower H again (%.2f)" % hunger.value())
	world.haze.clear()


## K7: the lethal pocket with the city's hunger (Santos «Повний перенос»).
func _k7() -> void:
	for row: Array in [[4000, 630.0, 22.5, "HUNGRY · slower stamina"], [6000, 300.0, 30.0, ""]]:
		player.restart_at(SAFE_POINT)
		await _ticks(30)
		_level(int(row[0]), float(row[1]))
		var entry: float = maxf(float(row[1]), FLOOR)
		if not world.lethal.request_open():
			_check(false, "K7 the pocket opens at H %d" % (int(row[0]) / 100))
			continue
		if mutation == "retry":
			world.lethal.entry_hp = -1.0   # the negative: RETRY at full hp
		_check(is_equal_approx(player.hp, entry), "K7 H %d: the pocket takes the city hp %.0f (≥ floor) → %.0f" % [int(row[0]) / 100, float(row[1]), player.hp])
		await _ticks(1)
		var line: String = world.lethal.hud.resources_label.text
		_check((row[3] == "" and not ("HUNGRY" in line)) or (row[3] != "" and line.ends_with(" · " + row[3])), "K7 the pocket's line carries the word «%s» (%s)" % [row[3], line])
		await _until(func() -> bool: return world.lethal.flow != null and int(world.lethal.flow.phase) == 1, 200)
		world.lethal.enemy.set_control(false)
		var frozen: int = hunger.centi
		player.dodge_stamina = 0.0
		player._dodge_regen_wait = 0.0
		await _ticks(60)
		_check(absf(player.dodge_stamina - float(row[2])) < 0.05, "K7 H %d: the dodge refills %.1f in a second of the fight (%.3f)" % [int(row[0]) / 100, row[2], player.dodge_stamina])
		await _ticks(120)
		_check(hunger.centi == frozen, "K7 H stands in the fight (%d → %d)" % [frozen, hunger.centi])
		player.set_round_hp(100.0)
		world.lethal.retry()
		await _ticks(2)
		_check(is_equal_approx(player.hp, entry), "K7 RETRY gives back the entry hp %.0f (%.0f)" % [entry, player.hp])
		player.set_round_hp(250.0)
		world.lethal.close("retreat")
		await _ticks(3)
		_check(is_equal_approx(player.hp, float(row[1])) and hunger.centi == frozen, "K7 after the pocket: the city hp %.0f and H as before (%.0f, %d)" % [float(row[1]), player.hp, hunger.centi])
	_level(FULL, CHOKO_HP)


## K8: Mira's crust.
func _k8() -> void:
	_level(2400, CHOKO_HP, 1)
	_check(not bool(hunger.food_state("crust").enabled) and hunger.food_state("crust").reason == "лише коли жетонів немає", "K8 with a token: no crust (%s)" % hunger.food_state("crust").reason)
	_level(3000, CHOKO_HP, 0)
	_check(not bool(hunger.food_state("crust").enabled) and hunger.food_state("crust").reason == "коли FOOD ≤ 25%", "K8 at H 30: no crust (%s)" % hunger.food_state("crust").reason)
	_level(2400, CHOKO_HP, 0)
	hunger.crust_wait = 0
	var fed: Dictionary = hunger.feed("crust")
	_check(bool(fed.ok) and hunger.centi == 5400 and progress.credits() == 0 and hunger.crust_wait == 54000, "K8 0 tokens and H 24: the crust, +30 for 0 (%.2f, wait %d)" % [hunger.value(), hunger.crust_wait])
	hunger.set_centi(2400)
	_check(not bool(hunger.food_state("crust").enabled) and hunger.food_state("crust").reason == "Міра пригостить пізніше", "K8 not twice in 15 min (%s)" % hunger.food_state("crust").reason)
	hunger.set_centi(FULL)
	hunger.simulate(53999)
	hunger.set_centi(2400)
	_check(not bool(hunger.food_state("crust").enabled), "K8 still not after 53 999 frames")
	hunger.set_centi(FULL)
	hunger.simulate(1)
	hunger.set_centi(2400)
	_check(bool(hunger.food_state("crust").enabled), "K8 again after 54 000 frames of hunger time")
	hunger.crust_wait = 0


## K9: Mira's counter in the real conversation.
func _k9() -> void:
	var shop: Dictionary = CityPlaces.shops()[0]
	player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(30)
	_level(4000, CHOKO_HP, 3)
	_check(npc.open_conversation(0), "K9 Mira talks")
	var labels: Array[String] = _labels()
	_check(not labels.is_empty() and labels[0] == "Поїсти · FOOD 40% · жетони 3" and _focused() == labels[0], "K9 hungry: the counter first and focused (%s, %s)" % [labels.slice(0, 2), _focused()])
	await _press("Поїсти")
	labels = _labels()
	# Plan 2026-10-08-Thirst-Substances-Icons step 2: the healthy food of T7 Л1 follows the three (T5 § 5.2 numbers).
	_check(labels == ["Відвар шавлії · FOOD +25% » 65% · WATER +30% » 100% · 1 жет.", "Житній буханець · FOOD +60% » 100% · 2 жет.", "Окраєць у борг · FOOD +30% » 70% · 0 жет. · лише коли жетонів немає",
		"Мочені яблука · FOOD +15% » 55% · VITAMINS 10:00 · 1 жет.", "Узвар · FOOD +15% » 55% · WATER +30% » 100% · VITAMINS 10:00 · 1 жет.", "Два яйця в мундирі · FOOD +15% » 55% · STRENGTH 15:00 · 1 жет.", "Пиріжок із сиром · FOOD +40% » 80% · STRENGTH 15:00 · 2 жет.",
		"Назад до розмови"], "K9 the counter: three foods and four healthy ones, gain → result · effect · price, the crust shown with its reason (%s)" % [labels])
	_check(npc.dialogue.body.text.begins_with("Припаси «Шавлії» · Жетони: 3 · FOOD 40%"), "K9 the heading (%s)" % npc.dialogue.body.text.get_slice("\n", 0))
	sfx.last_frame.erase("ui_confirm")
	_button("Відвар шавлії").grab_focus()
	await _press("Відвар шавлії")
	_check(progress.credits() == 2 and hunger.centi == 6500 and sfx.last_frame.has("ui_confirm") and _focused().begins_with("Відвар шавлії · FOOD +25% » 90% · WATER +30% » 100% · 1 жет."), "K9 the tea: −1, +25, ui_confirm, the focus stays on it (%d, %.2f, %s)" % [progress.credits(), hunger.value(), _focused()])
	await _press("Житній буханець")
	_check(progress.credits() == 0 and hunger.centi == FULL and _focused() == "Назад до розмови", "K9 the loaf: −2, up to 100 not past it; nothing left to buy → focus on «Назад» (%d, %.2f, %s)" % [progress.credits(), hunger.value(), _focused()])
	_check(_button("Відвар шавлії").disabled and str(_button("Відвар шавлії").get_meta("full_text")).ends_with("· ти ситий"), "K9 at 100: «ти ситий» (%s)" % _button("Відвар шавлії").get_meta("full_text"))
	npc.dialogue.close()
	await _ticks(2)
	# In the state: the tea lets it fade (10 s), the loaf does not (T1: the tea's property).
	_level(6000, CHOKO_HP, 3)
	world.haze.begin()
	hunger.set_centi(6000)
	npc.open_conversation(0)
	await _press("Поїсти")
	await _press("Житній буханець")
	_check(world.haze.haze_remaining() > 60.0 and progress.credits() == 1, "K9 in the state the loaf does not end it (%.1f s left)" % world.haze.haze_remaining())
	hunger.set_centi(6000)
	await _press("Назад до розмови")
	await _press("Поїсти")
	await _press("Відвар шавлії")
	_check(world.haze.haze_active() and world.haze.haze_remaining() <= 10.001 and progress.credits() == 0, "K9 in the state the tea leaves at most the 10 s fade (%.2f)" % world.haze.haze_remaining())
	npc.dialogue.close()
	world.haze.clear()
	await _ticks(2)


## K10: the save.
func _k10() -> void:
	var path: String = "user://city_hunger_progress_%d.json" % OS.get_process_id()
	var disk: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(disk)
	disk.setup("choko", false, path)
	disk.set_hunger(4321, 777)
	var again: Node = load("res://scripts/npc/CityProgress.gd").new()
	root.add_child(again)
	again.setup("choko", true, path)
	_check(again.save_ok and again.hunger_centi() == 4321 and again.crust_wait() == 777, "K10 H and the crust wait survive a reload (%d, %d)" % [again.hunger_centi(), again.crust_wait()])
	var old_save: String = "{\"version\":1,\"heroes\":{\"choko\":{\"accepted\":[],\"completed\":[],\"events\":{},\"credits\":4,\"palette\":\"original\",\"owned\":[\"original\",\"mint\"]}}}"
	for case: Array in [["old", old_save, true], ["over", old_save.replace("\"credits\":4", "\"credits\":4,\"hunger\":10001"), false], ["negative", old_save.replace("\"credits\":4", "\"credits\":4,\"hunger\":-1"), false], ["fraction", old_save.replace("\"credits\":4", "\"credits\":4,\"hunger\":12.5"), false], ["text", old_save.replace("\"credits\":4", "\"credits\":4,\"hunger\":\"abc\""), false], ["wait", old_save.replace("\"credits\":4", "\"credits\":4,\"crust_wait\":-5"), false]]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(String(case[1]))
		file.close()
		var before := FileAccess.get_file_as_bytes(path)
		var model: Node = load("res://scripts/npc/CityProgress.gd").new()
		root.add_child(model)
		model.setup("choko", true, path)
		if bool(case[2]):
			_check(model.save_ok and model.hunger_centi() == FULL and model.credits() == 4, "K10 an old save without H reads as 100 and stays valid")
		else:
			model.set_hunger(5000)
			_check(not model.save_ok and not model.save_enabled and FileAccess.get_file_as_bytes(path) == before, "K10 a damaged field (%s) is not written over" % case[0])
		model.queue_free()
	disk.queue_free()
	again.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## K11: the HUD rows, the hints and the cue.
func _k11() -> void:
	var hud: Node = world.hud
	var rects: Array[Rect2] = []
	var words: Array[String] = []
	for level: int in [FULL, 4500, 2200, 800]:
		_level(level)
		await _ticks(2)
		rects.append(hud.food_label.get_global_rect())
		words.append(hud.food_label.text)
	var card: Rect2 = hud._status_card.get_global_rect()
	_check(card.encloses(rects[0]) and rects.all(func(r: Rect2) -> bool: return r == rects[0]), "K11 FOOD lies in the status card with one rectangle at 100 / 45 / 22 / 8 (%s)" % [rects])
	_check(words == ["FOOD 100%", "FOOD 45% · HUNGRY", "FOOD 22% · FAMISHED", "FOOD 8% · FAINT"], "K11 the words (%s)" % [words])
	_check(hud.food_bar.framed and hud.health_label.visible, "K11 FAINT: the bar gets its frame; HEALTH shows in FAINT even at full hp")
	_level(9000, CHOKO_HP)
	await _ticks(2)
	_check(not hud.health_label.visible, "K11 sated at full hp: no HEALTH")
	_level(9000, 800.0)
	await _ticks(2)
	_check(hud.health_label.visible and hud.health_label.text == "HEALTH 77%" and hud.food_label.get_global_rect() == rects[0], "K11 hp below max: «%s»; FOOD did not move" % hud.health_label.text)
	# A crossing on the real clock: H 50.01 → 50.00 after 18 frames.
	_level(5001, CHOKO_HP)
	sfx.last_frame.erase("hunger_cue")
	await _until(func() -> bool: return hunger.centi <= 5000, 30)
	await _ticks(1)
	var cue_frame: int = int(sfx.last_frame.get("hunger_cue", -1))
	_check(hud.hint_label.visible and hud.hint_label.text == "HUNGRY · stamina recovers slower · food: «Шавлія»" and cue_frame > 0, "K11 crossing 50: «%s», hunger_cue on frame %d" % [hud.hint_label.text, cue_frame])
	var hints: int = 1
	var last_cue: int = cue_frame
	for tick: int in 20:
		hunger.set_centi(5001 if tick % 2 == 0 else 4999)
		await _ticks(1)
		if int(sfx.last_frame.get("hunger_cue", -1)) != last_cue:
			hints += 1
			last_cue = int(sfx.last_frame.get("hunger_cue", -1))
	_check(hints == 1, "K11 ±1 around 50 for 20 frames: one hint, one cue (%d)" % hints)
	await _ticks(int(3.0 * 60.0) + 4)
	_check(not hud.hint_label.visible, "K11 the hint holds 3 s and goes")
	hunger.set_centi(5600)   # FOOD rises 6 above the threshold: the hysteresis re-arms it (no re-binding here)
	await _ticks(2)
	hunger.set_centi(4999)
	await _ticks(2)
	_check(int(sfx.last_frame.get("hunger_cue", -1)) != last_cue, "K11 after FOOD rose 5 above it, the next crossing speaks again")
	_level(800, CHOKO_HP)
	await _ticks(2)
	hud._faint_cue_left = 0.05
	last_cue = int(sfx.last_frame.get("hunger_cue", -1))
	await _ticks(6)
	_check(int(sfx.last_frame.get("hunger_cue", -1)) != last_cue and hud._faint_cue_left > 29.0, "K11 FAINT repeats the cue every 30 s")
	hud.set_fight_mode(true)
	await _ticks(1)
	_check(not hud.food_label.is_visible_in_tree(), "K11 the pocket's arrangement hides the card and FOOD with it")
	hud.set_fight_mode(false)
	hud._body_queue.clear()
	_level(FULL, CHOKO_HP)
	await _ticks(2)
