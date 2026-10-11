extends SceneTree
## Plan docs/Plans/2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall.md step 0, branch A (steps 1–3): T6's review probe
## (anim_probe.gd, 2026-10-09) turned into a fixture with the plan's measures.
## Subject: for both heroes in the production CityWorld (its camera, light and HUD) driven by real keys (D, A, W, S,
## Space; one stick at 0.45 for the walk) — a stop from a walk and from a run, a 180° reverse, a 90° turn, a landing
## turned round, a standing and a running jump, a 3.5 m and a 6.5 m drop, a wall kick off the practice ledge (and one
## kicked 4 ticks after the catch, while TraversalBlend still blends the hang in — merge of branches A and B):
##   bone   no hero bone turns more than 30°/tick on the ground or in a transition;
##   foot   a planted foot (toe within 0.03 m of its standing height, both ticks on the floor) moves ≤ 50 mm in a tick;
##   freeze ≤ 4 ticks in a row at 0.0°/tick (< 0.1°, the pose in skeleton space as T6 measured it) while the body
##          moves or a transition runs (every window below);
##   hips   while a standing landing settles (from its lowest hips on) they never rise above the standing stance
##          + 0.02 m;
##   wall   from the wall kick on, no hero bone turns more than 30°/tick (the 160° turn takes ≥ 6 ticks);
##   legs   on a reverse, at ≥ 1 m/s, the leg clip's direction agrees with the travel seen from the drawn body within
##          67.5° (the clip is chosen for the body that is drawn, not for a course it has not turned to yet). Not on the
##          90° turn: there the legs keep the gameplay course, as on 595490d, because the frozen turn window of
##          tools/animation/ground_contact_check.gd (Choko frames 203–206) is measured on that course's footfalls; with
##          the legs on the drawn body that window moved 0.177 m (> 0.03) — a conflict handed to T1.
## Turns are measured in world space: the skeleton node's rotation times each bone's skeleton-space rotation, so a
## heading snapped on the node (the 160° wall kick) counts and a heading carried by the hips while the node flips
## (HeroBodyMotion's yaw offset) does not. The drawn heading is the hip line (LeftUpLeg → RightUpLeg), as in T6's probe.
## Every threshold is a plan literal, PLACEHOLDER until T6 accepts the frames; none is read from the current code.
##   --break=land|kneel|guard|foot|legs|kick — negative controls: the product of main 595490d put back for one family
##      (the landing played to its straight end with the 0.12 s hold; the heavy landing's kneel slid along the ground;
##      the guard at full weight from the first idle tick; the planted foot released in one tick; the legs chosen for
##      the gameplay course with the 420°/s body turn; the wall-kick heading snapped in one tick). A negative runs only
##      the actions of its family.
##   --break=yield|memory|follow — the merge of branches A and B, one seam at a time (all family wall): TraversalBlend
##      blends the kick's first tick in skeleton space while the node flips (yield); the kick remembers the pose before
##      TraversalBlend has drawn it (memory, seen on the early kick); TraversalBlend hands the kick over without following
##      the drawn pose, so it blends from the hang once the kick ends (follow).
##   --verbose prints every window tick (ANIM_GROUND_ROW).
##   --trace=<file> writes every tick's gameplay position, velocity and state (and its SHA-256) for a before/after
##      comparison: the presentation must not move the body.
## Sentinel: ANIM_GROUND_COMPLETE checks=N failures=M mutation=<m> red=<failed families|none>; failures print
## "ANIM_GROUND: [family] ...".
const BONE_LIMIT: float = 30.0          # plan: «на землі й на переходах ≤ 30°/тік на кістку» (PLACEHOLDER)
const FOOT_LIMIT: float = 0.050         # plan: «поставлена ступня за 1 тік не стрибає більше ніж на 50 мм» (PLACEHOLDER)
const FOOT_PLANT: float = 0.03          # T6 probe's planted-toe tolerance over the standing toe height (anim_lib.py)
const FREEZE_TICKS: int = 4             # plan: «≤ 4 тики підряд по 0,0°/тік» (PLACEHOLDER)
const FREEZE_DEGREES: float = 0.1       # «0,0°/тік»: T6 counted 7 such ticks on 595490d's light landing; headless they read 0.04–0.06°
const HIPS_RISE: float = 0.02           # plan: «таз не піднімається вище стійки (+0,02 м)» (PLACEHOLDER)
const HIPS_BOTTOM_TICKS: int = 20      # the landing's bottom is looked for in its first 20 ticks (the heavy one is down by ~14)
const WALL_LIMIT: float = 30.0          # plan step 3: «≤ 30°/тік» (PLACEHOLDER)
const LEGS_AGREE: float = 67.5          # one and a half sectors of LocomotionCadence's eight (45° each)
const LEGS_SPEED: float = 1.0           # m/s: below it a sector is noise
const JUMP_STATE := 4
const CASES: Array[String] = ["loco", "turn", "jump_stand", "jump_run", "drop_normal", "drop_heavy", "wallkick",
	"wallkick_early"]
