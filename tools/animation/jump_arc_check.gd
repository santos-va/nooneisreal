extends SceneTree
## Plan docs/Plans/2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum.md step 2 (jump arc С2); guards G1–G4 of T5
## docs/GDD/2026-10-09-Rope-Pull-And-Jump-Arc-Numbers.md § 2.4, in place of «≤ 19 ticks ≥ 15° from a run».
## Subject: for a jump from the ground in the production CityWorld (its camera, light and HUD; real Space and D; both
## heroes; standing and running) and for drops onto the street:
##   G1 the air after a take-off shows exactly takeoff → apex → fall; a drop without a take-off never tucks;
##   G2 no hero bone turns ≥ 15° in a tick in the air after the take-off (ticks 12 … landing);
##   G3 the largest turn in the take-off (ticks 0–11) is not above the value before bf38d3e (aa51881);
##   G4 on the standing landing no leg bone turns ≥ 15° in a tick; the light landing's lowest hips are not below
##      aa51881's; the hips go lower from light to normal (3.5 m drop) to heavy (6.5 m drop);
##   flip: no bone turns ≥ 90° in one tick on any landing (the 140° contact flip of Choko's forearm, aa51881).
## The "before" values are the aa51881 captures of the same measure (T2 jump_capture, 2026-10-08/09): the largest
## per-tick change of any hero bone's skeleton-space rotation, and the hero Hips height above CityFighter.floor_y().
##   --break=blend|tuck|land — negative controls: the 2026-10-08 blends, no tuck at all, the light landing at ×2.5.
## Sentinel: JUMP_ARC_COMPLETE checks=N failures=M mutation=<m> red=<failed families|none>; failures print
## "JUMP_ARC: ...".
const TURN_LIMIT: float = 15.0
const FLIP_LIMIT: float = 90.0
const TAKEOFF_TICKS: int = 12
const LANDING_TICKS: int = 35
## G3: aa51881 take-off maxima, degrees (T5 § 2.4 table; re-measured 2026-10-09 with the same probe).
const BEFORE_TAKEOFF: Dictionary = {"choko_run": 17.1, "choko_stand": 33.4, "skea_run": 22.1, "skea_stand": 17.2}
## G4: aa51881 lowest hips on the standing landing, metres above the floor (re-measured 2026-10-09).
const BEFORE_LIGHT_HIPS: Dictionary = {"choko": 0.717, "skea": 0.700}
const DROPS: Dictionary = {"drop_normal": 3.5, "drop_heavy": 6.5}
const JUMP_STATE := 4
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var red: Dictionary = {}
var router: Node


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _check(ok: bool, family: String, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("JUMP_ARC: [%s] %s" % [family, label])


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	await process_frame
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	for hero: String in ["choko", "skea"]:
		await _hero(hero)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	var families: Array = red.keys()
	families.sort()
	print("JUMP_ARC frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	print("JUMP_ARC_COMPLETE checks=%d failures=%d mutation=%s red=%s" % [checks, failures, mutation, ",".join(families) if not families.is_empty() else "none"])
	quit(1 if failures else 0)


func _hero(hero: String) -> void:
	var state: Node = root.get_node("GameState")
	state.p1_character = hero
	router.apply_profile("solo", false)
	var world: Node = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(40)
	world.onboarding.skip()
	var layer: Object = world.player.skeletal.living_body
	if mutation == "blend":
		layer.set("mode_blend", {"takeoff": 0.06, "apex": 0.08, "fall": 0.08, "rise": 0.10, "land_light": 0.05, "land_normal": 0.04, "land_heavy": 0.03})
	elif mutation == "tuck":
		layer.set("tuck_min_seconds", 99.0)
	elif mutation == "land":
		layer.set("light_land_rate", 2.5)
	var runs: Dictionary = {}
	var done: Dictionary = {}
	for case: String in ["stand", "run", "drop_normal", "drop_heavy"]:
		runs[case] = await _capture(world, case)
		done[case] = _complete(runs[case], "%s_%s" % [hero, case])
	for case: String in ["stand", "run"]:
		var run: Dictionary = runs[case]
		var id := "%s_%s" % [hero, case]
		if not done[case]:
			continue
		_check(run.air_modes == ["takeoff", "apex", "fall"], "G1", "%s: the air after the take-off is %s, expected takeoff → apex → fall" % [id, " → ".join(run.air_modes)])
		_check(run.air_turns.is_empty(), "G2", "%s: %d ticks in the air after the take-off turn a bone ≥ %.0f°: %s" % [id, run.air_turns.size(), TURN_LIMIT, run.air_turns.slice(0, 4)])
		_check(run.takeoff_max <= float(BEFORE_TAKEOFF[id]) + 0.05, "G3", "%s: the take-off turns a bone %.1f° in a tick, above %.1f° before (aa51881)" % [id, run.takeoff_max, BEFORE_TAKEOFF[id]])
		_check(run.land_max < FLIP_LIMIT, "flip", "%s: a bone flips %.1f° in one tick on the landing (%s)" % [id, run.land_max, run.land_bone])
	var stand: Dictionary = runs["stand"]
	var normal: Dictionary = runs["drop_normal"]
	var heavy: Dictionary = runs["drop_heavy"]
	if done["stand"]:
		_check(stand.leg_turns.is_empty(), "G4legs", "%s_stand: %d landing ticks turn a leg bone ≥ %.0f°: %s" % [hero, stand.leg_turns.size(), TURN_LIMIT, stand.leg_turns.slice(0, 4)])
		_check(stand.tier == "light" and stand.low >= float(BEFORE_LIGHT_HIPS[hero]) - 0.0005, "G4depth", "%s_stand: the %s landing's hips reach %.3f m, below %.3f m before (aa51881)" % [hero, stand.tier, stand.low, BEFORE_LIGHT_HIPS[hero]])
	for case: String in ["drop_normal", "drop_heavy"]:
		var drop: Dictionary = runs[case]
		if done[case]:
			_check("apex" not in drop.air_modes, "G1", "%s_%s: a drop without a take-off tucks (%s)" % [hero, case, " → ".join(drop.air_modes)])
			_check(drop.land_max < FLIP_LIMIT, "flip", "%s_%s: a bone flips %.1f° in one tick on the landing (%s)" % [hero, case, drop.land_max, drop.land_bone])
	if done["stand"] and done["drop_normal"] and done["drop_heavy"]:
		_check(stand.tier == "light" and normal.tier == "normal" and heavy.tier == "heavy", "count", "%s: the landings are light / normal / heavy (got %s / %s / %s)" % [hero, stand.tier, normal.tier, heavy.tier])
		_check(stand.low > normal.low and normal.low > heavy.low, "G4order", "%s: the hips go lower light %.3f > normal %.3f > heavy %.3f" % [hero, stand.low, normal.low, heavy.low])
	print("JUMP_ARC %s light %.3f normal %.3f heavy %.3f (lowest hips, m)" % [hero, stand.get("low", INF), normal.get("low", INF), heavy.get("low", INF)])
	world.queue_free()
	current_scene = null
	await _ticks(3)


func _complete(run: Dictionary, id: String) -> bool:
	var ok: bool = run.get("press", -1) >= 0 and run.get("land", -1) > run.get("press", -1)
	_check(ok, "count", "%s: the hero left the ground and landed (press %d, land %d)" % [id, run.get("press", -1), run.get("land", -1)])
	return ok


## One jump or drop on the market street (z = 20), the camera looking north. Per tick: the state, the floor contact,
## the living-body mode, the largest bone / leg-bone turn and the hips height; then the windows of § 2.4.
func _capture(world: Node, case: String) -> Dictionary:
	var hero: CharacterBody3D = world.player
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	var start := Vector3(-7.0, 0, 20) if case == "run" else Vector3(-1.0, 0, 20)
	hero.restart_at(start)
	hero._set_forward(Vector3.RIGHT)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-0.0, 1.0)
	await _ticks(30)
	var skeleton: Skeleton3D = hero.skeletal.hero_skeleton
	var layer: Object = hero.skeletal.living_body
	var previous: Dictionary = {}
	var rows: Array[Dictionary] = []
	var press_at := 36 if case == "run" else 0
	var drop: float = float(DROPS.get(case, 0.0))
	var landed := -1
	for tick: int in 200:
		if case == "run" and tick == 0:
			_key(KEY_D, true)
		if tick == press_at and drop > 0.0:
			hero.global_position = start + Vector3.UP * drop
			hero.velocity = Vector3.ZERO
			hero._set_state(JUMP_STATE)
		elif tick == press_at:
			_key(KEY_SPACE, true)
		elif tick == press_at + 6:
			_key(KEY_SPACE, false)
		await _ticks(1)
		var turn := 0.0
		var turn_bone := ""
		var leg := 0.0
		for bone: int in skeleton.get_bone_count():
			var rotation: Quaternion = skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion()
			if previous.has(bone):
				var degrees: float = rad_to_deg(2.0 * acos(clampf(absf(rotation.dot(previous[bone])), 0.0, 1.0)))
				if degrees > turn:
					turn = degrees
					turn_bone = skeleton.get_bone_name(bone)
				var name: String = skeleton.get_bone_name(bone)
				if name.contains("Leg") or name.contains("Foot") or name.contains("Toe"):
					leg = maxf(leg, degrees)
			previous[bone] = rotation
		var hips: float = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin).y - hero.floor_y()
		rows.append({"t": tick, "state": int(hero.state), "floor": hero.is_on_floor(), "mode": String(layer.get("mode")), "turn": turn, "bone": turn_bone, "leg": leg, "hips": hips, "tier": String(layer.get("landing_tier"))})
		if landed < 0 and tick > press_at and hero.is_on_floor() and int(hero.state) != JUMP_STATE:
			landed = tick
		if landed >= 0 and tick >= landed + LANDING_TICKS:
			break
	_key(KEY_D, false)
	var press := -1
	for row: Dictionary in rows:
		if row.state == JUMP_STATE:
			press = row.t
			break
	var out: Dictionary = {"press": press, "land": landed, "air_modes": [], "air_turns": [], "leg_turns": [], "takeoff_max": 0.0, "land_max": 0.0, "land_bone": "", "low": INF, "tier": ""}
	if press < 0 or landed < 0:
		return out
	for row: Dictionary in rows:
		var t: int = row.t
		if t >= press and t < landed:
			var mode: String = row.mode
			if out.air_modes.is_empty() or out.air_modes.back() != mode:
				out.air_modes.append(mode)
		if t >= press and t < press + TAKEOFF_TICKS:
			out.takeoff_max = maxf(out.takeoff_max, row.turn)
		if t >= press + TAKEOFF_TICKS and t < landed and row.turn >= TURN_LIMIT:
			out.air_turns.append("+%d %.1f %s" % [t - press, row.turn, row.bone])
		if t >= landed and t <= landed + LANDING_TICKS:
			if row.leg >= TURN_LIMIT:
				out.leg_turns.append("+%d %.1f" % [t - press, row.leg])
			if row.turn > out.land_max:
				out.land_max = row.turn
				out.land_bone = row.bone
			out.low = minf(out.low, row.hips)
		if t == landed:
			out.tier = row.tier
	print("JUMP_ARC %s %s press=%d land=%d air=%s takeoff_max=%.1f air_turns=%d leg_turns=%d land_max=%.1f(%s) low=%.3f tier=%s" % [hero.data.id, case, press, landed, "→".join(out.air_modes), out.takeoff_max, out.air_turns.size(), out.leg_turns.size(), out.land_max, out.land_bone, out.low, out.tier])
	return out
