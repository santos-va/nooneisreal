class_name DuelCamera
extends Node3D
## Free-movement duel camera (Prototype 0.3, GameState.free_move; FightCamera stays for the plane).
## Launch 6 (docs/Decisions/ADR-015-Solo-Camera-Behind-Fighter.md): solo vs CPU it stands behind P1 over the
## right shoulder; in VERSUS it stands side-on to the line between the fighters and turns with it, so up
## close it reads like the 0.2 side camera. The screen-right direction is GameState.duel.right (simulation side, never
## flips 180° when the fighters swap); this node only follows it — presentation, not gameplay.
## The SpringArm3D keeps the camera out of walls. Framing numbers are FightCamera's.
## Plan: docs/Plans/2026-10-03-Prototype-0.3-Free-Movement.md, step 0.3-2.

## T5 Арес, docs/GDD/02-Combat-System.md § Камера дуелі на швидкому розвороті:
## `camera_yaw_clamp` — the yaw turns at most this per physics tick (180°/s; FM C10, ДИЗАЙН).
const YAW_CLAMP_DEG := 3.0
## While the clamp lags the fighters' line by more than this, the arm pulls back (no cuts) …
const PULLBACK_LAG_DEG := 15.0
## … by up to this fraction of its length (+30 %, ДИЗАЙН).
const PULLBACK_MAX := 0.3
## Smoke bound (T2): while circling, the view stays within this of side-on — catches a camera that
## stops following the line. Not a design number.
const MAX_SIDE_OFF_DEG := 25.0
## Launch 6, ADR-015 + docs/GDD/02-Combat-System.md § Камера за спиною і плавність (T5 Арес, all PLACEHOLDER):
## `camera_yaw_accel` — the yaw's turn rate changes by at most this per physics tick (both modes).
const YAW_ACCEL_DEG := 0.25
## ADR-018 «the fight with air», numbers K-1 (GDD 02 § Кадр із запасом — replace ADR-015's closer ones; PLACEHOLDER).
## Mode `behind` (solo vs CPU): on the line P2 → P1, behind P1.
const BEHIND_DIST := 5.0          # m behind P1 while sep ≤ BEHIND_DIST_SEP …
const BEHIND_DIST_SEP := 4.0
const BEHIND_DIST_PER_M := 0.35   # … then +0.35 m per metre of sep …
const BEHIND_DIST_MAX := 9.0      # … up to 9 m
const BEHIND_HEIGHT_NEAR := 3.8   # m above the floor at sep ≤ 1 m …
const BEHIND_HEIGHT_FAR := 3.0    # … linearly down to this at sep ≥ 4 m
const BEHIND_SHOULDER := 1.0      # m to screen-right of P1
const BEHIND_FOCUS := 0.5         # the view aims at the pair's middle (ADR-018 п. 2, 4) …
const BEHIND_FOCUS_Y := 1.2       # … at this height
## Mode `side` (VERSUS): arm length = clamp(SIDE_DIST + SIDE_DIST_PER_M · sep, SIDE_DIST_MIN, SIDE_DIST_MAX).
const SIDE_DIST := 6.0
const SIDE_DIST_PER_M := 0.75
const SIDE_DIST_MIN := 8.0
const SIDE_DIST_MAX := 24.0
## Vertical field of view of both arena cameras (Arena.tscn), 91.5° horizontal in 16:9; the ceiling (ADR-018 п. 1).
const FOV_DEG := 60.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var cam: Camera3D = $SpringArm3D/Camera3D

var p1: Fighter
var p2: Fighter
var _shake: float = 0.0
var _yaw: float = 0.0
var _yaw_prev: float = 0.0   # yaw at the previous physics tick — the render frame interpolates between the two
var _omega: float = 0.0      # yaw turn this tick (rad/tick), |Δ| ≤ YAW_ACCEL_DEG per tick
var _pull: float = 0.0   # current arm pull-back fraction, 0 … PULLBACK_MAX
## ADR-015 mode, fixed for the match: true = behind P1 (FIGHT, TRAINING), false = side-on (VERSUS).
var behind: bool = false


func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	arm.collision_mask = 1    # static world only; fighters are layer 2
	behind = GameState.duel.behind
	_yaw = _target_yaw()
	_yaw_prev = _yaw
	_omega = 0.0
	rotation = Vector3(0.0, _yaw, 0.0)
	_apply(1.0)
	cam.make_current()


## Yaw of this rig whose +Z (the arm's direction, back toward the camera) points at the camera spot:
## side — 90° off screen-right; behind — from the focus to the spot behind P1's shoulder.
func _target_yaw() -> float:
	if behind:
		var v := behind_spot() - behind_focus()
		return atan2(v.x, v.z)
	var back := GameState.duel.right.cross(Vector3.UP)
	return atan2(back.x, back.z)


