class_name ParkourMotion
extends RefCounted
## City support poses from real motor contacts, using installed CC0 UAL sources.
## All distances/timings below are PLACEHOLDER art constraints, never movement authority.
const WALL_STRIDE: float = 0.72
const ENTRY_SECONDS: float = 0.10
## P5: below this sideways speed (m/s) a hang shows Climb_Idle, above it Climb_Left/Right.
const SHIMMY_SPEED: float = 0.3
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
var _frame_weights: Dictionary = {}
## The wall-run plant point of a foot in stance, including its take and let-go (_plants: only full contact).
var _held: Dictionary = {}
var _kick_source: String = "WallRun_Jump_R"
var _hero_id: String = ""
var _gear_serial: int = -1
var _accessory_points: Dictionary = {}
var accessory_lift: float = 0.0
var roll_support = preload("res://scripts/fighter/RollGroundSupport.gd").new()
## Seconds into the looping side-run / shimmy clip: they play at their authored rate while the body travels.
var _loop_time: float = 0.0
## ── Plan 2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall step 5 (branch B). Every value is a PLACEHOLDER art value.
## --break controls of tools/animation/anim_traversal_check.gd: false draws the product of main 595490d.
var wall_living: bool = true
var ledge_living: bool = true
var roll_tuck: bool = true
## Wall run: the feet step WALL_STEP_STRIDE metres of wall per Climb_Up cycle and the arms play it at most WALL_ARM_RATE
## times its authored rate (T6: at WALL_STRIDE Climb_Up ran ~9x its rate at 5 m/s and the arms flailed 40-73 deg/tick).
const WALL_STEP_STRIDE: float = 1.2
const WALL_ARM_RATE: float = 2.0
## A foot stays planted for this share of the cycle (0.34 m of wall at WALL_STEP_STRIDE, as the 0.36 m of a half cycle at
## WALL_STRIDE: further up the leg cannot reach its plant and the shoe floats off the wall), then swings; both feet are
## off the wall between plants, as in a run. Take and let-go each last WALL_PLANT_RAMP of the cycle.
const WALL_STANCE: float = 0.28
const WALL_PLANT_RAMP: float = 0.06
var _arm_cycle: float = 0.0
var _climb_up_seconds: float = 1.267
## Ledge hang: Climb_Idle plays, and the body swings from its grip -- the grab's swing decays to a breathing sway --
## while it turns about the vertical a quarter period later, so the hang never stands still (T6: 22 ticks at 0 deg).
const HANG_SWING: float = 5.0 # degrees added at the grab
const HANG_SWAY: float = 1.5 # degrees, what stays
const HANG_DECAY: float = 0.8 # seconds
const HANG_PERIOD: float = 1.6 # seconds
## Mantle: the drawn body rises on an ease-in-out arc over the motor's straight hang -> apex line (a pull, then a
## press; T6: "a lift"), and the ClimbLedge wrist flip at 0.32 s (55 deg/tick authored) is spread over MANTLE_WRIST.
const MANTLE_RISE: float = 1.455 # CityParkourProfile hang_height + clearance: the motor's hang -> apex rise
const MANTLE_WRIST: Vector2 = Vector2(0.26, 0.42)
## Landing roll: the tucked body turns once forward about its centre, finishing when the motor's roll is expected to stop
## (T6: "a plank, then a headstand"). The limbs take the Roll clip at ROLL_TUCK_AT, its tightest tuck (thighs 15-27 deg
## off the spine, hands at the knees); the clip's own orientation and its 1.15 m dive are dropped.
const ROLL_TUCK_AT: float = 0.72
## The turn is complete at this share of the roll; the rest of it unfolds the tuck upright.
const ROLL_TURN_DONE: float = 0.85
var _roll_turn: float = 0.0

