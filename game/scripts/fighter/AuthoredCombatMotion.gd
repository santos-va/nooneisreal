class_name AuthoredCombatMotion
extends RefCounted
## Existing CC0 UAL clips retargeted through SkeletalRig. Source seconds are measured
## on the imported 60 Hz donor, not combat frame data. See 2026-10-05-Authored-Combat.
## Low, turning and descending variants are documented composites of these sources,
## never advertised as additional library clips or gameplay root motion.
const SOURCES: Dictionary = {
	"jab": ["Punch_Jab", "", "left", 0.200, 0.250],
	"cross": ["Punch_Cross", "", "right", 0.300, 0.367],
	"bodyhook": ["Melee_Hook", "Melee_Hook_Rec", "right", 0.267, 0.467],
	"uppercut": ["Melee_Uppercut", "", "left", 0.267, 0.333],
	"frontkick": ["Kick", "", "right", 0.517, 0.583],
	"roundhouse": ["Kick", "", "right", 0.517, 0.583],
	"airhand": ["Punch_Cross", "", "right", 0.300, 0.367],
	"airkick": ["Kick", "", "right", 0.517, 0.583],
	"knee": ["Melee_Knee", "", "right", 0.300, 0.450],
	"cut": ["Sword_Light_A", "Sword_Light_A_Rec", "right", 0.233, 0.367],
	"thrust": ["Sword_Light_B", "Sword_Light_B_Rec", "right", 0.233, 0.433],
	"rising": ["Sword_UpperCut", "", "right", 0.200, 0.267],
	"cleave": ["Sword_Heavy_D", "", "right", 0.600, 0.700],
	"aircut": ["Sword_Aerial_A", "Sword_Aerial_A_Rec", "right", 0.233, 0.400],
	"lowhand": ["Punch_Jab", "", "left", 0.200, 0.250],
	"lowkick": ["Kick", "", "right", 0.517, 0.583],
	"lowcut": ["Sword_Regular_A", "Sword_Regular_A_Rec", "right", 0.233, 0.433],
	"spin": ["Kick", "", "right", 0.517, 0.583],
	"hookspin": ["Kick", "", "right", 0.517, 0.583],
	"hammer": ["OverhandThrow", "", "right", 0.383, 0.393],
}
var _base: Array[Transform3D] = []
var _crouch: Dictionary = {}
var _hero_contact_move: MoveData
var _hero_contact_frame: int = -1
var _hero_plants: Dictionary = {}

