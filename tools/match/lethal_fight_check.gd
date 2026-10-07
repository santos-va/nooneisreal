extends SceneTree
## Plan docs/Plans/2026-10-07-First-Enemy-Lethal-Fight.md step 2 + the HUD minimum of step 4 (ADR-024), on the real
## Arena and the real CityWorld, with real keyboard / gamepad events where a player acts:
##   A. Sparring is unchanged: arena `lethal` off, full HP every round, the clock and TIME UP, "<NAME> WINS".
##   B. The lethal pocket: explicit entry at the safe point; best-of-3 with no clock; HP carries with k; the enemy dies
##      only on the decisive KO; residents 3/5/11 stand aside and return; skills open only in the pocket, the enemy
##      hook stays sealed, the Printer stays off; the pocket's 7 m wall; the exit gives the city back; defeat →
##      RETRY FIGHT / RETURN TO SAFE POINT; TRAINING never leaks into the fight.
##   C. The CPU-only enemy: difficulty from its data, SNUFF only in its band, telegraph ≥ 20, series, low hooks,
##      recovery punish, the pocket edge.
##   D. The enemy body: its own model and pole, no hero gear, no hero dodge/face/limb profile, retarget within 3°.
## Thresholds are literals of GDD 02 / GDD 03 / the plan, never read from the code under test.
## --break=<m> is a negative control (see MUTATIONS); sentinel LETHAL_FIGHT_COMPLETE checks=N failures=M mutation=<m>;
## failures print "LETHAL_FIGHT: ...".
const MUTATIONS := ["sparring", "carry", "carry_none", "retry_carry", "death", "early_death", "clock", "npc", "npc_return", "skills", "outside", "exit", "edge"]
const CHOKO_MAX := 1050.0
const SKEA_MAX := 900.0
const ENEMY_MAX := 1000.0
const ENEMY_CARRIED := 350.0     # GDD 02 § Перенос HP — k: the loser of a round starts with k × max_hp (enemy 1000)
const HERO_AT_40 := 420.0        # Choko ends the round with 40 % of 1050 …
const HERO_CARRIED := 640.5      # … and starts the next with 61 % (GDD 02 table: "переможець … із 40 % має 61 %")
const POCKET_RADIUS := 7.0       # central_court r 7 (plan; 2026-10-07-City-Encounter-Options, PLACEHOLDER)
const ROUND_SECONDS := 99.0      # GameState round clock of a sparring round
const SNUFF_BAND := Vector2(2.0, 3.6)   # GDD 03 § Мінімум CPU
const TELEGRAPH_MIN := 20        # plan: CPU telegraph ≥ 20 frames
const HELD := [3, 5, 11]         # T5 audit: residents whose lanes cross the court
const SAFE_POINT := Vector3(0, 0, 9.5)
const RETARGET_LIMIT_DEG := 3.0  # the smoke's hero retarget limit
const AFTERMATH_MAX_TICKS := 300 # the pocket must close within 5 s of the decisive KO
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var state: Node
var router: Node
var sealed: Array[String] = []
var starts: Array[Dictionary] = []
## Project classes are loaded at run time: a --script main loop compiles before the autoloads exist.
var F: GDScript
var MF: GDScript


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LETHAL_FIGHT: " + label)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	_send(event)


func _tap_key(code: Key) -> void:
	_key(code, true)
	await _ticks(1)
	_key(code, false)
	await _ticks(1)


func _tap_pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = true
	_send(event)
	await _ticks(1)
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = button
	up.pressed = false
	_send(up)
	await _ticks(1)


func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


