class_name AuthoredHookMotion
extends RefCounted
## Existing CC0 UAL upper-body gestures over authored gait/jump. No rope authority writes.
## Wall-climb feet are deliberately excluded; actual hero arm lengths bound every grip.
const SOURCES: Array[String] = ["Interact", "Climb_Enter", "Climb_Idle", "Climb_Up", "ClimbLedge", "OverhandThrow", "Roll", "WallRun_Jump_L", "WallRun_Jump_R",
	# Plan 2026-10-07-Living-Body step 2 (ParkourMotion): P1 vault, P4 side wall run, P5 ledge shimmy.
	"SafetyVault", "WallRun_L", "WallRun_R", "Climb_Left", "Climb_Right"]
const SAMPLE_HZ: float = 30.0
const CATCH_SECONDS: float = 0.20 # PLACEHOLDER presentation timing, never an input delay.
const PARKOUR_CATCH_SECONDS: float = 0.12
const REEL_STROKE: float = 0.65 # PLACEHOLDER hand-over-hand cycle in real shortened metres.
const RELEASE_SECONDS: float = 0.14
var catch_seconds: float = CATCH_SECONDS
var reel_stroke: float = 1.2
var source_clip: String = ""
var source_time: float = 0.0
var source_phase: String = "idle"
var grip_error: float = 0.0
var reel_cycle: float = 0.0
var _cache: Dictionary = {}
var _lengths: Dictionary = {}
var _mask: Array[int] = []
var _base: Array[Transform3D] = []
var _last_output: Array[Transform3D] = []
var _release: Array[Transform3D] = []
var _phase: int = -1
var _phase_elapsed: float = 0.0
var _entry_elapsed: float = 0.0
var _release_elapsed: float = RELEASE_SECONDS
var _previous_length: float = 0.0
var _previous_token: int = 0
var _active: bool = false
var _reeling: bool = false
var _reel_mix: float = 0.0
var _grips: Dictionary = {}
var _release_grips: Dictionary = {}
var _recovery: bool = false

func setup(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	for bone: int in skeleton.get_bone_count():
		var name: String = skeleton.get_bone_name(bone)
		if name.begins_with("spine_") or name.begins_with("neck_") or name == "Head" or name.begins_with("clavicle_") or name.begins_with("upperarm_") or name.begins_with("lowerarm_") or name.begins_with("hand_") or name.contains("thumb") or name.contains("index") or name.contains("middle") or name.contains("ring") or name.contains("pinky"):
			_mask.append(bone)
	for source: String in SOURCES:
		var name: String = source if player.has_animation(source) else "ual2/" + source
		if not player.has_animation(name):
			push_error("Missing authored hook source: " + source)
			continue
		var length: float = player.get_animation(name).length
		_lengths[source] = length
		var frames: Array = []
		player.play(name)
		for frame: int in ceili(length * SAMPLE_HZ) + 1:
			skeleton.reset_bone_poses()
			player.seek(minf(float(frame) / SAMPLE_HZ, length), true)
			frames.append(AuthoredLocomotion._poses(skeleton))
		_cache[source] = frames
	player.stop()
	skeleton.reset_bone_poses()

static func grounded_travel(f: Fighter) -> bool:
	return f.state == Fighter.State.GRAPPLE and f.on_ground()

func update(f: Fighter, skeleton: Skeleton3D, delta: float) -> void:
	var hook: GrappleHook = f.grapple
	var phase: int = hook.phase
	catch_seconds = PARKOUR_CATCH_SECONDS if hook._responsive_traversal() else CATCH_SECONDS
	reel_stroke = REEL_STROKE if hook._responsive_traversal() else maxf(hook.reel_distance, 0.001)
	var recovery: bool = GrappleMotion.recovery_active(f)
	var active: bool = f.state == Fighter.State.GRAPPLE or recovery
	if active and not _active:
		_entry_elapsed = 0.0
		_release.clear()
	elif not active and _active:
		_release = _last_output.duplicate()
		_release_elapsed = 0.0
		_release_grips.clear()
		for side: String in _grips:
			_release_grips[side] = Vector3(_grips[side]) - f.global_position
	if not active and f.state not in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.JUMP]:
		_release.clear()
		_release_grips.clear()
	_active = active
	_recovery = recovery
	var grip: Dictionary = hook.presentation_grip()
	var active_token: int = int(grip.get("token", hook.token))
	if phase != _phase or active_token != _previous_token:
		_phase_elapsed = 0.0
		_previous_length = hook.rope_length
		if phase == GrappleHook.Phase.HANG:
			reel_cycle = 0.0
			_reel_mix = 0.0
	else:
		_phase_elapsed += maxf(delta, 0.0)
	_phase = phase
	_previous_token = active_token
	_entry_elapsed += maxf(delta, 0.0)
	# Rope V4: the city hook pulling itself in is the rope carrying the body, drawn as a hang, never a hand-over-hand
	# regrip (8 m/s would spin the cycle at 12 Hz). Only Space beyond the pull advances the cycle.
	_reeling = active and phase == GrappleHook.Phase.HANG and hook.attached and hook.rope_length < _previous_length - 0.00001 and not hook.pulling
	if _reeling:
		# Compact alternating pulls follow real shortening, independently of the total reel budget.
		reel_cycle += (_previous_length - hook.rope_length) / reel_stroke
	_previous_length = hook.rope_length
	_reel_mix = move_toward(_reel_mix, 1.0 if _reeling else 0.0, delta / 0.10)
	if not active:
		_release_elapsed += maxf(delta, 0.0)
		if _release_elapsed >= RELEASE_SECONDS:
			_release.clear()
			_release_grips.clear()
		source_clip = ""
		source_phase = "release" if not _release.is_empty() else "idle"
		return
	if recovery:
		source_clip = "Climb_Up"
		source_time = fposmod(hook.recovery_progress * 2.0, 1.0) * float(_lengths[source_clip])
		source_phase = "recover"
	elif phase == GrappleHook.Phase.WINDUP:
		source_clip = "OverhandThrow"
		source_time = lerpf(0.0, 0.40, hook.windup_progress)
		source_phase = "load_throw"
	elif phase == GrappleHook.Phase.FLIGHT:
		source_clip = "OverhandThrow"
		var progress: float = clampf(hook._flight_distance / maxf(hook._launch_origin.distance_to(hook.anchor_point), 0.001), 0.0, 1.0)
		source_time = lerpf(0.18 if hook.chain_throw else 0.40, 0.80, progress)
		source_phase = "transfer" if hook.chain_throw else "throw"
	elif phase == GrappleHook.Phase.ROPE_REACH:
		source_clip = "Interact"
		source_time = lerpf(0.30, 0.80, clampf(_phase_elapsed / catch_seconds, 0.0, 1.0))
		source_phase = "reach"
	elif phase == GrappleHook.Phase.HANG:
		# ROPE_REACH can be just one tick. Catch has its own presentation clock.
		if _phase_elapsed < catch_seconds:
			source_clip = "Climb_Enter"
			source_time = lerpf(0.25, 0.75, _phase_elapsed / catch_seconds)
			source_phase = "catch"
		else:
			source_clip = "Climb_Idle"
			source_time = fposmod(_phase_elapsed, float(_lengths[source_clip]))
			source_phase = "reel" if _reeling else ("pull" if hook.pulling else "hang")
	else:
		source_clip = ""
		source_phase = "idle"