func setup(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	player.play("Crouch_Idle")
	skeleton.reset_bone_poses()
	player.seek(0.0, true)
	for name: String in ["pelvis", "thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]:
		var bone: int = skeleton.find_bone(name)
		_crouch[bone] = skeleton.get_bone_pose(bone)
	player.stop()
	skeleton.reset_bone_poses()


static func resolve(move: MoveData, character_id: String) -> Dictionary:
	if move == null or not move.anim_clip.is_empty():
		return {}
	var fields: PackedStringArray = move.anim.split("_")
	if fields.size() != 4 or fields[0] not in ["limb", "sword"] or fields[1] not in ["left", "right"]:
		return {}
	var variant: String = fields[3]
	if variant == "airkick" and character_id == "skea":
		variant = "knee"
	if not SOURCES.has(variant):
		return {}
	var source: Array = SOURCES[variant]
	return {"clip": source[0], "recovery": source[1], "source_side": source[2],
		"contact": source[3], "follow_through": source[4], "side": fields[1],
		"limb": fields[2], "variant": fields[3], "mirror": fields[1] != source[2]}


## The first active frame is the measured source contact. Active frames show the
## follow-through; recovery plays the remaining source, instead of stretching a held hit.
static func clip_time(move: MoveData, frame: int, source: Dictionary, length: float) -> float:
	var window: int = move.startup + move.active
	if frame < move.startup:
		return float(source.contact) * clampf(float(frame) / maxi(move.startup, 1), 0.0, 1.0)
	if not String(source.recovery).is_empty() and frame >= window:
		return length * clampf(float(frame - window) / maxi(move.recovery, 1), 0.0, 1.0)
	var contact: float = minf(float(source.contact), length)
	var follow: float = minf(float(source.follow_through), length)
	if frame < window:
		return lerpf(contact, follow, float(frame - move.startup) / maxi(move.active, 1))
	return lerpf(follow, length, clampf(float(frame - window) / maxi(move.recovery, 1), 0.0, 1.0))


func restore(skeleton: Skeleton3D) -> void:
	for bone: int in _base.size():
		_set_pose(skeleton, bone, _base[bone])
	_base.clear()


func apply(skeleton: Skeleton3D, source: Dictionary, fighter: Fighter) -> void:
	if source.is_empty():
		return
	for bone: int in skeleton.get_bone_count():
		_base.append(skeleton.get_bone_pose(bone))
	# Mirror the complete donor including its support leg, spine, hands and fingers.
	# Reflection is in skeleton coordinates, independent of the fighter's world yaw.
	if source.mirror:
		var normal: Vector3 = (skeleton.global_basis.orthonormalized().inverse() * skeleton.get_parent().global_basis.orthonormalized() * Vector3.RIGHT).normalized()
		var reflection := Basis(Vector3.RIGHT - 2.0 * normal * normal.x, Vector3.UP - 2.0 * normal * normal.y, Vector3.BACK - 2.0 * normal * normal.z)
		var rotations: Array[Quaternion] = []
		for bone: int in skeleton.get_bone_count():
			var name: String = skeleton.get_bone_name(bone)
			var other: String = name.trim_suffix("_l") + "_r" if name.ends_with("_l") else (name.trim_suffix("_r") + "_l" if name.ends_with("_r") else name)
			var donor: int = skeleton.find_bone(other)
			var delta: Basis = skeleton.get_bone_global_pose(donor).basis.orthonormalized() * skeleton.get_bone_global_rest(donor).basis.orthonormalized().inverse()
			rotations.append((reflection * delta * reflection * skeleton.get_bone_global_rest(bone).basis.orthonormalized()).get_rotation_quaternion())
		for bone: int in skeleton.get_bone_count():
			var parent: int = skeleton.get_bone_parent(bone)
			var parent_rotation: Quaternion = Quaternion.IDENTITY if parent < 0 else rotations[parent]
			skeleton.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotations[bone]).normalized())
	# The imported attacks contain a travelling hip track. Keep its vertical weight
	# transfer, but remove horizontal root travel: Fighter alone owns ground displacement.
	var hips: int = skeleton.find_bone("pelvis")
	var rest: Vector3 = skeleton.get_bone_global_rest(hips).origin
	var current: Vector3 = skeleton.get_bone_global_pose(hips).origin
	var world_up: Vector3 = (skeleton.global_basis.inverse() * Vector3.UP).normalized()
	var target: Vector3 = rest + world_up * (current - rest).dot(world_up)
	var parent: int = skeleton.get_bone_parent(hips)
	var local: Vector3 = target if parent < 0 else skeleton.get_bone_global_pose(parent).affine_inverse() * target
	skeleton.set_bone_pose_position(hips, local)
	_apply_variant(skeleton, source, fighter)