func _run() -> void:
	await process_frame
	state = root.get_node("GameState")
	router = root.get_node("InputRouter")
	F = load("res://scripts/fighter/Fighter.gd")
	MF = load("res://scripts/arena/MatchFlow.gd")
	state.set_free_move(true)
	router.apply_profile("solo", false)
	state.training_mode = false
	state.p1_character = "choko"
	state.p2_character = "skea"
	# A negative control runs only the part its subject lives in (the full run does all three).
	if mutation in ["none", "sparring"]:
		await _sparring()
	if mutation not in ["sparring", "retry_carry"]:
		await _lethal_victory()
	if mutation in ["none", "retry_carry"]:
		await _lethal_defeat()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("LETHAL_FIGHT_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(0 if failures == 0 else 1)


# --- A. sparring ------------------------------------------------------------------------------------
func _sparring() -> void:
	state.skeletal_rig = false
	var arena: Node = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	var flow: Node = arena.get_node("MatchFlow")
	var hud: Node = arena.get_node("HUD")
	var p1: Node = arena.get("p1")
	var p2: Node = arena.get("p2")
	if mutation == "sparring":
		flow.lethal = true
	p1._brain = null
	if p2._brain != null:
		p2._brain.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(2)
	_check(not flow.lethal, "the arena duel is a sparring: MatchFlow.lethal is off")
	_check(hud.get("_round_label").text == "SPARRING · FIRST TO 2", "duel frame line reads SPARRING · FIRST TO 2, got '%s'" % hud.get("_round_label").text)
	_check(p2._brain == null or is_equal_approx(p2._brain.difficulty, 0.6), "the heroes' sparring CPU keeps difficulty 0.6")
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 200)
	var clock_before: float = flow.time_left
	await _ticks(30)
	_check(flow.time_left < clock_before - 0.4, "sparring clock runs (%.2f → %.2f)" % [clock_before, flow.time_left])
	p1.hp = HERO_AT_40
	p2._die(p1, p1.data.light)
	await _until(func() -> bool: return flow.round_no == 2, 220)
	_check(flow.round_no == 2 and is_equal_approx(p1.hp, CHOKO_MAX) and is_equal_approx(p2.hp, SKEA_MAX), "sparring round 2 starts at full HP: %.1f / %.1f (want %.0f / %.0f)" % [p1.hp, p2.hp, CHOKO_MAX, SKEA_MAX])
	_check(is_equal_approx(flow.time_left, ROUND_SECONDS), "sparring round 2 clock resets to %.0f s" % ROUND_SECONDS)
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 200)
	var texts: Array[String] = []
	flow.announce.connect(func(text: String, _s: float) -> void: texts.append(text))
	flow.time_left = 0.05
	await _ticks(6)
	_check(flow.phase == MF.Phase.ROUND_END and "TIME UP" in texts, "sparring round ends on TIME UP when the clock runs out")
	await _until(func() -> bool: return flow.phase != MF.Phase.ROUND_END, 220)
	_check(flow.phase == MF.Phase.MATCH_END, "two round wins end the sparring match")
	_check(texts.any(func(t: String) -> bool: return t.ends_with(" WINS")) and not texts.any(func(t: String) -> bool: return t.ends_with(" FALLS") or t == "DEFEATED"), "sparring ends with '<NAME> WINS', never FALLS / DEFEATED: %s" % [texts])
	_check(bool(hud.get("_result").visible), "sparring keeps its REMATCH result card")
	_check(not state.last_result.is_empty(), "sparring still writes its result snapshot")
	arena.queue_free()
	await _ticks(3)
	state.skeletal_rig = true


func _until(condition: Callable, limit: int) -> void:
	for tick: int in limit:
		if condition.call():
			return
		await _ticks(1)


# --- B/C/D. lethal pocket, victory path --------------------------------------------------------------
func _city() -> Node:
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	return world


