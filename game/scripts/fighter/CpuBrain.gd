class_name CpuBrain
extends Node
## Minimal sparring AI so one person can test alone. Drives the fighter through InputRouter's
## virtual-input layer — the same path a human uses. Seeded RNG = reproducible behaviour in tests.

var fighter: Fighter
var difficulty: float = 0.6
var _timer: int = 0
var _hold_block: int = 0
var _hold_grapple: int = 0
var _hold_side: int = 0        # free movement: frames left of a sidestep (up/down held)
var _side_key: String = "up"
var sidesteps: int = 0         # free movement: sidesteps started (smoke test reads it)
# Free movement behaviour odds (PLACEHOLDER — AI tuning, not combat numbers; T5 Арес may retune):
const SIDESTEP_CHANCE := 0.25        # per decision from close to mid range: circle instead of walking in / striking
const SIDESTEP_FRAMES := Vector2i(20, 40)
const PUNISH_SIDESTEP_CHANCE := 0.6  # × difficulty: strike when the opponent circles close by
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1337 + (fighter.player_index if fighter else 0)


func _in_smoke() -> bool:
	for n in fighter.get_tree().get_nodes_in_group("smoke"):
		if n is SmokeCloud and (n as SmokeCloud).covers(fighter.global_position):
			return true
	return false


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
	if _hold_side > 0:
		_hold_side -= 1
		if _hold_side == 0:
			InputRouter.v_release(p, _side_key)
	_timer -= 1
	if _timer > 0:
		return
	_timer = _rng.randi_range(6, 16)
	var dx := o.global_position.x - fighter.global_position.x
	var dist := absf(dx)
	if GameState.free_move:
		# free movement: sides and distance in the duel's screen frame (input is camera-relative)
		var d := Vector3(o.global_position.x - fighter.global_position.x, 0.0, o.global_position.z - fighter.global_position.z)
		dx = d.dot(GameState.duel.right)
		dist = d.length()
	var toward := "right" if dx > 0.0 else "left"
	var away := "left" if dx > 0.0 else "right"
	InputRouter.v_release(p, "left")
	InputRouter.v_release(p, "right")
	InputRouter.v_release(p, "crouch")
	if not fighter.is_actionable() and fighter.state != Fighter.State.JUMP:
		return
	# Shadow Veil / smoke: the CPU loses track and wanders
	if (o.veil_frames > 0 and o.revealed_frames <= 0) or _in_smoke():
		InputRouter.v_set(p, toward if _rng.randf() < 0.5 else away, true)
		return
	if GameState.free_move and _free_move_choice(p, o, dist):
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


## Free movement: answer an opponent who circles close by with a strike (attacks track on startup),
## and sometimes circle (close to mid range) instead of walking straight in. True = this decision is taken.
func _free_move_choice(p: int, o: Fighter, dist: float) -> bool:
	if _hold_side > 0:
		return true
	var to := Vector3(o.global_position.x - fighter.global_position.x, 0.0, o.global_position.z - fighter.global_position.z)
	if to.length() > 0.05:
		var tangential := (o.velocity - to.normalized() * o.velocity.dot(to.normalized()))
		tangential.y = 0.0
		if dist < 2.8 and tangential.length() > 1.0 and _rng.randf() < PUNISH_SIDESTEP_CHANCE * difficulty:
			InputRouter.v_press(p, "light")
			return true
	if dist > 1.2 and dist < 6.0 and _rng.randf() < SIDESTEP_CHANCE:
		_side_key = "up" if _rng.randf() < 0.5 else "down"
		_hold_side = _rng.randi_range(SIDESTEP_FRAMES.x, SIDESTEP_FRAMES.y)
		InputRouter.v_set(p, _side_key, true)
		sidesteps += 1
		return true
	return false