func _apply_variant(skeleton: Skeleton3D, source: Dictionary, fighter: Fighter) -> void:
	var move: MoveData = fighter.current_move
	var frame: int = fighter.move_frame
	var side: String = "l" if source.side == "left" else "r"
	if source.variant in ["spin", "hookspin"]:
		# The UAL kick supplies every joint; an additional full root turn preserves the
		# existing spinning technique. It finishes before contact and never unwinds.
		var hips: int = skeleton.find_bone("pelvis")
		var up: Vector3 = (skeleton.global_basis.inverse() * Vector3.UP).normalized()
		var turn: float = TAU * smoothstep(0.0, float(maxi(move.startup, 1)), float(frame))
		_set_global_rotation(skeleton, hips, Quaternion(up, turn * (1.0 if source.side == "left" else -1.0)) * _global_rotation(skeleton, hips))
	if source.variant not in ["lowhand", "lowkick", "lowcut"]:
		return
	# Low variants keep the source arc, but use an authored crouch/support stance.
	# The striking endpoint is lowered analytically; chain lengths are never scaled.
	var foot: bool = source.limb == "leg"
	var end: int = skeleton.find_bone(("foot_" if foot else "hand_") + side)
	var source_target: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(end).origin
	var source_rotation: Quaternion = _global_rotation(skeleton, end)
	for bone: int in _crouch:
		_set_pose(skeleton, bone, _crouch[bone])
	var weight: float = smoothstep(0.0, float(maxi(move.startup, 1)), float(frame))
	if frame >= move.startup + move.active:
		weight = 1.0 - smoothstep(0.0, float(maxi(move.recovery, 1)), float(frame - move.startup - move.active))
	if source.variant == "lowhand":
		# Carry the short hero arm forward with a small source-space weight transfer.
		# Solve both support legs back to their sampled crouch contacts; do not drag feet
		# or stretch the arm to compensate for the donor/hero proportion difference.
		var contacts: Dictionary = {}
		for leg: String in ["l", "r"]:
			contacts[leg] = skeleton.get_bone_global_pose(skeleton.find_bone("foot_" + leg)).origin
		var hips: int = skeleton.find_bone("pelvis")
		var forward: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0.0, 0.0)
		# PLACEHOLDER art weight shift; Fighter position and hitboxes are untouched.
		var shifted: Vector3 = skeleton.get_bone_global_pose(hips).origin + skeleton.global_basis.inverse() * (forward * 0.18 * weight)
		var parent: int = skeleton.get_bone_parent(hips)
		skeleton.set_bone_pose_position(hips, skeleton.get_bone_global_pose(parent).affine_inverse() * shifted)
		for leg: String in contacts:
			_solve_chain(skeleton, skeleton.find_bone("thigh_" + leg), skeleton.find_bone("calf_" + leg), skeleton.find_bone("foot_" + leg), contacts[leg])
	var actual: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(end).origin
	var target: Vector3 = source_target if foot else actual
	if foot:
		target.y = fighter.global_position.y + 0.10 + maxf(0.0, source_target.y - fighter.global_position.y - 0.10) * 0.28
		target = actual.lerp(target, weight)
	else:
		# Crouch replaces the pelvis orientation: keep the original strike's forward
		# reach instead of inheriting the wrist folded beside the crouching knee.
		target = source_target
		target.y = fighter.global_position.y + move.hitbox_offset.y
		target = actual.lerp(target, weight)
	var a: int = skeleton.find_bone(("thigh_" if foot else "upperarm_") + side)
	var b: int = skeleton.find_bone(("calf_" if foot else "lowerarm_") + side)
	_solve_chain(skeleton, a, b, end, skeleton.global_transform.affine_inverse() * target)
	if not foot:
		_set_global_rotation(skeleton, end, source_rotation)