func _lethal_victory() -> void:
	var world: Node = _city()
	var hero: Node = world.player
	var lethal: Node = world.lethal
	hero.sealed_action.connect(func(action: String) -> void: sealed.append(action))
	await _ticks(30)
	# Outside: skills sealed, no entry away from the safe point, the court never starts a fight by itself.
	await _skill_press_outside(world, "before the fight")
	hero.restart_at(Vector3(0, 0, 0))
	await _ticks(60)
	_check(not lethal.active, "standing in the court does not start a fight (explicit entry only)")
	hero.restart_at(Vector3(0, 0, 13))
	await _ticks(10)
	_check(not lethal.can_enter(), "no entry 3.5 m from the safe point")
	_court_ground(world)
	hero.restart_at(SAFE_POINT)
	await _ticks(150)   # the sealed-skill line (2 s) has priority over prompts
	_check(not lethal.active and lethal.can_enter(), "entry offered at the safe point, nothing opened yet")
	_check(world.hud.hint_label.visible and "FACE THE LAMPLIGHTER" in world.hud.hint_label.text, "the hint names the entry: '%s'" % world.hud.hint_label.text)
	var lanes := {}
	for index: int in world.npc_director.actors:
		lanes[index] = world.npc_director.actors[index].route.duplicate()
	state.training_mode = true   # TRAINING picked in the menu earlier must not reach the fight
	await _tap_key(KEY_G)        # SOLO interact
	await _ticks(1)
	_check(lethal.active, "the interact key at the safe point opens the fight")
	if not lethal.active:
		world.queue_free()
		await _ticks(3)
		return
	var enemy: Node = lethal.enemy
	var flow: Node = lethal.flow
	enemy.move_started.connect(func(f: Node, m: Resource) -> void: starts.append({"id": m.id, "dist": _flat(f.global_position - hero.global_position), "frame": Engine.get_physics_frames(), "total": m.total_frames()}))
	_check(flow.lethal and not state.training_mode, "the fight is lethal and TRAINING is off inside it")
	_check(enemy.data.id == "lamplighter" and enemy.is_cpu and enemy.player_index == 2 and enemy.data.cpu_only, "the enemy is the CPU-only Lamplighter as P2")
	_check(enemy.global_position.distance_to(Vector3(3, 0, 0)) < 0.05 and hero.global_position.distance_to(Vector3(-3, 0, 0)) < 0.05, "round 1 places the hero at (-3,0,0) and the enemy at (3,0,0) in the court")
	_check(is_equal_approx(hero.arena_radius, POCKET_RADIUS) and is_equal_approx(enemy.arena_radius, POCKET_RADIUS) and hero.arena_center.is_zero_approx(), "both fighters hold the pocket's 7 m circle around the court centre")
	_check(is_equal_approx(hero.hp, CHOKO_MAX) and is_equal_approx(enemy.hp, ENEMY_MAX), "round 1 starts at full HP")
	if mutation == "npc":
		world.npc_director.release_hold()
	var held: Array = lethal.held_residents.duplicate()
	held.sort()
	_check(held == HELD, "residents %s stand aside, got %s" % [HELD, held])
	for index: int in HELD:
		if world.npc_director.actors.has(index):
			var actor: Node3D = world.npc_director.actors[index]
			_check(_flat(actor.global_position) > POCKET_RADIUS + 1.0, "resident %d stands outside the pocket (%.2f m from the centre)" % [index, _flat(actor.global_position)])
			_check(_flat(actor.route[0]) > POCKET_RADIUS + 1.0 and actor.route.size() == 1, "resident %d waits outside instead of walking its lane" % index)
	for index: int in lanes:
		if not index in HELD and world.npc_director.actors.has(index):
			_check(world.npc_director.actors[index].route == lanes[index], "resident %d off the court keeps its lane" % index)
	_check(not world.npc_director.dialogue.prompt.visible and world.npc_director.fight_lock, "no conversation is offered during the fight")
	var camera := root.get_viewport().get_camera_3d()
	_check(lethal.camera != null and camera == lethal.camera.cam and world.camera_rig.process_mode == Node.PROCESS_MODE_DISABLED, "the duel camera holds the pair; the city camera rests")
	_check(state.duel.behind, "the pocket's camera stands behind the hero")
	_check(lethal.hud != null and lethal.hud.round_label.text == "ROUND 1 — TO THE DEATH", "HUD frame line reads ROUND 1 — TO THE DEATH, got '%s'" % (lethal.hud.round_label.text if lethal.hud else ""))
	_check(lethal.hud.enemy_name.text == "LAMPLIGHTER" and is_equal_approx(lethal.hud.enemy_bar.value, 1.0), "HUD shows the enemy's name and a full health bar")
	_check(not world.hud._status_card.visible and world.hud.fight_mode, "the exploration card steps aside for the fight HUD")
	await _ticks(1)
	var pause_rect: Rect2 = world.hud.pause_button.get_global_rect()
	_check(not pause_rect.intersects(lethal.hud.enemy_name.get_global_rect()) and not pause_rect.intersects(lethal.hud.enemy_bar.get_global_rect()) and not pause_rect.intersects(lethal.hud.round_label.get_global_rect()), "the city's pause button covers no part of the fight band (%s)" % pause_rect)
	_check(hero.printer != null and hero.printer.process_mode == Node.PROCESS_MODE_DISABLED, "Choko's Printer stays off in the pocket")
	await _model_checks(world, enemy, hero)
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 200)
	_check(flow.phase == MF.Phase.FIGHT, "round 1 reaches FIGHT")
	var clock_before: float = flow.time_left
	await _ticks(60)
	_check(is_equal_approx(flow.time_left, clock_before), "no clock in a lethal round (%.2f → %.2f)" % [clock_before, flow.time_left])
	if mutation == "clock":
		flow.lethal = false
	flow.time_left = 0.05
	await _ticks(6)
	_check(flow.phase == MF.Phase.FIGHT, "a lethal round never ends on TIME UP")
	flow.lethal = true
	await _skills_in_pocket(world, hero, enemy)
	await _pocket_wall(hero, enemy)
	await _cpu_checks(world, hero, enemy, flow)
	# Round 1 KO of the enemy: the enemy is not dead, both carry wounds into round 2.
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 400)
	hero.hp = HERO_AT_40
	enemy._die(hero, hero.data.light)
	if mutation == "early_death":
		lethal.close("victory")
	if mutation == "carry":
		flow.lethal = false
	# Poll through the owner: a lambda must not capture a flow that a broken close() may free.
	await _until(func() -> bool: return lethal.flow == null or lethal.flow.round_no == 2, 220)
	if not lethal.active or lethal.flow == null or not is_instance_valid(enemy) or not enemy.is_inside_tree():
		_check(false, "the first KO is not the enemy's death: round 2 starts with the same enemy")
		world.queue_free()
		await _ticks(3)
		return
	if mutation == "carry_none":
		hero.hp = HERO_AT_40
		enemy.hp = 0.0
	flow.lethal = true
	_check(flow.round_no == 2, "the first KO is not the enemy's death: round 2 starts with the same enemy")
	_check(is_equal_approx(enemy.hp, ENEMY_CARRIED), "the round's loser carries k × max: enemy %.1f (want %.1f)" % [enemy.hp, ENEMY_CARRIED])
	_check(is_equal_approx(hero.hp, HERO_CARRIED), "the winner at 40 %% carries 61 %%: hero %.1f (want %.1f)" % [hero.hp, HERO_CARRIED])
	_check(lethal.hud.round_label.text == "ROUND 2 — TO THE DEATH", "HUD frame line follows the round: '%s'" % lethal.hud.round_label.text)
	_check(enemy.state != F.State.KO, "the enemy stands up for round 2")
	# Decisive KO: the enemy dies (stays down, no reset), the pocket closes, the city comes back.
	await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT, 200)
	var texts: Array[String] = []
	flow.announce.connect(func(text: String, _s: float) -> void: texts.append(text))
	enemy._die(hero, hero.data.light)
	await _until(func() -> bool: return lethal.flow == null or lethal.flow.phase == MF.Phase.MATCH_END, 220)
	if mutation == "death" and lethal.flow != null:
		flow.call("_start_round")
	_check(texts.has("LAMPLIGHTER FALLS"), "the decisive KO announces LAMPLIGHTER FALLS: %s" % [texts])
	_check(lethal.hud != null and lethal.hud.announce_label.visible and lethal.hud.announce_label.text == "LAMPLIGHTER FALLS", "the fight HUD shows LAMPLIGHTER FALLS")
	_check(lethal.enemy_defeated and is_instance_valid(enemy) and enemy.state == F.State.KO and is_zero_approx(enemy.hp), "the dead enemy stays down (KO, hp 0, no reset)")
	_check(lethal.hud != null and not lethal.hud.defeat_card.visible, "victory shows no defeat card")
	var waited: int = 0
	while lethal.active and waited < AFTERMATH_MAX_TICKS:
		await _ticks(1)
		waited += 1
		if waited == 30 and is_instance_valid(enemy):
			_check(enemy.state == F.State.KO, "the body is still down half a second later")
	_check(not lethal.active and lethal.outcome == "victory", "the pocket closes after the death (%d ticks)" % waited)
	if mutation == "exit":
		world.camera_rig.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(2)
	_check(not is_instance_valid(enemy) or not enemy.is_inside_tree(), "the dead enemy leaves with the pocket")
	_check(root.get_viewport().get_camera_3d() == world.camera_rig.camera and world.camera_rig.process_mode == Node.PROCESS_MODE_INHERIT, "the city camera is back")
	_check(hero.opponent == null and not hero.lethal_pocket and is_equal_approx(hero.arena_radius, 20.0), "the hero is back on the open city's rules")
	_check(not state.duel.behind and is_equal_approx(Engine.time_scale, 1.0) and not router.ui_suppressed(), "duel frame, time scale and input are back")
	_check(state.training_mode, "TRAINING returns to its pre-fight value after the fight")
	state.training_mode = false
	_check(not world.hud.fight_mode and world.hud._status_card.visible and world.npc_director.dialogue != null and not world.npc_director.fight_lock, "the city HUD and conversations are back")
	if mutation == "npc_return":
		var stray: Array[Vector3] = [Vector3(30, 0, 30)]
		for index: int in HELD:
			if world.npc_director.actors.has(index):
				world.npc_director.actors[index].route = stray
	for index: int in HELD:
		if world.npc_director.actors.has(index) and lanes.has(index):
			_check(world.npc_director.actors[index].route == lanes[index], "resident %d walks its own lane again" % index)
	_check(not lethal.can_enter(), "a dead enemy offers no second fight this session")
	if mutation == "outside":
		hero.lethal_pocket = true
	await _skill_press_outside(world, "after the fight")
	hero.lethal_pocket = false
	hero.restart_at(Vector3(8.5, 0, 0))
	await _ticks(5)
	_check(_flat(hero.global_position) > POCKET_RADIUS + 1.0, "after the fight the court has no wall (%.2f m)" % _flat(hero.global_position))
	world.queue_free()
	await _ticks(3)


