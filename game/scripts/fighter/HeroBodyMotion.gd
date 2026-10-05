class_name HeroBodyMotion
extends RefCounted
## Ordered whole-body presentation: physical balance, authored gaze, neutral transitions.
## All rates/limits are PLACEHOLDER art constraints, never Fighter authority.
const NEUTRAL_BLEND: float = 0.24
const BODY_TURN_RATE: float = 420.0
const GAZE_TURN_RATE: float = 480.0
var serial: int = 0
var gaze_pitch: float = 0.0
var balance_weight: float = 0.0
var _dt: float = 0.0
var _heading: float = 0.0
var _yaw_offset: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
var _acceleration: Vector3 = Vector3.ZERO
var _lean: Vector3 = Vector3.ZERO
var _valid: bool = false
var _gaze: Vector3 = Vector3.ZERO
var _gaze_serial: int = -1
var _balance_serial: int = -1
var _turn_settle: float = 0.0
var _spine_previous: Dictionary = {}
var _spine_frame: Dictionary = {}
var _head: int = -1
var _neck: int = -1
var _front: int = -1
var _source_head: int = -1
var _source_rest: Quaternion
var _source_state: int = -1
var _transition_from: Array[Transform3D] = []
var _source_base: Array[Transform3D] = []
var _transition_elapsed: float = NEUTRAL_BLEND

func setup(hero: Skeleton3D, source: Skeleton3D) -> void:
	_head = hero.find_bone("Head")
	_neck = hero.find_bone("neck")
	_front = hero.find_bone("headfront")
	_source_head = source.find_bone("Head")
	_source_rest = source.get_bone_global_rest(_source_head).basis.orthonormalized().get_rotation_quaternion()

func reset() -> void:
	_valid = false
	_gaze = Vector3.ZERO
	_lean = Vector3.ZERO
	_yaw_offset = 0.0
	balance_weight = 0.0
	_transition_from.clear()
	_source_state = -1
	_gaze_serial = -1
	_balance_serial = -1
	_turn_settle = 0.0
	_spine_previous.clear()
	_spine_frame.clear()

static func neutral(state: int) -> bool:
	return state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK, Fighter.State.SWAP]

func update(f: Fighter, delta: float, velocity: Vector3, acceleration: Vector3) -> void:
	serial += 1
	_dt = maxf(delta, 0.0)
	_velocity = velocity
	_acceleration = acceleration
	var allowed: bool = neutral(f.state) or (f.state == Fighter.State.GRAPPLE and f.on_ground())
	if not _valid or not allowed:
		_heading = f.yaw()
		_valid = true
	else:
		_heading += clampf(wrapf(f.yaw() - _heading, -PI, PI), -deg_to_rad(BODY_TURN_RATE) * _dt, deg_to_rad(BODY_TURN_RATE) * _dt)
	_yaw_offset = wrapf(_heading - f.yaw(), -PI, PI) if allowed else 0.0
	_turn_settle = 0.20 if absf(_yaw_offset) > 0.001 else maxf(0.0, _turn_settle - _dt)
	var target_lean: Vector3 = Vector3(acceleration.x, 0, acceleration.z).limit_length(18.0) * (deg_to_rad(6.0) / 18.0) if allowed else Vector3.ZERO
	_lean = _lean.lerp(target_lean, 1.0 - exp(-_dt / 0.08))
	var hanging: bool = f.state == Fighter.State.GRAPPLE and f.grapple.attached and not f.on_ground()
	balance_weight = move_toward(balance_weight, 1.0 if hanging else 0.0, _dt / 0.16)
	if f.state not in [Fighter.State.GRAPPLE, Fighter.State.JUMP, Fighter.State.IDLE, Fighter.State.WALK]:
		balance_weight = 0.0

func prepare_source(source: Skeleton3D, f: Fighter) -> void:
	if f.state != _source_state:
		if neutral(f.state) and neutral(_source_state) and not (f.state in [Fighter.State.IDLE, Fighter.State.WALK] and _source_state in [Fighter.State.IDLE, Fighter.State.WALK]):
			_transition_from = AuthoredLocomotion._poses(source)
			_transition_elapsed = 0.0
		else:
			_transition_from.clear()
	_source_state = f.state

