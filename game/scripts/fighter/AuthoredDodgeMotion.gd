class_name AuthoredDodgeMotion
extends RefCounted
## UAL lateral evasion, aligned to the actual dash vector. Presentation only.
## Source 0..0.70 contains load, extension and catch; the long idle tail is omitted.
const SOURCE_END: float = 0.70
const RETURN_SECONDS: float = 0.10 # PLACEHOLDER visual settle, never an action lock.
var _base: Array[Transform3D] = []
var _entry: Array[Transform3D] = []
var _last_output: Array[Transform3D] = []
var _return: Array[Transform3D] = []
var _return_elapsed: float = RETURN_SECONDS
var _was_dodging: bool = false
var _last_progress: float = -1.0

static func source(fighter: Fighter) -> String:
	return "Dodge_Right" if fighter.dodge_local_direction().y >= 0.0 else "Dodge_Left"

static func source_time(fighter: Fighter) -> float:
	var progress: float = clampf(fighter.dodge_progress(), 0.0, 1.0)
	# Measured source anchors: load at 0, lateral extension .217, catch .433.
	if progress < 0.40:
		return lerpf(0.0, 0.217, progress / 0.40)
	if progress < 0.75:
		return lerpf(0.217, 0.433, (progress - 0.40) / 0.35)
	return lerpf(0.433, SOURCE_END, (progress - 0.75) / 0.25)

func prepare(skeleton: Skeleton3D, fighter: Fighter) -> void:
	var dodging: bool = fighter.dodging
	if dodging and (not _was_dodging or fighter.dodge_progress() < _last_progress):
		_entry = AuthoredLocomotion._poses(skeleton)
		_return.clear()
	elif not dodging and _was_dodging:
		_return = _last_output.duplicate()
		_return_elapsed = 0.0
	if not dodging and fighter.state not in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.JUMP]:
		_return.clear()
	_was_dodging = dodging
	_last_progress = fighter.dodge_progress() if dodging else -1.0

func restore(skeleton: Skeleton3D) -> void:
	for bone: int in _base.size():
		AuthoredLocomotion._set_pose(skeleton, bone, _base[bone])
	_base.clear()

func apply(skeleton: Skeleton3D, fighter: Fighter, delta: float) -> void:
	if fighter.dodging:
		_base = AuthoredLocomotion._poses(skeleton)
		var hips: int = skeleton.find_bone("pelvis")
		var rest: Vector3 = skeleton.get_bone_global_rest(hips).origin
		var current: Vector3 = skeleton.get_bone_global_pose(hips).origin
		var up: Vector3 = (skeleton.global_basis.inverse() * Vector3.UP).normalized()
		var target: Vector3 = rest + up * (current - rest).dot(up)
		var parent: int = skeleton.get_bone_parent(hips)
		skeleton.set_bone_pose_position(hips, skeleton.get_bone_global_pose(parent).affine_inverse() * target if parent >= 0 else target)
		var direction: Vector2 = fighter.dodge_local_direction()
		var side: Vector3 = fighter.forward.cross(Vector3.UP) * (1.0 if direction.y >= 0.0 else -1.0)
		var travel: Vector3 = fighter.forward * direction.x + fighter.forward.cross(Vector3.UP) * direction.y
		if travel.length_squared() > 0.001:
			var progress: float = fighter.dodge_progress()
			var turn_weight: float = smoothstep(0.0, 0.25, progress) * (1.0 - smoothstep(0.65, 1.0, progress))
			var turn: float = side.signed_angle_to(travel, Vector3.UP) * turn_weight
			AuthoredCombatMotion._set_global_rotation(skeleton, hips, Quaternion(up, turn) * AuthoredCombatMotion._global_rotation(skeleton, hips))
		var entry_weight: float = smoothstep(0.0, 0.18, fighter.dodge_progress())
		for bone: int in _entry.size():
			AuthoredLocomotion._set_pose(skeleton, bone, _entry[bone].interpolate_with(skeleton.get_bone_pose(bone), entry_weight))
		_last_output = AuthoredLocomotion._poses(skeleton)
	elif not _return.is_empty():
		_return_elapsed += maxf(delta, 0.0)
		if _return_elapsed >= RETURN_SECONDS:
			_return.clear()
			return
		_base = AuthoredLocomotion._poses(skeleton)
		var weight: float = smoothstep(0.0, RETURN_SECONDS, _return_elapsed)
		for bone: int in _return.size():
			AuthoredLocomotion._set_pose(skeleton, bone, _return[bone].interpolate_with(_base[bone], weight))
