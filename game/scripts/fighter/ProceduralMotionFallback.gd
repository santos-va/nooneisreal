class_name ProceduralMotionFallback
extends RefCounted
## Bridge the existing semantic capsule drawings onto UAL, only for moves without authored clips.
## This does not infer new attacks from unrelated library names or change combat data.
const LimbMotion = preload("res://scripts/fighter/LimbMotion.gd")
const MOVES := {
	"choko": ["crouch_light", "record", "time_stop"],
	"skea": ["low_kick", "shadow_veil", "cursed_grimoire", "cursed_grimoire_veil"],
}
## UAL bone -> [capsule pivot, UAL direction child]. Parents are visited in skeleton order.
const PARTS := {
	"pelvis": ["pelvis", "spine_01"],
	"spine_01": ["torso", "spine_02"],
	"spine_02": ["torso", "spine_03"],
	"spine_03": ["torso", "neck_01"],
	"neck_01": ["head", "Head"],
	"upperarm_l": ["upper_arm_l", "lowerarm_l"],
	"lowerarm_l": ["forearm_l", "hand_l"],
	"upperarm_r": ["upper_arm_r", "lowerarm_r"],
	"lowerarm_r": ["forearm_r", "hand_r"],
	"thigh_l": ["thigh_l", "calf_l"], "calf_l": ["shin_l", "foot_l"],
	"thigh_r": ["thigh_r", "calf_r"], "calf_r": ["shin_r", "foot_r"],
}

static func supports(character_id: String, move: MoveData) -> bool:
	return move != null and move.anim_clip.is_empty() and (move.id in MOVES.get(character_id, []) or LimbMotion.supports(move.anim))


static func apply(skeleton: Skeleton3D, animator: RigAnimator, upper_body_only: bool = false) -> void:
	# Capsule pivots already contain the authored stepped phase, root offset, spin and reaction.
	# Convert full rotations, rather than only aiming a bone, to preserve the pivot's twist.
	if not upper_body_only:
		skeleton.reset_bone_poses()
	var conversion: Quaternion = (skeleton.global_basis.orthonormalized().inverse() * animator.global_basis.orthonormalized()).get_rotation_quaternion()
	for i in skeleton.get_bone_count():
		var name: String = skeleton.get_bone_name(i)
		if not PARTS.has(name):
			continue
		var part: String = PARTS[name][0]
		if upper_body_only and part in ["pelvis", "thigh_l", "thigh_r", "shin_l", "shin_r"]:
			continue
		var child: int = skeleton.find_bone(PARTS[name][1])
		var rest: Transform3D = skeleton.get_bone_global_rest(i)
		var direction: Vector3 = (skeleton.get_bone_global_rest(child).origin - rest.origin).normalized()
		var axis: Vector3 = Vector3.UP if part in ["pelvis", "torso", "head"] else Vector3.DOWN
		var alignment := Quaternion(direction, conversion * axis)
		var pivot: Node3D = animator.parts[part]["pivot"]
		var rotation: Quaternion = (animator.global_basis.orthonormalized().inverse() * pivot.global_basis.orthonormalized()).get_rotation_quaternion()
		var desired: Quaternion = conversion * rotation * conversion.inverse() * alignment * rest.basis.orthonormalized().get_rotation_quaternion()
		var parent: int = skeleton.get_bone_parent(i)
		var parent_rotation := Quaternion.IDENTITY if parent < 0 else skeleton.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(i, (parent_rotation.inverse() * desired).normalized())
	if upper_body_only:
		return
	# Only the authored vertical offset; no horizontal root motion or gameplay writes.
	var pelvis: int = skeleton.find_bone("pelvis")
	var pos: Vector3 = skeleton.get_bone_rest(pelvis).origin
	# Capsule neutral pelvis height is 0.95 m (RigAnimator.setup).
	# UAL's root parent is rotated: skeleton-space UP is not pelvis-parent local Y.
	# Convert the displacement before adding it to a local bone pose, or a crouch floats
	# and moves sideways instead of lowering the hips.
	var offset: Vector3 = Vector3.UP * animator.root_offset.y * skeleton.get_bone_global_rest(pelvis).origin.y / 0.95
	var pelvis_parent: int = skeleton.get_bone_parent(pelvis)
	if pelvis_parent >= 0:
		offset = skeleton.get_bone_global_pose(pelvis_parent).basis.inverse() * offset
	skeleton.set_bone_pose_position(pelvis, pos + offset)
