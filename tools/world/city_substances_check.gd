extends SceneTree
## Plan docs/Plans/2026-10-08-Thirst-Substances-Icons.md step 2 — «Хміль» and «Задишка» (CitySubstances), the street
## pedlar (CityVendorEvent), «Сила» and «Вітаміни» (CityHunger), the `drugs` key and the T8 lines, in the real CityWorld
## (saves off), Choko and then Skea, against T5's lists (docs/GDD/2026-10-08-Substances-And-Nutrition.md § 10, items
## 1–11; docs/GDD/2026-10-08-Thirst-Numbers.md § 11, items 5 (the state), 7, 8) and T8 06-UI-UX § «Спрага…» W7–W11.
## Subject: for every substance state and every frame of it, nothing gets better — walk, dodge refill and braking never
## above 1, no wall steps where there were none, H never higher, hp never higher, tokens, trust, memory and quests byte for
## byte; refusing changes nothing; states never stack and shut the pocket; water and drinks let them fade, a drink cancels
## the hangover, the hangover hits W only; Off clears a state at once with no after-effect and no offer ever comes;
## «Сила» and «Вітаміни» give exactly their numbers on the hunger clock, never stack, «Сила» carries into the pocket.
##   B1 Off: 10 000 seeded director checks at the market court — no substance offer; Off mid-offer and mid-state;
##   B2 no gain, frame by frame, for «Заплутаність», «Хміль» and «Задишка» against the same frames without them;
##   B3 the pedlar: real key, the buttons (T8 п. 3), beer → «Хміль» −1 token; «Ні, дякую» changes nothing byte for byte;
##      alcohol not at W 50 / H 50, sold at W 51; the cigarette regardless; one offer a session shared with the leaves;
##   B4 no stacking: in a state no offer starts and no state begins;
##   B5 «Хміль»: braking distance Choko / Skea (T5 v, a × 0.5, integrated at 60 Hz), top speed ≤ normal, no wall steps,
##      camera FOV and turn bit for bit as without the state;
##   B6 the hangover: W 60 → 54 → 39 (THIRSTY, no DRY MOUTH), W 80 → DRY MOUTH · WATER −15, W 15 → 11, W 5 → 5, H untouched;
##      water during «Хміль» → W 100, no hangover;
##   B7 «Задишка»: 22.5 / s sated, 16.875 / s hungry, 30 / s after 3600 frames, H unchanged;
##   B8 the pocket is shut in each state (its words), open again after it;
##   B9 drinks: water → «Хміль» / «Задишка» 10 s, the haze untouched; the tea shortens all three; uzvar shortens; beer W +0;
##   B10 «Вітаміни»: +1 % per 180 (sated) / 360 (hungry) frames, the faint drain as before, the timer stands in the pause,
##       a conversation and the pocket;
##   B11 «Сила»: 36 / 27 per s in the city and the pocket, hang 4.0 s, after 54 000 frames 30 / s and 3.0 s with its end
##       words, a second dish gives the full timer and never × 1.44; the pocket's words `HUNGRY · THIRSTY · STRENGTH`;
##   W7 the effects line above HazeLine, HazeLine last; W11 COMFORT → DRUGS Off in «Хміль» through real keys.
## --break=walk|decel|regen|stack|hangover are negative controls (a profile gives a gain; a state begins over another;
## a drink keeps the hangover).
## Sentinel: CITY_SUBSTANCES_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_SUBSTANCES: ...".
const FULL := 10000
const DT := 1.0 / 60.0
const SAFE_POINT := Vector3(0.0, 0.0, 9.5)
const MARKET := Vector3(0.0, 0.0, 20.0)
const AT_PUMP := Vector3(-1.25, 0.0, 17.8)
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var router: Node
var content: Node
var world: Node
var hunger: Node
var thirst: Node
var substances: Node
var events: Node
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
		push_error("CITY_SUBSTANCES: " + label)


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


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = code
		key.physical_keycode = code
		key.pressed = down
		_send(key)
		await _ticks(1)


func _tap_interact() -> void:
	var code: Key = KEY_G
	for event: InputEvent in InputMap.action_get_events(router.action_name(1, "interact")):
		if event is InputEventKey:
			code = (event as InputEventKey).physical_keycode if (event as InputEventKey).physical_keycode != KEY_NONE else (event as InputEventKey).keycode
			break
	await _key(code)


func _labels(dialogue: Node) -> Array[String]:
	var labels: Array[String] = []
	for child: Node in dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and not child.has_meta("close"):
			labels.append(str(child.get_meta("full_text", child.text)))
	return labels


func _button(dialogue: Node, prefix: String) -> Button:
	for child: Node in dialogue.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion() and str(child.get_meta("full_text", child.text)).begins_with(prefix):
			return child
	return null


func _press(dialogue: Node, prefix: String) -> bool:
	var button: Button = _button(dialogue, prefix)
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	await _ticks(2)
	return true


func _close_all() -> void:
	if events.active != null:
		events.abort_active("fixture")
	if events.dialogue.opened:
		events.dialogue.close()
	if npc.dialogue.opened:
		npc.dialogue.close()
	if world.lethal.active:
		world.lethal.close("abort")
	if world.hud.paused_ui:
		world.hud.set_paused(false)
	world.haze.clear()
	substances.clear()
	hunger.strength_left = 0
	hunger.vitamins_left = 0
	world.hud._body_queue.clear()
	world.hud._haze_fades_left = 0.0
	await _ticks(3)