func restore(skeleton: Skeleton3D) -> void:
	for bone: int in _base.size():
		AuthoredLocomotion._set_pose(skeleton, bone, _base[bone])
	_base.clear()

func _pose(source: String, at: float, bone: int) -> Transform3D:
	var frames: Array = _cache[source]
	var sample: float = clampf(at * SAMPLE_HZ, 0.0, float(frames.size() - 1))
	var a: int = int(sample)
	return frames[a][bone].interpolate_with(frames[mini(a + 1, frames.size() - 1)][bone], sample - float(a))

func apply(skeleton: Skeleton3D, f: Fighter) -> void:
	if not _active:
		if _release.is_empty():
			return
		_base = AuthoredLocomotion._poses(skeleton)
		var t: float = smoothstep(0.0, RELEASE_SECONDS, _release_elapsed)
		for bone: int in _mask:
			AuthoredLocomotion._set_pose(skeleton, bone, _release[bone].interpolate_with(_base[bone], t))
		return
	if source_clip.is_empty() or not _cache.has(source_clip):
		return
	_base = AuthoredLocomotion._poses(skeleton)
	for bone: int in _mask:
		var name: String = skeleton.get_bone_name(bone)
		var torso: bool = name.begins_with("spine_") or name.begins_with("neck_") or name == "Head"
		if torso and _phase == GrappleHook.Phase.HANG and source_phase != "catch" and f.grapple._responsive_traversal():
			continue # Physical rope load owns the torso; authored climbing supplies the arms.
		if _recovery and f.state == Fighter.State.ATTACK and torso:
			continue # Preserve the kicking counterbalance along with hips and legs.
		var pose: Transform3D = _pose(source_clip, source_time, bone)
		if _phase == GrappleHook.Phase.HANG and source_phase != "catch" and _reel_mix > 0.0:
			# Rope load already drives the torso; a wall-climb torso folds into a low rope.
			pose = pose.interpolate_with(_pose("Climb_Up", fposmod(reel_cycle, 1.0) * float(_lengths["Climb_Up"]), bone), _reel_mix)
		# Local source rotation only: no wall-climb roots, translations, or scaled limbs.
		var weight: float = (0.65 if torso else 1.0) * smoothstep(0.0, 0.10, _entry_elapsed)
		var target: Quaternion = pose.basis.orthonormalized().get_rotation_quaternion()
		var base: Quaternion = _base[bone].basis.orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(bone, base.slerp(target, weight))
	_last_output = AuthoredLocomotion._poses(skeleton)

