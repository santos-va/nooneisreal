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
	GameState.stage_index = 1
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
	print("[smoke] ALL OK (%d checks)" % _oks.size())
	get_tree().quit(0)


## Saves a frame when run with a renderer and `--shots=DIR` (no-op headless).
func _shot(tag: String) -> void:
	if _shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(_shots_dir.path_join("%s.png" % tag))
		print("[smoke] shot ", tag)


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
	if _f > 5200:
		_fail("timeout at stage %d (p1 %d, p2 %d)" % [_stage, p1.state if p1 else -1, p2.state if p2 else -1])
		return
	if arena == null:
		var cs := get_tree().current_scene
		if cs == null or cs.name != "Arena":
			return
		arena = cs
		p1 = arena.p1
		p2 = arena.p2
		flow = arena.flow
		_ok("arena loaded: %s vs %s, stage %s" % [p1.data.display_name, p2.data.display_name, GameState.stage().id])
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
			if _f > _f0 + 50:
				if p2.hp < p2.data.max_hp:
					_ok("light string hit: p2 hp %.0f/%.0f" % [p2.hp, p2.data.max_hp])
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
				_finish()
			elif _f > _f0 + 400:
				_fail("round 3 never started")
