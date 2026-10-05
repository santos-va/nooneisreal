class_name HeroGroundContact
extends RefCounted
## Presentation-only terrain contact. Bone offsets and gameplay bodies are immutable.
## PLACEHOLDER limits in world metres, to be judged against skinned-sole/native evidence.
const CLEARANCE: float = 0.003
const MAX_VERTICAL: float = 0.25
const MAX_HORIZONTAL: float = 0.40
const TELEPORT_DISTANCE: float = 0.8
const RAY_ABOVE: float = 0.35
const RAY_BELOW: float = 0.55
const FootSamples = preload("res://scripts/fighter/HeroFootContact.gd")
static var _profiles: Dictionary = {}
static var _profiles_loaded: bool = false
var samples: Dictionary = {}
var _flat_samples: Dictionary = {}
var begin_frames: int = 0
var apply_calls: int = 0
var cache_hits: int = 0
var target_captures: int = 0
var query_count: int = 0
var body_support_reads: int = 0
var sample_count: int = 0
var pose_reads: int = 0
var history_updates: int = 0
var rejected_targets: int = 0
var _rig: Skeleton3D
var _indices: Dictionary = {}
var _rest_poles: Dictionary = {}
var _state: Dictionary = {}
var _planes: Dictionary = {}
var _final_rotations: Dictionary = {}
var _serial: int = 0
var _applied_serial: int = -1
var _body_position := Vector3.ZERO
var _body_valid: bool = false
var _frame_delta: float = 1.0 / 60.0
var _last_clip: String = ""

func setup(rig: Skeleton3D, mesh: MeshInstance3D, existing_samples: Dictionary = {}) -> void:
	_rig = rig
	if not _profiles_loaded:
		_profiles_loaded = true
		var path := "res://data/animation/foot_contacts.json"
		if FileAccess.file_exists(path):
			var parser := JSON.new()
			if parser.parse(FileAccess.get_file_as_string(path)) == OK:
				_profiles = validated_profiles(parser.data)
	if existing_samples.is_empty():
		var cache := FootSamples.new()
		cache.setup(rig, mesh)
		samples = cache.samples
	else:
		samples = existing_samples
	_flat_samples.clear()
	for side: String in samples:
		var offsets := PackedInt32Array([0])
		var bones := PackedInt32Array()
		var points := PackedVector3Array()
		var weights := PackedFloat32Array()
		var remainders := PackedFloat32Array()
		for influences: Array in samples[side]:
			var weight_sum: float = 0.0
			for influence: Array in influences:
				weight_sum += influence[2]
				bones.append(influence[0])
				points.append(influence[1] * influence[2])
				weights.append(influence[2])
			remainders.append(1.0-weight_sum)
			offsets.append(bones.size())
		_flat_samples[side] = {"offsets":offsets,"bones":bones,"points":points,"weights":weights,"remainders":remainders}
	for side: String in ["Left", "Right"]:
		var ids: Array[int] = [rig.find_bone(side + "UpLeg"), rig.find_bone(side + "Leg"), rig.find_bone(side + "Foot"), rig.find_bone(side + "ToeBase")]
		if ids.min() < 0:
			continue
		_indices[side] = ids
		var a: Vector3 = rig.get_bone_global_rest(ids[0]).origin
		var b: Vector3 = rig.get_bone_global_rest(ids[1]).origin
		var c: Vector3 = rig.get_bone_global_rest(ids[2]).origin
		var axis: Vector3 = (c - a).normalized()
		var pole: Vector3 = b - a - axis * (b - a).dot(axis)
		_rest_poles[side] = pole.normalized() if pole.length_squared() > 0.000001 else Vector3.BACK
	reset()

