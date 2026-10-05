class_name AuthoredLandingMotion
extends RefCounted
## Moving landing keeps authored gait; UAL Jump_Land supplies the compression curve.
## Solve the actual hero legs to this frame's gait ankles, never to a frozen world plant.
const SOURCE_END: float = 0.80
const SAMPLE_COUNT: int = 49
const MAX_DROP: float = 0.10 # PLACEHOLDER metres of presentation-only hip compression.
var _curve: PackedFloat32Array = []
var last_drop: float = 0.0
var last_foot_error: float = 0.0

func setup(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	var hips: int = skeleton.find_bone("pelvis")
	var up: Vector3 = (skeleton.global_basis.inverse() * Vector3.UP).normalized()
	player.play("Jump_Land")
	var first: float = 0.0
	var peak: float = 0.0
	for index: int in SAMPLE_COUNT:
		skeleton.reset_bone_poses()
		player.seek(SOURCE_END * float(index) / float(SAMPLE_COUNT - 1), true)
		var height: float = skeleton.get_bone_global_pose(hips).origin.dot(up)
		if index == 0:
			first = height
		var drop: float = maxf(first - height, 0.0)
		_curve.append(drop)
		peak = maxf(peak, drop)
	for index: int in _curve.size():
		_curve[index] /= maxf(peak, 0.0001)
	player.stop()
	skeleton.reset_bone_poses()

func apply(hero: Skeleton3D, phase: float) -> void:
	last_drop = 0.0
	last_foot_error = 0.0
	if phase < 0.0 or phase >= 1.0 or _curve.is_empty():
		return
	var sample: float = phase * float(SAMPLE_COUNT - 1)
	var index: int = mini(int(sample), SAMPLE_COUNT - 2)
	var curve: float = lerpf(_curve[index], _curve[index + 1], sample - float(index))
	# The sampled recovery may retain a small crouch: finish exactly at the gait pose.
	last_drop = MAX_DROP * curve * (1.0 - smoothstep(0.75, 1.0, phase))
	var targets: Dictionary = {}
	for side: String in ["Left", "Right"]:
		targets[side] = hero.get_bone_global_pose(hero.find_bone(side + "Foot")).origin
	var hips: int = hero.find_bone("Hips")
	var local_drop: Vector3 = hero.global_basis.inverse() * (Vector3.DOWN * last_drop)
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips) + local_drop)
	for side: String in ["Left", "Right"]:
		var end: int = hero.find_bone(side + "Foot")
		AuthoredCombatMotion._solve_chain(hero, hero.find_bone(side + "UpLeg"), hero.find_bone(side + "Leg"), end, targets[side])
		last_foot_error = maxf(last_foot_error, (hero.global_basis * (hero.get_bone_global_pose(end).origin - Vector3(targets[side]))).length())
