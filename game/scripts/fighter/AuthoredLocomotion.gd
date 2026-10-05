class_name AuthoredLocomotion
extends RefCounted
## Presentation-only grounded gait selection and clean-pose transitions.
## Walk/Jog/Sprint use installed UAL clips. Sprint and jump have authored entry/exit.
## Walk/jog starts and stops blend existing authored poses without root-motion authority.
const Cadence = preload("res://scripts/fighter/LocomotionCadence.gd")
enum Gait { IDLE, WALK, JOG, RUN }
# PLACEHOLDER visual thresholds, never movement speed or combat frame data.
const STOP_SPEED: float = 0.08
const WALK_LIMIT: float = 2.7
const RUN_LIMIT: float = 6.8
const HYSTERESIS: float = 0.22
const BLEND_SECONDS: float = 0.12
const TAKEOFF_SECONDS: float = 0.12
const LAND_SECONDS: float = 0.18
const SPRINT_TRANSITION_SECONDS: float = 0.18
var gait: Gait = Gait.IDLE
var transition: String = "idle"
var source_clip: String = ""
var speed: float = 0.0
var acceleration: float = 0.0
var active: bool = false
var _last_state: int = -1
var _air_elapsed: float = 0.0
var _land_elapsed: float = LAND_SECONDS
var _takeoff: bool = false
var special_clip: String = ""
var _sprint_transition: String = ""
var _sprint_elapsed: float = SPRINT_TRANSITION_SECONDS
var _last_clip: String = ""
var _last_output: Array[Transform3D] = []
var _blend_source: Array[Transform3D] = []
var _base: Array[Transform3D] = []
var _blend_elapsed: float = BLEND_SECONDS

func update(f: Fighter, distance: float, delta: float, leg_scale: float, permitted: bool = true) -> void:
	var previous_speed: float = speed
	var previous_gait: Gait = gait
	special_clip = ""
	if f.state == Fighter.State.JUMP:
		if _last_state != Fighter.State.JUMP:
			_air_elapsed = 0.0
			_takeoff = f.velocity.y > 0.0
		else:
			_air_elapsed += maxf(delta, 0.0)
		special_clip = "Jump_Start" if _takeoff and _air_elapsed < TAKEOFF_SECONDS else "Jump_Loop"
		_land_elapsed = LAND_SECONDS
	elif _last_state == Fighter.State.JUMP and f.state in [Fighter.State.IDLE, Fighter.State.WALK] and f.on_ground():
		_land_elapsed = 0.0
	else:
		_land_elapsed += maxf(delta, 0.0)
	_last_state = f.state
	if not permitted:
		special_clip = ""
	var grounded_hook: bool = f.state == Fighter.State.GRAPPLE and f.on_ground() and f.grapple.phase != GrappleHook.Phase.WINDUP
	active = permitted and (f.state in [Fighter.State.IDLE, Fighter.State.WALK] or grounded_hook)
	speed = maxf(distance, 0.0) / maxf(delta, 0.00001) if active else 0.0
	acceleration = (speed - previous_speed) / maxf(delta, 0.00001)
	if not active:
		gait = Gait.IDLE
		source_clip = ""
		transition = "inactive"
		_sprint_transition = ""
		if special_clip.is_empty():
			_last_clip = ""
			_last_output.clear()
			_blend_source.clear()
		return
	if _land_elapsed < LAND_SECONDS and speed <= STOP_SPEED:
		special_clip = "Jump_Land"
	var walk_limit: float = WALK_LIMIT * leg_scale
	var run_limit: float = RUN_LIMIT * leg_scale
	if speed <= STOP_SPEED:
		gait = Gait.IDLE
	elif f.grapple != null and f.grapple.recovering():
		# Winding is a deliberate walk with independent upper-body work, never a slowed run.
		gait = Gait.WALK
	elif previous_gait >= Gait.JOG and speed > walk_limit - HYSTERESIS:
		gait = Gait.RUN if speed > run_limit + (HYSTERESIS if previous_gait != Gait.RUN else -HYSTERESIS) else Gait.JOG
	else:
		gait = Gait.WALK if speed < walk_limit + HYSTERESIS else (Gait.RUN if speed > run_limit + HYSTERESIS else Gait.JOG)
	transition = "idle" if gait == Gait.IDLE else "steady"
	if previous_gait == Gait.IDLE and gait != Gait.IDLE:
		transition = "start"
	elif gait == Gait.IDLE and previous_gait != Gait.IDLE:
		transition = "stop"
	elif acceleration > 0.5:
		transition = "accelerate"
	elif acceleration < -0.5:
		transition = "decelerate"
	var forward: Vector3 = f.forward if GameState.free_move else Vector3(float(f.facing), 0.0, 0.0)
	var index: int = Cadence.sector(f.velocity, forward)
	source_clip = "" if gait == Gait.IDLE else (Cadence.WALK[index] if gait == Gait.WALK else Cadence.JOG[index])
	if gait == Gait.RUN and index == 0:
		source_clip = "Sprint_Loop"
	if gait == Gait.RUN and previous_gait != Gait.RUN and index == 0:
		_sprint_transition = "Sprint_Enter"
		_sprint_elapsed = 0.0
	elif previous_gait == Gait.RUN and gait != Gait.RUN and not f.grapple.recovering() and index == 0:
		_sprint_transition = "Sprint_Exit"
		_sprint_elapsed = 0.0
	else:
		_sprint_elapsed += maxf(delta, 0.0)
	if f.grapple.recovering() or index != 0 or (_sprint_transition == "Sprint_Enter" and gait != Gait.RUN):
		_sprint_transition = ""
	if _sprint_elapsed < SPRINT_TRANSITION_SECONDS and not _sprint_transition.is_empty() and special_clip.is_empty():
		special_clip = _sprint_transition