## T5's assumption for Fighter in this pocket: centre (0,0,0), flat floor at y = 0, nothing standing inside 7 m.
func _court_ground(world: Node) -> void:
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var worst: float = 0.0
	var probes: int = 0
	for ring: float in [0.0, 2.0, 4.0, 6.0, POCKET_RADIUS - 0.05]:
		for step: int in 16:
			var a: float = TAU * float(step) / 16.0
			var at := Vector3(cos(a) * ring, 0.0, sin(a) * ring)
			var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 1.0, 1))
			probes += 1
			worst = maxf(worst, 99.0 if hit.is_empty() else absf(float(hit.position.y)))
	_check(worst <= 0.01, "the court floor is y = 0 under all %d probes inside 7 m (worst %.3f)" % [probes, worst])
	var body := CylinderShape3D.new()
	body.radius = POCKET_RADIUS
	body.height = 2.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = body
	query.transform = Transform3D(Basis.IDENTITY, Vector3(0, 1.1, 0))
	query.collision_mask = 1
	var blockers: Array = space.intersect_shape(query, 8).map(func(r: Dictionary) -> String: return str(r.collider.name))
	_check(blockers.is_empty(), "nothing solid stands inside the pocket between 0.1 and 2.1 m (%s)" % [blockers])


func _skill_press_outside(world: Node, when: String) -> void:
	var hero: Node = world.player
	await _ticks(5)
	sealed.clear()
	hero.current_slot = ""
	await _tap_key(KEY_U)   # SOLO skill1
	await _ticks(2)
	_check(sealed.has("skill1") and hero.current_slot != "skill1", "%s: skill1 outside the pocket is sealed (sealed %s, slot '%s')" % [when, sealed, hero.current_slot])


