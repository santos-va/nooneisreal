class_name ParkourMotion
extends RefCounted
## City support poses from real motor contacts, using installed CC0 UAL sources.
## All distances/timings below are PLACEHOLDER art constraints, never movement authority.
const WALL_STRIDE: float = 0.72
const ENTRY_SECONDS: float = 0.10
var phase: String = ""
var cycle: float = 0.0
var grip_error: float = 0.0
var source_clip: String = ""
var _snapshot: Dictionary = {}
var _elapsed: float = 0.0
var _base: Array[Transform3D] = []
var _serial: int = 0
var _feet_serial: int = -1
var _plants: Dictionary = {}
var _frame_feet: Dictionary = {}

func update(f: Fighter, velocity: Vector3, delta: float, discontinuous: bool) -> void:
	_serial += 1
	var previous: String = phase
	var metadata: Variant = f.get_meta("parkour_presentation", {}) if f.state == Fighter.State.JUMP and not f.grapple.busy() else {}
	_snapshot = metadata if metadata is Dictionary else {}
	phase = str(_snapshot.get("phase", ""))
	if not valid_snapshot(_snapshot) or (phase == "wall_run" and f.data.id != "skea"):
		phase = ""
		_snapshot = {}
	if discontinuous or previous != phase:
		_elapsed = 0.0
		cycle = 0.0
		_plants.clear()
		_frame_feet.clear()
	_elapsed += maxf(delta, 0.0)
	if phase == "wall_run" and not discontinuous:
		# Actual 3D displacement: vertical wall travel advances feet; a blocked body does not.
		cycle = fposmod(cycle + velocity.length() * maxf(delta, 0.0) / WALL_STRIDE, 1.0)
	source_clip = "Climb_Idle" if phase == "hang" else ("ClimbLedge" if phase == "mantle" else ("Climb_Up" if phase == "wall_run" else ""))
	grip_error = 0.0

static func valid_snapshot(snapshot: Dictionary) -> bool:
	var mode: String = str(snapshot.get("phase", ""))
	if mode not in ["hang", "mantle", "wall_run"]:
		return false
	for key: String in (["wall_point", "wall_normal"] if mode == "wall_run" else ["left_hand", "right_hand"]):
		if not snapshot.get(key) is Vector3 or not Vector3(snapshot[key]).is_finite():
			return false
	if mode == "wall_run" and Vector3(snapshot.wall_normal).length_squared() < 0.5:
		return false
	var progress: Variant = snapshot.get("progress", 0.0)
	return (progress is int or progress is float) and is_finite(float(progress))

func restore(source: Skeleton3D) -> void:
	for bone: int in _base.size():
		AuthoredLocomotion._set_pose(source, bone, _base[bone])
	_base.clear()

func apply_source(source: Skeleton3D, clips: AuthoredHookMotion) -> void:
	if source_clip.is_empty() or not clips._cache.has(source_clip):
		return
	_base = AuthoredLocomotion._poses(source)
	var progress: float = clampf(float(_snapshot.get("progress", 0.0)), 0.0, 1.0)
	var at: float = (cycle if phase == "wall_run" else (progress if phase == "mantle" else 0.35)) * float(clips._lengths[source_clip])
	var weight: float = smoothstep(0.0, ENTRY_SECONDS, _elapsed)
	for bone: int in source.get_bone_count():
		var pose: Transform3D = clips._pose(source_clip, at, bone)
		# Rotations only: no imported wall-root translation or limb scaling.
		var target: Quaternion = pose.basis.orthonormalized().get_rotation_quaternion()
		var original: Quaternion = _base[bone].basis.orthonormalized().get_rotation_quaternion()
		source.set_bone_pose_rotation(bone, original.slerp(target, weight))
	# Supported poses must not inherit Jump_Loop's backward root translation.
	var pelvis: int = source.find_bone("pelvis")
	source.set_bone_pose_position(pelvis, _base[pelvis].origin.lerp(source.get_bone_rest(pelvis).origin, weight))

func apply_contacts(hero: Skeleton3D, f: Fighter) -> void:
	grip_error = 0.0
	if phase == "wall_run":
		_apply_wall_feet(hero, f)
		return
	if phase not in ["hang", "mantle"]:
		return
	# The motor's ledge points are the authority. Never substitute a nearby fake grip.
	# Mantling releases the ledge as the body clears it, avoiding arms bent behind the back.
	var progress: float = clampf(float(_snapshot.get("progress", 0.0)), 0.0, 1.0)
	var weight: float = 1.0 - smoothstep(0.22, 0.48, progress) if phase == "mantle" else 1.0
	_align_ledge_support(hero, weight)
	for side: String in ["Left", "Right"]:
		var key: String = side.to_lower() + "_hand"
		if not _snapshot.get(key) is Vector3 or not Vector3(_snapshot[key]).is_finite():
			continue
		var a: int = hero.find_bone(side + "Arm")
		var b: int = hero.find_bone(side + "ForeArm")
		var end: int = hero.find_bone(side + "Hand")
		if mini(a, mini(b, end)) < 0:
			continue
		var rotations: Array[Quaternion] = [hero.get_bone_pose_rotation(a), hero.get_bone_pose_rotation(b), hero.get_bone_pose_rotation(end)]
		var target: Vector3 = _snapshot[key]
		var contact_weight: float = weight
		if phase == "mantle":
			var shoulder: Vector3 = hero.global_transform * hero.get_bone_global_pose(a).origin
			var elbow: Vector3 = hero.global_transform * hero.get_bone_global_pose(b).origin
			var hand: Vector3 = hero.global_transform * hero.get_bone_global_pose(end).origin
			var reach: float = shoulder.distance_to(elbow) + elbow.distance_to(hand)
			contact_weight *= 1.0 - smoothstep(reach * 0.88, reach, shoulder.distance_to(target))
		AuthoredCombatMotion._solve_chain(hero, a, b, end, hero.global_transform.affine_inverse() * target)
		for index: int in 3:
			var bone: int = [a, b, end][index]
			hero.set_bone_pose_rotation(bone, rotations[index].slerp(hero.get_bone_pose_rotation(bone), contact_weight))
		if contact_weight >= 0.999:
			var actual: Vector3 = hero.global_transform * hero.get_bone_global_pose(end).origin
			grip_error = maxf(grip_error, actual.distance_to(target))

