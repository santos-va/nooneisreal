class_name IdlePresence
extends RefCounted
## Presentation-only additive stance, evaluated after the authored clip on the UAL skeleton.
## Pelvis stays authored; one foot at a time lifts through a bounded analytic two-bone solve.
## Angles below are provisional art amplitudes in degrees, never combat tuning.

## Plan docs/Plans/2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall.md step 2 (T6 review on 595490d: Choko's arms
## snapped into the guard 103–112°/tick on the first idle tick after a walk or a run). The overlay's weight falls to 0
## while the body travels or is in the air (the overlay is not drawn then) and comes back over RAMP_SECONDS once it
## stands; every other state keeps the weight it has, so a guard after an attack or a block is drawn as before.
const RAMP_SECONDS: float = 0.20 # PLACEHOLDER art duration (12 ticks)
## A variable only so a check can put the product of 595490d back (anim_ground_check --break=guard): 0 = full weight.
var ramp_seconds: float = RAMP_SECONDS
## SkeletalRig sets it each tick: only a hero walking the city ramps (this layer is on the mannequin, which seeds the
## ragdoll); everywhere else the guard keeps its full weight, as on 595490d.
var ramp_enabled: bool = false
var weight: float = 1.0
var phase: float = 0.0
var _bones: Dictionary = {}
var _skeleton: Skeleton3D
var _base_poses: Dictionary = {}
var _gain: float = 1.0


## SkeletalRig calls this on the ticks it does not draw the overlay because the body travels on the ground.
func fade(delta: float) -> void:
	weight = move_toward(weight, 0.0, maxf(delta, 0.0) / ramp_seconds) if ramp_enabled and ramp_seconds > 0.0 else 1.0


func apply(skeleton: Skeleton3D, fighter: Fighter, delta: float) -> void:
	var transfer: bool = fighter.state == Fighter.State.SWAP and fighter.data.id == "choko"
	if fighter.state == Fighter.State.JUMP and fighter.frozen_frames <= 0 and fighter.hitstop_frames <= 0:
		fade(delta)
	if (fighter.state != Fighter.State.IDLE and not transfer) or fighter.frozen_frames > 0 or fighter.hitstop_frames > 0:
		return
	if fighter.is_inside_tree() and fighter.get_tree().paused:
		return
	if fighter.data.id not in ["choko", "skea"]:
		return
	if not ramp_enabled or ramp_seconds <= 0.0:
		weight = 1.0
	elif not transfer:
		weight = move_toward(weight, 1.0, maxf(delta, 0.0) / ramp_seconds)
	# The sword transfer (SWAP) keeps its exact authored pose.
	_gain = 1.0 if transfer else smoothstep(0.0, 1.0, weight)
	if _skeleton != skeleton:
		_skeleton = skeleton
		_bones.clear()
		for name: String in ["spine_01", "spine_02", "spine_03", "neck_01", "Head", "upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r", "hand_l", "hand_r", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]:
			_bones[name] = skeleton.find_bone(name)
	# Save only our owned bones before this frame's layer. Some imported clips omit constant tracks;
	# AnimationPlayer.seek() cannot undo offsets on those bones by itself.
	_base_poses.clear()
	for bone: int in _bones.values():
		if bone >= 0:
			_base_poses[bone] = _skeleton.get_bone_pose(bone)
	if not transfer:
		phase += maxf(delta, 0.0)
	# Local clock and analytic harmonics: neither global RNG nor the fighter's replay RNG is touched.
	var t: float = 0.0 if transfer else phase + float(fighter.player_index) * 0.731
	var gain: float = (1.0 - 0.65 * clampf(fighter.fatigue, 0.0, 1.0)) * _gain
	if fighter.data.id == "choko":
		var shift: float = sin(t * 2.8)
		var breath: float = sin(t * 1.7)
		# Small connected thorax transfer; counter-rotation keeps the gaze collected.
		_rotate("spine_01", Vector3(0.7 * breath, 1.6 * shift, 1.1 * shift) * gain)
		_rotate("spine_03", Vector3(-0.4 * breath, -0.8 * shift, 0.7 * shift) * gain)
		_rotate("neck_01", Vector3(0.0, -0.8 * shift, -1.5 * shift) * gain)
		_collect_posture(fighter)
		_guard_arm("l", fighter, shift, breath)
		_guard_arm("r", fighter, shift, breath)
		# A collected lift/replant: no lateral slide, alternating support, both down between taps.
		var cycle: float = fposmod(t, 2.4)
		if not transfer and cycle < 0.55:
			_lift_foot("l", pow(sin(PI * cycle / 0.55), 2.0) * 0.018 * gain)
		elif not transfer and cycle >= 1.2 and cycle < 1.75:
			_lift_foot("r", pow(sin(PI * (cycle - 1.2) / 0.55), 2.0) * 0.018 * gain)
	else:
		# Smooth asymmetric bursts, rather than frame-random jitter or fake gameplay dodges.
		var sway: float = sin(t * 2.1 + 0.8)
		var feint: float = pow(maxf(0.0, sin(t * 3.7)), 5.0) - pow(maxf(0.0, sin(t * 2.3 + 1.2)), 5.0)
		_rotate("spine_02", Vector3(1.5 * sway, 2.0 * feint, 2.2 * sway) * gain)
		_rotate("spine_03", Vector3(-0.6 * sway, -1.0 * feint, -0.9 * sway) * gain)
		_rotate("neck_01", Vector3(2.5 * feint, 4.0 * feint, 3.0 * sway) * gain)
		_rotate("Head", Vector3(-2.0 * feint, 3.0 * sin(t * 4.1), -2.0 * sway) * gain)
		_rotate("upperarm_l", Vector3(1.0 * sway, 1.5 * feint, -2.5 * sway) * gain)
		_rotate("upperarm_r", Vector3(-1.8 * sway, -1.0 * feint, -2.0 * sway) * gain)