func _skills_in_pocket(world: Node, hero: Node, enemy: Node) -> void:
	enemy._brain.process_mode = Node.PROCESS_MODE_DISABLED
	router.v_clear(2)
	enemy.global_position = Vector3(0, 0, -4)
	await _until(func() -> bool: return hero.is_actionable(), 120)
	if mutation == "skills":
		hero.lethal_pocket = false
	sealed.clear()
	hero.current_slot = ""
	await _tap_key(KEY_U)
	await _ticks(1)
	_check(hero.current_slot == "skill1" and not sealed.has("skill1"), "skill1 opens in the pocket (slot '%s', sealed %s)" % [hero.current_slot, sealed])
	hero.lethal_pocket = true
	await _until(func() -> bool: return hero.is_actionable(), 240)
	sealed.clear()
	await _tap_key(KEY_Q)   # SOLO enemy hook
	await _ticks(2)
	_check(sealed.has("grapple_enemy") and not hero.grapple.busy() and hero.state != F.State.GRAPPLE, "the enemy hook stays sealed in the pocket")
	_check(world.hud.hint_label.visible and world.hud.hint_label.text == "ENEMY HOOK SEALED IN THIS FIGHT", "the pocket answers the hook with its own line: '%s'" % world.hud.hint_label.text)
	enemy._brain.process_mode = Node.PROCESS_MODE_INHERIT