func update(f: Fighter, velocity: Vector3, delta: float, discontinuous: bool) -> void:
	_serial += 1
	_hero_id = f.data.id
	var previous: String = phase
	var metadata: Variant = f.get_meta("parkour_presentation", {}) if not f.grapple.busy() else {}
	_snapshot = metadata if metadata is Dictionary else {}
	phase = str(_snapshot.get("phase", ""))
	var state_allowed: bool = f.state in [Fighter.State.IDLE, Fighter.State.WALK] and f.is_on_floor() if phase == "landing_roll" else f.state == Fighter.State.JUMP
	if not state_allowed or not valid_snapshot(_snapshot) or (phase == "wall_run" and f.data.id != "skea"):
		phase = ""
		_snapshot = {}
	if discontinuous or previous != phase:
		_elapsed = 0.0
		cycle = 0.0
		_loop_time = 0.0
		_arm_cycle = 0.0
		_roll_turn = 0.0
		_plants.clear()
		_held.clear()
		_frame_feet.clear()
	_elapsed += maxf(delta, 0.0)
	if phase == "wall_run" and not discontinuous:
		# Actual 3D displacement: vertical wall travel advances feet; a blocked body does not.
		var stride: float = WALL_STEP_STRIDE if wall_living else WALL_STRIDE
		var steps: float = velocity.length() * maxf(delta, 0.0) / stride
		cycle = fposmod(cycle + steps, 1.0)
		_arm_cycle = fposmod(_arm_cycle + minf(steps, WALL_ARM_RATE * maxf(delta, 0.0) / _climb_up_seconds), 1.0)
	if phase == "landing_roll" and not discontinuous:
		# The share of the roll behind the body: linear in time when the motor stops where it is expected to.
		var behind: float = float(_snapshot.get("progress", 0.0)) * float(_snapshot.get("duration", 0.0))
		_roll_turn = maxf(_roll_turn, clampf(behind / (behind + _roll_remaining(f)), 0.0, 1.0))
	if phase == "wall_kick" and previous != phase:
		_kick_source = "WallRun_Jump_L" if Vector3(_snapshot.wall_normal).dot(f.forward.cross(Vector3.UP)) < 0.0 else "WallRun_Jump_R"
	source_clip = {"hang": "Climb_Idle", "mantle": "ClimbLedge", "wall_run": "Climb_Up", "wall_kick": _kick_source, "landing_roll": "Roll", "vault": "SafetyVault"}.get(phase, "")
	var right: Vector3 = f.forward.cross(Vector3.UP)
	if phase == "wall_side":
		# The wall is on the hero's left when its outward normal points to the hero's right.
		source_clip = "WallRun_L" if Vector3(_snapshot.wall_normal).dot(right) > 0.0 else "WallRun_R"
	elif phase == "hang" and float(_snapshot.get("speed", 0.0)) > SHIMMY_SPEED:
		source_clip = "Climb_Right" if Vector3(_snapshot.get("direction", Vector3.ZERO)).dot(right) > 0.0 else "Climb_Left"
	if source_clip in ["WallRun_L", "WallRun_R", "Climb_Left", "Climb_Right"]:
		_loop_time += maxf(delta, 0.0)
	grip_error = 0.0

