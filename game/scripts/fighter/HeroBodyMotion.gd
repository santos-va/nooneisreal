class_name HeroBodyMotion
extends RefCounted
## Ordered whole-body presentation: physical balance, authored gaze, neutral transitions.
## All rates/limits are PLACEHOLDER art constraints, never Fighter authority.
const NEUTRAL_BLEND: float = 0.24
const BODY_TURN_RATE: float = 420.0
const GAZE_TURN_RATE: float = 480.0
## Plan docs/Plans/2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall.md steps 2–3 (T6 review on 595490d). A course more
## than PIVOT_FROM off the drawn body (a reverse) turns the body at PIVOT_TURN_RATE until it faces the course, and the
## legs are chosen for that drawn body (drawn_forward() → AuthoredLocomotion.update), so they stop backpedalling at
## 4.9 m/s. A wall kick turns the body in the air at AIR_TURN_RATE instead of 160° in one tick, and the hero pose
## crossfades from the hang it left over KICK_BLEND (the hands let go of the ledge 154°/tick otherwise). PLACEHOLDER.
const PIVOT_TURN_RATE: float = 720.0 # °/s: 12°/tick, a reverse in 15 ticks
const PIVOT_FROM: float = 100.0      # degrees
const AIR_TURN_RATE: float = 600.0   # °/s: 10°/tick, the 160° wall kick in 16 ticks (at 15°/tick a bone turned 35°/tick)
const KICK_BLEND: float = 0.25       # seconds
## Variables only so a check can put the product of 595490d back (anim_ground_check --break=legs / kick).
var pivot_turn_rate: float = PIVOT_TURN_RATE
var air_turn_rate: float = AIR_TURN_RATE
var kick_blend: float = KICK_BLEND
var legs_follow_body: bool = true
## --break=memory control of anim_ground_check: false remembers the kick's pose inside finish_pose, before TraversalBlend
## draws its blend (as the merge of branches A and B first did).
var remember_drawn: bool = true
## SkeletalRig sets it each tick: the pivot and the legs for the drawn body are for a hero walking the city only.
var pivot_enabled: bool = false
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
var _pivot: bool = false
var _air_turn: bool = false
var _spine_catching: Dictionary = {}
var _kicked: bool = false
var _kick_from: Array[Quaternion] = []
var _kick_hips: Quaternion = Quaternion.IDENTITY
var _kick_offset: Vector3 = Vector3.ZERO
var _kick_elapsed: float = KICK_BLEND
var _kick_aligned: Array[Quaternion] = []
var _kick_signs_serial: int = -1
var _last_rotations: Array[Quaternion] = []
var _last_hips: Quaternion = Quaternion.IDENTITY
var _last_offset: Vector3 = Vector3.ZERO
var _last_serial: int = -1
var _hips: int = -1

func setup(hero: Skeleton3D, source: Skeleton3D) -> void:
	_hips = hero.find_bone("Hips")
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
	_spine_catching.clear()
	_pivot = false
	_air_turn = false
	_kicked = false
	_kick_from.clear()
	_kick_elapsed = KICK_BLEND
	_last_serial = -1

## The heading the body is drawn at this tick (forward of `_heading`, Fighter.yaw()'s convention) while a pivot turns
## it; ZERO otherwise — an ordinary turn keeps the legs on the gameplay course, whose footfalls the frozen contact
## windows of tools/animation/ground_contact_check.gd are measured on — and when the legs follow the course (--break=legs).
func drawn_forward() -> Vector3:
	if not _valid or not legs_follow_body or not _pivot:
		return Vector3.ZERO
	return Vector3(cos(_heading), 0.0, -sin(_heading))

## True while the drawn body is still turning toward the course on the ground (HeroGroundContact holds low feet then).
func turning() -> bool:
	return _valid and absf(_yaw_offset) > deg_to_rad(3.0)

static func neutral(state: int) -> bool:
	return state in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK, Fighter.State.SWAP]

