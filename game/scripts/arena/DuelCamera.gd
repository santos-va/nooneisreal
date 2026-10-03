class_name DuelCamera
extends Node3D
## Free-movement duel camera (Prototype 0.3, GameState.free_move; FightCamera stays for the plane).
## Stands side-on to the line between the fighters and turns with it, so up close it reads like the
## 0.2 side camera. The screen-right direction is GameState.duel.right (simulation side, never
## flips 180° when the fighters swap); this node only follows it — presentation, not gameplay.
## The SpringArm3D keeps the camera out of walls. Framing numbers are FightCamera's.
## Plan: docs/Plans/2026-10-03-Prototype-0.3-Free-Movement.md, step 0.3-2.

## Smoke bound: the camera must not turn faster than this per physics frame during a 360° sidestep
## or a side swap. PLACEHOLDER — the grounded value comes from T3 Архімед (#24).
const MAX_TURN_DEG_PER_FRAME := 6.0
## Smoke bound: how far the view may lag from side-on (90° to the fighters' line) while circling —
## the smoothing lag. PLACEHOLDER — #24.
const MAX_SIDE_OFF_DEG := 25.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var cam: Camera3D = $SpringArm3D/Camera3D

var p1: Fighter
var p2: Fighter
var _shake: float = 0.0
var _yaw: float = 0.0


func setup(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	arm.collision_mask = 1    # static world only; fighters are layer 2
	_yaw = _target_yaw()
	_apply(1.0)
	cam.make_current()


## Yaw of this rig whose +Z (the arm's direction, back toward the camera) is 90° off screen-right.
func _target_yaw() -> float:
	var back := GameState.duel.right.cross(Vector3.UP)
	return atan2(back.x, back.z)


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
	_yaw = lerp_angle(_yaw, _target_yaw(), k)
	rotation = Vector3(0.0, _yaw, 0.0)
	arm.rotation = Vector3(-atan2(lift, dist), 0.0, 0.0)
	arm.spring_length = sqrt(dist * dist + lift * lift)


## Horizontal view direction of the camera (for the smoke turn-rate check).
func view_yaw() -> float:
	var z := cam.global_basis.z
	return atan2(z.x, z.z)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