static func valid_snapshot(snapshot: Dictionary) -> bool:
	var mode: String = str(snapshot.get("phase", ""))
	if mode not in ["hang", "mantle", "wall_run", "wall_kick", "landing_roll", "vault", "wall_side"]:
		return false
	var contacts: Array = ["floor_point", "floor_normal", "direction"] if mode == "landing_roll" else (["wall_point", "wall_normal"] if mode in ["wall_run", "wall_kick", "wall_side"] else ["left_hand", "right_hand"])
	for key: String in contacts:
		if not snapshot.get(key) is Vector3 or not Vector3(snapshot[key]).is_finite():
			return false
	if mode in ["wall_run", "wall_kick", "wall_side"] and Vector3(snapshot.wall_normal).length_squared() < 0.5:
		return false
	if mode == "landing_roll" and (Vector3(snapshot.floor_normal).normalized().dot(Vector3.UP) < 0.95 or Vector3(snapshot.direction).length_squared() < 0.5):
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
	if phase == "landing_roll" and roll_tuck:
		_apply_tuck(source, clips)
		return
	var progress: float = clampf(float(_snapshot.get("progress", 0.0)), 0.0, 1.0)
	var length: float = float(clips._lengths[source_clip])
	var at: float = (cycle if phase == "wall_run" else (0.35 if phase == "hang" else progress)) * length
	if phase == "hang" and ledge_living:
		at = fposmod(0.35 * length + _elapsed, length)
	var arms_at: float = at
	if phase == "wall_run":
		_climb_up_seconds = length
		if wall_living:
			arms_at = _arm_cycle * length
	if source_clip in ["WallRun_L", "WallRun_R", "Climb_Left", "Climb_Right"]:
		at = fposmod(_loop_time, length)
		arms_at = at
	var weight: float = smoothstep(0.0, ENTRY_SECONDS, _elapsed)
	if phase in ["wall_kick", "landing_roll"]:
		weight *= 1.0 - smoothstep(0.80, 1.0, progress)
	for bone: int in source.get_bone_count():
		var pose: Transform3D = clips._pose(source_clip, arms_at if _upper(source.get_bone_name(bone)) else at, bone)
		if phase == "mantle" and ledge_living and source.get_bone_name(bone) in ["hand_l", "hand_r"] and at > MANTLE_WRIST.x and at < MANTLE_WRIST.y:
			pose = clips._pose(source_clip, MANTLE_WRIST.x, bone).interpolate_with(clips._pose(source_clip, MANTLE_WRIST.y, bone), smoothstep(MANTLE_WRIST.x, MANTLE_WRIST.y, at))
		# Rotations only: no imported wall-root translation or limb scaling.
		var target: Quaternion = pose.basis.orthonormalized().get_rotation_quaternion()
		if _hero_id == "choko" and phase in ["landing_roll", "wall_kick"] and (source.get_bone_name(bone).begins_with("spine_") or source.get_bone_name(bone).begins_with("clavicle_")):
			# Keep the compact hero's chest shell from folding through itself.
			var rest: Quaternion = source.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion()
			target = rest.slerp(target, 0.20 if source.get_bone_name(bone).begins_with("spine_") else 0.0)
		if _hero_id == "choko" and phase == "landing_roll" and (source.get_bone_name(bone).begins_with("neck_") or source.get_bone_name(bone) == "Head"):
			# Preserve the hero's neck clearance instead of folding its larger head into chest tabs.
			var rest: Quaternion = source.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion()
			target = rest.slerp(target, 0.25)
		var original: Quaternion = _base[bone].basis.orthonormalized().get_rotation_quaternion()
		source.set_bone_pose_rotation(bone, original.slerp(target, weight))
	# Supported poses must not inherit Jump_Loop's backward root translation.
	var pelvis: int = source.find_bone("pelvis")
	var target_position: Vector3 = source.get_bone_rest(pelvis).origin
	if phase == "landing_roll":
		# Retain only authored vertical compression, never imported horizontal travel.
		var parent: int = source.get_bone_parent(pelvis)
		var parent_basis: Basis = source.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
		var up: Vector3 = ((source.global_basis * parent_basis).inverse() * Vector3.UP).normalized()
		var authored: Vector3 = clips._pose(source_clip, at, pelvis).origin
		target_position += up * (authored - target_position).dot(up)
	source.set_bone_pose_position(pelvis, _base[pelvis].origin.lerp(target_position, weight))

func apply_contacts(hero: Skeleton3D, f: Fighter) -> void:
	grip_error = 0.0
	if phase == "landing_roll":
		if roll_tuck:
			_turn_roll(hero)
		roll_support.apply(hero, f.skeletal.hero_mesh, _snapshot, _serial)
		return
	if phase == "wall_run":
		_apply_wall_feet(hero, f)
		return
	if phase not in ["hang", "mantle"]:
		return
	# The motor's ledge points are the authority. Never substitute a nearby fake grip.
	# Mantling releases the ledge as the body clears it, avoiding arms bent behind the back.
	var progress: float = clampf(float(_snapshot.get("progress", 0.0)), 0.0, 1.0)
	if ledge_living:
		if phase == "hang":
			_sway_hang(hero)
		else:
			var rise: float = minf(progress * 2.0, 1.0)
			var hips: int = hero.find_bone("Hips")
			hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips) + hero.global_basis.inverse() * (Vector3.UP * MANTLE_RISE * (smoothstep(0.0, 1.0, rise) - rise)))
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
		_frame_weights.clear()
		for side: String in ["Left", "Right"]:
			var foot: int = hero.find_bone(side + "Foot")
			var phase_offset: float = cycle + (0.5 if side == "Right" else 0.0)
			var stance: bool = fposmod(phase_offset, 1.0) < (WALL_STANCE if wall_living else 0.5)
			if not stance:
				_plants.erase(side)
				_held.erase(side)
				continue
			var ankle: Vector3 = hero.global_transform * hero.get_bone_global_pose(foot).origin
			var point: Vector3 = _held.get(side, ankle)
			var contact: Dictionary = _shoe_contact(hero, f, side, ankle, point, normal, wall)
			if contact.is_empty():
				_plants.erase(side)
				_held.erase(side)
				continue
			# Tangential coordinates stay planted; normal clearance follows the actual
			# animated shoe footprint, including protrusions missed by the ankle ray.
			_held[side] = contact.point
			_frame_feet[side] = contact.point
			# A plant takes and lets go of the foot over WALL_PLANT_RAMP of the cycle each instead of in one tick; only a
			# foot in full contact counts as planted.
			var stance_at: float = fposmod(phase_offset, 1.0)
			var weight: float = smoothstep(0.0, WALL_PLANT_RAMP, stance_at) * (1.0 - smoothstep(WALL_STANCE - WALL_PLANT_RAMP, WALL_STANCE, stance_at)) if wall_living else 1.0
			_frame_weights[side] = weight
			if weight >= 0.999:
				_plants[side] = contact.point
			else:
				_plants.erase(side)
		_feet_serial = _serial
	for side: String in _frame_feet:
		var a: int = hero.find_bone(side + "UpLeg")
		var b: int = hero.find_bone(side + "Leg")
		var end: int = hero.find_bone(side + "Foot")
		var original: Array[Quaternion] = [hero.get_bone_pose_rotation(a), hero.get_bone_pose_rotation(b), hero.get_bone_pose_rotation(end)]
		AuthoredCombatMotion._solve_chain(hero, a, b, end, hero.global_transform.affine_inverse() * Vector3(_frame_feet[side]))
		var plant: float = float(_frame_weights.get(side, 1.0))
		if plant < 1.0:
			for index: int in 3:
				var bone: int = [a, b, end][index]
				hero.set_bone_pose_rotation(bone, original[index].slerp(hero.get_bone_pose_rotation(bone), plant))

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

