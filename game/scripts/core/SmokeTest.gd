class_name SmokeTest
extends Node
## Headless end-to-end check (no GPU): drives both fighters through InputRouter's virtual-input
## layer — the same path a human uses. Round 1 = Choko's kit, round 2 = Skea's kit.
## Run: godot --headless --path game -- --smoke   (make check)

var _f: int = 0
var _f0: int = 0
var _stage: int = 0
var _x0: float = 0.0
var _n0: int = 0
var arena: Node3D
var p1: Fighter
var p2: Fighter
var flow: MatchFlow
var _oks: Array[String] = []
var _done: bool = false
var _shots_dir: String = ""
var _profile0: String = ""
var _old_arena: Node = null
var _river_runs: Array = []
var _river_min_gap: float = 99.0
var _atk_frames: int = 0
var _pose_changes: int = 0
var _last_pose: Array = []
var _run: int = 0
var _max_run: int = 0
# free movement (Prototype 0.3)
var _swept: float = 0.0
var _ang0: float = 0.0
var _d0: float = 0.0
var _hp0: float = 0.0
var _turn_max: float = 0.0
var _yaw_prev: float = 0.0
var _rmax: float = 0.0
var _data0: CharacterData = null
var _rotated: bool = false
var _picks: Dictionary = {}
var _v0: Vector3 = Vector3.ZERO
var _pull_max: float = 0.0


func _ready() -> void:
	print("[smoke] start, godot %s" % Engine.get_version_info().string)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_shots_dir = a.trim_prefix("--shots=")
			Engine.max_physics_steps_per_frame = 1   # one sim step per rendered frame → captures are exact
	GameState.p2_is_cpu = false
	GameState.training_mode = false
	GameState.p1_character = "choko"
	GameState.p2_character = "skea"
	GameState.stage_index = 2   # back_alley (river is index 0)
	get_tree().change_scene_to_file.call_deferred("res://scenes/arena/Arena.tscn")


func _ok(msg: String) -> void:
	_oks.append(msg)
	print("[smoke] OK  ", msg)


func _fail(msg: String) -> void:
	if _done:
		return
	_done = true
	printerr("[smoke] FAIL ", msg)
	print("[smoke] passed before failure: ", _oks.size())
	get_tree().quit(1)


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.set_free_move(false)
	print("[smoke] ALL OK (%d checks) in %d frames" % [_oks.size(), _f])
	get_tree().quit(0)


## Saves a frame when run with a renderer and `--shots=DIR` (no-op headless).
func _shot(tag: String) -> void:
	if _shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_shots_dir.path_join("%s.png" % tag))
		print("[smoke] shot ", tag)


## "" when every physical key of `prof` belongs to exactly one p1_/p2_ action (and SOLO gives P2
## no keys at all); otherwise a description of the first clash.
func _key_clash(prof: String) -> String:
	InputRouter.apply_profile(prof, false)
	var owner: Dictionary = {}
	for p in [1, 2]:
		for a in InputRouter.ACTIONS:
			var n := InputRouter.action_name(p, a)
			for ev in InputMap.action_get_events(n):
				if not ev is InputEventKey:
					continue
				var k := ev as InputEventKey
				if prof == InputRouter.PROFILE_SOLO and p == 2:
					return "P2 has key %s in SOLO" % OS.get_keycode_string(k.physical_keycode)
				var id := "%d@%d" % [k.physical_keycode, k.location]
				if owner.has(id):
					return "key %s in both %s and %s" % [OS.get_keycode_string(k.physical_keycode), owner[id], n]
				owner[id] = n
	if owner.is_empty():
		return "no keys at all"
	return ""


## Injects a real keyboard event (physical keycode) through the engine's input pipeline.
func _key(code: Key, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)


## (Re)loads the arena on the river stage; the main loop re-acquires it and resumes at stage 30.
func _load_river() -> void:
	_load_arena(0, 30)   # river


## (Re)loads the arena on `stage_idx`; the main loop re-acquires it and resumes at `next_stage`.
func _load_arena(stage_idx: int, next_stage: int) -> void:
	_old_arena = arena
	arena = null
	InputRouter.v_clear(1)
	InputRouter.v_clear(2)
	GameState.stage_index = stage_idx
	_stage = next_stage
	_f0 = _f
	get_tree().change_scene_to_file.call_deferred("res://scenes/arena/Arena.tscn")


# --- free movement helpers (Prototype 0.3) ------------------------------------------------------
static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Angle of `who` around `center` on the ground plane (radians).
static func _bearing(who: Fighter, center: Fighter) -> float:
	var d := _flat(who.global_position - center.global_position)
	return atan2(d.z, d.x)


## Free-movement approach: press toward the target in the duel's screen frame.
func _approach3d(who: Fighter, target: Fighter, dist: float) -> bool:
	var d := _flat(target.global_position - who.global_position)
	var p := who.player_index
	var toward_right := d.dot(GameState.duel.right) > 0.0
	InputRouter.v_set(p, "right", toward_right)
	InputRouter.v_set(p, "left", not toward_right)
	if d.length() < dist:
		InputRouter.v_set(p, "right", false)
		InputRouter.v_set(p, "left", false)
		return true
	return false


## Duel camera turn this physics frame (degrees), tracked into _turn_max; also how far the view is
## from side-on to the line between the fighters (90° = side-on), tracked into _rmax.
func _track_camera_turn() -> void:
	var y: float = arena.duel_camera.view_yaw()
	_turn_max = maxf(_turn_max, rad_to_deg(absf(angle_difference(_yaw_prev, y))))
	_yaw_prev = y
	var line := _flat(p2.global_position - p1.global_position)
	if line.length() > 0.5:
		var z: Vector3 = _flat(arena.duel_camera.cam.global_basis.z).normalized()
		_rmax = maxf(_rmax, absf(90.0 - rad_to_deg(z.angle_to(line.normalized()))))


## Puts `who` on the ground plane `dist` m from `center`, at `deg` around it from world +X (y kept),
## and lets both look at each other (lock-on would do the same on their next ground tick).
func _place(who: Fighter, center: Fighter, dist: float, deg: float) -> void:
	var d := Vector3(cos(deg_to_rad(deg)), 0.0, sin(deg_to_rad(deg))) * dist
	who.global_position = Vector3(center.global_position.x + d.x, who.global_position.y, center.global_position.z + d.z)
	who.forward = -d.normalized()
	center.forward = d.normalized()


## Records which anchor P1's grapple would pick with the current stick, and checks it is inside the
## yaw cone around the aim axis (stick, or forward when neutral).
func _cone_pick(tag: String) -> void:
	var a: Node3D = p1.grapple.best_anchor()
	if a == null:
		_fail("grapple cone (%s): no anchor picked" % tag)
		return
	var axis: Vector3 = p1.grapple.aim_axis()
	var to := _flat(a.global_position - p1.global_position)
	var ang := rad_to_deg(axis.angle_to(to.normalized()))
	if ang > p1.grapple.cone_deg + 0.01:
		_fail("grapple cone (%s): %s is %.1f° off the aim (cone %.0f°)" % [tag, a.name, ang, p1.grapple.cone_deg])
		return
	_picks[tag] = a


