extends SceneTree
## Plan docs/Plans/2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall.md step 0, branch B (T2-Б): the T6 review probe
## (scratchpad anim-review/probe/anim_probe.gd, main 595490d) turned into a regression for the rope, Skea's wall run,
## the ledge and the landing roll. Production CityWorld with its camera, light and HUD; real keys through
## Input.parse_input_event; both heroes; the T6 stations and key scripts.
## Subject: for every branch-B traversal action, drawn on the hero skeleton, from the press to the landing:
##   turn   — no hero bone turns more than TURN_LIMIT degrees in one tick (skeleton-space rotation, as T6 measured);
##   frozen — never more than FROZEN_RUN ticks in a row at 0.0°/tick (every bone under FROZEN_DEG) while the body
##            moves (≥ MOVING m/s) or an action holds it (rope attached, a parkour phase);
##   lean   — hanging on the rope after the catch, the body (Hips → neck) within LEAN_LIMIT degrees of the rope
##            (hand → anchor);
##   post   — the hanging body never slides against the support of its own anchor (GrappleHook._own_support);
##   arm    — the camera arm (SpringArm3D hit length) is at least ARM_MIN metres while hanging;
##   lift   — the mantle is a pull, not a lift: over its rise the drawn hips' vertical speed peaks at LIFT_RATIO × its
##            mean or more (a lift rises at one speed). T2's own guard for the plan's words, PLACEHOLDER — not a literal.
## turn/frozen/lean/post/arm thresholds are the plan's literals (PLACEHOLDER until T6 accepts the frames), never values
## read off the product.
## OPEN (measured and printed, not counted, pinned in the sentinel so a change has to be looked at):
##   rope_post  — the post contact is a geometry decision returned to T1 (the plan's 0.7 m arm measured worse than 1.0 m);
##   ledge_land — the light landing after the mantle is drawn by LivingBodyMotion's landings, branch A's lines.
##   --break=main|blend|lean|camera|wall|ledge|roll — negative controls. `main` switches every branch-B presentation
##   change back to the product of main 595490d; the others switch back one change each. Each must go red, naming
##   its families. Run on a main checkout (where the switches do not exist) the fixture gives the same numbers.
##   --out=<dir> — per-tick TSV of every case (diagnostics for the T6 before/after review).
## Sentinel: ANIM_TRAVERSAL_COMPLETE checks=N failures=M mutation=<m> red=<failed families|none> open=<open items|none>;
## failures print "ANIM_TRAVERSAL: ...".
const TURN_LIMIT: float = 30.0
const FROZEN_DEG: float = 0.05
const FROZEN_RUN: int = 4
const MOVING: float = 0.2
const LEAN_LIMIT: float = 10.0
const ARM_MIN: float = 3.0
const LIFT_RATIO: float = 1.3
const JUMP_STATE := 4
const GRAPPLE_STATE := 13
const HANG_PHASE := 3
## Presentation switches of branch B and their main 595490d values (the --break controls). A missing property (a main
## checkout) is skipped by Object.set — the product then simply is main.
const BREAKS: Dictionary = {
	"blend": [["traversal_blend", "enabled", false]],
	"lean": [["body_motion", "rope_follow", false]],
	"camera": [["camera", "ignore_own_support", false]],
	"wall": [["parkour_motion", "wall_living", false]],
	"ledge": [["parkour_motion", "ledge_living", false]],
	"roll": [["parkour_motion", "roll_tuck", false]],
}
var checks: int = 0
var failures: int = 0
var mutation: String = "none"
var red: Dictionary = {}
var open: Dictionary = {}
var out_dir: String = ""
var router: Node
var world: Node
var hero: CharacterBody3D
var held: Dictionary = {}


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
		elif argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
	_run.call_deferred()