## Atomic, bounded metadata admission. Bad/missing metadata disables horizontal
## planting; geometric penetration correction remains available without profiles.
static func validated_profiles(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("clips") is Dictionary:
		return {}
	var clips: Dictionary = value.clips
	if clips.size() > 64:
		return {}
	for name: Variant in clips:
		if not name is String or name.length() > 96 or not clips[name] is Dictionary:
			return {}
		var profile: Dictionary = clips[name]
		if not _number(profile.get("length")) or profile.length <= 0.0 or profile.length > 30.0:
			return {}
		if not profile.get("sides") is Dictionary:
			return {}
		for side: String in ["Left", "Right"]:
			if not profile.sides.get(side) is Dictionary:
				return {}
			var intervals: Variant = profile.sides[side].get("intervals")
			if not intervals is Array or intervals.size() > 32:
				return {}
			var end: float = -1.0
			for interval: Variant in intervals:
				if not interval is Array or interval.size() != 2:
					return {}
				if not _number(interval[0]) or not _number(interval[1]):
					return {}
				if interval[0] < 0.0 or interval[1] > 1.0 or interval[0] >= interval[1] or interval[0] < end:
					return {}
				end = interval[1]
	return clips.duplicate(true)

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func begin_frame(delta: float) -> void:
	_serial += 1
	begin_frames += 1
	_frame_delta = maxf(delta, 0.00001)
	query_count = 0
	body_support_reads = 0
	pose_reads = 0
	sample_count = 0

func reset() -> void:
	_state.clear()
	_planes.clear()
	_final_rotations.clear()
	_body_valid = false
	_last_clip = ""

func _allowed(fighter: Fighter, ragdoll: BoneRagdoll) -> bool:
	if ragdoll != null or fighter.airborne_attack or fighter.dodging:
		return false
	if fighter.state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK]:
		return true
	if fighter.state == Fighter.State.GRAPPLE:
		return fighter.grapple.phase == GrappleHook.Phase.WINDUP or (fighter.on_ground() and Vector2(fighter.velocity.x, fighter.velocity.z).length() > 0.08)
	if fighter.state in [Fighter.State.HITSTUN, Fighter.State.BLOCKSTUN, Fighter.State.STUMBLE]:
		return true
	# Grounded attacks receive upward penetration clearance only. Raised kick
	# feet remain authored; no attack uses a horizontal anchor or downward pull.
	if fighter.state == Fighter.State.ATTACK and fighter.current_move != null:
		return true
	return false

func apply(fighter: Fighter, source: Skeleton3D, clip: String, clip_time: float, _delta: float, ragdoll: BoneRagdoll = null) -> void:
	apply_calls += 1
	if _rig == null or not _allowed(fighter, ragdoll):
		reset()
		return
	var fresh: bool = _serial != _applied_serial
	if not fresh:
		cache_hits += 1
		for bone: int in _final_rotations:
			_rig.set_bone_pose_rotation(bone, _final_rotations[bone])
		return
	if fresh:
		if _body_valid and fighter.global_position.distance_to(_body_position) > TELEPORT_DISTANCE:
			reset()
		_body_position = fighter.global_position
		_body_valid = true
		_applied_serial = _serial
		_planes.clear()
		_final_rotations.clear()
		_last_clip = clip
		# The body support is authoritative for eligibility; foot rays refine the surface.
		body_support_reads += 1
		if absf(fighter.global_position.y - fighter.floor_y()) > 0.10:
			reset()
			return
	var poses: Array[Transform3D] = _poses()
	for side: String in _indices:
		var ids: Array = _indices[side]
		var ankle: Vector3 = _rig.global_transform * poses[ids[2]].origin
		var toe: Vector3 = _rig.global_transform * poses[ids[3]].origin
		if fresh:
			_planes[side] = _support(fighter, ankle)
		var plane: Dictionary = _planes.get(side, {})
		if plane.is_empty():
			_state.erase(side)
			continue
		var minimum: float = _sole_clearance(side, poses, plane)
		var stance: bool = _stance(fighter, source, side, clip, clip_time)
		if fresh:
			history_updates += 1
			var previous: Dictionary = _state.get(side, {})
			if not stance or minimum > 0.13:
				_state[side] = {"planted": false}
			elif not bool(previous.get("planted", false)):
				target_captures += 1
				_state[side] = {"planted": true, "anchor": toe}
		var planted: bool = bool(_state.get(side, {}).get("planted", false))
		var shift := Vector3.ZERO
		if planted:
			var anchor: Vector3 = _state[side].anchor
			shift = Vector3(anchor.x - toe.x, 0.0, anchor.z - toe.z)
			if shift.length() > MAX_HORIZONTAL:
				_state[side] = {"planted": false}
				shift = Vector3.ZERO
		# Lift only penetration during swing; never drag an authored raised foot down.
		var vertical: float = CLEARANCE - minimum
		if not plane.water:
			var normal: Vector3 = plane.normal
			vertical -= (normal.x * shift.x + normal.z * shift.z) / normal.y
		if vertical < 0.0 and not planted:
			vertical = 0.0
		if absf(vertical) > MAX_VERTICAL:
			rejected_targets += 1
			_state[side] = {"planted": false}
			continue
		shift.y = vertical
		if shift.length_squared() < 0.00000001:
			continue
		if not _solve(side, ankle + shift):
			rejected_targets += 1
			_state[side] = {"planted": false}
			# A stance target can exceed reach during a turn/stop. Release its XZ
			# anchor, while still correcting reachable vertical penetration.
			var lift: float = maxf(0.0, CLEARANCE - minimum)
			if lift <= 0.0 or not _solve(side, ankle + Vector3.UP * lift):
				continue
		# Mixed calf/shoe skin weights need a final bounded clearance pass.
		poses = _poses()
		var remainder: float = CLEARANCE - _sole_clearance(side, poses, plane)
		if remainder > 0.0002 and remainder < 0.03:
			var corrected: Vector3 = _rig.global_transform * poses[ids[2]].origin
			_solve(side, corrected + Vector3.UP * remainder)
			poses = _poses()

	for ids: Array in _indices.values():
		for bone: int in [ids[0], ids[1], ids[2]]:
			_final_rotations[bone] = _rig.get_bone_pose_rotation(bone)

