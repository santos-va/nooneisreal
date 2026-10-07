class_name CpuBrain
extends Node
## Minimal sparring AI so one person can test alone. Drives the fighter through InputRouter's
## virtual-input layer — the same path a human uses. Seeded RNG = reproducible behaviour in tests.
## A CPU-only enemy (CharacterData.cpu_only, ADR-024) runs _enemy_tick instead of the sparring choice: pocket edge,
## authored series, recovery punish, SNUFF only in its band, low hooks. The heroes' sparring path is untouched.

var fighter: Fighter
## Decision weight; CharacterData.cpu_difficulty (default 0.6 = the old constant, so the heroes are unchanged).
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


# CPU-only enemy tactics (docs/GDD/03-Skills-Framework.md § Мінімум CPU для цього кіта). All odds, bands and
# frame counts are PLACEHOLDER AI tuning, not combat numbers; T5 Арес may retune them.
## Authored series from the enemy's own slots, chained through the existing cancel rules (light → light → heavy,
## low hook → heavy, heavy → SNUFF). A step is pressed only after the previous one connected (hit or block).
const ENEMY_SERIES: Array = [["light", "light", "heavy"], ["crouch_light", "heavy"], ["heavy", "skill1"]]
const ENEMY_SNUFF_RANGE := Vector2(2.0, 3.6)   # GDD 03 § Мінімум CPU: SNUFF only when the foe is 2.0–3.6 m away
const ENEMY_STRIKE_RANGE := 2.3                # the pole jab's reach (GDD 03 § Кадри): start a series inside it
const ENEMY_CLOSE := 1.6                       # closer than this the zoner may step back to pole range
const ENEMY_EDGE_MARGIN := 1.5                 # m inside the pocket wall: no backing off outward past it
const ENEMY_PUNISH_REACT := 3                  # frames of the foe's whiffed recovery seen before the punish
const ENEMY_PAUSE := Vector2i(18, 30)          # breath after a series (or block instead)
const ENEMY_SNUFF_CHANCE := 0.35
const ENEMY_BACKOFF_CHANCE := 0.35
var series: Array = []          # the series in progress (fixtures read it)
var series_step: int = 0
var _series_pressed: int = -1   # step index already pressed for the current move
var series_done: int = 0        # completed series (every step pressed)
var punishes: int = 0
var snuffs: int = 0
var low_hooks: int = 0
var edge_holds: int = 0         # decisions where backing off was refused at the pocket wall
var _punish_seen: Object = null # the foe's move in the swing being watched
var _punish_move_frame: int = -1
var _punish_judged: bool = false # this swing already had its one roll
var _press_frame: int = -1      # InputRouter frame of the last series press (the move starts a tick later)


func _ready() -> void:
	_rng.seed = 1337 + (fighter.player_index if fighter else 0)
	if fighter != null and fighter.data != null:
		difficulty = fighter.data.cpu_difficulty


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
	if fighter.data.cpu_only:
		_enemy_tick(p, o)
		return
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


# --- CPU-only enemy (ADR-024) ------------------------------------------------------------------------
func _enemy_tick(p: int, o: Fighter) -> void:
	var d := Vector3(o.global_position.x - fighter.global_position.x, 0.0, o.global_position.z - fighter.global_position.z)
	var dist := d.length()
	var dx := d.dot(GameState.duel.right) if GameState.free_move else d.x
	var toward := "right" if dx > 0.0 else "left"
	var away := "left" if dx > 0.0 else "right"
	if _series_continue(p, dist):
		return
	if _punish(p, o, dist):
		return
	_timer -= 1
	if _timer > 0:
		return
	_timer = _rng.randi_range(6, 16)
	InputRouter.v_release(p, "left")
	InputRouter.v_release(p, "right")
	InputRouter.v_release(p, "crouch")
	InputRouter.v_release(p, "up")
	InputRouter.v_release(p, "down")
	if not fighter.is_actionable():
		return
	if (o.veil_frames > 0 and o.revealed_frames <= 0) or _in_smoke():
		InputRouter.v_set(p, _safe_back(toward, away), true)
		return
	if o.state == Fighter.State.ATTACK and dist < 2.8 and _rng.randf() < 0.5 * difficulty:
		InputRouter.v_press(p, "block")
		_hold_block = 20
		return
	if dist > ENEMY_SNUFF_RANGE.y:
		InputRouter.v_set(p, toward, true)
		if _rng.randf() < 0.12:
			InputRouter.v_press(p, "dash")
		return
	if dist > ENEMY_STRIKE_RANGE:
		if snuff_allowed(dist) and _rng.randf() < ENEMY_SNUFF_CHANCE:
			InputRouter.v_press(p, "skill1")
			snuffs += 1
		else:
			InputRouter.v_set(p, toward, true)
		return
	if dist < ENEMY_CLOSE and _rng.randf() < ENEMY_BACKOFF_CHANCE:
		InputRouter.v_set(p, _safe_back(toward, away), true)
		return
	_start_series(p, dist)


## SNUFF needs its band (GDD 03 § Мінімум CPU) and a ready cooldown; the telegraph itself is never cut.
func snuff_allowed(dist: float) -> bool:
	return dist >= ENEMY_SNUFF_RANGE.x and dist <= ENEMY_SNUFF_RANGE.y and fighter._skill_ready("skill1")