func apply_hands(hero: Skeleton3D, f: Fighter) -> void:
	grip_error = 0.0
	if not _active and _release_grips.is_empty():
		_grips.clear()
		return
	var hook: GrappleHook = f.grapple
	var grip: Dictionary = hook.presentation_grip() if _active else {}
	var targets: Dictionary = {}
	var weight: float = 1.0
	if not _active:
		weight = 1.0 - smoothstep(0.0, RELEASE_SECONDS, _release_elapsed)
		for side: String in _release_grips:
			targets[side] = f.global_position + Vector3(_release_grips[side])
	elif not grip.is_empty():
		var origin: Vector3 = grip.point
		var anchor: Vector3 = hook.anchor_point
		for side: String in ["Right", "Left"]:
			var shoulder: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Arm")).origin
			var elbow: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "ForeArm")).origin
			var hand: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Hand")).origin
			var reach: float = (shoulder.distance_to(elbow) + elbow.distance_to(hand)) * 0.97
			var radial: Vector3 = (anchor - origin).normalized()
			var wanted: Vector3 = shoulder + radial * (0.44 if side == "Right" else 0.31)
			var point: Vector3 = Geometry3D.get_closest_point_to_segment(wanted, origin, anchor) if _phase == GrappleHook.Phase.HANG else origin
			# Sliding alternates hands while actual reel distance advances the source cycle.
			if _phase == GrappleHook.Phase.HANG and _reel_mix > 0.0:
				var bone: int = hero.find_bone(side + "Hand")
				var authored: Vector3 = hero.global_transform * hero.get_bone_global_pose(bone).origin
				# Wall-climb source hands can retract to the chest. A supported rope
				# grip stays beyond the folded forearm, measured from this hero's arm.
				var minimum: float = reach * 0.72 if hook._responsive_traversal() else 0.10
				var maximum: float = reach * 0.95 if hook._responsive_traversal() else 0.55
				var along: float = clampf((authored - shoulder).dot(radial), minimum, maximum)
				var pull: Vector3 = Geometry3D.get_closest_point_to_segment(shoulder + radial * along, origin, anchor)
				point = point.lerp(pull, _reel_mix)
			# Intersect the physical span with this hero's actual arm reach sphere.
			var along_shoulder: float = (shoulder - origin).dot(radial)
			var perpendicular: float = shoulder.distance_squared_to(origin + radial * along_shoulder)
			var budget: float = sqrt(maxf(0.0, reach * reach - perpendicular))
			var lower: float = maxf(0.0, along_shoulder - budget)
			var upper: float = minf(origin.distance_to(anchor), along_shoulder + budget)
			if lower <= upper:
				point = origin + radial * clampf((point - origin).dot(radial), lower, upper)
			else:
				point = Geometry3D.get_closest_point_to_segment(shoulder, origin, anchor)
			targets[side] = point
		weight = smoothstep(0.0, catch_seconds, _phase_elapsed) if source_phase == "catch" else smoothstep(0.0, 0.10, _entry_elapsed)
	elif _phase in [GrappleHook.Phase.WINDUP, GrappleHook.Phase.FLIGHT] or _recovery:
		var endpoint: Vector3 = hook.visual_endpoint() if _recovery else hook.anchor_point
		if _phase == GrappleHook.Phase.WINDUP:
			endpoint = hook.aim_intent.get("point", f.global_position + GrappleHook.HAND + f.forward * 3.0)
		var shoulder: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone("RightArm")).origin
		targets["Right"] = shoulder + (endpoint - shoulder).normalized() * 0.50
		weight = smoothstep(0.55, 1.0, hook.windup_progress) * 0.8 if _phase == GrappleHook.Phase.WINDUP else 0.8
	_grips.clear()
	for side: String in targets:
		var a: int = hero.find_bone(side + "Arm")
		var b: int = hero.find_bone(side + "ForeArm")
		var end: int = hero.find_bone(side + "Hand")
		var original: Array[Quaternion] = [hero.get_bone_pose_rotation(a), hero.get_bone_pose_rotation(b), hero.get_bone_pose_rotation(end)]
		var target: Vector3 = hero.global_transform.affine_inverse() * Vector3(targets[side])
		var wrist_rotation: Quaternion = AuthoredCombatMotion._global_rotation(hero, end)
		var supported_rope: bool = _active and _phase == GrappleHook.Phase.HANG and hook._responsive_traversal()
		if supported_rope:
			weight = 1.0 # A caught rope is a support, including the authored catch gesture.
			# A wall-climb elbow twist is not a rope pull. Keep source regrip targets
			# and wrist orientation, but solve the supported arms from their rest plane.
			for bone: int in [a, b]:
				hero.set_bone_pose_rotation(bone, hero.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion())
		AuthoredCombatMotion._solve_chain(hero, a, b, end, target)
		if supported_rope:
			AuthoredCombatMotion._set_global_rotation(hero, end, wrist_rotation)
		for index: int in 3:
			var bone: int = [a, b, end][index]
			hero.set_bone_pose_rotation(bone, original[index].slerp(hero.get_bone_pose_rotation(bone), weight))
		var hand: Vector3 = hero.global_transform * hero.get_bone_global_pose(end).origin
		_grips[side] = hand
		if not grip.is_empty() and weight >= 0.999:
			grip_error = maxf(grip_error, hand.distance_to(Vector3(targets[side])))