func _stance(fighter: Fighter, _source: Skeleton3D, side: String, clip: String, time: float) -> bool:
	if fighter.state in [Fighter.State.ATTACK, Fighter.State.HITSTUN, Fighter.State.BLOCKSTUN, Fighter.State.STUMBLE]:
		return false
	if fighter.state in [Fighter.State.IDLE, Fighter.State.CROUCH, Fighter.State.BLOCK] and Vector2(fighter.velocity.x, fighter.velocity.z).length() < 0.08:
		return true
	if fighter.state == Fighter.State.GRAPPLE and fighter.grapple.phase == GrappleHook.Phase.WINDUP and Vector2(fighter.velocity.x, fighter.velocity.z).length() < 0.08:
		return true
	# Independently measured and frozen on 3df43a5 BEFORE this solver existed.
	# Raw source ball height/vertical velocity define support, never helper flags.
	var name: String = clip.get_file().trim_suffix("_Loop") + "_Loop"
	if not _profiles.has(name):
		return false
	var profile: Dictionary = _profiles[name]
	var phase: float = fposmod(time / float(profile.length), 1.0)
	for interval: Array in profile.sides[side].intervals:
		if phase + 0.000001 >= float(interval[0]) and phase - 0.000001 <= float(interval[1]):
			return true
	return false

func _support(fighter: Fighter, at: Vector3) -> Dictionary:
	if GameState.water != null:
		return {"point": Vector3(at.x, GameState.water.height(at.x, at.z), at.z), "normal": Vector3.UP, "water": true}
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * RAY_ABOVE, at + Vector3.DOWN * RAY_BELOW, 1)
	query.exclude = [fighter.get_rid()]
	query_count += 1
	var hit: Dictionary = fighter.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP) < 0.6:
		return {}
	return {"point": hit.position, "normal": hit.normal, "water": false}

func _poses() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone: int in _rig.get_bone_count():
		result.append(_rig.get_bone_global_pose(bone))
		pose_reads += 1
	return result