func _check(ok: bool, family: String, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		red[family] = true
		push_error("ANIM_TRAVERSAL: [%s] %s" % [family, label])


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	if bool(held.get(code, false)) == down:
		return
	held[code] = down
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _release_all() -> void:
	for code: Key in held.keys():
		_key(code, false)


func _run() -> void:
	await process_frame
	if not out_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(out_dir)
	router = root.get_node("InputRouter")
	var state: Node = root.get_node("GameState")
	state.set_free_move(true)
	for name: String in ["choko", "skea"]:
		await _hero(name)
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
	print("ANIM_TRAVERSAL frames=%d (the playable harness quits after 12000)" % Engine.get_process_frames())
	var opened: Array = open.keys()
	opened.sort()
	print("ANIM_TRAVERSAL_COMPLETE checks=%d failures=%d mutation=%s red=%s open=%s" % [checks, failures, mutation, ",".join(families) if not families.is_empty() else "none", ",".join(opened) if not opened.is_empty() else "none"])
	quit(1 if failures else 0)


func _hero(name: String) -> void:
	var state: Node = root.get_node("GameState")
	state.p1_character = name
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
	_apply_breaks()
	var cases: Array[String] = ["rope", "ledge", "roll"]
	if name == "skea":
		cases.append("wallrun")
	for case: String in cases:
		var rows: Array[Dictionary] = await _capture(case)
		_judge(name, case, rows)
	world.queue_free()
	current_scene = null
	await _ticks(3)


func _apply_breaks() -> void:
	var names: Array = BREAKS.keys() if mutation == "main" else ([mutation] if BREAKS.has(mutation) else [])
	for key: String in names:
		for entry: Array in BREAKS[key]:
			var owner: Object = world.camera_rig if entry[0] == "camera" else hero.skeletal.get(entry[0])
			if owner != null and String(entry[1]) in owner:
				owner.set(entry[1], entry[2])


## The T6 station and camera of each case: start, facing and the horizontal direction the camera looks along.
func _station(case: String) -> Array:
	match case:
		"rope":
			return [Vector3(0, 0, 9.5), Vector3(8, 0, -1.5).normalized(), Vector3.FORWARD]
		"ledge":
			return [Vector3(4, 0, 18.2), Vector3.FORWARD, Vector3.LEFT]
		"wallrun":
			return [Vector3(14, 0, 30.7), Vector3.FORWARD, Vector3.LEFT]
	return [Vector3(-6, 0, 20), Vector3.RIGHT, Vector3.FORWARD]


func _capture(case: String) -> Array[Dictionary]:
	_release_all()
	var station: Array = _station(case)
	var start: Vector3 = station[0]
	hero.restart_at(start)
	hero._set_forward(station[1])
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-Vector3(station[2]).x, -Vector3(station[2]).z)
	await _ticks(30)
	var skeleton: Skeleton3D = hero.skeletal.hero_skeleton
	var previous: Dictionary = {}
	for bone: int in skeleton.get_bone_count():
		previous[bone] = skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion()
	var rows: Array[Dictionary] = []
	var mark: Dictionary = {}
	var limit: int = 400
	var tick: int = 0
	while tick < limit:
		var t: int = tick
		var parkour: String = str(hero.get_meta("parkour_presentation", {}).get("phase", ""))
		match case:
			"rope":
				# tap E · pull · hold D 40 · A 40 · W 30 · S 30 · Space 50 · Z (detach) · land (T6 anim_probe «rope»)
				_key(KEY_E, t == 4)
				if not mark.has("hang") and int(hero.grapple.phase) == HANG_PHASE:
					mark["hang"] = t
				if mark.has("hang"):
					var h: int = t - int(mark.hang)
					_key(KEY_D, h >= 70 and h < 110)
					_key(KEY_A, h >= 110 and h < 150)
					_key(KEY_W, h >= 150 and h < 180)
					_key(KEY_S, h >= 180 and h < 210)
					_key(KEY_SPACE, h >= 210 and h < 260)
					_key(KEY_Z, h >= 262 and h < 264)
					limit = int(mark.hang) + 330
				elif t > 80:
					limit = t
			"ledge":
				_key(KEY_D, t >= 6 and (not mark.has("hang") or t - int(mark.hang) < 70))
				if not mark.has("hang") and parkour == "hang":
					mark["hang"] = t
				var h: int = t - int(mark.get("hang", 100000))
				_key(KEY_SPACE, (t >= 9 and not mark.has("hang")) or (mark.has("hang") and (h < 16 or (h >= 24 and h < 30))))
				if mark.has("hang"):
					limit = int(mark.hang) + 110
				elif t > 100:
					limit = t
			"wallrun":
				_key(KEY_D, t >= 6 and t < 100)
				_key(KEY_SPACE, t >= 9 and t < 70)
				limit = 170
			"roll":
				if t == 6:
					hero.global_position = start + Vector3.UP * 6.5
					hero.velocity = Vector3(4.0, -2.0, 0.0)
					hero._set_state(JUMP_STATE)
				_key(KEY_D, t >= 6 and not (mark.has("landed") and t >= int(mark.landed) + 50))
				_key(KEY_X, t >= 6 and not (mark.has("landed") and t >= int(mark.landed) + 50))
				limit = 120
		await _ticks(1)
		if not mark.has("left") and not hero.is_on_floor() and t > 3:
			mark["left"] = t
		if mark.has("left") and not mark.has("landed") and hero.is_on_floor() and t > int(mark.left):
			mark["landed"] = t
		rows.append(_row(t, skeleton, previous))
		tick += 1
	_release_all()
	await _ticks(2)
	if not out_dir.is_empty():
		var lines: PackedStringArray = []
		for row: Dictionary in rows:
			var cells: PackedStringArray = []
			for key: String in row:
				cells.append("%s=%s" % [key, str(row[key])])
			lines.append("\t".join(cells))
		var file := FileAccess.open(out_dir.path_join("%s_%s.tsv" % [hero.data.id, case]), FileAccess.WRITE)
		file.store_string("\n".join(lines) + "\n")
		file.close()
	return rows