func _both_in_view() -> bool:
	var cam: Camera3D = arena.duel_camera.cam
	return cam.is_position_in_frustum(p1.global_position + Vector3.UP) and cam.is_position_in_frustum(p2.global_position + Vector3.UP)


## The same scripted inputs on every river run (frame t from FIGHT start), so runs can be compared.
func _river_script(t: int) -> void:
	InputRouter.v_set(1, "right", t < 50 or (t > 420 and t < 470))
	InputRouter.v_set(2, "left", t < 30)
	InputRouter.v_set(2, "block", t > 200 and t < 260)
	InputRouter.v_set(1, "crouch", t > 500 and t < 530)
	if t in [80, 300]:
		InputRouter.v_press(1, "jump")
	if t in [140, 152, 400]:
		InputRouter.v_press(1, "light")
	if t in [180, 350]:
		InputRouter.v_press(2, "light")
	if t == 240:
		InputRouter.v_press(1, "heavy")
	if t == 320:
		InputRouter.v_press(2, "dash")
	if t == 460:
		InputRouter.v_press(2, "jump")


func _next() -> void:
	_stage += 1
	_f0 = _f
	InputRouter.v_clear(1)
	InputRouter.v_clear(2)


func _approach(who: Fighter, target: Fighter, dist: float) -> bool:
	var dx := target.global_position.x - who.global_position.x
	var p := who.player_index
	InputRouter.v_set(p, "right", dx > 0.0)
	InputRouter.v_set(p, "left", dx <= 0.0)
	if absf(dx) < dist:
		InputRouter.v_set(p, "right", false)
		InputRouter.v_set(p, "left", false)
		return true
	return false


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_f += 1
	if _f > 14000:
		_fail("timeout at stage %d (p1 %d, p2 %d)" % [_stage, p1.state if p1 else -1, p2.state if p2 else -1])
		return
	if arena == null:
		var cs := get_tree().current_scene
		if cs == null or cs.name != "Arena" or cs == _old_arena or not cs.is_inside_tree():
			return
		arena = cs
		p1 = arena.p1
		p2 = arena.p2
		flow = arena.flow
		_ok("arena loaded: %s vs %s, stage %s" % [p1.data.display_name, p2.data.display_name, GameState.stage().id])
		var bus := AudioServer.get_bus_index(Sfx.BUS)
		var vh := Sfx.variant_count("hit_light")
		if bus == -1 or AudioServer.get_bus_effect_count(bus) < 2 or vh < 3 or Sfx.variant_count("no_such_sfx") != 0:
			_fail("SFX: bus %d (effects %d), hit_light variants %d" % [bus, AudioServer.get_bus_effect_count(bus) if bus != -1 else 0, vh])
			return
		_ok("SFX bus with %d effects; hit_light %d variants, hit_heavy %d, whoosh %d" % [AudioServer.get_bus_effect_count(bus), vh, Sfx.variant_count("hit_heavy"), Sfx.variant_count("whoosh")])
		return
	match _stage:
		# ---------------- round 1: Choko ----------------
		0:
			if flow.phase == MatchFlow.Phase.FIGHT:
				_ok("round 1 started at frame %d" % _f)
				_next()
		1:
			if _approach(p1, p2, 1.7):
				_ok("walked into range")
				_next()
		2:
			if _f == _f0 + 2 or _f == _f0 + 14:
				InputRouter.v_press(1, "light")
			if p1.state == Fighter.State.ATTACK and p1.current_move != null and p1.chain_index == 0:
				if p1.move_frame == 2:
					_shot("00a_strike_windup")
				elif p1.move_frame == p1.current_move.startup + 1:
					_shot("00b_strike_impact")
			if p1.state == Fighter.State.ATTACK:
				_atk_frames += 1
				var snap: Array = p1.animator.pose.values()
				if snap != _last_pose:
					_pose_changes += 1
					_run += 1
					_max_run = maxi(_max_run, _run)
				else:
					_run = 0
				_last_pose = snap
			else:
				_run = 0
			if _f > _f0 + 50:
				if p2.hp < p2.data.max_hp:
					_ok("light string hit: p2 hp %.0f/%.0f" % [p2.hp, p2.data.max_hp])
					# 12 fps stepping: the arm may change only on step/key frames, never every frame
					# held drawings: a pose may change on two adjacent frames at most (a key frame next to
					# a step), never in a longer run — a run ≥ 3 means per-frame (60 fps) motion
					if _pose_changes < 2 or _max_run > 2:
						_fail("attack pose stepping: %d changes, longest run of changing frames %d (want ≤ 2)" % [_pose_changes, _max_run])
						return
					var wind := RigAnimator.attack_ext(0.45)
					var over := RigAnimator.attack_ext(1.0)
					if wind >= 0.0 or over <= 1.0 or absf(RigAnimator.attack_ext(3.0)) > 0.001:
						_fail("attack curve: wind-up %.2f, overshoot %.2f" % [wind, over])
						return
					_ok("strike readability: pose changed %d× over %d attack frames, longest run %d (12 fps steps), wind-up %.2f, overshoot %.2f, flinch zone '%s'" % [_pose_changes, _atk_frames, _max_run, wind, over, p2.animator.flinch_zone])
					_next()
				else:
					_fail("light did not connect")
		3:
			if p1.is_actionable() and _f > _f0 + 4 and _f0 > 0 and _x0 == 0.0:
				_x0 = 1.0
				InputRouter.v_press(1, "skill2")
			if p2.frozen_frames > 0:
				_ok("TIME STOP froze Skea (%d frames left, status '%s')" % [p2.frozen_frames, p2._status_text])
				_x0 = p2.hp
				_next()
			elif _f > _f0 + 90:
				_fail("time stop did not freeze (p1 state %d, dist %.2f)" % [p1.state, absf(p1.global_position.x - p2.global_position.x)])
		4:
			if _f == _f0 + 12:
				_shot("01_choko_time_stop")
			if p2.frozen_frames > 0 and p1.is_actionable() and _approach(p1, p2, 1.6) and _n0 == 0:
				_n0 = 1
				InputRouter.v_press(1, "light")
			if p2.frozen_frames == 0 and _f > _f0 + 4:
				if p2.hp < _x0:
					_ok("hit landed during frozen time, released on resume (hp %.0f → %.0f)" % [_x0, p2.hp])
					_next()
				else:
					_fail("no damage during time stop")
		5:
			_n0 = 0
			if p1.is_actionable() and p1.cooldowns.skill1 <= 0.0:
				_x0 = p1.global_position.x
				InputRouter.v_press(1, "skill1")
				_next()
		6:
			if p1.record_marker != null and _f < _f0 + 40:
				InputRouter.v_set(1, "left" if _x0 > 0.0 else "right", true)
			if _f == _f0 + 40:
				InputRouter.v_clear(1)
				if p1.record_marker == null:
					_fail("record marker was not placed")
					return
				_ok("RECORD marker placed; walked %.2f m away" % absf(p1.global_position.x - _x0))
				InputRouter.v_press(1, "skill1")
			if _f == _f0 + 30:
				_shot("02_choko_record_marker")
			if _f == _f0 + 43:
				_shot("03_choko_rewind_trail")
			if _f > _f0 + 44:
				if p1.record_marker == null and absf(p1.global_position.x - _x0) < 0.35:
					_ok("REWIND snapped Choko back (x %.2f ≈ %.2f), skill1 cd %.1f s" % [p1.global_position.x, _x0, p1.cooldowns.skill1])
					_next()
				elif _f > _f0 + 70:
					_fail("rewind failed (x %.2f vs %.2f, marker %s)" % [p1.global_position.x, _x0, p1.record_marker])
		7:
			if p1.is_actionable():
				InputRouter.v_set(1, "grapple", true)
				_next()
		8:
			InputRouter.v_set(1, "grapple", true)
			if p1.state == Fighter.State.GRAPPLE:
				_ok("grapple attached (charges left %d)" % p1.grapple.charges)
				_next()
			elif _f > _f0 + 30:
				_fail("grapple did not attach")
		9:
			InputRouter.v_set(1, "grapple", _f < _f0 + 40)
			if _f > _f0 + 50 and p1.state != Fighter.State.GRAPPLE:
				_ok("grapple released")
				_next()
			elif _f > _f0 + 200:
				_fail("grapple never released")
		10:
			if p1.is_actionable() and _approach(p1, p2, 1.8):
				p2.hp = 150.0
				p1.meter = Fighter.MAX_METER
				_next()
		11:
			if _f == _f0 + 3:
				InputRouter.v_press(1, "ultimate")
			if _f == _f0 + 30 or _f == _f0 + 62:
				_shot("04_choko_sword_storm_%d" % (_f - _f0))
			if p2.state == Fighter.State.KO:
				_ok("SWORD STORM KO'd Skea (ragdolls so far %d)" % p2.stats.ragdolls)
				_next()
			elif _f > _f0 + 150:
				_fail("sword storm did not KO (p2 hp %.0f state %d, p1 state %d)" % [p2.hp, p2.state, p1.state])
		# ---------------- round 2: Skea ----------------
		12:
			if flow.round_no == 2 and flow.phase == MatchFlow.Phase.FIGHT:
				_ok("round 2 started; driving Skea now")
				_next()
		13:
			if _approach(p2, p1, 1.5):
				_x0 = signf(p2.global_position.x - p1.global_position.x)
				_n0 = get_tree().get_nodes_in_group("afterimage").size()
				var toward := "left" if _x0 > 0.0 else "right"
				InputRouter.v_set(2, toward, true)
				InputRouter.v_press(2, "dash")
				_next()
		14:
			if _f == _f0 + 2 or _f == _f0 + 4:
				_shot("05_skea_flash_step_%d" % (_f - _f0))
			if _f == _f0 + 5:
				var ghosts := get_tree().get_nodes_in_group("afterimage").size()
				var side := signf(p2.global_position.x - p1.global_position.x)
				if side != _x0 and p2.dash_charges_left == 2 and ghosts > _n0:
					_ok("FLASH-STEP passed through Choko (side %+d → %+d), %d ghosts, charges %d" % [_x0, side, ghosts, p2.dash_charges_left])
					_next()
				else:
					_fail("flash failed (side %s→%s, charges %d, ghosts %d)" % [_x0, side, p2.dash_charges_left, ghosts])
		15:
			if p2.is_actionable() and _f > _f0 + 6:
				InputRouter.v_press(2, "skill1")
				_next()
		16:
			if _f == _f0 + 30:
				_shot("06_skea_kunai_rain")
			if _f > _f0 + 80:
				if p1.hp < p1.data.max_hp and (p1.armor_break_frames > 0 or p1.state == Fighter.State.LAUNCHED):
					_ok("KUNAI RAIN hit: Choko hp %.0f, armor break %d f" % [p1.hp, p1.armor_break_frames])
					_next()
				else:
					_fail("kunai rain missed (p1 hp %.0f, armor %d, dist %.2f)" % [p1.hp, p1.armor_break_frames, absf(p1.global_position.x - p2.global_position.x)])
		17:
			if p2.is_actionable():
				InputRouter.v_press(2, "skill2")
				_next()
		18:
			if _f == _f0 + 11:
				_shot("07_skea_shadow_veil")
			if _f == _f0 + 12:
				if p2.veil_frames > 0 and not p2.animator.visible:
					_ok("SHADOW VEIL: invisible %d f, smoke clouds %d" % [p2.veil_frames, get_tree().get_nodes_in_group("smoke").size()])
					_next()
				else:
					_fail("veil not active (frames %d, visible %s)" % [p2.veil_frames, p2.animator.visible])
		19:
			if p1.is_actionable() or p1.state == Fighter.State.IDLE:
				if _approach(p2, p1, 1.5):
					InputRouter.v_press(2, "light")
					_next()
			elif _f > _f0 + 200:
				_fail("p1 never became actionable for the veil strike")
		20:
			if p1.last_hit_crit and p1.dot_frames > 0:
				_ok("veil strike CRIT + bleed (%d f), Skea crits %d" % [p1.dot_frames, p2.stats.crits])
				_next()
			elif _f > _f0 + 40:
				_fail("no crit from veil (crit %s, dot %d, p1 state %d)" % [p1.last_hit_crit, p1.dot_frames, p1.state])
		21:
			if p2.is_actionable() and (p1.is_actionable() or p1.state == Fighter.State.IDLE or p1.state == Fighter.State.HITSTUN):
				if _approach(p2, p1, 2.2):
					p1.hp = 1000.0
					p2.meter = Fighter.MAX_METER
					_n0 = p1.stats.ragdolls
					InputRouter.v_press(2, "ultimate")
					_next()
		22:
			if _f == _f0 + 30 or _f == _f0 + 50:
				_shot("08_skea_grimoire_%d" % (_f - _f0))
			if p1.stats.ragdolls > _n0:
				_ok("CURSED GRIMOIRE: Choko ragdolled, hp %.0f, poison %d f" % [p1.hp, p1.dot_frames])
				_next()
			elif _f > _f0 + 160:
				_fail("grimoire did not ragdoll (p1 hp %.0f, state %d)" % [p1.hp, p1.state])
		23:
			if p1.state == Fighter.State.IDLE or p1.is_actionable():
				_ok("Choko got up after the ragdoll")
				p1.hp = 30.0
				_next()
			elif _f > _f0 + 260:
				_fail("Choko never got up")
		24:
			if p2.is_actionable() and _approach(p2, p1, 1.5):
				InputRouter.v_press(2, "light")
			if p1.state == Fighter.State.KO:
				_ok("Skea KO'd Choko; wins p1=%d p2=%d" % [flow.wins[1], flow.wins[2]])
				_next()
			elif _f > _f0 + 300:
				_fail("could not KO Choko (hp %.0f, state %d)" % [p1.hp, p1.state])
		25:
			if flow.round_no == 3 and flow.phase == MatchFlow.Phase.INTRO:
				_ok("round 3 started (1-1)")
				_next()
		# ---------------- keyboard profiles (ADR-009): real key events, not virtual input -------
		26:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.is_actionable() and p2.is_actionable():
				_profile0 = InputRouter.profile
				for prof in InputRouter.PROFILES:
					var clash := _key_clash(prof)
					if clash != "":
						_fail("profile %s: %s" % [prof, clash])
						return
				_ok("profiles SOLO/SHARED: every key drives one action; SOLO leaves P2 keyless")
				InputRouter.apply_profile(InputRouter.PROFILE_SOLO, false)
				_key(KEY_J, true)
				_next()
		27:
			if _f == _f0 + 2:
				_key(KEY_J, false)
			if p1.state == Fighter.State.ATTACK and p2.state != Fighter.State.ATTACK:
				_ok("SOLO: key J → P1 %s (P2 idle)" % p1.current_move.id)
				_next()
			elif _f > _f0 + 20:
				_fail("SOLO: J did not start a P1 attack (p1 state %d, p2 state %d)" % [p1.state, p2.state])
		28:
			if p1.is_actionable() and p2.is_actionable() and _f > _f0 + 30:
				InputRouter.apply_profile(InputRouter.PROFILE_SHARED, false)
				_key(KEY_K, true)
				_next()
		29:
			if _f == _f0 + 2:
				_key(KEY_K, false)
			if p2.state == Fighter.State.ATTACK and p1.state != Fighter.State.ATTACK:
				_ok("SHARED: key K → P2 %s (P1 idle)" % p2.current_move.id)
				InputRouter.apply_profile(_profile0, false)
				_load_river()
			elif _f > _f0 + 20:
				_fail("SHARED: K did not start a P2 attack (p1 state %d, p2 state %d)" % [p1.state, p2.state])
		# ---------------- river stage (docs/World/Stage-River.md § Перевірка) -------------------
		30:
			if flow.phase == MatchFlow.Phase.FIGHT and GameState.water != null:
				_ok("river run %d: water stage live (stage %s, swell every %.0f–%.0f s)" % [_river_runs.size() + 1, GameState.stage().id, GameState.water.swell_every_min, GameState.water.swell_every_max])
				_river_min_gap = 99.0
				_next()
		31:
			var t := _f - _f0
			_river_script(t)
			for f: Fighter in [p1, p2]:
				var gap := f.global_position.y - GameState.water.height(f.global_position.x)
				_river_min_gap = minf(_river_min_gap, gap)
				if gap < -0.05:
					_fail("river: P%d sank (y %.3f, surface %.3f, frame %d, state %d)" % [f.player_index, f.global_position.y, f.global_position.y - gap, t, f.state])
					return
			if t == 200 and _river_runs.is_empty():
				_shot("10_river_fight")
			if t == 600:
				_river_runs.append([p1.global_position, p2.global_position, p1.hp, p2.hp, GameState.water.height(0.0)])
				_ok("river run %d: nobody sank in 600 frames (min gap %.3f m); p1 x %.4f y %.4f, p2 x %.4f y %.4f" % [_river_runs.size(), _river_min_gap, p1.global_position.x, p1.global_position.y, p2.global_position.x, p2.global_position.y])
				if _river_runs.size() == 1:
					_load_river()
				else:
					var a: Array = _river_runs[0]
					var b: Array = _river_runs[1]
					var d: float = (a[0] as Vector3).distance_to(b[0]) + (a[1] as Vector3).distance_to(b[1]) + absf(a[2] - b[2]) + absf(a[3] - b[3]) + absf(a[4] - b[4])
					if d > 1e-5:
						_fail("river: two runs differ at frame 600 (Σ|Δ| %.6f): %s vs %s" % [d, str(a), str(b)])
						return
					_ok("river: deterministic — both runs identical at frame 600 (Σ|Δ| %.6f)" % d)
					_next()
		32:
			# both made unsteady; P1 guards, P2 stands idle; a 0.7 swell must topple only P2
			if p1.is_actionable() and p2.is_actionable() and p1.on_ground() and p2.on_ground():
				p1.data = p1.data.duplicate()
				p2.data = p2.data.duplicate()
				p1.data.water_balance = 0.55
				p2.data.water_balance = 0.55
				_next()
		33:
			InputRouter.v_set(1, "block", _f < _f0 + 9 + GameState.water.stumble_frames + 4)   # _next() clears virtual input
			if _f == _f0 + 6:
				_n0 = int(p1.stats.get("stumbles", 0))
				GameState.water.force_swell_next(0.7)
			if _f == _f0 + 9:
				if p2.state != Fighter.State.STUMBLE:
					_fail("swell 0.7 did not topple P2 with balance 0.55 (state %d)" % p2.state)
					return
				if p1.state == Fighter.State.STUMBLE or int(p1.stats.get("stumbles", 0)) != _n0:
					_fail("P1 stumbled while guarding (held %s, stumbles %s → %s)" % [InputRouter.held(1, "block"), _n0, p1.stats.get("stumbles", 0)])
					return
				InputRouter.v_press(2, "light")
				_shot("09_river_swell_stumble")
			if _f == _f0 + 12:
				if p2.state == Fighter.State.ATTACK:
					_fail("P2 attacked out of a stumble")
					return
				_ok("swell 0.7: P2 (balance 0.55) STUMBLE, can't attack; P1 guarding stays %d (BLOCK)" % p1.state)
			if _f == _f0 + 9 + GameState.water.stumble_frames + 4:
				if p2.state == Fighter.State.STUMBLE:
					_fail("stumble did not end after %d frames" % GameState.water.stumble_frames)
					return
				InputRouter.v_clear(1)
				p1.data.water_balance = 0.85
				p2.data.water_balance = 0.85
				_next()
		34:
			if _f == _f0 + 6:
				GameState.water.force_swell_next(0.7)
			if _f == _f0 + 10:
				if p1.state == Fighter.State.STUMBLE or p2.state == Fighter.State.STUMBLE:
					_fail("balance 0.85 stumbled on a 0.7 swell")
					return
				_ok("swell 0.7 vs balance 0.85: both stay up")
				GameState.set_free_move(true)
				_load_arena(2, 40)   # back_alley, free movement
			elif _f > _f0 + 400:
				_fail("round 3 never started")
		# ---------------- free movement, GameState.free_move (Prototype 0.3-1, 0.3-2) -------------
		40:
			if flow.phase == MatchFlow.Phase.FIGHT and p1.is_actionable() and p2.is_actionable():
				_profile0 = InputRouter.profile
				for prof in InputRouter.PROFILES:
					var clash := _key_clash(prof)
					if clash != "":
						_fail("free move, profile %s: %s" % [prof, clash])
						return
				InputRouter.apply_profile(InputRouter.PROFILE_SOLO, false)
				var w_up := false
				for ev in InputMap.action_get_events("p1_up"):
					w_up = w_up or (ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W)
				var w_jump := false
				for ev in InputMap.action_get_events("p1_jump"):
					w_jump = w_jump or (ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_W)
				InputRouter.apply_profile(_profile0, false)
				if not w_up or w_jump:
					_fail("free move SOLO: W on up %s, W on jump %s (want true, false)" % [w_up, w_jump])
					return
				if get_viewport().get_camera_3d() != arena.duel_camera.cam:
					_fail("free move: duel camera is not the current camera")
					return
				_ok("free move: duel camera current; SOLO W/S → sidestep (TODO #26), no key clashes in SOLO/SHARED")
				_ang0 = _bearing(p1, p2)
				_d0 = _flat(p1.global_position - p2.global_position).length()
				_swept = 0.0
				_next()
		41:
			# 0.3-1: sidestep 90° around the opponent; lock-on keeps facing them
			InputRouter.v_set(1, "up", true)
			var a := _bearing(p1, p2)
			_swept += angle_difference(_ang0, a)
			_ang0 = a
			if absf(_swept) >= PI * 0.5:
				InputRouter.v_clear(1)
				var to := _flat(p2.global_position - p1.global_position).normalized()
				var off := rad_to_deg(p1.forward.angle_to(to))
				var d := _flat(p1.global_position - p2.global_position).length()
				# circling speed = circle_speed_mult × walk_speed (T5 Арес): a quarter circle of radius d takes
				# (π/2 · d) / v seconds
				var want_f := (PI * 0.5 * _d0) / (p1.data.circle_speed_mult * p1.data.walk_speed) * 60.0
				if absf(float(_f - _f0) - want_f) > want_f * 0.05:
					_fail("sidestep speed: 90° took %d frames, want %.0f ± 5 %% (circle_speed_mult %.2f × walk %.1f)" % [_f - _f0, want_f, p1.data.circle_speed_mult, p1.data.walk_speed])
					return
				if off >= 5.0 or absf(d - _d0) > 0.01 or absf(p1.global_position.z) < 0.5:
					_fail("sidestep 90°: forward off by %.2f° (want < 5), distance %.3f → %.3f (want ±0.01), z %.2f" % [off, _d0, d, p1.global_position.z])
					return
				_shot("11_free_sidestep_90")
				_ok("sidestep 90° in %d frames (want %.0f at %.1f × walk): forward %.2f° off the opponent, distance %.3f → %.3f (arc, not spiral), p1 z %.2f" % [_f - _f0, want_f, p1.data.circle_speed_mult, off, _d0, d, p1.global_position.z])
				_n0 = 0
				_data0 = p1.data
				_next()
			elif _f > _f0 + 400:
				_fail("sidestep never reached 90° (swept %.1f°)" % rad_to_deg(_swept))
		42:
			if p1.is_actionable() and p2.is_actionable() and _approach3d(p1, p2, 1.5):
				_hp0 = p2.hp
				_rotated = false
				_ang0 = 0.0
				InputRouter.v_press(1, "light")
				_next()
		43:
			# 0.3-1: the opponent steps 60° around the attacker at the start of a light; tracking
			# (light: 30°, T5 Арес) turns the strike so it still lands. 60° − 30° = 30° stays inside the
			# hitbox at 1.5 m; 60° without tracking does not (negative control, attempt 2).
			if p1.state == Fighter.State.ATTACK and not _rotated:
				_rotated = true
				_ang0 = atan2(-p1.forward.z, p1.forward.x)
				var rel := _flat(p2.global_position - p1.global_position).normalized() * 1.5
				p2.global_position = p1.global_position + rel.rotated(Vector3.UP, deg_to_rad(60.0)) + Vector3(0.0, p2.global_position.y - p1.global_position.y, 0.0)
			if _rotated and p1.state == Fighter.State.ATTACK and p1.move_frame == p1.current_move.startup:
				# turn measured on the first active frame — after the attack lock-on turns the fighter anyway
				_d0 = rad_to_deg(absf(angle_difference(_ang0, atan2(-p1.forward.z, p1.forward.x))))
			if _f == _f0 + 30:
				var turned := _d0
				var hit := p2.hp < _hp0
				if _n0 == 0:
					var budget := p1.data.light.tracking_deg
					if not hit or absf(turned - budget) > 0.5:
						_fail("tracking: 60°-off light hit %s, turned %.1f° (want hit, %.1f° = tracking_deg)" % [hit, turned, budget])
						return
					_ok("tracking: light started 60° off the opponent turned %.1f° and hit (hp %.0f → %.0f)" % [turned, _hp0, p2.hp])
					p1.data = _data0.duplicate(true)
					p1.data.light.tracking_deg = 0.0
					_n0 = 1
					_stage = 42
					_f0 = _f
					InputRouter.v_clear(1)
				else:
					p1.data = _data0
					if hit or turned > 0.5:
						_fail("tracking negative control: tracking 0° still hit %s, turned %.1f°" % [hit, turned])
						return
					_ok("tracking negative control: with tracking_deg 0 the same strike turns %.1f° and misses" % turned)
					_rmax = 0.0
					_next()
		44:
			# 0.3-1: walk straight away from the opponent into the arena edge; never past the circle
			if not p1.is_actionable() and _f < _f0 + 60:
				return
			var away_right := _flat(p1.global_position - p2.global_position).dot(GameState.duel.right) > 0.0
			InputRouter.v_set(1, "right", away_right)
			InputRouter.v_set(1, "left", not away_right)
			_rmax = maxf(_rmax, _flat(p1.global_position).length())
			if _rmax > Fighter.ARENA_RADIUS + 0.001:
				_fail("arena circle: p1 at radius %.3f > %.2f" % [_rmax, Fighter.ARENA_RADIUS])
				return
			if _f > _f0 + 420:
				if _rmax < Fighter.ARENA_RADIUS - 0.05:
					_fail("arena circle: never reached the edge (max radius %.2f)" % _rmax)
					return
				_ok("arena circle: walked into the edge, max radius %.3f ≤ %.2f" % [_rmax, Fighter.ARENA_RADIUS])
				_next()
		45:
			if _f == _f0 + 1:
				# back to a duel distance in the middle, then a full circle around the opponent
				p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.0, p2.global_position.y, 0.0)
			if _f == _f0 + 20:
				_yaw_prev = arena.duel_camera.view_yaw()
				_turn_max = 0.0
				_rmax = 0.0
				_pull_max = 0.0
				_ang0 = _bearing(p1, p2)
				_swept = 0.0
			if _f > _f0 + 20:
				InputRouter.v_set(1, "up", true)
				_track_camera_turn()
				_pull_max = maxf(_pull_max, arena.backdrop.view_angle(arena.duel_camera.cam))
				var a := _bearing(p1, p2)
				_swept += angle_difference(_ang0, a)
				_ang0 = a
				if _f == _f0 + 120:
					_shot("12_free_duel_camera")
				if absf(_swept) >= TAU:
					InputRouter.v_clear(1)
					if _turn_max > (DuelCamera.YAW_CLAMP_DEG + 0.001) or not _both_in_view() or _rmax > DuelCamera.MAX_SIDE_OFF_DEG or _pull_max >= 90.0:
						_fail("duel camera on a 360° sidestep: max turn %.2f°/frame (bound %.1f), off side-on %.1f° (bound %.1f), both in view %s, backdrop at %.1f° (want < 90)" % [_turn_max, (DuelCamera.YAW_CLAMP_DEG + 0.001), _rmax, DuelCamera.MAX_SIDE_OFF_DEG, _both_in_view(), _pull_max])
						return
					_ok("duel camera: 360° sidestep in %d frames, max turn %.2f°/frame ≤ clamp %.3f, at most %.1f° off side-on ≤ %.1f, both fighters in view, backdrop at most %.1f° off the view (< 90)" % [_f - _f0 - 20, _turn_max, (DuelCamera.YAW_CLAMP_DEG + 0.001), _rmax, DuelCamera.MAX_SIDE_OFF_DEG, _pull_max])
					_next()
				elif _f > _f0 + 900:
					_fail("360° sidestep not finished (swept %.1f°)" % rad_to_deg(_swept))
		46:
			# 0.3-2: the fighters swap sides in one frame (flash-step through, jump over): the camera
			# must not flip 180°, the fighters swap sides on screen instead
			if _f == _f0 + 1:
				_yaw_prev = arena.duel_camera.view_yaw()
				_turn_max = 0.0
				var a := p1.global_position
				p1.global_position = Vector3(p2.global_position.x, a.y, p2.global_position.z)
				p2.global_position = Vector3(a.x, p2.global_position.y, a.z)
			elif _f > _f0 + 1:
				_track_camera_turn()
			if _f == _f0 + 40:
				var cam: Camera3D = arena.duel_camera.cam
				var s1 := cam.unproject_position(p1.global_position + Vector3.UP).x
				var s2 := cam.unproject_position(p2.global_position + Vector3.UP).x
				if _turn_max > (DuelCamera.YAW_CLAMP_DEG + 0.001) or not _both_in_view():
					_fail("duel camera on a side swap: max turn %.2f°/frame, both in view %s" % [_turn_max, _both_in_view()])
					return
				_shot("13_free_side_swap")
				_ok("duel camera: side swap without a flip, max turn %.2f°/frame; screen x p1 %.0f, p2 %.0f" % [_turn_max, s1, s2])
				# the line jumps 90° in one frame: the yaw clamp must hold and the arm must pull back
				_yaw_prev = arena.duel_camera.view_yaw()
				_turn_max = 0.0
				_pull_max = 0.0
				var r := _flat(p2.global_position - p1.global_position).length()
				p2.global_position = Vector3(p1.global_position.x, p2.global_position.y, p1.global_position.z - r)
			elif _f > _f0 + 40 and _f <= _f0 + 120:
				_pull_max = maxf(_pull_max, arena.duel_camera.pullback())
			if _f == _f0 + 120:
				var lag := rad_to_deg(absf(angle_difference(arena.duel_camera.view_yaw(), arena.duel_camera._target_yaw())))
				if _turn_max > DuelCamera.YAW_CLAMP_DEG + 0.001 or _pull_max < 0.2 or lag > 1.0 or not _both_in_view():
					_fail("duel camera on a 90° jump: max turn %.2f°/tick (clamp %.1f), max pull-back %.2f (want > 0.2), lag after 80 ticks %.1f°, both in view %s" % [_turn_max, DuelCamera.YAW_CLAMP_DEG, _pull_max, lag, _both_in_view()])
					return
				_ok("duel camera on a 90° jump: max turn %.2f°/tick ≤ %.1f, arm pulled back to +%.0f %%, caught up (lag %.2f°)" % [_turn_max, DuelCamera.YAW_CLAMP_DEG, _pull_max * 100.0, lag])
				_next()
		47:
			# 0.3-3: the anchor is chosen inside the aim cone — of the stick when deflected, else of the
			# gaze; the same spot gives a different anchor for stick up / down / neutral
			if _f == _f0 + 1:
				p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.0, p2.global_position.y, 0.0)
			if _f == _f0 + 10:
				InputRouter.v_set(1, "up", true)
			if _f == _f0 + 11:
				_cone_pick("up")
				InputRouter.v_set(1, "up", false)
				InputRouter.v_set(1, "down", true)
			if _f == _f0 + 12:
				_cone_pick("down")
				InputRouter.v_set(1, "down", false)
			if _f == _f0 + 13:
				_cone_pick("neutral")
				if _done:
					return
				var up: Node3D = _picks["up"]
				var down: Node3D = _picks["down"]
				var neutral: Node3D = _picks["neutral"]
				if up == down or up == neutral or down == neutral or signf(up.global_position.z) == signf(down.global_position.z):
					_fail("grapple cone: up %s, down %s, neutral %s — want three different anchors, up/down on opposite sides" % [up.name, down.name, neutral.name])
					return
				# next to a lamp: the nearest anchor (Anchor2 at x −4.5) is 90° off a stick-up aim and must lose
				p1.global_position = Vector3(-4.0, p1.global_position.y, 0.0)
			if _f == _f0 + 15:
				InputRouter.v_set(1, "up", true)
			if _f == _f0 + 16:
				_cone_pick("up_near_lamp")
				InputRouter.v_set(1, "up", false)
				if _done:
					return
				var near: Node3D = _picks["up_near_lamp"]
				_ok("grapple cone %.0f°: stick up → %s, down → %s, neutral (gaze) → %s; next to %s with stick up → %s (the lamp beside is outside the cone)" % [p1.grapple.cone_deg, (_picks["up"] as Node3D).name, (_picks["down"] as Node3D).name, (_picks["neutral"] as Node3D).name, "Anchor2", near.name])
				p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(2.0, p2.global_position.y, 0.0)
				_next()
		48:
			# 0.3-3: zip/reel into the depth: hold up + hold grapple until the hook reaches the anchor
			if _f == _f0 + 3:
				InputRouter.v_set(1, "up", true)
				_x0 = 0.0
				_rmax = 99.0
				InputRouter.v_set(1, "grapple", true)
			if _f > _f0 + 3:
				if _x0 > 0.0 or p1.state == Fighter.State.GRAPPLE:
					# measured on the release frame too (the hook lets go the frame it reaches the anchor)
					_d0 = p1.grapple.anchor_point.z
					_rmax = minf(_rmax, (p1.grapple.anchor_point - (p1.global_position + GrappleHook.HAND)).length())
				if p1.state == Fighter.State.GRAPPLE:
					_x0 = 1.0
					if p1.grapple._frames == 10:
						_shot("14_free_grapple_zip")
				elif _x0 > 0.0:
					if _rmax > 1.4 or absf(_d0) < 1.0 or signf(p1.global_position.z) != signf(_d0):
						_fail("grapple 3D: closest to anchor %.2f m (want < 1.4), anchor z %.2f, p1 z %.2f" % [_rmax, _d0, p1.global_position.z])
						return
					_ok("grapple 3D: reeled to the anchor at z %.2f (closest %.2f m), p1 now at z %.2f" % [_d0, _rmax, p1.global_position.z])
					_next()
				if _f > _f0 + 200:
					_fail("grapple 3D never attached/released (state %d, attached %s)" % [p1.state, _x0 > 0.0])
		49:
			# 0.3-3: pull the enemy along the gaze when they stand off the X line
			if not (p1.is_actionable() and p2.is_actionable()) and _f < _f0 + 200:
				return
			if _n0 != 49:
				_n0 = 49
				p1.global_position = Vector3(0.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(3.0, p2.global_position.y, 3.0)
				_f0 = _f
				return
			if _f == _f0 + 3:
				InputRouter.v_set(1, "crouch", true)
				InputRouter.v_press(1, "grapple")
			if _f == _f0 + 60:
				var want := p1.global_position + p1.forward * 1.25
				var miss := _flat(p2.global_position - want).length()
				var z_moved := absf(p2.global_position.z - 3.0)
				if p1.stats.grapples < 1 or miss > 0.6 or z_moved < 1.0:
					_fail("grapple pull 3D: grapples %d, P2 %.2f m from 1.25 m in front of P1 (want ≤ 0.6), z moved %.2f" % [p1.stats.grapples, miss, z_moved])
					return
				_ok("grapple pull 3D: P2 from (3, 3) to %.2f m off the spot 1.25 m in front of P1 (z moved %.2f)" % [miss, z_moved])
				_n0 = 0
				_next()
		50:
			# Ares numbers: guard arc ±block_arc_deg; side/back hits get +backhit_hitstun_bonus
			if not (p1.is_actionable() and p2.is_actionable()) and _f < _f0 + 300:
				return
			# fixed angles from the plan (T1 answer, item 4): 65° is blocked, 75° goes through (Ares: ±70°)
			var arc: float = p2.data.block_arc_deg
			var res := []
			for deg in [65.0, 75.0]:
				_place(p2, p1, 2.0, 0.0)
				var to := _flat(p1.global_position - p2.global_position).normalized()
				p2.forward = to.rotated(Vector3.UP, deg_to_rad(deg))
				res.append(p2._guards_against(p1))
			if res[0] != true or res[1] != false:
				_fail("block arc ±%.0f°: guards at 65° %s, at 75° %s (want true, false)" % [arc, res[0], res[1]])
				return
			var lm: MoveData = p1.data.light
			_place(p2, p1, 1.5, 0.0)
			p2.forward = _flat(p2.global_position - p1.global_position).normalized()   # back to the attacker
			p2.receive_hit(p1, lm)
			var back := p2.stun_frames
			if back != lm.hitstun + lm.backhit_hitstun_bonus:
				_fail("backhit: stun %d, want %d + %d" % [back, lm.hitstun, lm.backhit_hitstun_bonus])
				return
			# soft wall: past the circle, the outward part of the velocity goes, the tangential part stays
			var n := Vector3(cos(0.7), 0.0, sin(0.7))
			var t := Vector3.UP.cross(n)
			p1.global_position = n * (Fighter.ARENA_RADIUS + 0.2) + Vector3(0.0, p1.global_position.y, 0.0)
			p1.velocity = n * 5.0 + t * 3.0
			p1._soft_wall()
			var out := p1.velocity.dot(n)
			var tan := p1.velocity.dot(t)
			var rad := _flat(p1.global_position).length()
			if absf(out) > 0.001 or absf(tan - 3.0) > 0.001 or absf(rad - Fighter.ARENA_RADIUS) > 0.001:
				_fail("soft wall: outward %.3f (want 0), tangential %.3f (want 3), radius %.3f" % [out, tan, rad])
				return
			p1.velocity = Vector3.ZERO
			p1.global_position = Vector3(-2.0, p1.global_position.y, 0.0)
			_ok("block arc ±%.0f°: attacker at 65° blocked, at 75° not; back hit stun %d = hitstun %d + %d; soft wall keeps tangential 3.0 m/s, outward → 0" % [arc, back, lm.hitstun, lm.backhit_hitstun_bonus])
			_next()
		51:
			# TIME STOP is a circle in 3D: P2 off the X line inside it freezes; at |dx| = 1 but 5 m deep it does not
			if (_n0 == 0 or _n0 == 2) and not (p1.is_actionable() and p2.is_actionable()):
				if _f > _f0 + 400:
					_fail("time stop 3D: never ready (p1 %d, p2 %d, cd %.1f)" % [p1.state, p2.state, p1.cooldowns.skill2])
				return
			if _n0 == 0:
				p1.cooldowns.skill2 = 0.0
				_n0 = 1
				p1.global_position = Vector3(0.0, p1.global_position.y, 0.0)
				p2.global_position = Vector3(1.0, p2.global_position.y, 5.0)   # |dx| 1 ≤ 4.2, distance 5.1 > 4.2
				InputRouter.v_press(1, "skill2")
				_f0 = _f
				return
			if _n0 == 1 and _f == _f0 + 20:
				if p2.frozen_frames > 0:
					_fail("time stop 3D: froze P2 5.1 m away (only |dx| = 1)")
					return
				_n0 = 2
				p1.cooldowns.skill2 = 0.0
			if _n0 == 2 and p1.is_actionable() and p2.is_actionable():
				p1.cooldowns.skill2 = 0.0
				_n0 = 3
				_place(p2, p1, 3.0, 50.0)
				InputRouter.v_press(1, "skill2")
				_f0 = _f
			if _n0 == 3 and _f == _f0 + 20:
				if p2.frozen_frames <= 0:
					_fail("time stop 3D: P2 3 m away at 50° not frozen (p1 state %d move %s cd %.1f, dist %.2f, p2 state %d inv %d)" % [p1.state, p1.current_move.id if p1.current_move else "-", p1.cooldowns.skill2, _flat(p2.global_position - p1.global_position).length(), p2.state, p2.invulnerable_frames])
					return
				_ok("TIME STOP 3D: P2 3 m away at 50° frozen; P2 at |dx| 1 but 5.1 m away untouched")
				_n0 = 0
				_next()
		52:
			# SWORD STORM: a 5.4 × 1.2 m band along the gaze. P2 at 40° off the X axis is hit; moved 2 m
			# to the side of the band after the first tick, the rest of the storm misses
			if _n0 == 0:
				if p2.frozen_frames > 0 or not (p1.is_actionable() and p2.is_actionable()):
					if _f > _f0 + 400:
						_fail("sword storm 3D: never ready")
					return
				_n0 = 1
				p2.hp = p2.data.max_hp
				p1.meter = Fighter.MAX_METER
				_place(p2, p1, 3.0, 40.0)
				_hp0 = p2.hp
				_rotated = false
				InputRouter.v_press(1, "ultimate")
				_f0 = _f
				return
			if not _rotated and p2.hp < _hp0:
				_rotated = true
				var fwd := p1.forward
				var side := Vector3.UP.cross(fwd)
				p2.global_position = p1.global_position + fwd * 3.0 + side * 2.0 + Vector3(0.0, p2.global_position.y - p1.global_position.y, 0.0)
				_x0 = p2.hp
			if _rotated and _f == _f0 + 110:
				if p2.hp != _x0:
					_fail("sword storm 3D: hit P2 2 m beside the band (hp %.0f → %.0f)" % [_x0, p2.hp])
					return
				_ok("SWORD STORM 3D: band along the gaze hit P2 at 40° (hp %.0f → %.0f); 2 m beside the band — no more hits" % [_hp0, _x0])
				_n0 = 0
				_next()
			elif _f > _f0 + 120:
				_fail("sword storm 3D: P2 at 40° never hit (hp %.0f)" % p2.hp)
		53:
			# KUNAI RAIN lands on P1's spot (off the X line) at the throw
			if _n0 == 0:
				if not (p1.is_actionable() and p2.is_actionable()) or p2.cooldowns.skill1 > 0.0:
					if _f > _f0 + 600:
						_fail("kunai 3D: never ready (p1 %d, p2 %d)" % [p1.state, p2.state])
					return
				_n0 = 1
				p1.hp = p1.data.max_hp
				p1.armor_break_frames = 0
				_place(p1, p2, 4.0, -60.0)
				_hp0 = p1.hp
				InputRouter.v_press(2, "skill1")
				_f0 = _f
				return
			if _f == _f0 + 80:
				if p1.hp >= _hp0 or p1.armor_break_frames <= 0:
					_fail("kunai 3D: P1 4 m away at -60° not hit (hp %.0f, armor %d)" % [p1.hp, p1.armor_break_frames])
					return
				_ok("KUNAI RAIN 3D: P1 4 m away at -60° hit (hp %.0f → %.0f), armor break %d f" % [_hp0, p1.hp, p1.armor_break_frames])
				_n0 = 0
				_next()
		54:
			# CURSED GRIMOIRE is a circle: P1 at |dx| 1 but 5 m deep is untouched; P1 2.5 m away at 60° is hit
			if _n0 == 0 or _n0 == 2:
				if not (p1.is_actionable() and p2.is_actionable()):
					if _f > _f0 + 600:
						_fail("grimoire 3D: never ready (p1 %d, p2 %d)" % [p1.state, p2.state])
					return
				p1.hp = p1.data.max_hp
				p2.meter = Fighter.MAX_METER
				if _n0 == 0:
					p2.global_position = Vector3(0.0, p2.global_position.y, 0.0)
					p1.global_position = Vector3(1.0, p1.global_position.y, 5.0)
				else:
					_place(p1, p2, 2.5, 60.0)
				_hp0 = p1.hp
				_x0 = float(p1.stats.ragdolls)
				InputRouter.v_press(2, "ultimate")
				_n0 += 1
				_f0 = _f
				return
			if _n0 == 1 and _f == _f0 + 100:
				if p1.hp < _hp0:
					_fail("grimoire 3D: hit P1 5.1 m away (|dx| 1): hp %.0f → %.0f" % [_hp0, p1.hp])
					return
				_n0 = 2
				_f0 = _f
			if _n0 == 3 and _f == _f0 + 100:
				if p1.hp >= _hp0 or float(p1.stats.ragdolls) <= _x0:
					_fail("grimoire 3D: P1 2.5 m away at 60° not hit (hp %.0f, ragdolls %d)" % [p1.hp, p1.stats.ragdolls])
					return
				_ok("CURSED GRIMOIRE 3D: P1 2.5 m away at 60° hit and ragdolled (hp %.0f → %.0f); at |dx| 1 but 5.1 m away untouched" % [_hp0, p1.hp])
				_n0 = 0
				_next()
		55:
			# FLASH STEP goes through the opponent along the line; a sideways stick turns the exit by 45°
			if _n0 == 0 or _n0 == 2:
				if not (p1.is_actionable() and p2.is_actionable()) or p2.dash_charges_left <= 0:
					if _f > _f0 + 900:
						_fail("flash 3D: never ready (p1 %d, p2 %d, charges %d)" % [p1.state, p2.state, p2.dash_charges_left])
					return
				_place(p2, p1, 1.5, 135.0)
				_v0 = p2.global_position
				if _n0 == 2:
					InputRouter.v_set(2, "up", true)
				InputRouter.v_press(2, "dash")
				_n0 += 1
				_f0 = _f
				return
			if (_n0 == 1 or _n0 == 3) and _f == _f0 + 8:
				InputRouter.v_clear(2)
				var line := _flat(p1.global_position - _v0).normalized()
				var went := _flat(p2.global_position - _v0)
				var ang := rad_to_deg(line.angle_to(went.normalized()))
				if _n0 == 1:
					var through := _flat(p2.global_position - p1.global_position).dot(_flat(_v0 - p1.global_position)) < 0.0
					if not through or ang > 1.0:
						_fail("flash 3D: neutral flash from 135° — through %s, %.1f° off the line" % [through, ang])
						return
					_ok("FLASH STEP 3D: from 135° straight through P2's line (%.1f° off), %.2f m travelled" % [ang, went.length()])
					_n0 = 2
				else:
					if absf(ang - Fighter.FLASH_SIDE_DEG) > 1.0:
						_fail("flash 3D: sideways stick turned the exit %.1f° (want %.0f°)" % [ang, Fighter.FLASH_SIDE_DEG])
						return
					_ok("FLASH STEP 3D: sideways stick turned the exit %.1f° off the line (rule %.0f°)" % [ang, Fighter.FLASH_SIDE_DEG])
					_finish()