func _pocket_wall(hero: Node, enemy: Node) -> void:
	hero.global_position = Vector3(7.6, 0.02, 0)
	enemy.global_position = Vector3(-7.6, 0.02, 0)
	await _ticks(2)
	_check(_flat(hero.global_position) <= POCKET_RADIUS + 0.001, "the pocket wall holds the hero at 7 m (%.3f)" % _flat(hero.global_position))
	_check(_flat(enemy.global_position) <= POCKET_RADIUS + 0.001, "the pocket wall holds the enemy at 7 m (%.3f)" % _flat(enemy.global_position))
	hero.global_position = Vector3(-2, 0.02, 0)
	enemy.global_position = Vector3(2, 0.02, 0)
	await _ticks(2)


func _cpu_checks(world: Node, hero: Node, enemy: Node, flow: Node) -> void:
	var brain: Node = enemy._brain
	_check(is_equal_approx(brain.difficulty, enemy.data.cpu_difficulty) and is_equal_approx(enemy.data.cpu_difficulty, 0.6), "the enemy's CPU reads difficulty from its data")
	_check(enemy.data.skill1 != null and enemy.data.skill1.startup >= TELEGRAPH_MIN, "SNUFF telegraphs %d frames (≥ %d)" % [enemy.data.skill1.startup if enemy.data.skill1 else 0, TELEGRAPH_MIN])
	enemy.cooldowns["skill1"] = 0.0
	_check(not brain.snuff_allowed(SNUFF_BAND.x - 0.1) and brain.snuff_allowed(SNUFF_BAND.x) and brain.snuff_allowed(SNUFF_BAND.y) and not brain.snuff_allowed(SNUFF_BAND.y + 0.1), "SNUFF is chosen only in its 2.0–3.6 m band")
	# The pocket edge: an outward retreat inside 1.5 m of the wall turns into a sidestep toward the centre.
	if mutation == "edge":
		enemy.arena_radius = 100.0
	hero.global_position = Vector3(3.0, 0.02, 0)
	enemy.global_position = Vector3(6.2, 0.02, 0)
	await _ticks(1)
	var away: String = "right" if (enemy.global_position - hero.global_position).dot(state.duel.right) > 0.0 else "left"
	var toward: String = "left" if away == "right" else "right"
	var pick: String = brain._safe_back(toward, away)
	_check(pick != away and brain.key_world(pick).dot(Vector3(1, 0, 0)) <= 0.3, "at the pocket wall the enemy refuses to back into it (picked '%s')" % pick)
	enemy.arena_radius = POCKET_RADIUS
	enemy.global_position = Vector3(0.5, 0.02, 0)
	hero.global_position = Vector3(-2.5, 0.02, 0)
	await _ticks(1)
	away = "right" if (enemy.global_position - hero.global_position).dot(state.duel.right) > 0.0 else "left"
	toward = "left" if away == "right" else "right"
	_check(brain._safe_back(toward, away) == away, "away from the wall the enemy may step back")
	# A whiffed heavy inside the pole's reach gets punished during its recovery.
	var punished_in_recovery: int = 0
	for trial: int in 6:
		await _until(func() -> bool: return flow.phase == MF.Phase.FIGHT and hero.is_actionable() and enemy.is_actionable(), 240)
		# 3.15 m: Choko's heavy (reach 2.1 m + 0.5 m step) whiffs; after the step the pole's heavy (2.8 m) reaches.
		hero.global_position = Vector3(-1.575, 0.02, 0)
		enemy.global_position = Vector3(1.575, 0.02, 0)
		hero.velocity = Vector3.ZERO
		enemy.velocity = Vector3.ZERO
		brain._timer = 100000   # decisions off: only the punish reflex runs
		await _ticks(2)
		var before: int = brain.punishes
		router.v_press(1, "heavy")
		var whiff := true
		var answered := false
		for tick: int in 90:
			await _ticks(1)
			if hero.has_hit:
				whiff = false
			if brain.punishes > before and not answered:
				answered = hero.state == F.State.ATTACK
			if hero.state != F.State.ATTACK and tick > 5:
				break
		if whiff and answered:
			punished_in_recovery += 1
		brain._timer = 0
		router.v_clear(1)
		await _ticks(40)
	_check(punished_in_recovery >= 1, "the enemy punishes a whiffed heavy in its recovery (%d of 6 trials)" % punished_in_recovery)
	# Free fight: series, low hooks, SNUFF only in band. The hero only takes it (huge HP so the round never ends).
	starts.clear()
	hero.hp = 1.0e6
	brain._timer = 0
	var done_before: int = brain.series_done
	for tick: int in 1500:
		await _ticks(1)
		if tick % 200 == 0:
			hero.global_position = Vector3(-3.2 if tick % 400 == 0 else -0.8, 0.02, 0)
			enemy.cooldowns["skill1"] = 0.0
	var snuffs: Array = starts.filter(func(s: Dictionary) -> bool: return s.id == "snuff")
	var lows: Array = starts.filter(func(s: Dictionary) -> bool: return s.id == "low_hook")
	_check(brain.series_done > done_before, "the enemy completes authored series (%d)" % (brain.series_done - done_before))
	_check(lows.size() >= 1, "the enemy crouches for low hooks (%d)" % lows.size())
	_check(snuffs.size() >= 1, "the enemy uses SNUFF in a free fight (%d)" % snuffs.size())
	for s: Dictionary in snuffs:
		_check(float(s.dist) >= SNUFF_BAND.x - 0.2 and float(s.dist) <= SNUFF_BAND.y + 0.2, "SNUFF started at %.2f m, inside its band (±0.2 m of one tick's walk)" % float(s.dist))
	# A chain = moves started inside the previous move (a cancel). GDD 03: series of 2–3, then a pause or a guard.
	var longest: int = 0
	var run: int = 0
	var shortest_gap: int = 100000
	var last_end: int = -100000
	for s: Dictionary in starts:
		if int(s.frame) < last_end:
			run += 1
		else:
			if run >= 2:   # the move after a series
				shortest_gap = mini(shortest_gap, int(s.frame) - last_end)
			run = 1
		longest = maxi(longest, run)
		last_end = int(s.frame) + int(s.total)
	_check(longest >= 2 and longest <= 3, "series chain 2–3 moves (longest %d)" % longest)
	_check(shortest_gap >= 16, "a breath or a guard of ≥ 16 frames after each series (shortest %d)" % shortest_gap)
	print("LETHAL_FIGHT_INFO cpu: punished %d/6 whiffs, 1500 ticks: %d moves, %d series, %d low hooks, %d SNUFF at %s m, longest chain %d, shortest gap after a series %d" % [punished_in_recovery, starts.size(), brain.series_done - done_before, lows.size(), snuffs.size(), snuffs.map(func(x: Dictionary) -> String: return "%.2f" % float(x.dist)), longest, shortest_gap])
	hero.hp = HERO_AT_40