func _start_series(p: int, dist: float) -> void:
	var options: Array = []
	for candidate: Array in ENEMY_SERIES:
		if candidate.has("skill1") and not fighter._skill_ready("skill1"):
			continue
		options.append(candidate)
	series = options[_rng.randi_range(0, options.size() - 1)]
	series_step = 0
	_series_pressed = -1
	_press_step(p, dist)


## Presses the current step; false when the step cannot be taken (the series then ends).
func _press_step(p: int, dist: float) -> bool:
	var action: String = series[series_step]
	if action == "skill1" and not snuff_allowed(dist):
		return false
	if action == "crouch_light":
		InputRouter.v_set(p, "crouch", true)
		InputRouter.v_press(p, "light")
		low_hooks += 1
	else:
		InputRouter.v_release(p, "crouch")
		InputRouter.v_press(p, action)
		if action == "skill1":
			snuffs += 1
	_series_pressed = series_step
	_press_frame = InputRouter.frame()
	return true


## Keeps a series going: the next step is pressed in the cancel window of a move that connected. A whiff, a stun or
## the last step ends it with a breath (pause) or a guard. True while the series owns this tick.
func _series_continue(p: int, dist: float) -> bool:
	if series.is_empty():
		return false
	var m := fighter.current_move
	if fighter.state == Fighter.State.ATTACK and m != null:
		if fighter.has_hit and fighter.move_frame >= m.startup + m.active and _series_pressed == series_step:
			if series_step + 1 >= series.size():
				series_done += 1
				_end_series(p)
				return false
			series_step += 1
			if not _press_step(p, dist):
				_end_series(p)
				return false
		return true
	if InputRouter.frame() - _press_frame <= InputRouter.BUFFER_FRAMES:
		return true      # pressed; the move has not started yet
	_end_series(p)       # the move ended (whiff, stun, recovery) without the next step
	return false


func _end_series(p: int) -> void:
	series = []
	series_step = 0
	_series_pressed = -1
	InputRouter.v_release(p, "crouch")
	# The breath starts after the last move's own recovery, never inside it.
	var left := 0
	if fighter.state == Fighter.State.ATTACK and fighter.current_move != null:
		left = maxi(0, fighter.move_end_frame(fighter.current_move) - fighter.move_frame)
	if _rng.randf() < 0.5 * difficulty:
		InputRouter.v_press(p, "block")
		_hold_block = left + 16
		_timer = _hold_block
	else:
		_timer = left + _rng.randi_range(ENEMY_PAUSE.x, ENEMY_PAUSE.y)


## The foe whiffed and is still recovering inside the pole's reach: answer with the strike that fits the frames left.
## One roll per foe move, weighted by difficulty.
func _punish(p: int, o: Fighter, dist: float) -> bool:
	var m := o.current_move
	if o.state != Fighter.State.ATTACK or m == null:
		_punish_seen = null
		return false
	if m != _punish_seen or o.move_frame < _punish_move_frame:
		_punish_seen = m          # a new swing (another move, or the same move started again)
		_punish_judged = false
	_punish_move_frame = o.move_frame
	if _punish_judged or not fighter.is_actionable() or o.has_hit:
		return false
	if o.move_frame < m.startup + m.active + ENEMY_PUNISH_REACT:
		return false
	_punish_judged = true
	if _rng.randf() >= difficulty:
		return false
	var left := o.move_end_frame(m) - o.move_frame
	for slot: String in ["heavy", "light"]:
		var answer: MoveData = fighter.data.heavy if slot == "heavy" else fighter.data.light
		if answer != null and dist <= reach(answer) and left > answer.startup:
			InputRouter.v_release(p, "left")
			InputRouter.v_release(p, "right")
			InputRouter.v_release(p, "crouch")
			InputRouter.v_press(p, slot)
			punishes += 1
			_timer = answer.startup + answer.active
			return true
	return false


## Forward reach of a move, as the GDD tables count it: hitbox_offset.x + hitbox_size.x / 2.
static func reach(m: MoveData) -> float:
	return m.hitbox_offset.x + m.hitbox_size.x * 0.5


## World direction of a CPU movement key (DuelFrame.to_world for a player without the behind camera).
static func key_world(key: String) -> Vector3:
	match key:
		"right":
			return GameState.duel.right
		"left":
			return -GameState.duel.right
		"up":
			return GameState.duel.depth()
	return -GameState.duel.depth()


## Backing off near the pocket wall would walk into it: inside ENEMY_EDGE_MARGIN of the wall, an outward retreat
## becomes a sidestep toward the centre (GDD 03: remember the pocket's edge, do not back into the wall).
func _safe_back(toward: String, away: String) -> String:
	var off := Fighter._flat(fighter.global_position - fighter.arena_center)
	if off.length() < fighter.arena_radius - ENEMY_EDGE_MARGIN:
		return away
	var n := off.normalized()
	if key_world(away).dot(n) <= 0.3:
		return away
	edge_holds += 1
	if key_world("up").dot(n) < 0.0:
		return "up"
	if key_world("down").dot(n) < 0.0:
		return "down"
	return toward
