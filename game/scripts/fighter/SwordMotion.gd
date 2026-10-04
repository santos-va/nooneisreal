class_name SwordMotion
extends RefCounted
## Presentation-only sword drawings and a two-hand transfer; gameplay owns its contact frame.
## Amplitudes are provisional art tuning, not extra attack reach or hitboxes.
const VARIANTS: Array[String] = ["cut", "thrust", "rising", "lowcut", "aircut"]

static func supports(anim: String) -> bool:
	var fields := anim.split("_")
	return fields.size() == 4 and fields[0] == "sword" and fields[1] in ["left", "right"] and fields[2] == "hand" and fields[3] in VARIANTS

static func apply(rig: RigAnimator, anim: String, ext: float) -> void:
	var fields := anim.split("_")
	var side := "l" if fields[1] == "left" else "r"
	var other := "r" if side == "l" else "l"
	var mirror := 1.0 if side == "l" else -1.0
	var variant: String = fields[3]
	var swing := -0.7 * mirror
	var shoulder := 1.4
	var elbow := 0.55
	var twist := 0.65
	if variant == "thrust":
		swing = 0.0
		shoulder = 1.6
		elbow = 0.10
		twist = 0.30
	elif variant == "rising":
		swing = 0.30 * mirror
		shoulder = 2.15
		elbow = 0.35
		twist = 0.45
	elif variant == "lowcut":
		rig._crouch()
		shoulder = 0.95
	elif variant == "aircut":
		shoulder = 1.95
		rig._pose_set("thigh_" + other, Vector3(0, 0, 0.55))
		rig._pose_set("shin_" + other, Vector3(0, 0, -1.0))
	rig._pose_set("upper_arm_" + side, Vector3(swing * ext, 0, lerpf(0.65, shoulder, ext)))
	rig._pose_set("forearm_" + side, Vector3(0, 0, lerpf(1.25, elbow, ext)))
	rig._pose_set("upper_arm_" + other, Vector3(0, 0, 0.75))
	rig._pose_set("forearm_" + other, Vector3(0, 0, 1.4))
	rig._pose_set("pelvis", Vector3(0, mirror * twist * 0.3 * ext, 0))
	rig._pose_set("torso", Vector3(0, mirror * twist * 0.7 * ext, -0.05 * ext))

static func transfer_weight(progress: float) -> float:
	return smoothstep(0.0, 0.35, progress) * (1.0 - smoothstep(0.65, 1.0, progress))

static func apply_transfer(rig: Skeleton3D, fighter: Fighter) -> void:
	if fighter.state != Fighter.State.SWAP:
		return
	var weight := transfer_weight(fighter.sword_swap_progress())
	var from_side := "Right" if fighter.sword_swap_from == "right" else "Left"
	var source_hand := rig.find_bone(from_side + "Hand")
	var left := rig.find_bone("LeftArm")
	var right := rig.find_bone("RightArm")
	if mini(source_hand, mini(left, right)) < 0:
		return
	var up := (rig.global_basis.inverse() * Vector3.UP).normalized()
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var forward := (rig.global_basis.inverse() * facing).normalized()
	var scale_m := rig.global_basis.get_scale().x
	var shoulder_mid := (rig.get_bone_global_pose(left).origin + rig.get_bone_global_pose(right).origin) * 0.5
	var meeting := shoulder_mid + (-up * 0.08 + forward * 0.18) / maxf(scale_m, 0.0001)
	# Aim the blade into clear space, not through the chest. Invert the grip calibration
	# (+weapon Y = blade, hand grip uses -90 degrees around X) to derive both wrist frames.
	var blade_direction := (facing * 0.8 + Vector3.UP * 0.6).normalized()
	var across := facing.cross(Vector3.UP).normalized()
	var weapon_basis := Basis(across, blade_direction, across.cross(blade_direction))
	for side: String in ["Left", "Right"]:
		var hand := rig.find_bone(side + "Hand")
		var hand_basis: Basis = weapon_basis * fighter.skeletal.sword.grip_calibration(side.to_lower()).inverse()
		var shared_rotation := (rig.global_basis.orthonormalized().inverse() * hand_basis).get_rotation_quaternion()
		var start := rig.get_bone_global_pose(hand).origin
		# Fingers meet around one grip; a small fore/aft separation avoids coincident palms.
		var separation := forward * (-0.025 if side == from_side else 0.025) / maxf(scale_m, 0.0001)
		var target := start.lerp(meeting + separation, weight)
		var original := rig.get_bone_global_pose(hand).basis.orthonormalized().get_rotation_quaternion()
		_solve_arm(rig, side, target, -up + forward.cross(up) * (-0.5 if side == "Left" else 0.5))
		_set_global(rig, hand, original.slerp(shared_rotation, weight))