func _level(h: int, w: int, hp: float = -1.0, tokens: int = -1) -> void:
	hunger.enable_for_test(h)
	thirst.enable_for_test(w)
	var value: float = player.data.max_hp if hp < 0.0 else hp
	hunger.city_hp = value
	player.set_round_hp(value)
	if tokens >= 0:
		progress.spend_credits(progress.credits())
		progress.earn_credits(tokens)
	world.hud._body_queue.clear()
	world.hud.bind_hunger(hunger)


## The scales stand still for a scenario that reads exact edges (W 50 / 51): no decay step in the next hours of frames.
func _hold_scales() -> void:
	hunger._decay_left = 1 << 30
	thirst._decay_left = 1 << 30


func _reset_director() -> void:
	events.session_time = 1000.0
	events.last_end_time = -INF
	events.last_alley_time = -INF
	events.leaves_count = 0
	events.vendor_count = 0


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	sfx = root.get_node("Sfx")
	content = root.get_node("ContentSettings")
	var state: Node = root.get_node("GameState")
	var old_content: String = content.get("storage_path")
	content.call("load_settings", "user://city_substances_content_%d.cfg" % OS.get_process_id())
	content.call("mark_notice_seen")
	content.call("set_drugs_mode", "full")
	state.set_free_move(true)
	router.apply_profile("solo", false)
	await _open_world("choko")
	if mutation == "walk":
		world.haze.walk_scale = 1.05          # the negative: a profile that walks faster
	if mutation == "decel":
		substances.tipsy_decel_scale = 1.05   # the negative: «Хміль» that brakes harder
	if mutation == "regen":
		substances.winded_regen_scale = 1.05  # the negative: «Задишка» that refills faster
	# B2 first: the guard must see the very first «Хміль» / «Задишка» of the session (a once-only gain would hide later).
	for scenario: Callable in [_b2, _b1, _b3, _b4, _b5, _b6, _b7, _b8, _b9, _b10, _b11, _w7, _w11]:
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
	print("CITY_SUBSTANCES_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
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
	substances = world.substances
	events = world.events
	player = world.player
	progress = world.progress
	npc = world.npc_director
	events.enable_for_test(2468)   # a scripted run keeps the director off; on, with no random starts
	events.start_chance = 0.0
	await _ticks(20)
	player.restart_at(MARKET)
	await _ticks(30)


func _close_world() -> void:
	world.queue_free()
	await _ticks(3)


## B1: `drugs` Off — no offer over 10 000 seeded checks; Off mid-offer and mid-state clears at once.
func _b1() -> void:
	player.restart_at(MARKET)
	await _ticks(10)
	content.call("set_drugs_mode", "off")
	_reset_director()
	events.enable_for_test(1789)
	events.start_chance = 1.0
	var substance_starts: int = 0
	for check: int in 10000:
		events._check_left = 0.0
		events._physics_process(events.check_seconds)
		if events.active != null:
			if String(events.active.get("id")) in ["leaves", "vendor"]:
				substance_starts += 1
			events.abort_active("fixture")
			events.last_end_time = -INF
	_check(substance_starts == 0 and events.block_reason("vendor") == "content" and events.block_reason("leaves") == "content", "B1 Off: 10 000 director checks at the market court, %d substance offers (vendor %s, leaves %s)" % [substance_starts, events.block_reason("vendor"), events.block_reason("leaves")])
	events.start_chance = 0.0
	await _close_all()
	content.call("set_drugs_mode", "full")
	_reset_director()
	_check(events.try_start("vendor"), "B1 Full: the pedlar can start at the market court (%s)" % events.block_reason("vendor"))
	content.call("set_drugs_mode", "off")
	await _ticks(2)
	_check(events.active == null and String(events.outcomes.back()) == "vendor:abort_content", "B1 Off mid-offer: the pedlar is gone at once (%s)" % events.outcomes.back())
	content.call("set_drugs_mode", "full")
	_level(8000, 6000)
	var fades: Array[String] = []
	var catch_fade := func(id: String) -> void: fades.append(id)
	substances.fading.connect(catch_fade)
	substances.begin("tipsy")
	content.call("set_drugs_mode", "off")
	await _ticks(2)
	substances.fading.disconnect(catch_fade)
	_check(not substances.active() and fades.is_empty() and thirst.centi >= 6000 - 1 and not world.hud.haze_label.visible, "B1 Off mid-«Хміль»: gone at once — no fade, no hangover (W %.2f), no TIPSY line" % thirst.value())
	content.call("set_drugs_mode", "full")


## Everything a state could give, sampled on the current frame.
func _sample(base_walk: float, base_regen: float) -> Dictionary:
	return {"walk": player.speed_mult() / base_walk, "regen": player.dodge_regen_scale() / base_regen, "decel": player.decel_scale(),
		"walls": player.wall_run_allowed(), "h": hunger.centi, "hp": hunger.city_hp}


## The progress a state must never touch: everything but the scales' own fields.
func _ledger() -> String:
	var snapshot: Dictionary = progress.snapshot()
	for hero: String in snapshot.heroes:
		for field: String in ["hunger", "thirst", "crust_wait"]:
			snapshot.heroes[hero].erase(field)
	return JSON.stringify(snapshot) + JSON.stringify(npc.population.relationships) + JSON.stringify(npc.population.people)


## One state over its whole length, frame by frame, against the same frames without it.
func _no_gain(id: String, frames: int) -> void:
	var runs: Array = []
	for with_state: bool in [false, true]:
		_level(8000, 8000, 800.0, 3)
		var base_walk: float = player.speed_mult()
		var base_regen: float = player.dodge_regen_scale()
		var ledger: String = _ledger()
		if with_state:
			if id == "haze":
				world.haze.begin()
			else:
				substances.begin(id)
		var samples: Array = []
		for frame: int in frames:
			hunger.step_frame()
			if id == "haze":
				world.haze._physics_process(DT)
			else:
				substances.step(DT)
			samples.append(_sample(base_walk, base_regen))
		runs.append({"samples": samples, "ledger": ledger, "ledger_after": _ledger(), "tokens": progress.credits()})
	var without: Array = runs[0].samples
	var within: Array = runs[1].samples
	var worst: Dictionary = {"walk": 0.0, "regen": 0.0, "decel": 0.0}
	var walls_new: int = 0
	var h_higher: int = 0
	var hp_higher: int = 0
	for frame: int in frames:
		for axis: String in ["walk", "regen", "decel"]:
			worst[axis] = maxf(float(worst[axis]), float(within[frame][axis]))
		if bool(within[frame].walls) and not bool(without[frame].walls):
			walls_new += 1
		if int(within[frame].h) > int(without[frame].h):
			h_higher += 1
		if float(within[frame].hp) > float(without[frame].hp) + 0.0001:
			hp_higher += 1
	_check(float(worst.walk) <= 1.0 + 1e-6 and float(worst.regen) <= 1.0 + 1e-6 and float(worst.decel) <= 1.0 + 1e-6, "B2 %s, %d frames: walk ≤ 1 (max %.4f), dodge refill ≤ 1 (max %.4f), braking ≤ 1 (max %.4f)" % [id, frames, worst.walk, worst.regen, worst.decel])
	_check(walls_new == 0 and h_higher == 0 and hp_higher == 0, "B2 %s: no new wall steps (%d frames), H never higher (%d), hp never higher (%d)" % [id, walls_new, h_higher, hp_higher])
	_check(runs[1].ledger_after == runs[1].ledger and runs[1].tokens == 3, "B2 %s: tokens, faces, quests, palettes, trust and memory byte for byte" % id)


## B2: the guard «жодної вигоди» (T5 § 10.2).
func _b2() -> void:
	await _no_gain("haze", 5400)
	world.haze.clear()
	await _no_gain("tipsy", 7200)
	substances.clear()
	await _no_gain("winded", 3600)
	substances.clear()
	_level(FULL, FULL)


## Starts the pedlar beside the hero and opens his offer through the real key.
func _vendor_offer() -> Node:
	player.restart_at(MARKET)
	await _ticks(15)
	_reset_director()
	if not events.try_start("vendor"):
		_check(false, "the pedlar starts at the market court (%s)" % events.block_reason("vendor"))
		return null
	var event: Node = events.active
	event.person.global_position = player.global_position + Vector3(1.4, 0.0, 0.0)
	event.person.stop()
	await _until(func() -> bool: return is_instance_valid(event) and event.phase == "offer", 60)
	await _until(func() -> bool: return events.dialogue.prompt.visible, 30)
	await _tap_interact()
	var ok: bool = is_instance_valid(event) and events.dialogue.opened and event.phase == "talk"
	_check(ok, "the real interact key opens the pedlar's offer")
	return event if ok else null


## B3: the pedlar.
func _b3() -> void:
	_level(8000, 8000, -1.0, 3)
	_hold_scales()
	var event: Node = await _vendor_offer()
	if event == null:
		return
	var beer: String = "Темне з бочки · TIPSY 2:00 · ноги важчі, без кроків по стіні · 1 жет."
	var smoke: String = "Гільза · WINDED 1:00 · дихання збивається, ухил відновлюється повільніше · 1 жет."
	_check(_labels(events.dialogue) == [beer, smoke, "Ні, дякую", "Піти"], "B3 the buttons name the price in the body and in tokens (%s)" % [_labels(events.dialogue)])
	var before: Array = [_ledger(), progress.credits(), hunger.centi, thirst.centi, player.hp, player.speed_mult(), player.dodge_regen_scale(), player.decel_scale(), substances.active(), world.haze.haze_active()]
	await _press(events.dialogue, "Ні, дякую")
	var after: Array = [_ledger(), progress.credits(), hunger.centi, thirst.centi, player.hp, player.speed_mult(), player.dodge_regen_scale(), player.decel_scale(), substances.active(), world.haze.haze_active()]
	_check(after == before, "B3 «Ні, дякую»: progress, tokens, H, W, hp, every multiplier and no state — byte for byte")
	events.dialogue.close()
	await _until(func() -> bool: return events.active == null, 600)
	_check(String(events.outcomes.back()) == "vendor:refused", "B3 refused (%s)" % events.outcomes.back())
	_reset_director()
	_check(events.block_reason("vendor") == "place" or events.block_reason("vendor") == "", "B3 a new session: he may come again (%s)" % events.block_reason("vendor"))
	events.leaves_count = 1
	_check(events.block_reason("vendor") == "session", "B3 one substance offer a session, shared with the leaves (%s)" % events.block_reason("vendor"))
	events.leaves_count = 0
	events.vendor_count = 1
	_check(events.block_reason("leaves") == "session", "B3 … and the other way round (%s)" % events.block_reason("leaves"))
	# Hunger and thirst: no alcohol at H 50 or W 50, sold at W 51; the cigarette regardless.
	for row: Array in [[8000, 5000, "спершу вода"], [5000, 8000, "спершу поїж"], [8000, 5100, ""]]:
		_level(int(row[0]), int(row[1]), -1.0, 3)
		_hold_scales()
		event = await _vendor_offer()
		if event == null:
			continue
		var button: Button = _button(events.dialogue, "Темне з бочки")
		var cigarette: Button = _button(events.dialogue, "Гільза")
		var ok: bool = button != null and (button.disabled == not String(row[2]).is_empty()) and (String(row[2]).is_empty() or str(button.get_meta("full_text")).ends_with("· " + row[2])) and cigarette != null and not cigarette.disabled
		_check(ok, "B3 H %d W %d: beer %s, the cigarette sold (%s)" % [int(row[0]) / 100, int(row[1]) / 100, "not sold «%s»" % row[2] if not String(row[2]).is_empty() else "sold", button.get_meta("full_text") if button != null else "none"])
		if String(row[2]).is_empty():
			await _press(events.dialogue, "Темне з бочки")
			_check(substances.active() and substances.state == "tipsy" and progress.credits() == 2 and thirst.centi == 5100 and hunger.centi == int(row[0]), "B3 beer: «Хміль», −1 token, W +0, H +0 (%s, %d, %.2f, %.2f)" % [substances.state, progress.credits(), thirst.value(), hunger.value()])
		events.dialogue.close()
		await _until(func() -> bool: return events.active == null, 600)
		substances.clear()
	_level(8000, 8000, -1.0, 0)
	event = await _vendor_offer()
	if event != null:
		var none: Button = _button(events.dialogue, "Гільза")
		_check(none != null and none.disabled and str(none.get_meta("full_text")).ends_with("· бракує 1 жет."), "B3 with no token: «бракує 1 жет.» in words (%s)" % (none.get_meta("full_text") if none != null else "none"))
		events.dialogue.close()
		await _until(func() -> bool: return events.active == null, 600)


## B4: states never stack — no offer and no new state while one lasts.
func _b4() -> void:
	player.restart_at(MARKET)
	await _ticks(10)
	_reset_director()
	_level(8000, 8000, -1.0, 3)
	substances.begin("winded")
	if mutation == "stack":
		substances.state = ""   # the negative: the state forgets itself and lets another one begin
	_check(not events.try_start("vendor") and events.block_reason("vendor") == "state", "B4 «Задишка»: no pedlar (%s)" % events.block_reason("vendor"))
	_check(not events.try_start("leaves") and events.block_reason("leaves") == "state", "B4 «Задишка»: no leaves (%s)" % events.block_reason("leaves"))
	_check(not substances.begin("tipsy") and substances.state == "winded", "B4 «Задишка»: «Хміль» does not begin over it (%s)" % substances.state)
	substances.clear()
	world.haze.begin()
	_check(not events.try_start("vendor") and events.block_reason("vendor") == "state" and not substances.begin("winded"), "B4 «Заплутаність»: no pedlar, no «Задишка» (%s)" % events.block_reason("vendor"))
	world.haze.clear()


## One walk down the open street at full speed and its braking: [braking distance, top speed, camera samples].
func _brake(tipsy: bool) -> Dictionary:
	player.restart_at(Vector3(0.0, 0.0, 26.0))
	world.camera_rig.reset_view()
	await _ticks(30)
	_level(FULL, FULL)
	if tipsy:
		substances.begin("tipsy")
		substances._elapsed = 10.0   # on the plateau: the full weight
	var camera: Camera3D = world.camera_rig.camera
	var shots: Array = []
	var fov_changed: bool = false
	var top: float = 0.0
	router.v_set(1, "up", true)
	for frame: int in 70:
		await _ticks(1)
		# The lens's own turn (the rig's yaw, the arm's pitch) and its FOV; the arm's length follows the body's position,
		# which carries the world's physics noise even between two plain runs, so the full basis is compared within 1e-4.
		var rig: Node = world.camera_rig
		shots.append([camera.fov, rig.rotation, rig.arm.rotation, camera.global_basis])
		top = maxf(top, Vector2(player.velocity.x, player.velocity.z).length())
	var start: Vector3 = player.global_position
	router.v_set(1, "up", false)
	var stopped: bool = false
	for frame: int in 60:
		await _ticks(1)
		fov_changed = fov_changed or not is_equal_approx(camera.fov, world.haze.base_fov)
		if Vector2(player.velocity.x, player.velocity.z).length() < 0.001:
			stopped = true
			break
	var distance: float = Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	var walls: bool = player.wall_run_allowed()
	substances.clear()
	return {"distance": distance, "top": top, "shots": shots, "fov_changed": fov_changed, "stopped": stopped, "walls": walls}


## FOV, the rig's yaw and the arm's pitch bit for bit; the camera's basis within 1e-4 (no sway, no tilt).
static func _same_lens(a: Array, b: Array) -> bool:
	if a.size() != b.size() or a.is_empty():
		return false
	for i: int in a.size():
		if a[i][0] != b[i][0] or a[i][1] != b[i][1] or a[i][2] != b[i][2]:
			return false
		var x: Basis = a[i][3]
		var y: Basis = b[i][3]
		for axis: int in 3:
			if (x[axis] - y[axis]).length() > 1e-4:
				return false
	return true


## The braking distance a 60 Hz step integrates for speed `v` and deceleration `a` (velocity updated, then moved).
static func integrated_brake(v: float, a: float) -> float:
	var distance: float = 0.0
	var speed: float = v
	while speed > 0.0:
		speed = maxf(0.0, speed - a * DT)
		distance += speed * DT
	return distance


## B5: «Хміль» — braking, top speed, no wall steps, nothing on the camera.
func _b5() -> void:
	var plain: Dictionary = await _brake(false)
	var tipsy: Dictionary = await _brake(true)
	var v: float = player.data.walk_speed
	var a: float = player.data.ground_decel
	var expected: float = integrated_brake(v, a * 0.5)
	var continuous: float = v * v / (2.0 * a * 0.5)
	print("CITY_SUBSTANCES_INFO choko brake: plain %.3f m, tipsy %.3f m; integrated %.3f, continuous v²/2a %.3f (T5 0.63)" % [plain.distance, tipsy.distance, expected, continuous])
	# T5 § 10.5 gives v²/2a (continuous); the game steps 60 Hz, so the expected value is T5's v and a × 0.5 integrated.
	_check(tipsy.stopped and absf(float(tipsy.distance) - expected) <= 0.02, "B5 Choko «Хміль»: braking %.3f m (T5 v %.1f, a %.0f × 0.5 at 60 Hz: %.3f ± 0.02)" % [tipsy.distance, v, a, expected])
	_check(float(tipsy.distance) > float(plain.distance) * 1.8, "B5 Choko: the braking is longer than without the state (%.3f vs %.3f)" % [tipsy.distance, plain.distance])
	_check(float(tipsy.top) <= float(plain.top) + 1e-6, "B5 Choko: top speed not above normal (%.4f vs %.4f)" % [tipsy.top, plain.top])
	substances.begin("tipsy")
	_check(not player.wall_run_allowed() and not player.parkour._wall_run_allowed(player), "B5 «Хміль»: no wall steps")
	substances.clear()
	_check(_same_lens(plain.shots, tipsy.shots) and not bool(tipsy.fov_changed), "B5 camera: FOV and turn bit for bit as without the state over %d frames of the walk, FOV never moved" % (tipsy.shots as Array).size())


## Steps the hunger clock (when `clock`) and the state for `frames` frames.
func _run_state(frames: int, clock: bool) -> void:
	for frame: int in frames:
		if clock:
			hunger.step_frame()
		substances.step(DT)


## Steps until the state has ended (city time is float seconds, as CityHaze): the frames it took and W on its last
## frame before the end.
func _run_to_end(clock: bool) -> Array[int]:
	var frames: int = 0
	var w_last: int = thirst.centi
	while substances.active() and frames < 10000:
		w_last = thirst.centi
		if clock:
			hunger.step_frame()
		if substances.remaining() > DT * 0.5:
			w_last = thirst.centi
		substances.step(DT)
		frames += 1
	return [frames, w_last]


## B6: the hangover on W (T5 Р6′).
func _b6() -> void:
	var hud: Node = world.hud
	for row: Array in [[6000, 3900, "THIRSTY · stamina recovers slower · water: the pump on the market square, free"], [8000, 5900, "DRY MOUTH · WATER −15"]]:
		_level(8000, int(row[0]))
		var h_start: int = hunger.centi
		substances.begin("tipsy")
		var hangovers: Array[int] = []
		var catch := func(dropped: int, _crossed: bool) -> void: hangovers.append(dropped)
		substances.hangover.connect(catch)
		var run: Array[int] = _run_to_end(true)
		substances.hangover.disconnect(catch)
		var w_end: int = thirst.centi + (hangovers[0] if not hangovers.is_empty() else 0)
		await _ticks(2)
		var texts: Array = hud._body_queue.map(func(entry: Dictionary) -> String: return String(entry.text))
		var by_clock: int = h_start - int(floor(float(run[0]) / 18.0))
		_check(absi(run[0] - 7200) <= 1 and absi(w_end - (int(row[0]) - 600)) <= 1 and thirst.centi == maxi(w_end - 1500, mini(w_end, 1100)) and absi(thirst.centi - int(row[1])) <= 1 and absi(hunger.centi - by_clock) <= 1, "B6 «Хміль» from W %d: %d frames, W %.2f at its end, the hangover → %.2f (T5 %.2f); H by the clock only (%d)" % [int(row[0]) / 100, run[0], w_end / 100.0, thirst.value(), int(row[1]) / 100.0, hunger.centi])
		_check(texts.has("TIPSY WEARS OFF · Steady steps again") and texts.has(row[2]) and (row[2] == "DRY MOUTH · WATER −15" or not texts.has("DRY MOUTH · WATER −15")), "B6 from W %d the hints: %s" % [int(row[0]) / 100, texts])
		hud._body_queue.clear()
	for row: Array in [[1500, 1100], [500, 500]]:
		_level(8000, int(row[0]))
		var h: int = hunger.centi
		substances.begin("tipsy")
		_run_to_end(false)   # the clock stands: W meets the end exactly at its level
		_check(thirst.centi == int(row[1]) and hunger.centi == h, "B6 the hangover from W %d → %d, H untouched (%d)" % [int(row[0]) / 100, thirst.centi / 100, hunger.centi])
	_level(8000, 6000)
	substances.begin("tipsy")
	_run_state(600, false)
	thirst.drink_water("fixture")
	if mutation == "hangover":
		substances._drank = false   # the negative: the drink keeps the hangover
	_run_state(1200, false)
	_check(not substances.active() and thirst.centi == FULL, "B6 water during «Хміль»: W 100 and no hangover (%.2f)" % thirst.value())
	hud._body_queue.clear()


## The refill of one second on CityFighter's own tick.
func _refill_per_second() -> float:
	player.set_control(true)
	player.dodge_stamina = 0.0
	player._dodge_regen_wait = 0.0
	for frame: int in 60:
		player._tick_dodge_stamina(DT)
	return player.dodge_stamina


## B7: «Задишка».
func _b7() -> void:
	for row: Array in [[FULL, 22.5], [4500, 16.875]]:
		_level(int(row[0]), FULL)
		var h: int = hunger.centi
		substances.begin("winded")
		substances._elapsed = 10.0
		var refill: float = _refill_per_second()
		_check(absf(refill - float(row[1])) < 0.01 and hunger.centi == h, "B7 «Задишка» at H %d: %.3f / s (%.3f), H unchanged" % [int(row[0]) / 100, row[1], refill])
		substances.clear()
	_level(FULL, FULL)
	var h_start: int = hunger.centi
	substances.begin("winded")
	var run: Array[int] = _run_to_end(false)
	_check(absi(run[0] - 3600) <= 1 and not substances.active() and absf(_refill_per_second() - 30.0) < 0.01 and hunger.centi == h_start, "B7 after %d frames (3600): 30 / s again, H unchanged (%d)" % [run[0], hunger.centi])


## B8: the pocket is shut in every state and opens after it.
func _b8() -> void:
	player.restart_at(SAFE_POINT)
	await _ticks(30)
	for row: Array in [["haze", "TOO HAZY TO FIGHT · Wait it out, or eat at «Шавлія» to clear it sooner"], ["tipsy", "TOO TIPSY TO FIGHT · Wait it out, or drink water to clear it sooner"], ["winded", "TOO WINDED TO FIGHT · Wait it out, or drink water to clear it sooner"]]:
		if row[0] == "haze":
			world.haze.begin()
		else:
			substances.begin(row[0])
		await _ticks(2)
		var prompt: String = world.hud._story_prompt
		await _tap_interact()
		await _ticks(2)
		_check(prompt == row[1] and not world.lethal.active, "B8 %s: the pocket stays shut, «%s» (%s)" % [row[0], row[1], prompt])
		world.haze.clear()
		substances.clear()
		await _ticks(2)
		_check(world.hud._story_prompt.contains("FACE THE LAMPLIGHTER"), "B8 after %s: the entry is offered again («%s»)" % [row[0], world.hud._story_prompt])


## B9: drinks against the states.
func _b9() -> void:
	player.restart_at(AT_PUMP)
	player._set_forward(Vector3.LEFT)
	await _ticks(30)
	for id: String in ["tipsy", "winded"]:
		_level(8000, 4000, -1.0, 2)
		substances.begin(id)
		var h: int = hunger.centi
		await _tap_interact()
		_check(substances.active() and substances.remaining() <= 10.001 and thirst.centi >= FULL - 1 and hunger.centi <= h and progress.credits() == 2, "B9 water in %s: 10 s left (%.2f), W 100, H +0, tokens −0" % [id, substances.remaining()])
		substances.clear()
	_level(8000, 4000, -1.0, 2)
	world.haze.begin()
	world.haze._elapsed = 10.0
	await _tap_interact()
	_check(world.haze.haze_remaining() > 60.0, "B9 water leaves «Заплутаність» (%.1f s)" % world.haze.haze_remaining())
	world.haze.clear()
	for id: String in ["haze", "tipsy", "winded"]:
		_level(6000, 4000, -1.0, 2)
		if id == "haze":
			world.haze.begin()
			hunger.set_centi(6000)
		else:
			substances.begin(id)
		var fed: Dictionary = hunger.feed("tea")
		var left: float = world.haze.haze_remaining() if id == "haze" else substances.remaining()
		_check(bool(fed.ok) and left <= 10.001 and hunger.centi == 8500 and thirst.centi == 7000, "B9 the tea in %s: %.1f s left, H +25, W +30" % [id, left])
		world.haze.clear()
		substances.clear()
	_level(6000, 4000, -1.0, 2)
	substances.begin("winded")
	var uzvar: Dictionary = hunger.feed("uzvar")
	_check(bool(uzvar.ok) and substances.remaining() <= 10.001 and hunger.centi == 7500 and thirst.centi == 7000 and hunger.vitamins_left == hunger.vitamins_full_frames, "B9 uzvar: «Задишка» 10 s, H +15, W +30, «Вітаміни»")
	substances.clear()
	_level(FULL, FULL, -1.0, 2)
	substances.begin("tipsy")
	_check(bool(hunger.food_state("tea").enabled), "B9 the tea at H 100 and W 100 can be had in «Хміль» (it shortens the state)")
	substances.clear()


## B10: «Вітаміни».
func _b10() -> void:
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	for row: Array in [[9000, 180, "sated"], [3000, 360, "hungry"]]:
		_level(int(row[0]), FULL, 500.0, 2)
		hunger.feed("pickled_apples")
		hunger.simulate(int(row[1]) - 1)
		var early: float = hunger.city_hp
		hunger.simulate(1)
		_check(hunger.vitamins_left > 0 and is_equal_approx(early, 500.0) and is_equal_approx(hunger.city_hp, 510.5), "B10 «Вітаміни» %s: +1 %% at %d frames, not before (%.1f → %.1f)" % [row[2], row[1], early, hunger.city_hp])
	_level(8000, FULL, 800.0, 2)
	hunger.feed("pickled_apples")
	hunger.set_centi(800)
	hunger.simulate(299)
	var faint_early: float = hunger.city_hp
	hunger.simulate(1)
	_check(is_equal_approx(faint_early, 800.0) and is_equal_approx(hunger.city_hp, 789.5), "B10 faint: −1 %% per 300 frames as without vitamins (%.1f → %.1f)" % [faint_early, hunger.city_hp])
	_level(8000, FULL, 800.0, 2)
	hunger.feed("pickled_apples")
	var left: int = hunger.vitamins_left
	world.hud.set_paused(true)
	await _ticks(120)
	var in_pause: int = hunger.vitamins_left
	world.hud.set_paused(false)
	_check(in_pause == left, "B10 the timer stands in the pause (%d → %d)" % [left, in_pause])
	var shop: Dictionary = CityPlaces.shops()[0]
	player.restart_at(Vector3(shop.worker.x, 0.0, shop.service.z))
	await _ticks(20)
	left = hunger.vitamins_left
	npc.open_conversation(0)
	await _ticks(120)
	var in_talk: int = hunger.vitamins_left
	npc.dialogue.close()
	_check(in_talk == left, "B10 the timer stands in a conversation (%d → %d)" % [left, in_talk])


## The hang on the PracticeLedge (4, 1.4, 15.8), its grip face z 17, top 2.8: seconds until it lets go (motor ticks).
func _hang_seconds() -> float:
	player.set_physics_process(false)
	router.v_clear(1)
	player.restart_at(Vector3(4.0, 1.3, 17.7))
	player.position = Vector3(4.0, 1.3, 17.7)
	player._set_state(int((load("res://scripts/fighter/Fighter.gd") as GDScript).get_script_constant_map()["State"]["JUMP"]))
	player.velocity = Vector3.UP
	player._wish = Vector3.FORWARD
	var ticks: int = 0
	var caught: bool = player.parkour.tick(player, DT, {"axis": 0.0, "jump_held": true, "block": false, "crouch": false}) and player.parkour.phase == "hang"
	while caught and player.parkour.phase == "hang" and ticks < 600:
		player.parkour.tick(player, DT, {"axis": 0.0, "jump_held": true, "block": false, "crouch": false})
		ticks += 1
	player.set_physics_process(true)
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	return float(ticks) / 60.0 if caught else -1.0


## B11: «Сила».
func _b11() -> void:
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(8000, FULL, -1.0, 4)
	var plain_hang: float = await _hang_seconds()
	await _ticks(5)
	_level(FULL - 1500, FULL, -1.0, 4)
	hunger.feed("eggs")
	_check(hunger.strength_left == 54000 and absf(_refill_per_second() - 36.0) < 0.01, "B11 «Сила» sated: 36 / s")
	var strong_hang: float = await _hang_seconds()
	await _ticks(5)
	_check(absf(plain_hang - 3.0) <= 0.05 and absf(strong_hang - 4.0) <= 0.05, "B11 the hang: %.2f s without, %.2f s with «Сила» (3.0 / 4.0)" % [plain_hang, strong_hang])
	hunger.set_centi(4500)
	_check(absf(_refill_per_second() - 27.0) < 0.01, "B11 «Сила» hungry: 27 / s")
	hunger.simulate(20000)
	hunger.feed("eggs")
	_check(hunger.strength_left == 54000 and absf(_refill_per_second() - 27.0) < 0.01, "B11 a second dish: the full timer again, never stacked (%d, 27 / s, not × 1.44)" % hunger.strength_left)
	hunger.set_centi(FULL)
	thirst.set_centi(FULL)   # 74 000 frames of the clock would make the hero thirsty (B 1): keep W out of it
	world.hud._body_queue.clear()
	hunger.simulate(53999)
	_check(hunger.strength_left == 1 and absf(_refill_per_second() - 36.0) < 0.01, "B11 still «Сила» after 53 999 frames")
	hunger.simulate(1)
	await _ticks(2)
	var texts: Array = world.hud._body_queue.map(func(entry: Dictionary) -> String: return String(entry.text))
	_check(hunger.strength_left == 0 and absf(_refill_per_second() - 30.0) < 0.01 and texts.has("STRENGTH WEARS OFF · Stamina and grip back to normal"), "B11 after 54 000 frames: 30 / s and its end words (%s)" % [texts])
	var back_hang: float = await _hang_seconds()
	await _ticks(5)
	_check(absf(back_hang - 3.0) <= 0.05, "B11 the hang is 3.0 s again (%.2f)" % back_hang)
	# The pocket: «Сила» carries (× 1.2 with the band), its timer stands; the words.
	for row: Array in [[4000, 4000, 27.0, "HUNGRY · THIRSTY · STRENGTH"], [FULL, FULL, 36.0, "STRENGTH"]]:
		player.restart_at(SAFE_POINT)
		await _ticks(30)
		_level(int(row[0]) - 1500, int(row[1]), -1.0, 4)
		hunger.feed("eggs")
		hunger.set_centi(int(row[0]))
		var timer: int = hunger.strength_left
		if not world.lethal.request_open():
			_check(false, "B11 the pocket opens")
			continue
		await _ticks(1)
		var line: String = world.lethal.hud.resources_label.text
		await _until(func() -> bool: return world.lethal.flow != null and int(world.lethal.flow.phase) == 1, 200)
		world.lethal.enemy.set_control(false)
		player.dodge_stamina = 0.0
		player._dodge_regen_wait = 0.0
		await _ticks(60)
		_check(line.ends_with(" · " + row[3]) and absf(player.dodge_stamina - float(row[2])) < 0.05 and hunger.strength_left == timer, "B11 the pocket at H %d W %d: «%s», %.1f / s (%.3f), the timer stands (%d → %d)" % [int(row[0]) / 100, int(row[1]) / 100, line, row[2], player.dodge_stamina, timer, hunger.strength_left])
		world.lethal.close("retreat")
		await _ticks(3)
	_level(FULL, FULL)


## W7: the effects line above HazeLine; HazeLine the card's last line; the words.
func _w7() -> void:
	_level(8000, FULL, -1.0, 4)
	hunger.feed("eggs")
	hunger.feed("pickled_apples")
	substances.begin("tipsy")
	await _ticks(2)
	var column: Node = world.hud.haze_label.get_parent()
	var visible: Array[Node] = []
	for child: Node in column.get_children():
		if child is Control and (child as Control).visible:
			visible.append(child)
	var effects: String = world.hud.effects_label.text
	var state: String = world.hud.haze_label.text
	_check(visible.back() == world.hud.haze_label and visible[visible.size() - 2] == world.hud.effects_label, "W7 the effects line right above HazeLine, HazeLine last (%s)" % [visible.map(func(n: Node) -> String: return n.name)])
	_check(effects == "STRENGTH 15:00 · VITAMINS 10:00" and state == "TIPSY 2:00", "W7 the words «%s» / «%s»" % [effects, state])
	var hue: float = world.hud.effects_label.get_theme_color("font_color").h * 360.0
	_check(hue > 30.0 and hue < 330.0, "W7 the effects colour is never red (hue %.0f°)" % hue)
	substances.clear()


## W11: COMFORT → DRUGS Off in «Хміль», through real keys — no state line, no hangover, no end hint.
func _w11() -> void:
	player.restart_at(Vector3(0.0, 0.0, 20.0))
	await _ticks(10)
	_level(8000, 6000)
	substances.begin("tipsy")
	await _ticks(2)
	_check(world.hud.haze_label.visible and world.hud.haze_label.text.begins_with("TIPSY "), "W11 «%s» shown" % world.hud.haze_label.text)
	var w: int = thirst.centi
	await _key(KEY_ESCAPE)
	var hud: Node = world.hud
	_check(hud.paused_ui, "W11 Esc opens the city pause")
	hud.comfort_button.pressed.emit()
	await process_frame
	var panel: Control = hud.comfort
	panel.drugs_choice.grab_focus()
	await _key(KEY_ENTER)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	_check(panel.visible and panel.drugs_choice.selected == 1, "W11 DRUGS shows Off")
	await _key(KEY_ESCAPE)
	await _key(KEY_ESCAPE)
	await _ticks(3)
	var texts: Array = hud._body_queue.map(func(entry: Dictionary) -> String: return String(entry.text))
	_check(not substances.active() and not hud.haze_label.visible and thirst.centi >= w - 1 and not texts.has("TIPSY WEARS OFF · Steady steps again"), "W11 Off: no state, no line, W not −15 (%.2f), no end hint (%s)" % [thirst.value(), texts])
	content.call("set_drugs_mode", "full")


## Skea: the braking in «Хміль».
func _skea() -> void:
	var plain: Dictionary = await _brake(false)
	var tipsy: Dictionary = await _brake(true)
	var v: float = player.data.walk_speed
	var a: float = player.data.ground_decel
	var expected: float = integrated_brake(v, a * 0.5)
	print("CITY_SUBSTANCES_INFO skea brake: plain %.3f m, tipsy %.3f m; integrated %.3f, continuous v²/2a %.3f (T5 0.69)" % [plain.distance, tipsy.distance, expected, v * v / (2.0 * a * 0.5)])
	_check(player.data.id == "skea" and tipsy.stopped and absf(float(tipsy.distance) - expected) <= 0.02, "S Skea «Хміль»: braking %.3f m (60 Hz %.3f ± 0.02)" % [tipsy.distance, expected])
	_check(float(tipsy.top) <= float(plain.top) + 1e-6 and _same_lens(plain.shots, tipsy.shots) and not bool(tipsy.fov_changed), "S Skea: top speed not above normal, the lens as without the state")