## The final short-armed hero needs a proportion-aware contact solve, not donor-length
## assumptions. Keep the actual hero feet planted while its authored low weight shift plays.
func adjust_hero_contact(hero: Skeleton3D, fighter: Fighter) -> void:
	var source: Dictionary = resolve(fighter.current_move, fighter.data.id) if fighter.state == Fighter.State.ATTACK else {}
	if source.is_empty() or source.variant != "lowhand":
		_hero_plants.clear()
		_hero_contact_move = null
		return
	var move: MoveData = fighter.current_move
	if _hero_contact_move != move or fighter.move_frame < _hero_contact_frame:
		_hero_plants.clear()
		for side: String in ["Left", "Right"]:
			_hero_plants[side] = hero.get_bone_global_pose(hero.find_bone(side + "Foot")).origin
		_hero_contact_move = move
	_hero_contact_frame = fighter.move_frame
	for side: String in _hero_plants:
		_solve_chain(hero, hero.find_bone(side + "UpLeg"), hero.find_bone(side + "Leg"), hero.find_bone(side + "Foot"), _hero_plants[side])
	var side: String = "Left" if source.side == "left" else "Right"
	var hand: int = hero.find_bone(side + "Hand")
	var actual: Vector3 = hero.global_transform * hero.get_bone_global_pose(hand).origin
	var forward: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0.0, 0.0)
	var reach: float = (actual - fighter.global_position).dot(forward)
	var near_edge: float = move.hitbox_offset.x - move.hitbox_size.x * 0.5
	var target: Vector3 = actual + forward * maxf(0.0, near_edge + 0.08 - reach)
	target.y = fighter.global_position.y + move.hitbox_offset.y
	var weight: float = smoothstep(0.0, float(maxi(move.startup, 1)), float(fighter.move_frame))
	if fighter.move_frame >= move.startup + move.active:
		weight = 1.0 - smoothstep(0.0, float(maxi(move.recovery, 1)), float(fighter.move_frame - move.startup - move.active))
	target = actual.lerp(target, weight)
	_solve_chain(hero, hero.find_bone(side + "Arm"), hero.find_bone(side + "ForeArm"), hand, hero.global_transform.affine_inverse() * target)


static func _solve_chain(skeleton: Skeleton3D, a: int, b: int, end: int, target: Vector3) -> void:
	var start: Vector3 = skeleton.get_bone_global_pose(a).origin
	var hinge: Vector3 = skeleton.get_bone_global_pose(b).origin
	var tip: Vector3 = skeleton.get_bone_global_pose(end).origin
	var end_rotation: Quaternion = _global_rotation(skeleton, end)
	var upper: float = start.distance_to(hinge)
	var lower: float = hinge.distance_to(tip)
	var direction: Vector3 = (target - start).normalized()
	var distance: float = clampf(start.distance_to(target), absf(upper - lower) + 0.0001, upper + lower - 0.0001)
	var bend: Vector3 = (hinge - start) - direction * (hinge - start).dot(direction)
	if bend.length_squared() < 0.0000001:
		return
	var along: float = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var knee: Vector3 = start + direction * along + bend.normalized() * sqrt(maxf(0.0, upper * upper - along * along))
	_set_global_rotation(skeleton, a, Quaternion((hinge - start).normalized(), (knee - start).normalized()) * _global_rotation(skeleton, a))
	hinge = skeleton.get_bone_global_pose(b).origin
	tip = skeleton.get_bone_global_pose(end).origin
	_set_global_rotation(skeleton, b, Quaternion((tip - hinge).normalized(), (start + direction * distance - hinge).normalized()) * _global_rotation(skeleton, b))
	_set_global_rotation(skeleton, end, end_rotation)


static func _global_rotation(skeleton: Skeleton3D, bone: int) -> Quaternion:
	return skeleton.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()


static func _set_global_rotation(skeleton: Skeleton3D, bone: int, rotation: Quaternion) -> void:
	var parent: int = skeleton.get_bone_parent(bone)
	var parent_rotation: Quaternion = Quaternion.IDENTITY if parent < 0 else _global_rotation(skeleton, parent)
	skeleton.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotation).normalized())


static func _set_pose(skeleton: Skeleton3D, bone: int, pose: Transform3D) -> void:
	skeleton.set_bone_pose_position(bone, pose.origin)
	skeleton.set_bone_pose_rotation(bone, pose.basis.orthonormalized().get_rotation_quaternion())
	skeleton.set_bone_pose_scale(bone, pose.basis.get_scale())
