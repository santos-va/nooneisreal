class_name CpuBrain
extends Node
## Minimal sparring AI so one person can test alone. Drives the fighter through InputRouter's
## virtual-input layer — the same path a human uses. Seeded RNG = reproducible behaviour in tests.

var fighter: Fighter
var difficulty: float = 0.6
var _timer: int = 0
var _hold_block: int = 0
var _hold_grapple: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1337 + (fighter.player_index if fighter else 0)


func _physics_process(_delta: float) -> void:
	if fighter == null:
		return
	var p := fighter.player_index
	var o := fighter.opponent
	if o == null or fighter.control_locked or GameState.training_mode:
		InputRouter.v_clear(p)
		return
	if _hold_block > 0:
		_hold_block -= 1
		if _hold_block == 0:
			InputRouter.v_release(p, "block")
	if _hold_grapple > 0:
		_hold_grapple -= 1
		if _hold_grapple == 0:
			InputRouter.v_release(p, "grapple")
	_timer -= 1
	if _timer > 0:
		return
	_timer = _rng.randi_range(6, 16)
	var dx := o.global_position.x - fighter.global_position.x
	var dist := absf(dx)
	var toward := "right" if dx > 0.0 else "left"
	var away := "left" if dx > 0.0 else "right"
	InputRouter.v_release(p, "left")
	InputRouter.v_release(p, "right")
	InputRouter.v_release(p, "crouch")
	if not fighter.is_actionable() and fighter.state != Fighter.State.JUMP:
		return
	# defend when the opponent swings in range
	if o.state == Fighter.State.ATTACK and dist < 2.8 and _rng.randf() < 0.5 * difficulty:
		InputRouter.v_press(p, "block")
		_hold_block = 20
		return
	if dist > 2.1:
		var r := _rng.randf()
		if r < 0.07 and fighter.grapple.charges > 0 and dist > 4.5:
			InputRouter.v_set(p, "grapple", true)
			_hold_grapple = 18
		elif r < 0.17:
			InputRouter.v_set(p, toward, true)
			InputRouter.v_press(p, "dash")
		elif r < 0.23:
			InputRouter.v_set(p, toward, true)
			InputRouter.v_press(p, "jump")
		else:
			InputRouter.v_set(p, toward, true)
		return
	var r := _rng.randf()
	if r < 0.42:
		InputRouter.v_press(p, "light")
	elif r < 0.64:
		InputRouter.v_press(p, "heavy")
	elif r < 0.74 and fighter._skill_ready("skill1"):
		InputRouter.v_press(p, "skill1")
	elif r < 0.8 and fighter._skill_ready("skill2"):
		InputRouter.v_press(p, "skill2")
	elif r < 0.86 and fighter.meter >= Fighter.MAX_METER:
		InputRouter.v_press(p, "ultimate")
	elif r < 0.94:
		InputRouter.v_press(p, "block")
		_hold_block = 16
	else:
		InputRouter.v_set(p, away, true)