const BREAK_CASES: Dictionary = {"land": ["jump_stand", "drop_normal"], "kneel": ["drop_heavy"], "guard": ["loco"],
	"foot": ["loco"], "legs": ["turn"], "kick": ["wallkick"], "yield": ["wallkick"], "memory": ["wallkick_early"],
	"follow": ["wallkick"]}
const SECTORS: Array[String] = ["Fwd", "Fwd_R", "Right", "Bwd_R", "Bwd", "Bwd_L", "Left", "Fwd_L"]
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var trace_path: String = ""
var verbose: bool = false
var trace: PackedStringArray = []
var trace_hash := HashingContext.new()
var red: Dictionary = {}
var summary: PackedStringArray = []
var world: Node
var hero: CharacterBody3D
var held_keys: Dictionary = {}


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
		elif argument.begins_with("--trace="):
			trace_path = argument.trim_prefix("--trace=")
		elif argument == "--verbose":
			verbose = true
	trace_hash.start(HashingContext.HASH_SHA256)
	_run.call_deferred()


func _check(ok: bool, family: String, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("ANIM_GROUND: [%s] %s" % [family, label])


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	if bool(held_keys.get(code, false)) == down:
		return
	held_keys[code] = down
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _stick_x(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _release_all() -> void:
	for code: Key in held_keys.keys():
		_key(code, false)
	_stick_x(0.0)


func _run() -> void:
	await process_frame
	if mutation != "none" and not BREAK_CASES.has(mutation):
		push_error("ANIM_GROUND: unknown --break=%s" % mutation)
		quit(2)
		return
	var router: Node = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	for hero_name: String in ["choko", "skea"]:
		state.p1_character = hero_name
		router.apply_profile("solo", false)
		world = load("res://scenes/world/CityWorld.tscn").instantiate()
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
		hero = world.player
		_apply_break()
		for case_name: String in (BREAK_CASES[mutation] if mutation != "none" else CASES):
			var run: Dictionary = await _capture(hero_name, case_name)
			_judge(hero_name, case_name, run)
		_release_all()
		world.queue_free()
		current_scene = null
		await _ticks(3)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	if not trace_path.is_empty():
		var file := FileAccess.open(trace_path, FileAccess.WRITE)
		file.store_string("\n".join(trace) + "\n")
		file.close()
		print("ANIM_GROUND trace rows=%d sha256=%s" % [trace.size(), trace_hash.finish().hex_encode()])
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	for line: String in summary:
		print(line)
	var families: Array = red.keys()
	families.sort()
	print("ANIM_GROUND frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	print("ANIM_GROUND_COMPLETE checks=%d failures=%d mutation=%s red=%s" % [checks, failures, mutation, ",".join(families) if not families.is_empty() else "none"])
	quit(1 if failures else 0)


## The product of main 595490d, one family at a time. Each value is the one that tree ran with.
func _apply_break() -> void:
	var rig: Object = hero.skeletal
	match mutation:
		"land":
			rig.living_body.set("land_settle", false)
		"kneel":
			# The heavy landing of 595490d whole: its fast descent drags the kneeling foot, the lift alone is not it.
			rig.living_body.set("land_settle", false)
			rig.living_body.set("kneel_step", false)
		"guard":
			rig.idle_presence.set("ramp_seconds", 0.0)
		"foot":
			rig.ground_contact.set("step_seconds", 0.0)
		"legs":
			rig.body_motion.set("legs_follow_body", false)
			rig.body_motion.set("pivot_turn_rate", 420.0)   # HeroBodyMotion.BODY_TURN_RATE on main
		"kick":
			rig.body_motion.set("air_turn_rate", 0.0)
			rig.body_motion.set("kick_blend", 0.0)
		"yield":
			rig.traversal_blend.set("yield_kick", false)
		"memory":
			rig.body_motion.set("remember_drawn", false)
		"follow":
			rig.traversal_blend.set("follow_kick", false)


func _view(view: Vector3) -> void:
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-view.x, -view.z)


func _point(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin


## T6's case scripts (anim_probe.gd), unchanged in timing, plus the 3.5 m drop of jump_arc_check.
func _capture(hero_name: String, case_name: String) -> Dictionary:
	_release_all()
	var start := Vector3(-7, 0, 20)
	var forward := Vector3.RIGHT
	var view := Vector3.FORWARD     # camera looks −z: travel along ±x is seen from the side
	match case_name:
		"jump_stand":
			start = Vector3(-1, 0, 20)
		"drop_normal", "drop_heavy":
			start = Vector3(-6, 0, 20)
		"wallkick", "wallkick_early":
			start = Vector3(4, 0, 18.2)
			forward = Vector3.FORWARD
			view = Vector3.LEFT      # camera looks −x: D moves −z, the approach to the ledge is seen from the side
	hero.restart_at(start)
	hero._set_forward(forward)
	_view(view)
	var skeleton: Skeleton3D = hero.skeletal.hero_skeleton
	var stance: Array[float] = []
	for tick: int in 30:
		await _ticks(1)
		if tick >= 10:
			stance.append(_point(skeleton, "Hips").y - hero.floor_y())
	var rest_toe: Dictionary = {}
	for side: String in ["Left", "Right"]:
		rest_toe[side] = _point(skeleton, side + "ToeBase").y - hero.floor_y()
	var stance_hips: float = 0.0
	for value: float in stance:
		stance_hips += value / float(stance.size())
	var previous: Dictionary = {}
	var rows: Array[Dictionary] = []
	var mark: Dictionary = {}
	var limit := 260
	var tick := 0
	while tick < limit:
		var t := tick
		var parkour: String = str(hero.get_meta("parkour_presentation", {}).get("phase", ""))
		match case_name:
			"loco":
				# idle 0–23 · walk (stick 0.45) 24–95 · stop 96–135 · jog (D) 136–207 · stop 208–259
				if t == 24:
					_stick_x(0.45)
				elif t == 96:
					_stick_x(0.0)
				elif t == 136:
					_key(KEY_D, true)
				elif t == 208:
					_key(KEY_D, false)
			"turn":
				# jog +x (D) 6–59 · reverse (A) 60–109 · turn 90° (W) 110–165 · jump at 150 · S in the air 166–199
				_key(KEY_D, t >= 6 and t < 60)
				_key(KEY_A, t >= 60 and t < 110)
				_key(KEY_W, t >= 110 and t < 166)
				_key(KEY_SPACE, t >= 150 and t < 156)
				_key(KEY_S, t >= 166 and t < 200)
				limit = 240
			"jump_stand":
				if t == 10:
					_key(KEY_SPACE, true)
				elif t == 16:
					_key(KEY_SPACE, false)
				limit = 110
			"jump_run":
				if t == 4:
					_key(KEY_D, true)
				elif t == 40:
					_key(KEY_SPACE, true)
				elif t == 46:
					_key(KEY_SPACE, false)
				elif t == 112:
					_key(KEY_D, false)
				limit = 150
			"drop_normal", "drop_heavy":
				if t == 6:
					hero.global_position = start + Vector3.UP * (3.5 if case_name == "drop_normal" else 6.5)
					hero.velocity = Vector3.ZERO
					hero._set_state(JUMP_STATE)
				limit = 120
			"wallkick":
				if t == 6:
					_key(KEY_D, true)
				if t == 9:
					_key(KEY_SPACE, true)
				if not mark.has("hang") and parkour == "hang":
					mark["hang"] = t
				if mark.has("hang"):
					var h := t - int(mark.hang)
					if h == 16:
						_key(KEY_SPACE, false)
					if h == 18:
						_key(KEY_D, false)
						_key(KEY_A, true)
					if h == 24:
						_key(KEY_SPACE, true)
					elif h == 30:
						_key(KEY_SPACE, false)
					if h == 60:
						_key(KEY_A, false)
					limit = int(mark.hang) + 110
				elif t > 100:
					limit = t
				else:
					limit = 200
			"wallkick_early":
				# The same approach and ledge; the jump let go 1 tick after the catch, the kick pressed 3 ticks after it —
				# TraversalBlend still blends the hang in (BLEND_SECONDS) when the kick takes over. A is let go 35 ticks after
				# the kick, as in "wallkick" (kick h25, A up h60), so the landing is the same kind.
				if t == 6:
					_key(KEY_D, true)
				if t == 9:
					_key(KEY_SPACE, true)
				if not mark.has("hang") and parkour == "hang":
					mark["hang"] = t
				if mark.has("hang"):
					var h := t - int(mark.hang)
					if h == 1:
						_key(KEY_SPACE, false)
					if h == 2:
						_key(KEY_D, false)
						_key(KEY_A, true)
					if h == 3:
						_key(KEY_SPACE, true)
					elif h == 9:
						_key(KEY_SPACE, false)
					if mark.has("kick") and t - int(mark.kick) == 35:
						_key(KEY_A, false)
					limit = int(mark.hang) + 110
				elif t > 100:
					limit = t
				else:
					limit = 200
		await _ticks(1)
		var row: Dictionary = _row(t, skeleton, previous)
		rows.append(row)
		if not mark.has("left") and not hero.is_on_floor() and t > 3:
			mark["left"] = t
		if mark.has("left") and not mark.has("landed") and hero.is_on_floor() and t > int(mark.left):
			mark["landed"] = t
		if not mark.has("kick") and String(row.parkour) == "wall_kick":
			mark["kick"] = t
		if not trace_path.is_empty():
			var cells: Array = [hero_name, case_name, t, hero.global_position, hero.velocity, int(hero.state), hero.is_on_floor()]
			var line: PackedStringArray = []
			for value: Variant in cells:
				line.append(var_to_str(value))
			trace.append("\t".join(line))
			trace_hash.update(var_to_bytes(cells))
		tick += 1
	_release_all()
	return {"rows": rows, "mark": mark, "stance_hips": stance_hips, "rest_toe": rest_toe}


func _row(t: int, skeleton: Skeleton3D, previous: Dictionary) -> Dictionary:
	var node: Quaternion = skeleton.global_basis.orthonormalized().get_rotation_quaternion()
	var turn := 0.0
	var turn_bone := ""
	var pose := 0.0
	for bone: int in skeleton.get_bone_count():
		var local: Quaternion = skeleton.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()
		var rotation: Quaternion = node * local
		if previous.has(bone):
			var degrees: float = rad_to_deg(2.0 * acos(clampf(absf(rotation.dot(previous[bone][0])), 0.0, 1.0)))
			if degrees > turn:
				turn = degrees
				turn_bone = skeleton.get_bone_name(bone)
			pose = maxf(pose, rad_to_deg(2.0 * acos(clampf(absf(local.dot(previous[bone][1])), 0.0, 1.0))))
		previous[bone] = [rotation, local]
	var floor_y: float = hero.floor_y()
	var lateral: Vector3 = _point(skeleton, "RightUpLeg") - _point(skeleton, "LeftUpLeg")
	var drawn: Vector3 = Vector3.UP.cross(Vector3(lateral.x, 0.0, lateral.z)).normalized()
	var rig: Object = hero.skeletal
	return {"t": t, "state": int(hero.state), "floor": hero.is_on_floor(), "velocity": hero.velocity,
		"turn": turn, "bone": turn_bone, "pose": pose, "floor_y": floor_y,
		"toe": {"Left": _point(skeleton, "LeftToeBase"), "Right": _point(skeleton, "RightToeBase")},
		"hips": _point(skeleton, "Hips").y - floor_y, "drawn": drawn,
		"clip": String(rig.locomotion.source_clip), "special": String(rig.locomotion.special_clip),
		"living": String(rig.living_body.mode), "parkour": str(hero.get_meta("parkour_presentation", {}).get("phase", "")),
		"contact": _contact_state(rig)}


## Ground-contact state of each foot for --verbose rows: P planted, S stepping, - free (read-only).
func _contact_state(rig: Object) -> String:
	var state: Variant = rig.ground_contact.get("_state")
	var out := ""
	for side: String in ["Left", "Right"]:
		var foot: Dictionary = (state as Dictionary).get(side, {}) if state is Dictionary else {}
		out += "S" if foot.has("step_from") else ("P" if bool(foot.get("planted", false)) else "-")
	return out


## Windows of each action: [name, first tick, end tick (exclusive), families].
func _windows(case_name: String, mark: Dictionary, end: int) -> Array:
	var land: int = int(mark.get("landed", -1))
	var out: Array = []
	match case_name:
		"loco":
			out.append(["stop_walk", 96, 136, ["bone", "foot", "freeze"]])
			out.append(["start_run", 136, 160, []])   # reported only: a start from standing is not an action of this plan
			out.append(["stop_run", 208, 260, ["bone", "foot", "freeze"]])
		"turn":
			out.append(["reverse", 60, 110, ["bone", "foot", "freeze", "legs"]])
			out.append(["turn90", 110, 150, ["bone", "foot", "freeze"]])   # legs: see the header
			if land >= 0:
				out.append(["land_turned", land, mini(land + 40, end), ["bone", "foot", "freeze", "hips"]])
		"jump_stand":
			if land >= 0:
				out.append(["land", land, mini(land + 45, end), ["bone", "foot", "freeze", "hips"]])
		"jump_run":
			if land >= 0:
				out.append(["land_running", land, mini(land + 20, end), ["bone", "foot", "freeze"]])
			out.append(["stop_after", 112, 150, ["bone", "foot", "freeze"]])
		"drop_normal", "drop_heavy":
			if land >= 0:
				out.append(["land", land, mini(land + 60, end), ["bone", "foot", "freeze", "hips"]])
		"wallkick", "wallkick_early":
			if mark.has("kick"):
				out.append(["kick", int(mark.kick), mini(int(mark.kick) + 25, end), ["wall", "freeze"]])
			if land >= 0:
				out.append(["land_after_kick", land, mini(land + 30, end), ["bone", "foot", "freeze"]])
	return out


func _judge(hero_name: String, case_name: String, run: Dictionary) -> void:
	var rows: Array = run.rows
	var mark: Dictionary = run.mark
	var id := "%s_%s" % [hero_name, case_name]
	var needs_land: bool = case_name not in ["loco"]
	if needs_land:
		_check(mark.has("landed"), "count", "%s: the hero left the ground and landed (marks %s)" % [id, str(mark)])
	if case_name in ["wallkick", "wallkick_early"]:
		_check(mark.has("kick"), "count", "%s: the wall kick fired off the practice ledge (marks %s)" % [id, str(mark)])
	for window: Array in _windows(case_name, mark, rows.size()):
		var name: String = window[0]
		var first: int = window[1]
		var end: int = window[2]
		var families: Array = window[3]
		var wid := "%s %s" % [id, name]
		var worst := 0.0
		var worst_at := -1
		var worst_bone := ""
		var slide := 0.0
		var slide_at := -1
		var slide_side := ""
		var still := 0
		var longest := 0
		var longest_at := -1
		var low := INF
		var high := -INF
		var high_at := -1
		var legs_worst := 0.0
		var legs_at := -1
		var legs_clip := ""
		for k: int in range(maxi(first, 1), mini(end, rows.size())):
			var row: Dictionary = rows[k]
			var before: Dictionary = rows[k - 1]
			if verbose:
				print("ANIM_GROUND_ROW %s t=%d st=%d fl=%s v=%.2f turn=%.2f %s pose=%.2f hips=%.3f clip=%s sp=%s lb=%s pk=%s gc=%s yaw=%.1f L=%s R=%s" % [wid, row.t, row.state, row.floor, Vector2(row.velocity.x, row.velocity.z).length(), row.turn, row.bone, row.pose, row.hips, row.clip, row.special, row.living, row.parkour, row.contact, rad_to_deg(atan2(row.drawn.x, row.drawn.z)), row.toe.Left, row.toe.Right])
			if row.turn > worst:
				worst = row.turn
				worst_at = row.t
				worst_bone = row.bone
			still = still + 1 if row.pose < FREEZE_DEGREES else 0
			if still > longest:
				longest = still
				longest_at = row.t
			if row.floor and before.floor:
				for side: String in ["Left", "Right"]:
					var limit: float = float(run.rest_toe[side]) + FOOT_PLANT
					var a: Vector3 = before.toe[side]
					var b: Vector3 = row.toe[side]
					if a.y - float(before.floor_y) <= limit and b.y - float(row.floor_y) <= limit:
						var moved: float = Vector2(b.x - a.x, b.z - a.z).length()
						if moved > slide:
							slide = moved
							slide_at = row.t
							slide_side = side
			if row.floor and row.hips < low and k < first + HIPS_BOTTOM_TICKS:
				# The exit begins at the bottom of the landing (its first HIPS_BOTTOM_TICKS): only a rise after it counts
				# (plan: «поки триває вихід»); a later breath of the stance lower than a shallow landing is not its bottom.
				low = row.hips
				high = -INF
				high_at = -1
			if row.floor and row.hips > high:
				high = row.hips
				high_at = row.t
			var flat := Vector3(row.velocity.x, 0.0, row.velocity.z)
			var sector: int = _sector(String(row.clip))
			if row.floor and flat.length() >= LEGS_SPEED and sector >= 0:
				var drawn: Vector3 = row.drawn
				var right: Vector3 = drawn.cross(Vector3.UP)
				var travel: float = rad_to_deg(atan2(flat.dot(right), flat.dot(drawn)))
				var off: float = absf(wrapf(travel - float(sector) * 45.0, -180.0, 180.0))
				if off > legs_worst:
					legs_worst = off
					legs_at = row.t
					legs_clip = row.clip
		summary.append("ANIM_GROUND %s ticks=%d..%d bone=%.1f(t%d %s) foot=%.0fmm(t%d %s) freeze=%d(t%d) hips=%.3f→%.3f/%.3f(t%d) legs=%.0f(t%d %s)" % [wid, first, end - 1, worst, worst_at, worst_bone, slide * 1000.0, slide_at, slide_side, longest, longest_at, low, high, float(run.stance_hips), high_at, legs_worst, legs_at, legs_clip])
		if "bone" in families:
			_check(worst <= BONE_LIMIT, "bone", "%s: %s turns %.1f°/tick at t%d, above %.0f°" % [wid, worst_bone, worst, worst_at, BONE_LIMIT])
		if "wall" in families:
			_check(worst <= WALL_LIMIT, "wall", "%s: %s turns %.1f°/tick at t%d after the wall kick, above %.0f°" % [wid, worst_bone, worst, worst_at, WALL_LIMIT])
		if "foot" in families:
			_check(slide <= FOOT_LIMIT, "foot", "%s: the planted %s foot moves %.0f mm in a tick at t%d, above %.0f mm" % [wid, slide_side, slide * 1000.0, slide_at, FOOT_LIMIT * 1000.0])
		if "freeze" in families:
			_check(longest <= FREEZE_TICKS, "freeze", "%s: %d ticks in a row at 0.0°/tick (ending t%d), above %d" % [wid, longest, longest_at, FREEZE_TICKS])
		if "hips" in families:
			_check(high <= float(run.stance_hips) + HIPS_RISE, "hips", "%s: the hips rise to %.3f m at t%d, above the stance %.3f + %.2f m" % [wid, high, high_at, float(run.stance_hips), HIPS_RISE])
		if "legs" in families:
			_check(legs_worst <= LEGS_AGREE, "legs", "%s: the legs play %s %.0f° off the travel seen from the drawn body at t%d, above %.1f°" % [wid, legs_clip, legs_worst, legs_at, LEGS_AGREE])


## Direction sector of a locomotion source clip (LocomotionCadence order), -1 when it is not a directional loop.
func _sector(clip: String) -> int:
	if clip.begins_with("Sprint"):
		return 0
	var cadence: GDScript = load("res://scripts/fighter/LocomotionCadence.gd")
	var walk: int = cadence.WALK.find(clip)
	if walk >= 0:
		return walk
	return cadence.JOG.find(clip)
