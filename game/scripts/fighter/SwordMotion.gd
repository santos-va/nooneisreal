class_name SwordMotion
extends RefCounted
## Presentation-only sword drawings and a two-hand transfer; gameplay owns its contact frame.
## Amplitudes are provisional art tuning, not extra attack reach or hitboxes.
# PLACEHOLDER anatomical presentation bounds, verified on the actual Choko mesh.
const READY_FOREARM_ROLL: float = 120.0
const READY_WRIST_SWING: float = 25.0
const READY_REACH_ADJUST: float = 0.24
const ATTACK_TOTAL_SWING: float = 50.0
const ATTACK_FOREARM_ROLL: float = 45.0
const ATTACK_WRIST_SWING: float = 45.0
const ATTACK_CORE_CLEARANCE: float = 0.160
const VARIANTS: Array[String] = ["cut", "thrust", "rising", "cleave", "lowcut", "aircut"]

static func supports(anim: String) -> bool:
	var fields := anim.split("_")
	return fields.size() == 4 and fields[0] == "sword" and fields[1] in ["left", "right"] and fields[2] == "hand" and fields[3] in VARIANTS

static func apply(rig: RigAnimator, anim: String, ext: float, phase: float = -1.0) -> void:
	LimbMotion.apply_guard(rig, "choko")
	var guard_pose: Dictionary = rig.target_pose.duplicate()
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
	elif variant == "cleave":
		# Reverse-route finisher: committed downward cut rather than the rising cut.
		swing = -0.25 * mirror
		shoulder = 0.8
		elbow = 0.15
		twist = 0.85
	elif variant == "lowcut":
		rig._crouch()
		shoulder = 0.95
	elif variant == "aircut":
		shoulder = 1.95
		rig._pose_set("thigh_" + other, Vector3(0, 0, 0.55))
		rig._pose_set("shin_" + other, Vector3(0, 0, -1.0))
	rig._pose_set("upper_arm_" + side, Vector3(swing * ext, 0, lerpf(2.65 if variant == "cleave" else 0.65, shoulder, ext)))
	rig._pose_set("forearm_" + side, Vector3(0, 0, lerpf(1.25, elbow, ext)))
	rig._pose_set("upper_arm_" + other, Vector3(0, 0, 0.75))
	rig._pose_set("forearm_" + other, Vector3(0, 0, 1.4))
	rig._pose_set("pelvis", Vector3(0, mirror * twist * 0.3 * ext, 0))
	rig._pose_set("torso", Vector3(0, mirror * twist * 0.7 * ext, -0.05 * ext))

	# Braced lower body and a protecting off-hand make the blade feel carried by a fighter.
	if variant not in ["lowcut", "aircut"]:
		rig._pose_set("thigh_" + other, Vector3(0, 0, 0.18 + 0.22 * maxf(ext, 0.0)))
		rig._pose_set("shin_" + other, Vector3(0, 0, -0.3 - 0.25 * maxf(ext, 0.0)))
		rig.target_root_offset.y = -0.045 * maxf(ext, 0.0)
	rig._pose_set("head", Vector3(0, -mirror * twist * 0.3 * ext, -0.08))
	if phase >= 2.0:
		var settle: float = smoothstep(0.12, 1.0, phase - 2.0)
		for part: String in guard_pose:
			rig.target_pose[part] = (rig.target_pose[part] as Vector3).lerp(guard_pose[part], settle)
		rig.target_root_offset *= 1.0 - settle

static func transfer_weight(progress: float) -> float:
	return smoothstep(0.0, 0.35, progress) * (1.0 - smoothstep(0.65, 1.0, progress))

static func apply_transfer(rig: Skeleton3D, fighter: Fighter) -> void:
	if fighter.state != Fighter.State.SWAP:
		if fighter.state == Fighter.State.ATTACK and fighter.sword_drawn and fighter.current_move != null and (supports(fighter.current_move.anim) or fighter.current_move.anim_clip.begins_with("Sword_")):
			_clear_body_grip(rig, fighter, "Right" if fighter.attack_sword_hand == "right" else "Left")
		if fighter.sword_drawn and fighter.state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK, Fighter.State.JUMP, Fighter.State.DASH]:
			_ready_grip(rig, fighter, "Right" if fighter.sword_hand == "right" else "Left")
		return
	if fighter.sword_swap_drawing:
		_ready_grip(rig, fighter, "Right" if fighter.sword_swap_to == "right" else "Left")
		apply_draw(rig, fighter)
		return
	_ready_grip(rig, fighter, "Left")
	_ready_grip(rig, fighter, "Right")
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
	# (+weapon Y = blade; the palm-side calibration is owned by the weapon) to derive both wrist frames.
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

