class_name HeroFootContact
extends RefCounted
## Narrow presentation correction for crouching shoes. Never moves a fighter or its hips.
## Provisional art ceiling, in world metres; larger errors need pose/rig repair, not hidden IK.
const MAX_LIFT: float = 0.25
const CLEARANCE: float = 0.003
var samples: Dictionary = {}
var _skeleton: Skeleton3D

func setup(skeleton: Skeleton3D, mesh: MeshInstance3D) -> void:
	_skeleton = skeleton
	samples.clear()
	if mesh.skin == null:
		return
	for side: String in ["Left", "Right"]:
		samples[side] = []
		var foot: int = skeleton.find_bone(side + "Foot")
		var toe: int = skeleton.find_bone(side + "ToeBase")
		if foot < 0 or toe < 0:
			continue
		for surface: int in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or indices.is_empty():
				continue
			var stride: int = indices.size() / vertices.size()
			for vertex: int in vertices.size():
				var influences: Array = []
				var shoe_weight: float = 0.0
				for j: int in stride:
					var offset: int = vertex * stride + j
					if weights[offset] <= 0.0:
						continue
					var bind: int = indices[offset]
					var bone: int = skeleton.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
					if bone < 0:
						continue
					influences.append([bone, mesh.skin.get_bind_pose(bind) * vertices[vertex], weights[offset]])
					if bone == foot or bone == toe:
						shoe_weight += weights[offset]
				# Include all vertices predominantly skinned to the shoe; no ankle-radius guess.
				if shoe_weight >= 0.5:
					samples[side].append(influences)

func permitted(fighter: Fighter, ragdoll: BoneRagdoll) -> bool:
	if ragdoll != null or fighter.airborne_attack or fighter.velocity.y > 0.01:
		return false
	if absf(fighter.global_position.y - fighter.floor_y()) > 0.025:
		return false
	if fighter.state == Fighter.State.CROUCH:
		return true
	if fighter.state == Fighter.State.GRAPPLE:
		return fighter.grapple != null and fighter.grapple.phase == GrappleHook.Phase.WINDUP
	if fighter.state != Fighter.State.ATTACK or fighter.current_move == null:
		return false
	return (fighter.data.id == "choko" and fighter.current_move.id == "crouch_light") or fighter.current_move.anim in ["limb_left_hand_lowhand", "limb_right_hand_lowhand"]

func apply(fighter: Fighter, ragdoll: BoneRagdoll) -> void:
	if _skeleton == null or not permitted(fighter, ragdoll):
		return
	for side: String in ["Left", "Right"]:
		var lift: float = penetration(side, GameState.water) + CLEARANCE
		if lift <= CLEARANCE or lift > MAX_LIFT:
			continue  # Preserve lifted feet and expose errors beyond this bounded correction.
		_solve(side, lift)

func penetration(side: String, field: WaveField) -> float:
	var result: float = -INF
	var transforms: Array[Transform3D] = []
	for bone: int in _skeleton.get_bone_count():
		transforms.append(_skeleton.get_bone_global_pose(bone))
	for influences: Array in samples.get(side, []):
		var point: Vector3 = Vector3.ZERO
		for influence: Array in influences:
			point += (transforms[influence[0]] * influence[1]) * influence[2]
		point = _skeleton.global_transform * point
		var surface: float = field.height(point.x, point.z) if field != null else 0.0
		result = maxf(result, surface - point.y)
	return result

func _solve(side: String, lift: float) -> bool:
	var hip: int = _skeleton.find_bone(side + "UpLeg")
	var knee: int = _skeleton.find_bone(side + "Leg")
	var foot: int = _skeleton.find_bone(side + "Foot")
	if mini(hip, mini(knee, foot)) < 0:
		return false
	var a: Vector3 = _skeleton.get_bone_global_pose(hip).origin
	var b: Vector3 = _skeleton.get_bone_global_pose(knee).origin
	var c: Vector3 = _skeleton.get_bone_global_pose(foot).origin
	var target: Vector3 = c + _skeleton.global_basis.inverse() * (Vector3.UP * lift)
	var upper: float = a.distance_to(b)
	var lower: float = b.distance_to(c)
	var distance: float = a.distance_to(target)
	if distance >= upper + lower - 0.00001 or distance <= absf(upper - lower) + 0.00001:
		return false
	var axis: Vector3 = (target - a).normalized()
	var bend: Vector3 = (b - a) - axis * (b - a).dot(axis)
	if bend.length_squared() < 0.00000001:
		return false
	var along: float = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var desired: Vector3 = a + axis * along + bend.normalized() * sqrt(maxf(0.0, upper * upper - along * along))
	var foot_rotation: Quaternion = _rotation(foot)
	_set_rotation(hip, Quaternion((b - a).normalized(), (desired - a).normalized()) * _rotation(hip))
	b = _skeleton.get_bone_global_pose(knee).origin
	c = _skeleton.get_bone_global_pose(foot).origin
	_set_rotation(knee, Quaternion((c - b).normalized(), (target - b).normalized()) * _rotation(knee))
	_set_rotation(foot, foot_rotation)
	return true

func _rotation(bone: int) -> Quaternion:
	return _skeleton.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()

func _set_rotation(bone: int, rotation: Quaternion) -> void:
	var parent: int = _skeleton.get_bone_parent(bone)
	var parent_rotation: Quaternion = Quaternion.IDENTITY if parent < 0 else _rotation(parent)
	_skeleton.set_bone_pose_rotation(bone, (parent_rotation.inverse() * rotation).normalized())