func restore_base(skeleton: Skeleton3D) -> void:
	# Called before the next seek, also on transition away from IDLE/SWAP. Frozen frames never call it.
	if skeleton != _skeleton:
		_base_poses.clear()
		return
	for bone: int in _base_poses:
		var pose: Transform3D = _base_poses[bone]
		skeleton.set_bone_pose_position(bone, pose.origin)
		skeleton.set_bone_pose_rotation(bone, pose.basis.orthonormalized().get_rotation_quaternion())
		skeleton.set_bone_pose_scale(bone, pose.basis.get_scale())
	_base_poses.clear()


func _rotate(name: String, degrees: Vector3) -> void:
	var bone: int = _bones[name]
	if bone < 0:
		return
	var offset: Quaternion = Quaternion.from_euler(degrees * (PI / 180.0))
	_skeleton.set_bone_pose_rotation(bone, (_skeleton.get_bone_pose_rotation(bone) * offset).normalized())


func _lift_foot(side: String, fraction: float) -> void:
	var hip: int = _bones["thigh_" + side]
	var knee: int = _bones["calf_" + side]
	var foot: int = _bones["foot_" + side]
	if mini(hip, mini(knee, foot)) < 0 or fraction <= 0.000001:
		return
	var a: Vector3 = _skeleton.get_bone_global_pose(hip).origin
	var b: Vector3 = _skeleton.get_bone_global_pose(knee).origin
	var c: Vector3 = _skeleton.get_bone_global_pose(foot).origin
	var foot_rotation: Quaternion = _global_rotation(foot)
	var upper: float = a.distance_to(b)
	var lower: float = b.distance_to(c)
	if minf(upper, lower) < 0.00001:
		return
	var up: Vector3 = (_skeleton.global_basis.inverse() * Vector3.UP).normalized()
	var target: Vector3 = c + up * ((upper + lower) * fraction)
	var distance: float = a.distance_to(target)
	# Do not clamp into a sideways slip if the authored chain cannot reach this target.
	if distance >= upper + lower - 0.00001 or distance <= absf(upper - lower) + 0.00001:
		return
	var axis: Vector3 = (target - a).normalized()
	var bend: Vector3 = (b - a) - axis * (b - a).dot(axis)
	if bend.length_squared() < 0.00000001:
		return  # A straight/ambiguous knee needs an authored pole; keep its source pose.
	var along: float = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var height: float = sqrt(maxf(0.0, upper * upper - along * along))
	var desired_knee: Vector3 = a + axis * along + bend.normalized() * height
	_set_global_rotation(hip, Quaternion((b - a).normalized(), (desired_knee - a).normalized()) * _global_rotation(hip))
	var moved_knee: Vector3 = _skeleton.get_bone_global_pose(knee).origin
	var moved_foot: Vector3 = _skeleton.get_bone_global_pose(foot).origin
	_set_global_rotation(knee, Quaternion((moved_foot - moved_knee).normalized(), (target - moved_knee).normalized()) * _global_rotation(knee))
	_set_global_rotation(foot, foot_rotation)


func _global_rotation(bone: int) -> Quaternion:
	return _skeleton.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()