## Correct the actual hand, never a detached prop. The authored wrist/contact point
## stays fixed. A short deterministic projection keeps the reversed blade outside
## torso/head; split its least-direction change between axial forearm twist and wrist.
## Bounds are PLACEHOLDER art limits, not permission to stretch an arm or hitbox.
static func _clear_body_grip(rig: Skeleton3D, fighter: Fighter, side: String) -> void:
	var forearm: int = rig.find_bone(side + "ForeArm")
	var hand: int = rig.find_bone(side + "Hand")
	var world: Basis = rig.global_basis.orthonormalized()
	var wrist: Vector3 = rig.global_transform * rig.get_bone_global_pose(hand).origin
	var elbow: Vector3 = rig.global_transform * rig.get_bone_global_pose(forearm).origin
	var original: Quaternion = (world * rig.get_bone_global_pose(hand).basis.orthonormalized()).get_rotation_quaternion()
	var rotation: Quaternion = original
	var weapon = fighter.skeletal.sword
	var calibration: Basis = weapon.grip_calibration(side.to_lower())
	var offset: Vector3 = weapon.grip_offset(side.to_lower())
	var hips: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone("Hips")).origin
	var chest: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone("Spine")).origin
	var head: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone("Head")).origin + Vector3.UP * 0.10
	var obstacles: Array = [[hips, chest, ATTACK_CORE_CLEARANCE], [head, head, ATTACK_CORE_CLEARANCE]]
	for leg: String in ["Left", "Right"]:
		var thigh: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone(leg + "UpLeg")).origin
		var knee: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone(leg + "Leg")).origin
		var ankle: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone(leg + "Foot")).origin
		obstacles.append([thigh, knee, 0.125])
		obstacles.append([knee, ankle, 0.105])
	var profile: PackedVector3Array = weapon.blade_profile_edges[posmod(fighter.attack_sword_form, 3)]
	for iteration: int in 8:
		var basis := Basis(rotation)
		var grip: Vector3 = wrist + basis * offset
		var direction: Vector3 = basis * calibration.y
		var nearest: float = INF
		var point: Vector3 = grip
		var core: Vector3 = hips
		# The actual tapered facets leave space near the hilt which a constant-width
		# rectangle incorrectly consumes. Pair zero keeps the stronger centerline envelope.
		for edge: int in profile.size() / 2:
			var start: Vector3 = grip + basis * calibration * profile[edge * 2]
			var end: Vector3 = grip + basis * calibration * profile[edge * 2 + 1]
			for obstacle: Array in obstacles:
				var pair: PackedVector3Array = Geometry3D.get_closest_points_between_segments(start, end, obstacle[0], obstacle[1])
				var distance: float = pair[0].distance_to(pair[1]) - float(obstacle[2]) + (0.0 if edge == 0 else 0.015)
				if distance < nearest:
					nearest = distance
					point = pair[0]
					core = pair[1]
		if nearest >= 0.0:
			break
		var away: Vector3 = (point - core).normalized()
		var axis: Vector3 = (point - wrist).normalized().cross(away).normalized()
		if axis.length_squared() < 0.5:
			break
		var angle: float = atan2(0.002 - nearest, point.distance_to(wrist)) * 1.1
		rotation = (Quaternion(axis, angle) * rotation).normalized()
		var correction: Quaternion = rotation * original.inverse()
		if correction.get_angle() > deg_to_rad(ATTACK_TOTAL_SWING):
			rotation = original.slerp(rotation, deg_to_rad(ATTACK_TOTAL_SWING) / correction.get_angle())
	var correction: Quaternion = (rotation * original.inverse()).normalized()
	if correction.w < 0.0:
		correction = -correction
	var arm_axis: Vector3 = (wrist - elbow).normalized()
	var projected: Vector3 = arm_axis * Vector3(correction.x, correction.y, correction.z).dot(arm_axis)
	var twist := Quaternion(projected.x, projected.y, projected.z, correction.w).normalized()
	if twist.get_angle() > deg_to_rad(ATTACK_FOREARM_ROLL):
		twist = Quaternion.IDENTITY.slerp(twist, deg_to_rad(ATTACK_FOREARM_ROLL) / twist.get_angle())
	var residual: Quaternion = correction * twist.inverse()
	if residual.get_angle() > deg_to_rad(ATTACK_WRIST_SWING):
		residual = Quaternion.IDENTITY.slerp(residual, deg_to_rad(ATTACK_WRIST_SWING) / residual.get_angle())
	_set_global(rig, forearm, (world.inverse() * Basis(twist) * world).get_rotation_quaternion() * _rotation(rig, forearm))
	_set_global(rig, hand, (world.inverse() * Basis(residual * twist * original)).get_rotation_quaternion())