## Ground separation between the fighters (m).
func _sep() -> float:
	var d := p2.global_position - p1.global_position
	return Vector2(d.x, d.z).length()


## Behind mode: the point the view aims at (60 % P1 → P2, 1.2 m up).
func behind_focus() -> Vector3:
	var f := p1.global_position.lerp(p2.global_position, BEHIND_FOCUS)
	return Vector3(f.x, BEHIND_FOCUS_Y, f.z)


## Behind mode: where the camera wants to stand — behind P1 on the line, over the right shoulder, GDD 02 numbers.
func behind_spot() -> Vector3:
	var sep := _sep()
	var dist := minf(BEHIND_DIST + maxf(sep - BEHIND_DIST_SEP, 0.0) * BEHIND_DIST_PER_M, BEHIND_DIST_MAX)
	var h := lerpf(BEHIND_HEIGHT_NEAR, BEHIND_HEIGHT_FAR, clampf((sep - 1.0) / 3.0, 0.0, 1.0))
	var line: Vector3 = GameState.duel.line
	var p := p1.global_position - line * dist + line.cross(Vector3.UP) * BEHIND_SHOULDER
	return Vector3(p.x, h, p.z)


## The yaw runs on the physics tick, so the smoke measures exactly what the rules say: |turn| ≤ YAW_CLAMP_DEG
## per tick and |change of turn| ≤ YAW_ACCEL_DEG per tick. The turn eases off so it can stop on the target
## (speed ≤ √(2·accel·remaining)) instead of overshooting.
func _physics_process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	_yaw_prev = _yaw
	var diff := angle_difference(_yaw, _target_yaw())
	var accel := deg_to_rad(YAW_ACCEL_DEG)
	var want := signf(diff) * minf(minf(deg_to_rad(YAW_CLAMP_DEG), sqrt(2.0 * accel * absf(diff))), absf(diff))
	_omega += clampf(want - _omega, -accel, accel)
	_yaw += _omega
	rotation = Vector3(0.0, _yaw, 0.0)
	var lag := rad_to_deg(absf(angle_difference(_yaw, _target_yaw())))
	_pull = lerpf(_pull, PULLBACK_MAX if lag > PULLBACK_LAG_DEG else 0.0, 1.0 - pow(0.0015, delta))


## Yaw turn this physics tick (degrees) — the smoke's |Δω| check.
func turn_deg() -> float:
	return rad_to_deg(_omega)


## Arm pull-back right now (0 … PULLBACK_MAX), for the smoke test.
func pullback() -> float:
	return _pull


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	# render frames between physics ticks: interpolate the yaw (ADR-015 п. 3), never step it at 60 Hz
	rotation = Vector3(0.0, lerp_angle(_yaw_prev, _yaw, Engine.get_physics_interpolation_fraction()), 0.0)
	_apply(1.0 - pow(0.0015, delta))
	if _shake > 0.001:
		cam.h_offset = randf_range(-_shake, _shake)
		cam.v_offset = randf_range(-_shake, _shake) * 0.7
		_shake = lerpf(_shake, 0.0, minf(1.0, 11.0 * delta))
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0


## k = smoothing toward the target this frame (1 = snap).
func _apply(k: float) -> void:
	if behind:
		_apply_behind(k)
		return
	var a := p1.global_position
	var b := p2.global_position
	var sep := Vector3(a.x - b.x, 0.0, a.z - b.z).length()
	var hi := maxf(a.y, b.y)
	var dist := clampf(SIDE_DIST + sep * SIDE_DIST_PER_M, SIDE_DIST_MIN, SIDE_DIST_MAX)
	var focus := Vector3((a.x + b.x) * 0.5, 1.25 + hi * 0.4, (a.z + b.z) * 0.5)
	var lift := 0.35 + hi * 0.05 + dist * 0.14
	global_position = global_position.lerp(focus, k) if k < 1.0 else focus
	arm.rotation = Vector3(-atan2(lift, dist), 0.0, 0.0)
	arm.spring_length = sqrt(dist * dist + lift * lift) * (1.0 + _pull)


## Behind mode: rig at the focus, arm pitched and stretched so the camera lands on behind_spot() (the yaw is
## the rate-limited one, so on a fast turn the camera swings round instead of cutting).
func _apply_behind(k: float) -> void:
	var focus := behind_focus()
	var v := behind_spot() - focus
	var flat := Vector2(v.x, v.z).length()
	global_position = global_position.lerp(focus, k) if k < 1.0 else focus
	arm.rotation = Vector3(-atan2(v.y, flat), 0.0, 0.0)
	arm.spring_length = v.length() * (1.0 + _pull)


## Horizontal view direction of the camera (for the smoke turn-rate check).
func view_yaw() -> float:
	var z := cam.global_basis.z
	return atan2(z.x, z.z)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