func _guard_arm(side: String, fighter: Fighter, shift: float, breath: float) -> void:
	var shoulder: int = _bones["upperarm_" + side]
	var elbow: int = _bones["lowerarm_" + side]
	var hand: int = _bones["hand_" + side]
	if mini(shoulder, mini(elbow, hand)) < 0:
		return
	var a: Vector3 = _skeleton.get_bone_global_pose(shoulder).origin
	var b: Vector3 = _skeleton.get_bone_global_pose(elbow).origin
	var c: Vector3 = _skeleton.get_bone_global_pose(hand).origin
	var upper: float = a.distance_to(b)
	var lower: float = b.distance_to(c)
	var length: float = upper + lower
	if _gain <= 0.0:
		return
	var source: Array[Quaternion] = [_skeleton.get_bone_pose_rotation(shoulder), _skeleton.get_bone_pose_rotation(elbow), _skeleton.get_bone_pose_rotation(hand)]
	if minf(upper, lower) < 0.00001:
		return
	var up: Vector3 = (_skeleton.global_basis.inverse() * Vector3.UP).normalized()
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0.0, 0.0)
	var forward: Vector3 = (_skeleton.global_basis.inverse() * facing).normalized()
	var right: Vector3 = forward.cross(up).normalized()
	var sign_side: float = -1.0 if side == "l" else 1.0
	# Collected chest-level readiness, not both hands above the head; elbows stay tucked.
	# Proportional targets work on the measured source chain; this is an idle guard, not hitbox IK.
	var reach: float = (0.50 if side == "l" else 0.37) + sign_side * 0.035 * shift
	var rise: float = (-0.30 if side == "l" else -0.25) + 0.015 * breath
	var target: Vector3 = a + length * (forward * reach + up * rise + right * sign_side * 0.035)
	var axis: Vector3 = (target - a).normalized()
	var distance: float = a.distance_to(target)
	if distance >= length - 0.00001 or distance <= absf(upper - lower) + 0.00001:
		return
	var pole: Vector3 = -up + right * sign_side * 0.25
	var bend: Vector3 = (pole - axis * pole.dot(axis)).normalized()
	var along: float = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var desired_elbow: Vector3 = a + axis * along + bend * sqrt(maxf(0.0, upper * upper - along * along))
	_set_global_rotation(shoulder, Quaternion((b - a).normalized(), (desired_elbow - a).normalized()) * _global_rotation(shoulder))
	var moved_elbow: Vector3 = _skeleton.get_bone_global_pose(elbow).origin
	var moved_hand: Vector3 = _skeleton.get_bone_global_pose(hand).origin
	_set_global_rotation(elbow, Quaternion((moved_hand - moved_elbow).normalized(), (target - moved_elbow).normalized()) * _global_rotation(elbow))
	# Neutral anatomical wrist relative to the forearm, rather than the source sword-grip bend.
	_skeleton.set_bone_pose_rotation(hand, _skeleton.get_bone_rest(hand).basis.orthonormalized().get_rotation_quaternion())
	if _gain < 1.0:
		# Step 2 of plan 2026-10-09: the guard gains its weight over RAMP_SECONDS (local rotations, parents first).
		var bones: Array[int] = [shoulder, elbow, hand]
		for index: int in bones.size():
			_skeleton.set_bone_pose_rotation(bones[index], source[index].slerp(_skeleton.get_bone_pose_rotation(bones[index]), _gain).normalized())


func _collect_posture(fighter: Fighter) -> void:
	var up: Vector3 = (_skeleton.global_basis.inverse() * Vector3.UP).normalized()
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0.0, 0.0)
	var forward: Vector3 = (_skeleton.global_basis.inverse() * facing).normalized()
	var right: Vector3 = forward.cross(up).normalized()
	# Provisional 6-degree thorax opening leaves the authored pelvis and support untouched.
	var chest: int = _bones["spine_03"]
	_set_global_rotation(chest, Quaternion(right, deg_to_rad(6.0) * _gain) * _global_rotation(chest))
	var head: int = _bones["Head"]
	var rest: Quaternion = _skeleton.get_bone_global_rest(head).basis.orthonormalized().get_rotation_quaternion()
	# UAL faces +Z in skeleton space (SkeletalRig.MODEL_YAW). Correct pitch only, keeping its yaw.
	var gaze: Vector3 = (_global_rotation(head) * rest.inverse()) * Vector3.BACK
	var pitch: float = asin(clampf(gaze.dot(up), -1.0, 1.0))
	# Choko retarget adds a measured ~15-degree downward gaze offset; +4 donor gives ~-11 hero.
	var correction: float = clampf(deg_to_rad(4.0) - pitch, deg_to_rad(-30.0), deg_to_rad(30.0)) * _gain
	var neck: int = _bones["neck_01"]
	_set_global_rotation(neck, Quaternion(right, correction * 0.4) * _global_rotation(neck))
	_set_global_rotation(head, Quaternion(right, correction * 0.6) * _global_rotation(head))


func _set_global_rotation(bone: int, rotation: Quaternion) -> void:
	var parent: int = _skeleton.get_bone_parent(bone)
	var parent_rotation: Quaternion = Quaternion.IDENTITY if parent < 0 else _global_rotation(parent)
	_skeleton.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotation).normalized())
