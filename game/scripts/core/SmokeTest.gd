class_name SmokeTest
extends Node
## Headless end-to-end check (no GPU needed): loads the arena, drives P1 through the virtual-input
## layer, verifies hits, launcher→ragdoll, grapple attach/release and an ultimate KO.
## Run: godot --headless --path game -- --smoke   (make check)

var _f: int = 0
var _f0: int = 0
var _stage: int = 0
var arena: Node3D
var p1: Fighter
var p2: Fighter
var flow: MatchFlow
var _oks: Array[String] = []
var _done: bool = false


func _ready() -> void:
	print("[smoke] start, godot %s" % Engine.get_version_info().string)
	GameState.p2_is_cpu = false
	GameState.training_mode = false
	GameState.p1_character = "choko"
	GameState.p2_character = "skeasse"
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


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_f += 1
	if _f > 2400:
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
		_ok("arena loaded: %s vs %s, stage %s (texture=%s)" % [p1.data.display_name, p2.data.display_name, GameState.stage().id, arena.backdrop.using_texture])
		return
	match _stage:
		0:
			if flow.phase == MatchFlow.Phase.FIGHT:
				_ok("round 1 started, controls unlocked at frame %d" % _f)
				_next()
		1:
			InputRouter.v_set(1, "right", true)
			if absf(p1.global_position.x - p2.global_position.x) < 1.7:
				InputRouter.v_set(1, "right", false)
				_ok("walked into range (dx=%.2f)" % absf(p1.global_position.x - p2.global_position.x))
				_next()
		2:
			if _f == _f0 + 2:
				InputRouter.v_press(1, "light")
			if _f == _f0 + 14:
				InputRouter.v_press(1, "light")
			if _f > _f0 + 50:
				if p2.hp < p2.data.max_hp:
					_ok("light hits connected: p2 hp %.0f/%.0f, p1 meter %.0f, hitstop seen" % [p2.hp, p2.data.max_hp, p1.meter])
					_next()
				else:
					_fail("light attack did not connect (p1 state %d, p2 state %d)" % [p1.state, p2.state])
		3:
			if _f == _f0 + 2:
				InputRouter.v_press(1, "skill1")
			if _f > _f0 + 70:
				if p2.stats.ragdolls > 0:
					_ok("skill1 launcher spawned a ragdoll (p2 state %d, x=%.2f)" % [p2.state, p2.global_position.x])
					_next()
				else:
					_fail("no ragdoll after skill1 (p2 state %d hp %.0f)" % [p2.state, p2.hp])
		4:
			if p2.is_actionable() and _f > _f0 + 20:
				_ok("p2 got up after ragdoll at frame %d" % (_f - _f0))
				InputRouter.v_set(1, "grapple", true)
				_next()
		5:
			if p1.state == Fighter.State.GRAPPLE:
				_ok("grapple attached to anchor at %s (charges left %d)" % [p1.grapple.anchor_point, p1.grapple.charges])
				_next()
			elif _f > _f0 + 20:
				_fail("grapple did not attach (p1 state %d, charges %d)" % [p1.state, p1.grapple.charges])
		6:
			if _f > _f0 + 40:
				InputRouter.v_set(1, "grapple", false)
			if _f > _f0 + 50 and p1.state != Fighter.State.GRAPPLE:
				_ok("grapple released; p1 state %d, y=%.2f" % [p1.state, p1.global_position.y])
				_next()
			elif _f > _f0 + 200:
				_fail("grapple never released")
		7:
			if p1.is_actionable():
				_ok("p1 landed and is actionable")
				_next()
		8:
			var dx := p2.global_position.x - p1.global_position.x
			InputRouter.v_set(1, "right" if dx > 0.0 else "left", true)
			InputRouter.v_set(1, "left" if dx > 0.0 else "right", false)
			if absf(dx) < 1.8:
				InputRouter.v_set(1, "right", false)
				InputRouter.v_set(1, "left", false)
				p2.hp = 150.0
				p1.meter = Fighter.MAX_METER
				_next()
		9:
			if _f == _f0 + 3:
				InputRouter.v_press(1, "ultimate")
			if p2.state == Fighter.State.KO:
				_ok("ultimate KO'd p2; flow phase %d" % flow.phase)
				_next()
			elif _f > _f0 + 90:
				_fail("ultimate did not KO (p2 hp %.0f state %d, p1 state %d meter %.0f)" % [p2.hp, p2.state, p1.state, p1.meter])
		10:
			if flow.phase == MatchFlow.Phase.INTRO and flow.round_no == 2:
				_ok("round 2 started after KO; wins p1=%d p2=%d" % [flow.wins[1], flow.wins[2]])
				_finish()
			elif _f > _f0 + 400:
				_fail("round 2 never started (phase %d)" % flow.phase)


func _next() -> void:
	_stage += 1
	_f0 = _f
