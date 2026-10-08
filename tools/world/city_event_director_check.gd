extends SceneTree
## Plan docs/Plans/2026-10-08-City-Events-Stage-1.md step 1 — the city event director (CityEventDirector) in the real
## CityWorld (saves off). Subject: for every director check, an event starts only when the street is empty, the hero has
## tokens, no fight pocket is near, no other event runs and the cooldowns allow it; a scripted run never starts one by
## itself; the director draws only its own seeded RNG, so a seed replays the same city day.
##   A. A scripted run (this one) starts with the director off: eligible and with chance 1, nothing starts.
##   B. Grace, gap and the alley cooldown hold at their literal values; one event at a time; a modal blocks.
##   C. Never near a fight pocket (predicate on a ring around every pocket + a placed hero); never next to a resident.
##   D. Same seed → same sequence of starts and faces; the global RNG is not drawn.
##   E. A temporary passer-by appears with the event and is gone when it ends; the 12 residents are untouched.
## Literal thresholds (plan PLACEHOLDERs, never read from the director): grace 90 s, gap 60 s, alley cooldown 240 s,
## pocket margin 6 m, empty street 8 m.
## --break=headless|cooldown|pocket|empty|rng are negative controls.
## Sentinel: CITY_EVENT_DIRECTOR_COMPLETE checks=N failures=M mutation=<m>; failures print "CITY_EVENT_DIRECTOR: ...".
const GRACE := 90.0
const GAP := 60.0
const ALLEY_COOLDOWN := 240.0
const POCKET_MARGIN := 6.0
const EMPTY_RADIUS := 8.0
const ALLEY_SPOT := Vector3(16.0, 0.0, 6.0)
const RESIDENT_SPOT := Vector3(22.5, 0.0, 4.5)      # resident 10's lane runs x 24.5–25.5, z 0–8
const POCKET_SPOT := Vector3(0.0, 0.0, 11.5)        # 11.5 m from the central court (radius 7 + 6)
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var world: Node
var events: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_EVENT_DIRECTOR: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _place(point: Vector3) -> void:
	world.player.restart_at(point)
	await _ticks(40)


func _passersby() -> int:
	var count: int = 0
	for child: Node in events.get_children():
		if child is CityPasserby and not child.is_queued_for_deletion():
			count += 1
	return count


## Fresh timers: the session long past grace, nothing ended, nothing started.
func _reset_clock() -> void:
	events.session_time = 1000.0
	events.last_end_time = -INF
	events.last_alley_time = -INF
	events.leaves_count = 0