func special_time(length: float) -> float:
	if special_clip in ["Sprint_Enter", "Sprint_Exit"]:
		return length * clampf(_sprint_elapsed / SPRINT_TRANSITION_SECONDS, 0.0, 1.0)
	if special_clip == "Jump_Start":
		# Sample the rising half: the simulation has already left the ground.
		return lerpf(length * 0.45, length, clampf(_air_elapsed / TAKEOFF_SECONDS, 0.0, 1.0))
	if special_clip == "Jump_Land":
		return length * clampf(_land_elapsed / LAND_SECONDS, 0.0, 1.0)
	return -1.0

func moving() -> bool:
	return active and gait != Gait.IDLE

func moving_landing_phase() -> float:
	return _land_elapsed / LAND_SECONDS if active and moving() and _land_elapsed < LAND_SECONDS else -1.0

## Call after restoring other previous-frame overlays, immediately before seeking.
func restore(skeleton: Skeleton3D) -> void:
	for bone: int in _base.size():
		_set_pose(skeleton, bone, _base[bone])
	_base.clear()

## Call immediately after seek and before sword/combat/recovery/idle overlays.
func apply(skeleton: Skeleton3D, clip: String, delta: float) -> void:
	if not active and special_clip.is_empty():
		return
	if clip != _last_clip:
		_blend_source = _last_output.duplicate()
		_blend_elapsed = 0.0
		_last_clip = clip
	_blend_elapsed += maxf(delta, 0.0)
	if not _blend_source.is_empty() and _blend_elapsed < BLEND_SECONDS:
		_base = _poses(skeleton)
		var weight: float = smoothstep(0.0, BLEND_SECONDS, _blend_elapsed)
		for bone: int in _base.size():
			_set_pose(skeleton, bone, _blend_source[bone].interpolate_with(_base[bone], weight))
	else:
		# Steady clips are untouched: rewriting unkeyed bones through matrix
		# decomposition each tick would accumulate quaternion round-off.
		_base.clear()
		_blend_source.clear()
	_last_output = _poses(skeleton)

static func _poses(skeleton: Skeleton3D) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone: int in skeleton.get_bone_count():
		result.append(skeleton.get_bone_pose(bone))
	return result

static func _set_pose(skeleton: Skeleton3D, bone: int, pose: Transform3D) -> void:
	skeleton.set_bone_pose_position(bone, pose.origin)
	skeleton.set_bone_pose_rotation(bone, pose.basis.orthonormalized().get_rotation_quaternion())
	skeleton.set_bone_pose_scale(bone, pose.basis.get_scale())