func update(f: Fighter, delta: float, velocity: Vector3, acceleration: Vector3) -> void:
	serial += 1
	_dt = maxf(delta, 0.0)
	_velocity = velocity
	_acceleration = acceleration
	# A wall kick turns the course in the air (CityParkourMotor._try_kick); the body follows it until it faces it.
	var snapshot: Variant = f.get_meta("parkour_presentation", {})   # any Variant: ParkourMotion.valid_snapshot's rule
	var kicked: bool = f.state == Fighter.State.JUMP and snapshot is Dictionary and str((snapshot as Dictionary).get("phase", "")) == "wall_kick"
	_air_turn = air_turn_rate > 0.0 and _valid and f.state == Fighter.State.JUMP and (kicked or _air_turn)
	var allowed: bool = neutral(f.state) or (f.state == Fighter.State.GRAPPLE and f.on_ground()) or _air_turn
	if not _valid or not allowed:
		_heading = f.yaw()
		_valid = true
		_pivot = false
	else:
		var off: float = wrapf(f.yaw() - _heading, -PI, PI)
		_pivot = pivot_enabled and pivot_turn_rate > BODY_TURN_RATE and neutral(f.state) and (absf(off) > deg_to_rad(PIVOT_FROM) or (_pivot and absf(off) > 0.001))
		var rate: float = air_turn_rate if _air_turn else (pivot_turn_rate if _pivot else BODY_TURN_RATE)
		_heading += clampf(off, -deg_to_rad(rate) * _dt, deg_to_rad(rate) * _dt)
	_yaw_offset = wrapf(_heading - f.yaw(), -PI, PI) if allowed else 0.0
	if _air_turn and absf(_yaw_offset) <= 0.001 and not kicked:
		_air_turn = false
	# The kick's first tick crossfades from the pose drawn on the tick before it (remember_pose keeps it).
	if kicked and not _kicked and kick_blend > 0.0 and _last_serial == serial - 1:
		_kick_from = _last_rotations.duplicate()
		_kick_hips = _last_hips
		_kick_offset = _last_offset
		_kick_elapsed = 0.0
	elif f.state != Fighter.State.JUMP:
		_kick_elapsed = KICK_BLEND
		_kick_from.clear()
	elif _kick_elapsed < kick_blend:
		_kick_elapsed += _dt
	_kicked = kicked
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
				# Step 2 of plan 2026-10-09: the chest keeps up with a pivot and, once the turn has settled, catches up at
				# the same bounded rate instead of jumping the rest of the way (32.7°/tick at the end of a reverse).
				var limit: float = maxf(10.0, pivot_turn_rate / 60.0 + 2.0) if _pivot else 10.0
				if (_turn_settle > 0.0 or _spine_catching.has(name)) and _spine_previous.has(name):
					var previous: Quaternion = _spine_previous[name]
					var angle: float = previous.angle_to(world)
					var step: float = deg_to_rad(limit) * 60.0 * _dt
					world = previous.slerp(world, minf(1.0, step / maxf(angle, 0.000001)))
					if angle > step and pivot_enabled and pivot_turn_rate > BODY_TURN_RATE:
						_spine_catching[name] = true
					else:
						_spine_catching.erase(name)
				_spine_frame[name] = world
				_spine_previous[name] = world
			elif _spine_frame.has(name):
				world = _spine_frame[name]
			AuthoredCombatMotion._set_global_rotation(hero, bone, hero.global_basis.orthonormalized().get_rotation_quaternion().inverse() * world)
		_balance_serial = serial
	else:
		_spine_previous.clear()
		_spine_frame.clear()
		_spine_catching.clear()
	if balance_weight <= 0.00001:
		return
	# The whole hanging chain responds to support/load. No cycling Jump_Loop knees.
	var radial: Vector3 = (f.grapple.anchor_point - (f.global_position + GrappleHook.HAND)).normalized()
	var tangent: Vector3 = _velocity.slide(radial)
	# City rope (plan 2026-10-09-Animation-Feel step 4): the body hangs along the rope — T6 measured it at 12–16° while
	# the rope stood at 33–54° (the 0.28 lean of the duel rope tops out at 15.6°) — and the legs trail the swing.
	var follow: bool = rope_follow and f.grapple._responsive_traversal()
	var desired_up: Vector3 = _rope_body_up(radial) if follow else (Vector3.UP + Vector3(radial.x, 0.0, radial.z) * 0.28).normalized()
	var turn: Quaternion = Quaternion(Vector3.UP, desired_up)
	var axis_world: Vector3 = turn.get_axis()
	# The rope takes the body in half the hang ramp; the catch blend (TraversalBlend) spreads it over the catch.
	var lean: float = smoothstep(0.0, 0.5, balance_weight) if follow else balance_weight
	if turn.get_angle() > 0.00001:
		_rotate_world(hero, hips, axis_world, turn.get_angle() * lean)
		if not follow:
			_rotate_world(hero, hero.find_bone("Spine"), axis_world, -turn.get_angle() * balance_weight * 0.30)
	var rest: Vector3 = hero.get_bone_rest(hips).origin
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips).lerp(rest, balance_weight))
	var trail: Vector3 = Vector3(tangent.x, 0.0, tangent.z).limit_length(7.0) * 0.025
	var hang: Vector3 = _rope_legs(desired_up, f) if follow else Vector3.DOWN
	for side: String in ["Left", "Right"]:
		var a: int = hero.find_bone(side + "UpLeg")
		var b: int = hero.find_bone(side + "Leg")
		var end: int = hero.find_bone(side + "Foot")
		var hip: Vector3 = hero.global_transform * hero.get_bone_global_pose(a).origin
		var knee: Vector3 = hero.global_transform * hero.get_bone_global_pose(b).origin
		var foot: Vector3 = hero.global_transform * hero.get_bone_global_pose(end).origin
		var length: float = hip.distance_to(knee) + knee.distance_to(foot)
		var target: Vector3 = hip + hang * length * 0.94 - (Vector3.ZERO if follow else trail)
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

