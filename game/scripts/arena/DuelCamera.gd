class_name DuelCamera
extends Node3D
## Free-movement duel camera (Prototype 0.3, GameState.free_move; FightCamera stays for the plane).
## Stands side-on to the line between the fighters and turns with it, so up close it reads like the
## 0.2 side camera. The screen-right direction is GameState.duel.right (simulation side, never
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

@onready var arm: SpringArm3D = $SpringArm3D
@onready var cam: Camera3D = $SpringArm3D/Camera3D

var p1: Fighter
var p2: Fighter
var _shake: float = 0.0
var _yaw: float = 0.0
var _pull: float = 0.0   # current arm pull-back fraction, 0 … PULLBACK_MAX


func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	arm.collision_mask = 1    # static world only; fighters are layer 2
	_yaw = _target_yaw()
	rotation = Vector3(0.0, _yaw, 0.0)
	_apply(1.0)
	cam.make_current()


## Yaw of this rig whose +Z (the arm's direction, back toward the camera) is 90° off screen-right.
func _target_yaw() -> float:
	var back := GameState.duel.right.cross(Vector3.UP)
	return atan2(back.x, back.z)


## The yaw clamp runs on the physics tick, so the smoke measures exactly what the rule says.
func _physics_process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	var diff := angle_difference(_yaw, _target_yaw())
	var step := clampf(diff, -deg_to_rad(YAW_CLAMP_DEG), deg_to_rad(YAW_CLAMP_DEG))
	_yaw += step
	rotation = Vector3(0.0, _yaw, 0.0)
	var lag := rad_to_deg(absf(diff - step))
	_pull = lerpf(_pull, PULLBACK_MAX if lag > PULLBACK_LAG_DEG else 0.0, 1.0 - pow(0.0015, delta))


## Arm pull-back right now (0 … PULLBACK_MAX), for the smoke test.
func pullback() -> float:
	return _pull


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
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
	var a := p1.global_position
	var b := p2.global_position
	var sep := Vector3(a.x - b.x, 0.0, a.z - b.z).length()
	var hi := maxf(a.y, b.y)
	var dist := clampf(5.5 + sep * 0.78, 7.0, 15.5)
	var focus := Vector3((a.x + b.x) * 0.5, 1.25 + hi * 0.4, (a.z + b.z) * 0.5)
	var lift := 0.35 + hi * 0.05 + dist * 0.14
	global_position = global_position.lerp(focus, k) if k < 1.0 else focus
	arm.rotation = Vector3(-atan2(lift, dist), 0.0, 0.0)
	arm.spring_length = sqrt(dist * dist + lift * lift) * (1.0 + _pull)


## Horizontal view direction of the camera (for the smoke turn-rate check).
func view_yaw() -> float:
	var z := cam.global_basis.z
	return atan2(z.x, z.z)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