## Collected idle resets donor wrists to rest. With a corrected forward grip,
## share its safe readiness between forearm roll and a bounded wrist swing.
## Axial roll preserves the elbow/wrist positions and every segment length.
static func _ready_grip(rig: Skeleton3D, fighter: Fighter, side: String) -> void:
	var forearm: int = rig.find_bone(side + "ForeArm")
	var hand: int = rig.find_bone(side + "Hand")
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var shoulder: int = rig.find_bone(side + "Arm")
	var wrist: Vector3 = rig.global_transform * rig.get_bone_global_pose(hand).origin
	var shoulder_world: Vector3 = rig.global_transform * rig.get_bone_global_pose(shoulder).origin
	var outside: Vector3 = facing.cross(Vector3.UP) * (-1.0 if side == "Left" else 1.0)
	var target_world: Vector3 = shoulder_world + facing * 0.27 - Vector3.UP * 0.18 + outside * 0.055
	target_world = wrist + (target_world - wrist).limit_length(READY_REACH_ADJUST)
	var pole: Vector3 = rig.global_basis.inverse() * (-Vector3.UP + outside * 0.5)
	_solve_arm(rig, side, rig.global_transform.affine_inverse() * target_world, pole)
	var axis: Vector3 = (rig.get_bone_global_pose(hand).origin - rig.get_bone_global_pose(forearm).origin).normalized()
	var calibration: Basis = fighter.skeletal.sword.grip_calibration(side.to_lower())
	var current: Vector3 = rig.get_bone_global_pose(hand).basis.orthonormalized() * calibration.y
	var desired: Vector3 = (rig.global_basis.orthonormalized().inverse() * (facing * 0.8 + Vector3.UP * 0.6)).normalized()
	var from: Vector3 = current.slide(axis).normalized()
	var to: Vector3 = desired.slide(axis).normalized()
	if from.length_squared() > 0.5 and to.length_squared() > 0.5:
		var roll: float = clampf(from.signed_angle_to(to, axis), -deg_to_rad(READY_FOREARM_ROLL), deg_to_rad(READY_FOREARM_ROLL))
		_set_global(rig, forearm, Quaternion(axis, roll) * _rotation(rig, forearm))
	current = (rig.get_bone_global_pose(hand).basis.orthonormalized() * calibration.y).normalized()
	var swing: Quaternion = Quaternion(current, desired)
	var weight: float = minf(1.0, deg_to_rad(READY_WRIST_SWING) / maxf(swing.get_angle(), 0.000001))
	_set_global(rig, hand, Quaternion.IDENTITY.slerp(swing, weight) * _rotation(rig, hand))

## Reach over the shoulder toward the same back mount before bringing the blade forward.
## PLACEHOLDER art trajectory; SWAP contact/duration remain Fighter's explicit contract.
static func apply_draw(rig: Skeleton3D, fighter: Fighter) -> void:
	var side: String = "Right" if fighter.sword_swap_to == "right" else "Left"
	var hand: int = rig.find_bone(side + "Hand")
	var shoulder: int = rig.find_bone(side + "Arm")
	if mini(hand, shoulder) < 0:
		return
	var t: float = fighter.sword_swap_progress()
	var up: Vector3 = (rig.global_basis.inverse() * Vector3.UP).normalized()
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var forward: Vector3 = (rig.global_basis.inverse() * facing).normalized()
	var socket: Transform3D = fighter.skeletal.sword.back_grip()
	var wrist_basis: Basis = socket.basis * fighter.skeletal.sword.grip_calibration(side.to_lower()).inverse()
	var wrist_world: Vector3 = socket.origin - wrist_basis * fighter.skeletal.sword.grip_offset(side.to_lower())
	var reach: Vector3 = rig.global_transform.affine_inverse() * wrist_world
	var weight: float = smoothstep(0.0, 0.32, t) * (1.0 - smoothstep(0.48, 1.0, t))
	var original: Quaternion = _rotation(rig, hand)
	var desired: Quaternion = (rig.global_basis.orthonormalized().inverse() * wrist_basis).get_rotation_quaternion()
	var target: Vector3 = rig.get_bone_global_pose(hand).origin.lerp(reach, weight)
	# Lift the real arm around the shoulder on release; straight interpolation
	# would sweep the long blade through the torso before the ready stance.
	var release: float = clampf((t - 0.48) / 0.52, 0.0, 1.0)
	var outward: Vector3 = -facing.cross(Vector3.UP)
	var arc: Vector3 = (outward * 0.10 + Vector3.UP * 0.08) * sin(release * PI)
	target += rig.global_basis.inverse() * arc
	_solve_arm(rig, side, target, -up - forward)
	_set_global(rig, hand, original.slerp(desired, weight))


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