func finish_roll_support(f: Fighter) -> bool:
	if phase != "landing_roll" or _gear_serial == _serial:
		return false
	_gear_serial = _serial
	accessory_lift = 0.0
	var minimum: float = INF
	var normal: Vector3 = Vector3(_snapshot.floor_normal).normalized()
	var floor_point: Vector3 = _snapshot.floor_point
	var holders: Array = [f.skeletal.gear]
	if f.skeletal.sword != null:
		holders.append(f.skeletal.sword)
	for holder: Node3D in holders:
		if holder == null:
			continue
		for mesh: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
			if not mesh.is_visible_in_tree() or mesh.mesh == null:
				continue
			var key: int = mesh.mesh.get_instance_id()
			if not _accessory_points.has(key):
				var points := PackedVector3Array()
				for surface: int in mesh.mesh.get_surface_count():
					points.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
				_accessory_points[key] = points
			var local_normal: Vector3 = mesh.global_basis.transposed() * normal
			var offset: float = (mesh.global_position - floor_point).dot(normal)
			for point: Vector3 in _accessory_points[key]:
				minimum = minf(minimum, point.dot(local_normal) + offset)
	if not is_finite(minimum):
		return false
	accessory_lift = maxf(0.0, 0.003 - minimum) / maxf(normal.y, 0.95)
	if accessory_lift < 0.000001:
		return false
	# Gear is part of the visible support silhouette. Keep the same correction
	# in the physics cache so repeated retargets rebuild the identical final pose.
	roll_support.lift += accessory_lift
	var hero: Skeleton3D = f.skeletal.hero_skeleton
	var hips: int = hero.find_bone("Hips")
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips) + hero.global_basis.inverse() * (Vector3.UP * accessory_lift))
	return true

## Upper body: what the wall-run arm clock drives (the AuthoredHookMotion mask: spine, neck, head, shoulders, arms, hands).
static func _upper(name: String) -> bool:
	return name.begins_with("spine_") or name.begins_with("neck_") or name == "Head" or name.begins_with("clavicle_") or name.begins_with("upperarm_") or name.begins_with("lowerarm_") or name.begins_with("hand_") or name.contains("thumb") or name.contains("index") or name.contains("middle") or name.contains("ring") or name.contains("pinky")

## Seconds the motor's roll still has (CityParkourMotor.tick_ground: it decelerates to a quarter of roll_min_speed, or
## stops at roll_seconds), read-only from the actor's own profile; 0.3 s when the actor has none.
func _roll_remaining(f: Fighter) -> float:
	var motor: Variant = f.get("parkour")
	var profile: Resource = motor.profile if motor != null and "profile" in motor else null
	if profile == null:
		return 0.3
	var speed: float = float(_snapshot.get("speed", 0.0))
	var by_speed: float = (speed - float(profile.roll_min_speed) * 0.25) / maxf(float(profile.roll_deceleration), 0.001)
	var by_clock: float = float(profile.roll_seconds) * (1.0 - float(_snapshot.get("progress", 0.0)))
	return maxf(minf(by_speed, by_clock), 1.0 / 60.0)