## Near-last step of the hero pose (SkeletalRig.retarget): the wall kick's crossfade from the pose it left. The pose
## drawn this tick is remembered for a kick on the next tick by remember_pose(), after TraversalBlend has drawn its own
## blend (merge of branches A and B). A repeat call in the same tick gives the same pose.
## The hips are blended in the frame of the drawn heading: the course itself turns at AIR_TURN_RATE (update()), so the
## crossfade carries only the pose, never the turn a second time.
func finish_pose(hero: Skeleton3D, f: Fighter) -> void:
	if hero == null or _hips < 0:
		return
	var heading := Quaternion(Vector3.UP, _heading)
	var node: Quaternion = hero.global_basis.orthonormalized().get_rotation_quaternion()
	var parent: int = hero.get_bone_parent(_hips)
	var parent_rotation: Quaternion = node * (hero.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY)
	if not _kick_from.is_empty() and _kick_elapsed < kick_blend and _kick_from.size() == hero.get_bone_count():
		# A crossfade from the pose left toward the kick's moving pose. The target keeps the sign it had on the tick before
		# and slerpni never re-picks the short arc, so no bone flips to the other way round mid-blend.
		var weight: float = smoothstep(0.0, kick_blend, _kick_elapsed)
		var parent_transform: Transform3D = hero.global_transform * (hero.get_bone_global_pose(parent) if parent >= 0 else Transform3D.IDENTITY)
		var offset: Vector3 = heading.inverse() * (hero.global_transform * hero.get_bone_global_pose(_hips).origin - f.global_position)
		var from: Array[Quaternion] = _kick_from.duplicate()
		from[_hips] = _kick_hips
		var targets: Array[Quaternion] = []
		for bone: int in hero.get_bone_count():
			targets.append(heading.inverse() * parent_rotation * hero.get_bone_pose_rotation(bone) if bone == _hips else hero.get_bone_pose_rotation(bone))
		if _kick_elapsed <= 0.0 or _kick_aligned.size() != targets.size():
			_kick_aligned = from.duplicate()   # the first tick takes the short arc from the pose left
		for bone: int in targets.size():
			if targets[bone].dot(_kick_aligned[bone]) < 0.0:
				targets[bone] = -targets[bone]
		if _kick_signs_serial != serial:
			_kick_aligned = targets.duplicate()
			_kick_signs_serial = serial
		for bone: int in targets.size():
			var blended: Quaternion = from[bone].slerpni(targets[bone], weight).normalized()
			hero.set_bone_pose_rotation(bone, (parent_rotation.inverse() * heading * blended).normalized() if bone == _hips else blended)
		hero.set_bone_pose_position(_hips, parent_transform.affine_inverse() * (f.global_position + heading * _kick_offset.lerp(offset, weight)))
	if not remember_drawn:
		_remember(hero, f, heading, parent_rotation)