func _world(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin


func _row(t: int, skeleton: Skeleton3D, previous: Dictionary) -> Dictionary:
	var turn: float = 0.0
	var turn_bone: String = ""
	for bone: int in skeleton.get_bone_count():
		var rotation: Quaternion = skeleton.get_bone_global_pose(bone).basis.get_rotation_quaternion()
		var degrees: float = rad_to_deg(2.0 * acos(clampf(absf(rotation.dot(previous[bone])), 0.0, 1.0)))
		if degrees > turn:
			turn = degrees
			turn_bone = skeleton.get_bone_name(bone)
		previous[bone] = rotation
	var hook: Node = hero.grapple
	var snapshot: Dictionary = hero.get_meta("parkour_presentation", {})
	var hips: Vector3 = _world(skeleton, "Hips")
	var neck: Vector3 = _world(skeleton, "neck")
	var lean: float = -1.0
	var rope: float = -1.0
	if bool(hook.attached) and int(hook.phase) == HANG_PHASE:
		var line: Vector3 = Vector3(hook.anchor_point) - (hero.global_position + Vector3(0.0, 1.25, 0.0))
		lean = rad_to_deg((neck - hips).angle_to(line))
		rope = rad_to_deg(line.angle_to(Vector3.UP))
	var post: bool = false
	var own: Array = hook.get("_own_support") if hook.get("_own_support") != null else []
	for index: int in hero.get_slide_collision_count():
		if hero.get_slide_collision(index).get_collider_rid() in own:
			post = true
	return {"t": t, "state": int(hero.state), "floor": hero.is_on_floor(), "speed": hero.velocity.length(),
		"pos": hero.global_position, "phase": int(hook.phase), "attached": bool(hook.attached),
		"hook": String(hero.skeletal.authored_hook.source_phase), "pk": str(snapshot.get("phase", "")),
		"progress": float(snapshot.get("progress", 0.0)), "turn": turn, "bone": turn_bone, "lean": lean, "rope": rope,
		"post": post, "arm": float(world.camera_rig.arm.get_hit_length()),
		"hips": hips.y - hero.floor_y(), "hipsw": hips.y, "head": _world(skeleton, "Head").y - hero.floor_y(),
		"living": String(hero.skeletal.living_body.mode),
		"lhand": _world(skeleton, "LeftHand"), "rhand": _world(skeleton, "RightHand")}


## The ticks of one action: from its first active tick to its landing (the tick the hero stands again).
func _window(rows: Array[Dictionary], case: String) -> Array[Dictionary]:
	var first: int = -1
	var last: int = -1
	for index: int in rows.size():
		var row: Dictionary = rows[index]
		var active: bool
		match case:
			"rope":
				active = int(row.state) == GRAPPLE_STATE or bool(row.attached)
			"roll":
				active = String(row.pk) == "landing_roll"
			_:
				active = not String(row.pk).is_empty() or int(row.state) == JUMP_STATE
		if active:
			if first < 0:
				first = index
			last = index
	if first < 0:
		return []
	if case == "roll":
		first = maxi(first - 2, 0) # the touchdown into the roll
	# Through the landing: the first tick on the floor out of the air and the action.
	var end: int = last
	while end + 1 < rows.size() and not (bool(rows[end].floor) and int(rows[end].state) != JUMP_STATE and int(rows[end].state) != GRAPPLE_STATE and String(rows[end].pk).is_empty()):
		end += 1
	return rows.slice(first, end + 1)


func _judge(name: String, case: String, rows: Array[Dictionary]) -> void:
	var id: String = "%s_%s" % [name, case]
	var window: Array[Dictionary] = _window(rows, case)
	var reached: bool = not window.is_empty()
	var phases: Dictionary = {}
	for row: Dictionary in rows:
		phases[String(row.pk)] = true
		if int(row.phase) == HANG_PHASE:
			phases["rope_hang"] = true
	match case:
		"rope":
			reached = reached and phases.has("rope_hang")
		"ledge":
			reached = reached and phases.has("hang") and phases.has("mantle")
		"wallrun":
			reached = reached and phases.has("wall_run")
		"roll":
			reached = reached and phases.has("landing_roll")
	_check(reached, "count", "%s: the action ran (phases %s)" % [id, phases.keys()])
	if not reached:
		return
	var family: String = {"rope": "rope", "ledge": "ledge", "wallrun": "wall", "roll": "roll"}[case]
	var turns: Array[String] = []
	var worst: float = 0.0
	var worst_at: String = ""
	var run: int = 0
	var longest: int = 0
	var longest_at: String = ""
	var coarse: int = 0
	var coarse_longest: int = 0
	for row: Dictionary in window:
		if float(row.turn) > worst:
			worst = row.turn
			worst_at = "t%d %s %s/%s" % [row.t, row.bone, row.hook, row.pk]
		if float(row.turn) > TURN_LIMIT:
			turns.append("t%d %.1f° %s (%s%s)" % [row.t, row.turn, row.bone, row.hook, "/" + String(row.pk) if not String(row.pk).is_empty() else ""])
		var holding: bool = float(row.speed) >= MOVING or bool(row.attached) or not String(row.pk).is_empty()
		if holding and float(row.turn) < FROZEN_DEG:
			run += 1
			if run > longest:
				longest = run
				longest_at = "t%d %s/%s" % [row.t, row.hook, row.pk]
		else:
			run = 0
		# Diagnostic only: T6's sheets print whole degrees, so «0°/тік» there is anything under 0.5°.
		coarse = coarse + 1 if holding and float(row.turn) < 0.5 else 0
		coarse_longest = maxi(coarse_longest, coarse)
	_check(turns.is_empty(), family + "_turn", "%s: %d ticks turn a bone > %.0f°/tick: %s" % [id, turns.size(), TURN_LIMIT, turns.slice(0, 6)])
	_check(longest <= FROZEN_RUN, family + "_frozen", "%s: %d ticks in a row at 0.0°/tick while moving or held (ending %s), limit %d" % [id, longest, longest_at, FROZEN_RUN])
	var summary: String = "ANIM_TRAVERSAL %s ticks=%d max_turn=%.1f (%s) frozen_run=%d under_half_degree_run=%d" % [id, window.size(), worst, worst_at, longest, coarse_longest]
	if case == "ledge":
		var speeds: Array[float] = []
		var previous_hips: float = NAN
		for row: Dictionary in window:
			var rising: bool = String(row.pk) == "mantle" and float(row.progress) > 0.0 and float(row.progress) <= 0.5
			if rising and not is_nan(previous_hips):
				speeds.append((float(row.hipsw) - previous_hips) * 60.0)
			previous_hips = float(row.hipsw) if String(row.pk) == "mantle" else NAN
		var mean: float = 0.0
		var peak: float = 0.0
		for speed: float in speeds:
			mean += speed / float(maxi(speeds.size(), 1))
			peak = maxf(peak, speed)
		var ratio: float = peak / mean if mean > 0.001 else 0.0
		_check(speeds.size() >= 4 and ratio >= LIFT_RATIO, family + "_lift", "%s: the mantle's hips rise at %.2f m/s at most against %.2f m/s on average (×%.2f over %d ticks), a lift under ×%.1f" % [id, peak, mean, ratio, speeds.size(), LIFT_RATIO])
		var landed: Array[String] = []
		var after: bool = false
		for row: Dictionary in rows:
			after = after or String(row.pk) == "mantle"
			if after and String(row.living).begins_with("land_") and not landed.has(String(row.living)):
				landed.append(String(row.living))
		if not landed.is_empty():
			open["ledge_land"] = true
		summary += " rise_ratio=%.2f landing_after_mantle=%s" % [ratio, ",".join(landed) if not landed.is_empty() else "none"]
	if case == "rope":
		var lean_max: float = 0.0
		var lean_at: String = ""
		var lean_bad: Array[String] = []
		var posts: Array[String] = []
		var arm_min: float = INF
		var arm_bad: Array[String] = []
		var rope_max: float = 0.0
		for row: Dictionary in window:
			if int(row.phase) != HANG_PHASE or not bool(row.attached):
				continue
			if bool(row.post):
				posts.append("t%d" % row.t)
			if bool(row.floor):
				continue
			arm_min = minf(arm_min, row.arm)
			if float(row.arm) < ARM_MIN:
				arm_bad.append("t%d %.2f" % [row.t, row.arm])
			if String(row.hook) == "catch":
				continue
			rope_max = maxf(rope_max, row.rope)
			if float(row.lean) > lean_max:
				lean_max = row.lean
				lean_at = "t%d rope %.0f°" % [row.t, row.rope]
			if float(row.lean) > LEAN_LIMIT:
				lean_bad.append("t%d %.1f° (rope %.0f°)" % [row.t, row.lean, row.rope])
		_check(lean_bad.is_empty(), "rope_lean", "%s: %d hanging ticks hold the body > %.0f° off the rope: %s" % [id, lean_bad.size(), LEAN_LIMIT, lean_bad.slice(0, 6)])
		if not posts.is_empty():
			open["rope_post"] = true
			print("ANIM_TRAVERSAL OPEN rope_post %s: the hanging body slides against its own anchor's post on %d ticks %s (geometry: returned to T1)" % [id, posts.size(), posts.slice(0, 8)])
		_check(arm_bad.is_empty(), "rope_arm", "%s: %d hanging ticks pull the camera arm under %.1f m: %s" % [id, arm_bad.size(), ARM_MIN, arm_bad.slice(0, 6)])
		summary += " lean_max=%.1f (%s) rope_max=%.0f post_ticks=%d arm_min=%.2f" % [lean_max, lean_at, rope_max, posts.size(), arm_min]
	print(summary)