static func _solve_arm(rig: Skeleton3D, side: String, target: Vector3, pole: Vector3) -> void:
	var shoulder := rig.find_bone(side + "Arm")
	var elbow := rig.find_bone(side + "ForeArm")
	var hand := rig.find_bone(side + "Hand")
	var a := rig.get_bone_global_pose(shoulder).origin
	var b := rig.get_bone_global_pose(elbow).origin
	var c := rig.get_bone_global_pose(hand).origin
	var upper := a.distance_to(b)
	var lower := b.distance_to(c)
	var axis := (target - a).normalized()
	var distance := clampf(a.distance_to(target), absf(upper - lower) + 0.001, upper + lower - 0.001)
	target = a + axis * distance
	var along := (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var bend := (pole - axis * pole.dot(axis)).normalized()
	var desired := a + axis * along + bend * sqrt(maxf(0, upper * upper - along * along))
	_set_global(rig, shoulder, Quaternion((b - a).normalized(), (desired - a).normalized()) * _rotation(rig, shoulder))
	b = rig.get_bone_global_pose(elbow).origin
	c = rig.get_bone_global_pose(hand).origin
	_set_global(rig, elbow, Quaternion((c - b).normalized(), (target - b).normalized()) * _rotation(rig, elbow))

static func _rotation(rig: Skeleton3D, bone: int) -> Quaternion:
	return rig.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()

static func _set_global(rig: Skeleton3D, bone: int, rotation: Quaternion) -> void:
	var parent := rig.get_bone_parent(bone)
	var parent_rotation := Quaternion.IDENTITY if parent < 0 else _rotation(rig, parent)
	rig.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotation).normalized())

## Mirror only the upper-body sword drawing, not root motion, legs or hitboxes.
## Preserve unkeyed donor poses for the next seek (imported constant tracks can be absent).
static func restore_mirror(rig: Skeleton3D, saved: Dictionary) -> void:
	for bone: int in saved:
		rig.set_bone_pose_rotation(bone, saved[bone])
	saved.clear()

static func mirror_authored(rig: Skeleton3D, fighter: Fighter) -> Dictionary:
	var saved: Dictionary = {}
	if fighter.data.id != "choko" or fighter.state != Fighter.State.ATTACK or fighter.attack_sword_hand != "left" or fighter.current_move == null or not fighter.current_move.anim_clip.begins_with("Sword_"):
		return saved
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var normal := (rig.global_basis.inverse() * facing.cross(Vector3.UP)).normalized()
	var reflection := Basis(Vector3.RIGHT - 2.0 * normal * normal.x, Vector3.UP - 2.0 * normal * normal.y, Vector3.BACK - 2.0 * normal * normal.z)
	var mapping: Dictionary = {"spine_01": "spine_01", "spine_02": "spine_02", "spine_03": "spine_03", "neck_01": "neck_01", "Head": "Head"}
	for part: String in ["clavicle", "upperarm", "lowerarm", "hand"]:
		mapping[part + "_l"] = part + "_r"
		mapping[part + "_r"] = part + "_l"
	var desired: Dictionary = {}
	for name: String in mapping:
		var target := rig.find_bone(name)
		var source := rig.find_bone(mapping[name])
		if mini(target, source) < 0:
			continue
		saved[target] = rig.get_bone_pose_rotation(target)
		var delta := rig.get_bone_global_pose(source).basis.orthonormalized() * rig.get_bone_global_rest(source).basis.orthonormalized().inverse()
		desired[target] = (reflection * delta * reflection * rig.get_bone_global_rest(target).basis.orthonormalized()).get_rotation_quaternion()
	# Skeleton indices are parents first, unlike the left/right mapping dictionary.
	for bone in rig.get_bone_count():
		if desired.has(bone):
			_set_global(rig, bone, desired[bone])
	return saved