func restore_source(source: Skeleton3D) -> void:
	for bone: int in _source_base.size():
		AuthoredLocomotion._set_pose(source, bone, _source_base[bone])
	_source_base.clear()

func apply_source(source: Skeleton3D) -> void:
	if _transition_from.is_empty():
		return
	_transition_elapsed += _dt
	if _transition_elapsed >= NEUTRAL_BLEND:
		_transition_from.clear()
		return
	_source_base = AuthoredLocomotion._poses(source)
	var weight: float = smoothstep(0.0, NEUTRAL_BLEND, _transition_elapsed)
	for bone: int in _source_base.size():
		AuthoredLocomotion._set_pose(source, bone, _transition_from[bone].interpolate_with(_source_base[bone], weight))

func apply_balance(hero: Skeleton3D, f: Fighter) -> void:
	var hips: int = hero.find_bone("Hips")
	if absf(_yaw_offset) > 0.00001:
		_rotate_world(hero, hips, Vector3.UP, _yaw_offset)
		var lead: float = clampf(-_yaw_offset * 0.36, -deg_to_rad(4.0), deg_to_rad(4.0))
		_rotate_world(hero, hero.find_bone("Spine02"), Vector3.UP, lead * 0.5)
		_rotate_world(hero, hero.find_bone("Spine"), Vector3.UP, lead * 0.5)
	if neutral(f.state) and _lean.length_squared() > 0.000001:
		var axis: Vector3 = Vector3.UP.cross(_lean).normalized()
		_rotate_world(hero, hero.find_bone("Spine02"), axis, _lean.length() * 0.55)
		_rotate_world(hero, hero.find_bone("Spine"), axis, _lean.length() * 0.45)
	# Directional gait clips and visual heading settle together. Bound only the
	# neutral turn, never an attack/reaction or the authored steady gait arc.
	if neutral(f.state):
		var fresh: bool = _balance_serial != serial
		for name: String in ["Spine02", "Spine01", "Spine"]:
			var bone: int = hero.find_bone(name)
			var world: Quaternion = (hero.global_basis.orthonormalized() * hero.get_bone_global_pose(bone).basis.orthonormalized()).get_rotation_quaternion()
			if fresh:
				if _turn_settle > 0.0 and _spine_previous.has(name):
					var previous: Quaternion = _spine_previous[name]
					var angle: float = previous.angle_to(world)
					world = previous.slerp(world, minf(1.0, deg_to_rad(10.0) * 60.0 * _dt / maxf(angle, 0.000001)))
				_spine_frame[name] = world
				_spine_previous[name] = world
			elif _spine_frame.has(name):
				world = _spine_frame[name]
			AuthoredCombatMotion._set_global_rotation(hero, bone, hero.global_basis.orthonormalized().get_rotation_quaternion().inverse() * world)
		_balance_serial = serial
	else:
		_spine_previous.clear()
		_spine_frame.clear()
	if balance_weight <= 0.00001:
		return
	# The whole hanging chain responds to support/load. No cycling Jump_Loop knees.
	var radial: Vector3 = (f.grapple.anchor_point - (f.global_position + GrappleHook.HAND)).normalized()
	var tangent: Vector3 = _velocity.slide(radial)
	var desired_up: Vector3 = (Vector3.UP + Vector3(radial.x, 0.0, radial.z) * 0.28).normalized()
	var turn: Quaternion = Quaternion(Vector3.UP, desired_up)
	var axis_world: Vector3 = turn.get_axis()
	if turn.get_angle() > 0.00001:
		_rotate_world(hero, hips, axis_world, turn.get_angle() * balance_weight)
		_rotate_world(hero, hero.find_bone("Spine"), axis_world, -turn.get_angle() * balance_weight * 0.30)
	var rest: Vector3 = hero.get_bone_rest(hips).origin
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips).lerp(rest, balance_weight))
	var trail: Vector3 = Vector3(tangent.x, 0.0, tangent.z).limit_length(7.0) * 0.025
	for side: String in ["Left", "Right"]:
		var a: int = hero.find_bone(side + "UpLeg")
		var b: int = hero.find_bone(side + "Leg")
		var end: int = hero.find_bone(side + "Foot")
		var hip: Vector3 = hero.global_transform * hero.get_bone_global_pose(a).origin
		var knee: Vector3 = hero.global_transform * hero.get_bone_global_pose(b).origin
		var foot: Vector3 = hero.global_transform * hero.get_bone_global_pose(end).origin
		var length: float = hip.distance_to(knee) + knee.distance_to(foot)
		var target: Vector3 = hip + Vector3.DOWN * length * 0.94 - trail
		target = foot.lerp(target, balance_weight)
		AuthoredCombatMotion._solve_chain(hero, a, b, end, hero.global_transform.affine_inverse() * target)