func _align_ledge_support(hero: Skeleton3D, weight: float) -> void:
	# Imported heroes have short arms. Shift the visible body within its capsule
	# toward the real support, instead of stretching arms or moving grip targets.
	var hips: int = hero.find_bone("Hips")
	var support: Vector3 = (Vector3(_snapshot.left_hand) + Vector3(_snapshot.right_hand)) * 0.5
	var direction: Vector3 = support - hero.global_transform * hero.get_bone_global_pose(hips).origin
	direction.y = 0.0
	if not direction.is_zero_approx():
		HeroBodyMotion._rotate_world(hero, hero.find_bone("Spine02"), Vector3.UP.cross(direction.normalized()), deg_to_rad(8.0) * weight)
	var correction: Vector3 = Vector3.ZERO
	for side: String in ["Left", "Right"]:
		var shoulder: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Arm")).origin
		var elbow: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "ForeArm")).origin
		var hand: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Hand")).origin
		var reach: float = (shoulder.distance_to(elbow) + elbow.distance_to(hand)) * 0.93
		var delta: Vector3 = Vector3(_snapshot[side.to_lower() + "_hand"]) - shoulder
		correction += delta.normalized() * maxf(0.0, delta.length() - reach) * 0.5
	correction = correction.limit_length(0.15) * weight
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips) + hero.global_basis.inverse() * correction)

func _apply_wall_feet(hero: Skeleton3D, f: Fighter) -> void:
	var normal: Vector3 = Vector3(_snapshot.wall_normal).normalized()
	var wall: Vector3 = _snapshot.wall_point
	if _feet_serial != _serial:
		_frame_feet.clear()
		for side: String in ["Left", "Right"]:
			var foot: int = hero.find_bone(side + "Foot")
			var phase_offset: float = cycle + (0.5 if side == "Right" else 0.0)
			var stance: bool = fposmod(phase_offset, 1.0) < 0.5
			if not stance:
				_plants.erase(side)
				continue
			var ankle: Vector3 = hero.global_transform * hero.get_bone_global_pose(foot).origin
			var point: Vector3 = _plants.get(side, ankle)
			var contact: Dictionary = _shoe_contact(hero, f, side, ankle, point, normal, wall)
			if contact.is_empty():
				_plants.erase(side)
				continue
			# Tangential coordinates stay planted; normal clearance follows the actual
			# animated shoe footprint, including protrusions missed by the ankle ray.
			_plants[side] = contact.point
			_frame_feet[side] = _plants[side]
		_feet_serial = _serial
	for side: String in _frame_feet:
		var a: int = hero.find_bone(side + "UpLeg")
		var b: int = hero.find_bone(side + "Leg")
		var end: int = hero.find_bone(side + "Foot")
		AuthoredCombatMotion._solve_chain(hero, a, b, end, hero.global_transform.affine_inverse() * Vector3(_frame_feet[side]))

func _shoe_contact(hero: Skeleton3D, f: Fighter, side: String, ankle: Vector3, plant: Vector3, normal: Vector3, wall: Vector3) -> Dictionary:
	var tangent: Vector3 = normal.cross(Vector3.UP).normalized()
	var bounds_min: Vector3 = Vector3(INF, INF, INF)
	var bounds_max: Vector3 = Vector3(-INF, -INF, -INF)
	var poses: Array[Transform3D] = []
	for bone: int in hero.get_bone_count():
		poses.append(hero.global_transform * hero.get_bone_global_pose(bone))
	var samples: Array = f.skeletal.foot_contact.samples.get(side, [])
	if samples.is_empty():
		return {}
	for influences: Array in samples:
		var vertex: Vector3 = Vector3.ZERO
		for influence: Array in influences:
			vertex += (poses[influence[0]] * influence[1]) * influence[2]
		var offset: Vector3 = vertex - ankle
		var projected: Vector3 = Vector3(offset.dot(tangent), offset.y, offset.dot(normal))
		bounds_min = bounds_min.min(projected)
		bounds_max = bounds_max.max(projected)
	var support: float = -INF
	for across: float in [bounds_min.x, (bounds_min.x + bounds_max.x) * 0.5, bounds_max.x]:
		for height: float in [bounds_min.y, (bounds_min.y + bounds_max.y) * 0.5, bounds_max.y]:
			var point: Vector3 = plant + tangent * across + Vector3.UP * height
			var plane: Vector3 = point - normal * (point - wall).dot(normal)
			var query := PhysicsRayQueryParameters3D.create(plane + normal * 0.65, plane - normal * 0.65, 1, [f.get_rid()])
			var hit: Dictionary = f.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or not Vector3(hit.position).is_finite() or Vector3(hit.normal).dot(normal) < 0.7:
				continue
			support = maxf(support, Vector3(hit.position).dot(normal))
	if not is_finite(support):
		return {}
	# Measure the whole shoe's leading extent, not an assumed ankle radius.
	var coordinate: float = support - bounds_min.z + HeroFootContact.CLEARANCE
	return {"point": plant + normal * (coordinate - plant.dot(normal))}