func _model_checks(world: Node, enemy: Node, hero: Node) -> void:
	await _ticks(2)
	var rig: Node = enemy.skeletal
	_check(rig != null and rig.hero != null and rig.hero_skeleton != null, "the enemy draws its own model (lamplighter_m0.glb)")
	if rig == null or rig.hero_skeleton == null:
		return
	_check(rig.gear == null and hero.skeletal != null and hero.skeletal.gear != null, "hero gear stays on the hero; the enemy carries none of it")
	_check(rig.staff != null and rig.staff.pieces.size() >= 8 and rig.sword == null, "the enemy carries the procedural pole, no sword")
	var head: int = rig.hero_skeleton.find_bone("Head")
	var head_y: float = (rig.hero_skeleton.global_transform * rig.hero_skeleton.get_bone_global_pose(head)).origin.y
	var hook_y: float = (rig.staff.global_transform * Vector3(0, rig.staff.LENGTH - rig.staff.GRIP_FROM_BOTTOM, 0)).y
	_check(hook_y > head_y + 0.2, "the hook rises above the head when the pole is carried (hook %.2f m, head %.2f m)" % [hook_y, head_y])
	_check(enemy.dodge_profile() != hero.dodge_profile() and not enemy.DODGE_PROFILES.values().has(enemy.dodge_profile()) and is_equal_approx(enemy.dodge_profile().stamina_max, 100.0), "the enemy dodges on neutral defaults, not a hero profile")
	_check(rig.face_presentation.profile == null and not load("res://scripts/fighter/LimbMotion.gd").PROFILES.has("lamplighter"), "no hero face or limb profile on the enemy")
	var bridge: GDScript = load("res://scripts/fighter/ProceduralMotionFallback.gd")
	_check(bridge.call("supports", "lamplighter", enemy.data.skill1) and bridge.call("supports", "lamplighter", enemy.data.light), "the enemy's moves draw the existing poses on its skeleton")
	var worst: float = 0.0
	for tick: int in 20:
		await _ticks(1)
		for bone: String in rig.HERO_AIM:
			if bone in ["neck", "LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg"]:
				continue
			worst = maxf(worst, rig.aim_error(bone))
	_check(worst <= RETARGET_LIMIT_DEG, "the enemy model follows the mannequin within 3° (worst %.2f°)" % worst)