## Last step of the hero pose: in the air only, the pose drawn this tick — after TraversalBlend — remembered for a kick on
## the next tick. Taken before TraversalBlend (as the merge first did), a kick 4 ticks after catching the ledge crossfaded
## from a hang pose that blend had not drawn yet: 95.5° (Choko) / 70.3° (Skea) on a hand in the kick's first tick.
func remember_pose(hero: Skeleton3D, f: Fighter) -> void:
	if hero == null or _hips < 0 or not remember_drawn:
		return
	var node: Quaternion = hero.global_basis.orthonormalized().get_rotation_quaternion()
	var parent: int = hero.get_bone_parent(_hips)
	var parent_rotation: Quaternion = node * (hero.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY)
	_remember(hero, f, Quaternion(Vector3.UP, _heading), parent_rotation)

func _remember(hero: Skeleton3D, f: Fighter, heading: Quaternion, parent_rotation: Quaternion) -> void:
	if f.state == Fighter.State.JUMP:
		_last_rotations.resize(hero.get_bone_count())
		for bone: int in hero.get_bone_count():
			_last_rotations[bone] = hero.get_bone_pose_rotation(bone)
		_last_hips = heading.inverse() * parent_rotation * hero.get_bone_pose_rotation(_hips)
		_last_offset = heading.inverse() * (hero.global_transform * hero.get_bone_global_pose(_hips).origin - f.global_position)
		_last_serial = serial

static func _rotate_world(hero: Skeleton3D, bone: int, axis: Vector3, angle: float) -> void:
	var local: Vector3 = (hero.global_basis.inverse() * axis).normalized()
	AuthoredCombatMotion._set_global_rotation(hero, bone, Quaternion(local, angle) * AuthoredCombatMotion._global_rotation(hero, bone))


# ── City rope pose (plan 2026-10-09-Animation-Feel-Landing-Rope-Stop-Wall step 4, branch B). PLACEHOLDER art values. ──
## --break control of tools/animation/anim_traversal_check.gd: false draws the duel's 0.28 lean (main 595490d).
var rope_follow: bool = true
## The steepest the body leans along a rope; past it (the hero swung above the anchor) it stays at this angle.
const ROPE_MAX_LEAN: float = 75.0 * PI / 180.0
## The legs follow the rope line as a damped pendulum of their own: they trail the swing and overshoot a little when
## it turns (the live weight), instead of hanging straight down from a leaning body.
const LEG_FREQUENCY: float = 9.0 # rad/s
const LEG_DAMPING: float = 0.55
var _leg_dir: Vector3 = Vector3.ZERO
var _leg_speed: Vector3 = Vector3.ZERO
var _leg_serial: int = -1

## The body's up axis on the rope: along the rope, never leaning past ROPE_MAX_LEAN.
func _rope_body_up(radial: Vector3) -> Vector3:
	var angle: float = radial.angle_to(Vector3.UP)
	if angle <= ROPE_MAX_LEAN or angle < 0.00001:
		return radial
	return Vector3.UP.slerp(radial, ROPE_MAX_LEAN / angle).normalized()

## Where the legs point this tick: a spring toward −body_up, advanced once per physics tick (a repeated render reuses it).
func _rope_legs(body_up: Vector3, f: Fighter) -> Vector3:
	var wanted: Vector3 = -body_up
	if _leg_serial != serial:
		if _leg_dir.is_zero_approx() or balance_weight < 0.05 or not f.grapple.attached:
			_leg_dir = wanted
			_leg_speed = Vector3.ZERO
		else:
			var pull: Vector3 = (wanted - _leg_dir) * LEG_FREQUENCY * LEG_FREQUENCY - _leg_speed * 2.0 * LEG_DAMPING * LEG_FREQUENCY
			_leg_speed += pull * _dt
			_leg_dir = (_leg_dir + _leg_speed * _dt).normalized()
		_leg_serial = serial
	return _leg_dir