func _run() -> void:
	await process_frame
	var state: Node = root.get_node("GameState")
	var graphics: Node = root.get_node("GraphicsSettings")
	state.p1_character = "choko"
	state.set_free_move(true)
	root.get_node("InputRouter").apply_profile("solo", false)
	if mutation == "headless":
		graphics.set("scripted_override", 0)   # the scripted-run detection broken: the director thinks a player runs
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	events = world.events
	await _ticks(20)
	world.progress.earn_credits(8)

	# --- A. scripted run: off by default --------------------------------------------------------------------------
	await _place(ALLEY_SPOT)
	_reset_clock()
	var chance: float = events.start_chance
	events.start_chance = 1.0
	await _ticks(180)
	_check(not events.enabled and events.started.is_empty(), "a scripted run keeps the director off: enabled %s, started %s" % [events.enabled, events.started])
	if events.active != null:
		events.abort_active("fixture")
		await _ticks(2)
	graphics.set("scripted_override", -1)

	# --- B. grace, gap, cooldown, one at a time, modal ----------------------------------------------------------
	events.enable_for_test(1234)
	if mutation == "cooldown":
		events.alley_cooldown_seconds = 0.0
	if mutation == "pocket":
		events.pocket_margin = -100.0
	if mutation == "empty":
		events.empty_radius = 0.0
	_reset_clock()
	events.session_time = GRACE - 1.0
	_check(events.block_reason("alley") == "grace", "inside the first %.0f s nothing starts (%s)" % [GRACE, events.block_reason("alley")])
	events.session_time = GRACE + 0.5
	_check(events.block_reason("alley") == "", "after %.0f s the empty street with tokens allows the alley (%s)" % [GRACE, events.block_reason("alley")])
	_check(events.block_reason("leaves") == "place", "the leaves wait for the market court or the roof bridge (%s)" % events.block_reason("leaves"))
	world.progress.spend_credits(world.progress.credits())
	_check(events.block_reason("alley") == "credits", "no tokens, no alley (%s)" % events.block_reason("alley"))
	world.progress.earn_credits(8)
	var holder := Node.new()
	root.add_child(holder)
	root.get_node("InputRouter").acquire_ui(holder)
	_check(events.block_reason("alley") == "ui", "a modal blocks every event (%s)" % events.block_reason("alley"))
	root.get_node("InputRouter").release_ui(holder)
	holder.queue_free()
	await _ticks(2)
	await _ticks(int(events.check_seconds * 60.0) + 4)
	_check(events.started == ["alley"] and events.active != null, "with chance 1 the alley starts at the next check (%s)" % [events.started])
	_check(_passersby() == 1, "the event brings exactly one passer-by first (%d)" % _passersby())
	_check(events.block_reason("leaves") == "active" and not events.try_start("leaves"), "one event at a time")
	_check(world.npc_director.population.people.size() == 12, "the 12 residents stay 12")
	events.abort_active("fixture")
	await _ticks(3)
	_check(events.active == null and _passersby() == 0, "the passer-by is gone when the event ends (%d left)" % _passersby())
	var ended: float = events.session_time
	events.session_time = ended + 30.0
	_check(events.block_reason("alley") == "gap", "%.0f s after an event: still the quiet gap (%s)" % [GAP, events.block_reason("alley")])
	events.session_time = ended + 100.0
	_check(events.block_reason("alley") == "cooldown", "100 s after the alley: its %.0f s cooldown holds (%s)" % [ALLEY_COOLDOWN, events.block_reason("alley")])
	events.session_time = ended + ALLEY_COOLDOWN + 1.0
	_check(events.block_reason("alley") == "", "after %.0f s the alley may come again (%s)" % [ALLEY_COOLDOWN, events.block_reason("alley")])

	# --- C. pockets and residents --------------------------------------------------------------------------------
	var ring_ok: bool = true
	for pocket: Dictionary in CityLayout.combat_pockets():
		for step: int in 16:
			var angle: float = TAU * float(step) / 16.0
			var direction := Vector3(sin(angle), 0.0, cos(angle))
			var near: Vector3 = Vector3(pocket.center) + direction * (float(pocket.radius) + POCKET_MARGIN - 0.5)
			var far: Vector3 = Vector3(pocket.center) + direction * (float(pocket.radius) + POCKET_MARGIN + 0.5)
			var near_blocked: bool = events.near_pocket(near)
			var far_free: bool = true
			for other: Dictionary in CityLayout.combat_pockets():
				if Vector2(far.x - other.center.x, far.z - other.center.z).length() <= float(other.radius) + POCKET_MARGIN:
					far_free = false
			if not near_blocked or (far_free and events.near_pocket(far)):
				ring_ok = false
	_check(ring_ok, "every point within radius + %.0f m of a fight pocket is closed to events, beyond it open" % POCKET_MARGIN)
	await _place(POCKET_SPOT)
	_reset_clock()
	await _ticks(180)
	_check(events.started.size() == 1, "a hero %.1f m from the central court never gets an event (%s, reason %s)" % [POCKET_SPOT.length(), events.started, events.block_reason("alley")])
	if events.active != null:
		events.abort_active("fixture")
		await _ticks(2)
	await _place(RESIDENT_SPOT)
	await _ticks(40)
	_reset_clock()
	var resident_close: bool = events.residents_near(world.player.global_position, EMPTY_RADIUS) > 0
	await _ticks(180)
	_check(resident_close and events.started.size() == 1, "with a resident within %.0f m the street is not empty: no alley (close %s, %s, reason %s)" % [EMPTY_RADIUS, resident_close, events.started, events.block_reason("alley")])
	if events.active != null:
		events.abort_active("fixture")
		await _ticks(2)

	# --- D. own seeded RNG -----------------------------------------------------------------------------------------
	events.start_chance = chance
	events.enabled = false
	await _place(ALLEY_SPOT)
	var first: Array = await _sequence(4321, false)
	var second: Array = await _sequence(4321, mutation == "rng")
	_check(first == second and first.size() == 5, "the same seed replays the same starts and faces (%s vs %s)" % [first, second])
	seed(4242)
	var expected: int = randi()
	seed(4242)
	events.enable_for_test(99)
	_reset_clock()
	for tick: int in 120:
		events._physics_process(1.0)
		if events.active != null:
			events.abort_active("fixture")
			_reset_clock()
	_check(randi() == expected, "120 director checks with starts leave the global RNG untouched")
	await _ticks(3)

	world.queue_free()
	await _ticks(2)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	print("CITY_EVENT_DIRECTOR_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)


## Five starts from `seed_value` at the alley spot: [checks before the start, event, face] each.
func _sequence(seed_value: int, unseeded: bool) -> Array:
	var result: Array = []
	if events.active != null:
		events.abort_active("fixture")
	events.enable_for_test(seed_value)
	if unseeded:
		events.rng.randomize()   # the negative: the seed is ignored
	_reset_clock()
	for start: int in 5:
		var count: int = 0
		while events.active == null and count < 2000:
			events._physics_process(events.check_seconds)
			count += 1
		var face: String = String(events.active.get("face_id")) if events.active != null else ""
		result.append([count, events.started.back() if not events.started.is_empty() else "", face])
		events.abort_active("fixture")
		_reset_clock()
	events.enabled = false
	await _ticks(2)
	return result