func apply_gaze(hero: Skeleton3D, source: Skeleton3D, f: Fighter, ragdoll: BoneRagdoll) -> void:
	if ragdoll != null or f.state in [Fighter.State.HITSTUN, Fighter.State.STUMBLE, Fighter.State.LAUNCHED, Fighter.State.KNOCKDOWN, Fighter.State.WALL_SPLAT, Fighter.State.GETUP, Fighter.State.KO] or RigAnimator.levitating(f):
		_gaze = Vector3.ZERO
		return
	if _gaze_serial != serial:
		# Source face is +Z at rest. Hero headfront supplies its real face axis below;
		# unlike inherited neck alignment this removes the measured ~15 degree bias.
		var delta: Quaternion = source.get_bone_global_pose(_source_head).basis.orthonormalized().get_rotation_quaternion() * _source_rest.inverse()
		var authored: Vector3 = (hero.global_basis * (delta * Vector3.BACK)).normalized()
		var pitch: float = asin(clampf(authored.y, -1.0, 1.0))
		# A soft anatomical response keeps the source derivative instead of clamping
		# every jab/lowhand frame to the identical -20 degree world-space plateau.
		gaze_pitch = deg_to_rad(-7.0) + deg_to_rad(12.0) * tanh(pitch / deg_to_rad(45.0))
		var flat: Vector3 = Vector3(authored.x, 0.0, authored.z).normalized()
		var desired: Vector3 = flat * cos(gaze_pitch) + Vector3.UP * sin(gaze_pitch)
		if f.state == Fighter.State.GRAPPLE and f.grapple.attached:
			var head: Vector3 = hero.global_transform * hero.get_bone_global_pose(_head).origin
			desired = desired.slerp((f.grapple.anchor_point - head).normalized(), 0.30)
		var fast: bool = f.state == Fighter.State.ATTACK or f.dodging
		if _gaze.is_zero_approx() or fast:
			_gaze = desired
		else:
			var angle: float = _gaze.angle_to(desired)
			_gaze = _gaze.slerp(desired, minf(1.0, deg_to_rad(GAZE_TURN_RATE) * _dt / maxf(angle, 0.000001)))
		_gaze_serial = serial
	var direction: Vector3 = (hero.get_bone_global_pose(_front).origin - hero.get_bone_global_pose(_head).origin).normalized()
	var wanted: Vector3 = (hero.global_basis.inverse() * _gaze).normalized()
	var correction: Quaternion = Quaternion(direction, wanted)
	AuthoredCombatMotion._set_global_rotation(hero, _neck, Quaternion.IDENTITY.slerp(correction, 0.40) * AuthoredCombatMotion._global_rotation(hero, _neck))
	direction = (hero.get_bone_global_pose(_front).origin - hero.get_bone_global_pose(_head).origin).normalized()
	AuthoredCombatMotion._set_global_rotation(hero, _head, Quaternion(direction, wanted) * AuthoredCombatMotion._global_rotation(hero, _head))

static func _rotate_world(hero: Skeleton3D, bone: int, axis: Vector3, angle: float) -> void:
	var local: Vector3 = (hero.global_basis.inverse() * axis).normalized()
	AuthoredCombatMotion._set_global_rotation(hero, bone, Quaternion(local, angle) * AuthoredCombatMotion._global_rotation(hero, bone))