func _tuck_weight() -> float:
	return smoothstep(0.0, 0.20, _roll_turn) * (1.0 - smoothstep(0.55, 1.0, _roll_turn))

## The roll's tuck on the mannequin: the Roll clip's limbs at ROLL_TUCK_AT; the pelvis keeps the stance's orientation and
## height (the turn and the floor contact are drawn on the hero, _turn_roll and RollGroundSupport).
func _apply_tuck(source: Skeleton3D, clips: AuthoredHookMotion) -> void:
	var weight: float = _tuck_weight()
	var pelvis: int = source.find_bone("pelvis")
	for bone: int in source.get_bone_count():
		var name: String = source.get_bone_name(bone)
		if bone == pelvis or name.begins_with("hand_"):
			continue # the hands keep the stance's wrists: the tuck's wrists flip across 180° on the way back
		var target: Quaternion = clips._pose("Roll", ROLL_TUCK_AT, bone).basis.orthonormalized().get_rotation_quaternion()
		if _hero_id == "choko" and (name.begins_with("spine_") or name.begins_with("clavicle_")):
			# Keep the compact hero's chest shell from folding through itself (as the authored roll does).
			var rest: Quaternion = source.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion()
			target = rest.slerp(target, 0.20 if name.begins_with("spine_") else 0.0)
		if _hero_id == "choko" and (name.begins_with("neck_") or name == "Head"):
			var rest: Quaternion = source.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion()
			target = rest.slerp(target, 0.25)
		source.set_bone_pose_rotation(bone, _base[bone].basis.orthonormalized().get_rotation_quaternion().slerp(target, weight))

## One forward turn of the whole hero about its centre (the mean of its bones) while it rolls along the floor.
func _turn_roll(hero: Skeleton3D) -> void:
	var direction: Vector3 = Vector3(_snapshot.direction)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return
	var axis: Vector3 = (hero.global_basis.inverse() * Vector3.UP.cross(direction.normalized())).normalized()
	_turn_about(hero, axis, _centre(hero), TAU * smoothstep(0.0, ROLL_TURN_DONE, _roll_turn))

## The hang's swing from the grip: about the ledge line through the grips, then about the vertical, a quarter apart.
func _sway_hang(hero: Skeleton3D) -> void:
	var grip: Vector3 = (Vector3(_snapshot.left_hand) + Vector3(_snapshot.right_hand)) * 0.5
	var outward: Vector3 = Vector3(_snapshot.get("wall_normal", Vector3.ZERO))
	outward.y = 0.0
	if outward.length_squared() < 0.0001:
		return
	var along: Vector3 = outward.normalized().cross(Vector3.UP).normalized()
	var phase_angle: float = TAU * _elapsed / HANG_PERIOD
	var swing: float = deg_to_rad(HANG_SWING * exp(-_elapsed / HANG_DECAY) + HANG_SWAY) * sin(phase_angle)
	var pivot: Vector3 = hero.global_transform.affine_inverse() * grip
	_turn_about(hero, (hero.global_basis.inverse() * along).normalized(), pivot, swing)
	_turn_about(hero, (hero.global_basis.inverse() * Vector3.UP).normalized(), pivot, deg_to_rad(HANG_SWAY) * cos(phase_angle))

static func _centre(hero: Skeleton3D) -> Vector3:
	var sum: Vector3 = Vector3.ZERO
	for bone: int in hero.get_bone_count():
		sum += hero.get_bone_global_pose(bone).origin
	return sum / float(maxi(hero.get_bone_count(), 1))

## Turns the whole hero (its root, Hips) by `angle` about `axis` through `pivot`, all in skeleton space.
static func _turn_about(hero: Skeleton3D, axis: Vector3, pivot: Vector3, angle: float) -> void:
	if absf(angle) < 0.000001 or axis.length_squared() < 0.5:
		return
	var hips: int = hero.find_bone("Hips")
	var turn: Quaternion = Quaternion(axis, angle)
	hero.set_bone_pose_rotation(hips, (turn * hero.get_bone_pose_rotation(hips)).normalized())
	hero.set_bone_pose_position(hips, pivot + turn * (hero.get_bone_pose_position(hips) - pivot))