func _sole_clearance(side: String, poses: Array[Transform3D], plane: Dictionary) -> float:
	if not plane.water:
		# Exact linear projection of every weighted skin vertex onto the support
		# plane. Preweighted bind points avoid per-influence 3D matrix transforms.
		var normal: Vector3 = plane.normal / plane.normal.y
		var origin: Vector3 = plane.point
		var rows := PackedVector3Array()
		var biases := PackedFloat32Array()
		var rig_transform: Transform3D = _rig.global_transform
		for pose: Transform3D in poses:
			var world: Transform3D = rig_transform * pose
			rows.append(world.basis.transposed() * normal)
			biases.append(world.origin.dot(normal))
		var flat: Dictionary = _flat_samples.get(side,{})
		if flat.is_empty():
			return INF
		var offsets: PackedInt32Array = flat.offsets
		var bones: PackedInt32Array = flat.bones
		var points: PackedVector3Array = flat.points
		var weights: PackedFloat32Array = flat.weights
		var remainders: PackedFloat32Array = flat.remainders
		var translation: float = rig_transform.origin.dot(normal)
		var minimum: float = INF
		for vertex: int in offsets.size()-1:
			var height: float = translation * remainders[vertex]
			for index: int in range(offsets[vertex],offsets[vertex+1]):
				height += rows[bones[index]].dot(points[index]) + biases[bones[index]] * weights[index]
			minimum = minf(minimum,height)
		sample_count += offsets.size()-1
		return minimum - origin.dot(normal)
	# Water is nonlinear: retain each fully skinned world-XZ point. Only wave
	# coefficients constant across this pass and bone transforms are cached.
	var field: WaveField = GameState.water
	var coefficients: Array[Vector4] = []
	for index: int in 3:
		var k: float = TAU / field.wavelengths[index]
		var direction: Vector2 = field._dir(index)
		coefficients.append(Vector4(k*direction.x,k*direction.y,field.phases[index]-k*field.speeds[index]*field.time_s(),field.amplitudes[index]))
	var swell: float = field.swell_amplitude * field.swell_env()
	var world_bases: Array[Basis] = []
	var world_origins := PackedVector3Array()
	var rig_transform: Transform3D = _rig.global_transform
	for pose: Transform3D in poses:
		var world: Transform3D = rig_transform * pose
		world_bases.append(world.basis)
		world_origins.append(world.origin)
	var flat: Dictionary = _flat_samples.get(side,{})
	if flat.is_empty():
		return INF
	var offsets: PackedInt32Array = flat.offsets
	var bones: PackedInt32Array = flat.bones
	var points: PackedVector3Array = flat.points
	var weights: PackedFloat32Array = flat.weights
	var remainders: PackedFloat32Array = flat.remainders
	var minimum: float = INF
	var c0: Vector4 = coefficients[0]
	var c1: Vector4 = coefficients[1]
	var c2: Vector4 = coefficients[2]
	for vertex: int in offsets.size()-1:
		var point: Vector3 = rig_transform.origin * remainders[vertex]
		for index: int in range(offsets[vertex],offsets[vertex+1]):
			point += world_bases[bones[index]] * points[index] + world_origins[bones[index]] * weights[index]
		var phase0: float = c0.x*point.x+c0.y*point.z+c0.z
		var surface: float = c0.w*sin(phase0)+c1.w*sin(c1.x*point.x+c1.y*point.z+c1.z)+c2.w*sin(c2.x*point.x+c2.y*point.z+c2.z)
		if swell != 0.0:
			surface += swell*sin(phase0+1.2)
		minimum = minf(minimum,point.y-surface)
	sample_count += offsets.size()-1
	return minimum

func _solve(side: String, world_target: Vector3) -> bool:
	var ids: Array = _indices[side]
	var a: Vector3 = _rig.get_bone_global_pose(ids[0]).origin
	var b: Vector3 = _rig.get_bone_global_pose(ids[1]).origin
	var c: Vector3 = _rig.get_bone_global_pose(ids[2]).origin
	var target: Vector3 = _rig.global_transform.affine_inverse() * world_target
	var upper: float = a.distance_to(b)
	var lower: float = b.distance_to(c)
	var distance: float = a.distance_to(target)
	if distance >= upper + lower - 0.00001 or distance <= absf(upper - lower) + 0.00001:
		return false
	var axis: Vector3 = (target - a).normalized()
	var pole: Vector3 = (b-a) - axis * (b-a).dot(axis)
	if pole.length_squared() < 0.000001:
		var rest: Vector3 = _rest_poles[side]
		pole = rest - axis * rest.dot(axis)
	if pole.length_squared() < 0.000001:
		return false
	var along: float = (upper*upper-lower*lower+distance*distance)/(2.0*distance)
	var knee: Vector3 = a + axis*along + pole.normalized()*sqrt(maxf(0.0,upper*upper-along*along))
	var foot_rotation: Quaternion = _rotation(ids[2])
	_set_rotation(ids[0], Quaternion((b-a).normalized(),(knee-a).normalized())*_rotation(ids[0]))
	b = _rig.get_bone_global_pose(ids[1]).origin
	c = _rig.get_bone_global_pose(ids[2]).origin
	_set_rotation(ids[1], Quaternion((c-b).normalized(),(target-b).normalized())*_rotation(ids[1]))
	_set_rotation(ids[2], foot_rotation)
	return true

func _rotation(bone: int) -> Quaternion:
	return _rig.get_bone_global_pose(bone).basis.orthonormalized().get_rotation_quaternion()

func _set_rotation(bone: int, rotation: Quaternion) -> void:
	var parent: int = _rig.get_bone_parent(bone)
	var parent_rotation: Quaternion = Quaternion.IDENTITY if parent < 0 else _rotation(parent)
	_rig.set_bone_pose_rotation(bone, (parent_rotation.inverse()*rotation).normalized())