# --- B. defeat path: RETRY FIGHT / RETURN TO SAFE POINT ---------------------------------------------
func _lethal_defeat() -> void:
	var world: Node = _city()
	var hero: Node = world.player
	var lethal: Node = world.lethal
	await _ticks(30)
	hero.restart_at(SAFE_POINT)
	await _ticks(20)
	await _tap_key(KEY_G)
	await _ticks(1)
	_check(lethal.active, "second session: the entry opens the fight again")
	if not lethal.active:
		world.queue_free()
		await _ticks(3)
		return
	var enemy: Node = lethal.enemy
	await _lose(lethal, hero)
	var hud: Node = lethal.hud
	_check(hud.defeat_card.visible and hud.defeat_title.text == "DEFEATED" and hud.retry_button.text == "RETRY FIGHT" and hud.return_button.text == "RETURN TO SAFE POINT", "the hero falls: DEFEATED with RETRY FIGHT / RETURN TO SAFE POINT")
	_check(hud.retry_button.has_focus() and router.ui_suppressed(), "the defeat card owns input with RETRY FIGHT focused")
	_check(lethal.active and is_instance_valid(enemy) and not lethal.enemy_defeated, "the enemy survives the hero's fall")
	await _tap_key(KEY_ENTER)
	await _ticks(2)
	if mutation == "retry_carry":
		hero.hp = lethal.flow.carried_hp(0.0, CHOKO_MAX)
	_check(lethal.active and lethal.flow.round_no == 1 and lethal.flow.wins == {1: 0, 2: 0}, "RETRY FIGHT starts a new match at round 1")
	_check(is_equal_approx(hero.hp, CHOKO_MAX) and is_equal_approx(enemy.hp, ENEMY_MAX), "RETRY FIGHT gives both full HP: %.1f / %.1f" % [hero.hp, enemy.hp])
	_check(not hud.defeat_card.visible and not router.ui_suppressed(), "RETRY FIGHT closes the card and returns input")
	await _lose(lethal, hero)
	_check(hud.defeat_card.visible and hud.retry_button.has_focus(), "the second fall shows the card again")
	await _tap_key(KEY_DOWN)
	_check(hud.return_button.has_focus(), "Down moves the focus to RETURN TO SAFE POINT")
	await _tap_pad(JOY_BUTTON_A)
	await _ticks(3)
	_check(not lethal.active and lethal.outcome == "retreat", "RETURN TO SAFE POINT (gamepad A) ends the fight without a death")
	_check(hero.global_position.distance_to(SAFE_POINT) < 0.2, "the hero stands at the safe point (%s)" % hero.global_position)
	_check(is_equal_approx(hero.hp, CHOKO_MAX) and hero.opponent == null and not router.ui_suppressed(), "no consequence: full HP, no opponent, input free")
	_check(not lethal.enemy_defeated and not is_instance_valid(enemy) or not enemy.is_inside_tree(), "the living enemy leaves with the pocket")
	await _ticks(20)
	_check(lethal.can_enter(), "the entry is offered again after a retreat")
	# Leaving the scene mid-fight puts the globals back.
	state.training_mode = true
	await _tap_key(KEY_G)
	await _ticks(2)
	_check(lethal.active and not state.training_mode, "third fight opens with TRAINING off")
	world.restart_exploration()
	await _ticks(2)
	_check(not lethal.active and lethal.outcome == "abort" and state.training_mode and root.get_viewport().get_camera_3d() == world.camera_rig.camera, "restart from the pause aborts the fight and restores the city")
	state.training_mode = false
	world.queue_free()
	await _ticks(3)


func _lose(lethal: Node, hero: Node) -> void:
	for round_index: int in 2:
		await _until(func() -> bool: return lethal.flow.phase == MF.Phase.FIGHT, 400)
		hero._die(lethal.enemy, lethal.enemy.data.light)
		await _until(func() -> bool: return lethal.flow.phase != MF.Phase.ROUND_END and lethal.flow.phase != MF.Phase.FIGHT, 220)
	await _until(func() -> bool: return lethal.hud.defeat_card.visible, 30)
