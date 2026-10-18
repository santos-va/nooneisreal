class_name AuthoredHookMotion
extends RefCounted
## Existing CC0 UAL upper-body gestures over authored gait/jump. No rope authority writes.
## Wall-climb feet are deliberately excluded; actual hero arm lengths bound every grip.
const SOURCES: Array[String] = ["Interact", "Climb_Enter", "Climb_Idle", "Climb_Up", "ClimbLedge", "OverhandThrow", "Roll", "WallRun_Jump_L", "WallRun_Jump_R",
	# Plan 2026-10-07-Living-Body step 2 (ParkourMotion): P1 vault, P4 side wall run, P5 ledge shimmy.
	"SafetyVault", "WallRun_L", "WallRun_R", "Climb_Left", "Climb_Right",
	# ADR-028 (T6 docs/Art/2026-10-15-Rope-Climb-Animation.md § 5): the reel of a left rope, hands together at the waist.
	"Fish_Reel"]
const SAMPLE_HZ: float = 30.0
const CATCH_SECONDS: float = 0.20 # PLACEHOLDER presentation timing, never an input delay.
const PARKOUR_CATCH_SECONDS: float = 0.12
const REEL_STROKE: float = 0.65 # PLACEHOLDER hand-over-hand cycle in real shortened metres.
const RELEASE_SECONDS: float = 0.14
## The city rope (ADR-028; T6 docs/Art/2026-10-15-Rope-Climb-Animation.md, all PLACEHOLDER until T6 accepts game frames):
## while climbing or sliding the hands hold a line ROPE_AHEAD in front of the shoulders, the slide's hands stay one over the
## other at SLIDE_HANDS, and the feet clamp the line: FOOT_SIDE either side of it, FOOT_BEHIND behind it, between FOOT_LOW
## and FOOT_HIGH over the feet's rest point in phase with the regrip (the slide: SLIDE_FEET, 0.07 apart). The climb's hands
## take row Г's stroke (CLIMB_HAND_LOW…CLIMB_HAND_HIGH over the shoulder) at CLIMB_CADENCE_HZ, the elbow on a pole
## (T6 acceptance 2026-10-15 § 9 п. 1; docs/Fix/2026-10-15-Rope-Perch-Entry-Fix.md).
const ROPE_AHEAD: float = 0.14
const SLIDE_HANDS := {"Right": 0.30, "Left": 0.18}
const FOOT_SIDE: float = 0.05
const FOOT_BEHIND: float = 0.06
const FOOT_LOW: float = 0.24
const FOOT_HIGH: float = 0.46
const SLIDE_FEET := {"Right": 0.37, "Left": 0.30}
## The grip on an anchor's arm: the wrists 0.04 m over the arm's middle line (T6 § 3: point + 0.34).
const PERCH_WRIST: float = 0.04
## T6 acceptance 2026-10-15 § 9 п. 2: the rope's top → the pull-up is handed over here, not by TraversalBlend (which kept
## the rope's lean for the first ticks): the hands start where they were drawn and the authored arms crossfade over
## HANDOVER_SECONDS. PLACEHOLDER.
const HANDOVER_SECONDS: float = 0.12
## T6 acceptance 2026-10-15 § 9 п. 1 (row Г of docs/Art/2026-10-15-Rope-Climb-Animation.md): the city climb's drawn cycle
## is capped at CLIMB_CADENCE_HZ, unbound from the real shortening (3.6 m/s over REEL_STROKE spun it at 5.5 Hz); the hands
## take turns between CLIMB_HAND_LOW and CLIMB_HAND_HIGH over the shoulder on the rope's line (the elbow pole keeps the
## forearm from flipping, see _elbow_pole), changing places every half cycle; the feet clamp in phase, both together, one
## «knees up → legs straight» a cycle (the caterpillar). The climb's speed (T5 3.6 m/s) is not touched. PLACEHOLDER (T6).
const CLIMB_CADENCE_HZ: float = 2.0
const CLIMB_HAND_LOW: float = 0.02
const CLIMB_HAND_HIGH: float = 0.30
## --break controls of tools/grapple/rope_climb_check.gd: `cadence` (0: the cycle follows the shortening again, 5.5 Hz),
## `stroke` (false: the hands kept on the rope by the reach clamp, ±0.02 m), `antiphase` (false: the feet half a cycle apart).
var climb_cadence_hz: float = CLIMB_CADENCE_HZ
## --break control of rope_climb_check (`two_hands`): false keeps both hands on the arm through a shot from the grip (15а).
var one_hand_throw: bool = true
var climb_stroke: bool = true
var feet_in_phase: bool = true
## The pull-up's and the grip's hands stay within this share of the arm's reach (see apply_hands). PLACEHOLDER.
const PERCH_REACH: float = 0.97
## T6 § 9 п. 1: the elbow of an arm holding the city rope or an anchor's arm bends toward the body's side, a little back and
## down (as _solve_leg's knee toward the body's forward): the rest-plane solve flipped the forearm 60–178°/tick when the hand
## passed the line of the rest upper arm. While the feet clamp the rope (climb, slide: _clamp_mix) the hands reach across
## the chest to its line, which stands nearly opposite an outward-and-back pole — there the elbow goes outward and a little
## forward instead (ELBOW_CLIMB, square to both that reach and a hand straight up), and stays so through the pull-up; the
## pole turns between the two over ELBOW_TURN_SECONDS. PLACEHOLDER weights: outward, back, down.
const ELBOW_HANG := Vector3(1.0, 0.5, 0.3)
const ELBOW_CLIMB := Vector3(1.0, -0.6, 0.2)
const ELBOW_TURN_SECONDS: float = 0.3
## The city rope's arm bones turn at most this much a tick from the arm drawn on the tick before (the upper arm's and the
## forearm's rotation in skeleton space, the authored shoulder under them included): where a hand's path crosses close to
## its shoulder the elbow changes sides, and this spreads it over a few ticks — the hand lags its target for them.
## PLACEHOLDER.
const ARM_TURN_CAP: float = 14.0 * PI / 180.0
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
var _clamp_mix: float = 0.0
var _slide_mix: float = 0.0
var _handover_from: Array[Transform3D] = []
var _handover_elapsed: float = HANDOVER_SECONDS
var _top_from: Dictionary = {}
var _arm_memory: Dictionary = {}
## The arms as solved on the tick before (taken from _arm_memory once per physics tick, in update()): a repeated render of
## the same tick starts from the same arms and draws the same pose.
var _arm_previous: Dictionary = {}
## --break control of tools/grapple/rope_climb_check.gd (`elbow`): false solves every tick from the rest pose again.
var arm_continuity: bool = true
var _grips_origin: Vector3 = Vector3.ZERO
var _pole_mix: float = 0.0
## T6 acceptance 2026-10-15 § 9 п. 7: the shot from the grip — the hand on the target's side lets go of the arm and throws
## (OverhandThrow on that arm only), the other keeps the arm. "" — none.
var throw_side: String = ""
var _throw_time: float = 0.0

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
	var previous_phase: String = source_phase
	throw_side = ""
	_arm_previous = _arm_memory.duplicate()
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
		var advance: float = (_previous_length - hook.rope_length) / reel_stroke
		if hook.climb_enabled and climb_cadence_hz > 0.0:
			advance = minf(advance, climb_cadence_hz * maxf(delta, 0.0)) # the city climb's cadence cap (T6 § 9 п. 1)
		reel_cycle += advance
	_previous_length = hook.rope_length
	_reel_mix = move_toward(_reel_mix, 1.0 if _reeling else 0.0, delta / 0.10)
	var city_rope: bool = active and hook.climb_enabled and phase == GrappleHook.Phase.HANG and hook.attached
	_clamp_mix = move_toward(_clamp_mix, 1.0 if city_rope and (hook.climbing or hook.sliding) else 0.0, delta / 0.10)
	_slide_mix = move_toward(_slide_mix, 1.0 if city_rope and hook.sliding else 0.0, delta / 0.10)
	var climb_pole: bool = (city_rope and (hook.climbing or hook.sliding)) or (active and phase == GrappleHook.Phase.CLIMB_TOP)
	_pole_mix = move_toward(_pole_mix, 1.0 if climb_pole else 0.0, delta / ELBOW_TURN_SECONDS)
	if not active:
		_release_elapsed += maxf(delta, 0.0)
		if _release_elapsed >= RELEASE_SECONDS:
			_release.clear()
			_release_grips.clear()
		source_clip = ""
		source_phase = "release" if not _release.is_empty() else "idle"
		_track_handover(f, previous_phase, delta)
		return
	if recovery and hook.reeling_in and _lengths.has("Fish_Reel"):
		source_clip = "Fish_Reel"
		source_time = fposmod(_phase_elapsed, float(_lengths[source_clip]))
		source_phase = "reel_in"
	elif recovery:
		source_clip = "Climb_Up"
		source_time = fposmod(hook.recovery_progress * 2.0, 1.0) * float(_lengths[source_clip])
		source_phase = "recover"
	elif phase == GrappleHook.Phase.CLIMB_TOP:
		# T6 § 3 «підтягнувся й перехопився»: one Climb_Up stroke over the pull-up onto the arm.
		source_clip = "Climb_Up"
		source_time = clampf(hook._climb_elapsed / maxf(hook.climb_top_seconds, 0.001), 0.0, 1.0) * float(_lengths[source_clip])
		source_phase = "climb_top"
	elif phase == GrappleHook.Phase.PERCH or (hook.target_min_rise() == GrappleHook.PERCH_MIN_RISE and phase in [GrappleHook.Phase.WINDUP, GrappleHook.Phase.FLIGHT]):
		# T6 § 3: the arms of Climb_Idle on the two grip points, the legs of the jump below them.
		source_clip = "Climb_Idle"
		source_time = fposmod(_phase_elapsed, float(_lengths[source_clip]))
		source_phase = "perch"
		throw_side = hook.perch_throw_side() if one_hand_throw else ""
		if phase == GrappleHook.Phase.WINDUP:
			_throw_time = lerpf(0.0, 0.40, hook.windup_progress)
		elif phase == GrappleHook.Phase.FLIGHT:
			_throw_time = lerpf(0.40, 0.80, clampf(hook._flight_distance / maxf(hook._launch_origin.distance_to(hook.anchor_point), 0.001), 0.0, 1.0))
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
			source_phase = "reel" if _reeling else ("pull" if hook.pulling else ("slide" if hook.sliding else "hang"))
	else:
		source_clip = ""
		source_phase = "idle"
	_track_handover(f, previous_phase, delta)

## The pull-up's handover (see HANDOVER_SECONDS), city rope only: armed when the source phase enters or leaves
## "climb_top"; the hands' start is taken from the grips drawn on the tick before.
func _track_handover(f: Fighter, previous_phase: String, delta: float) -> void:
	if not f.grapple.climb_enabled:
		_handover_from.clear()
		_top_from.clear()
		return
	if source_phase != previous_phase and (source_phase == "climb_top" or previous_phase == "climb_top") and not _last_output.is_empty():
		_handover_from = _last_output.duplicate()
		_handover_elapsed = 0.0
	elif _handover_elapsed < HANDOVER_SECONDS:
		_handover_elapsed += maxf(delta, 0.0)
	if source_phase == "climb_top" and previous_phase != "climb_top":
		_top_from.clear()
		for side: String in _grips:
			_top_from[side] = Vector3(_grips[side]) - _grips_origin
	elif source_phase not in ["climb_top", "perch"]:
		_top_from.clear()

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
		if torso and source_phase in ["perch", "climb_top"]:
			continue # The grip on the arm: the torso hangs as on the rope (T6 § 3: no wall-climb knee to the post).
		if _recovery and f.state == Fighter.State.ATTACK and torso:
			continue # Preserve the kicking counterbalance along with hips and legs.
		var pose: Transform3D = _pose(source_clip, source_time, bone)
		if not throw_side.is_empty() and name.ends_with("_r" if throw_side == "Right" else "_l"):
			pose = _pose("OverhandThrow", _throw_time, bone) # the throwing arm of a shot from the grip
		if _phase == GrappleHook.Phase.HANG and source_phase != "catch" and _reel_mix > 0.0:
			# Rope load already drives the torso; a wall-climb torso folds into a low rope.
			pose = pose.interpolate_with(_pose("Climb_Up", fposmod(reel_cycle, 1.0) * float(_lengths["Climb_Up"]), bone), _reel_mix)
		# Local source rotation only: no wall-climb roots, translations, or scaled limbs.
		var weight: float = (0.65 if torso else 1.0) * smoothstep(0.0, 0.10, _entry_elapsed)
		var target: Quaternion = pose.basis.orthonormalized().get_rotation_quaternion()
		if _handover_elapsed < HANDOVER_SECONDS and _handover_from.size() > bone:
			# The pull-up's handover: from the arms drawn when it began (their local rotation, as written below).
			target = _handover_from[bone].basis.orthonormalized().get_rotation_quaternion().slerp(target, smoothstep(0.0, HANDOVER_SECONDS, _handover_elapsed))
			weight = 1.0
		var base: Quaternion = _base[bone].basis.orthonormalized().get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(bone, base.slerp(target, weight))
	_last_output = AuthoredLocomotion._poses(skeleton)

func apply_hands(hero: Skeleton3D, f: Fighter) -> void:
	grip_error = 0.0
	if not _active and _release_grips.is_empty():
		_grips.clear()
		_arm_memory.clear()
		_arm_previous.clear()
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
		# The city climb and slide hold a line in front of the shoulders (T6 § 1, «мотузка на 0,14 м попереду плечей»).
		if _clamp_mix > 0.0:
			origin += Vector3(f.forward.x, 0.0, f.forward.z).normalized() * ROPE_AHEAD * _clamp_mix
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
				if hook.climb_enabled and climb_stroke:
					# Row Г: this hand's height over its shoulder on the rope's line, the other hand half a cycle apart.
					var wave: float = 0.5 - 0.5 * cos(TAU * (reel_cycle + (0.0 if side == "Right" else 0.5)))
					# The stroke deepens as the elbow's pole turns to the climb's (both start from the hang's hands up high).
					var rise: float = lerpf(CLIMB_HAND_HIGH, lerpf(CLIMB_HAND_LOW, CLIMB_HAND_HIGH, wave), smoothstep(0.0, 1.0, _pole_mix))
					var up: float = maxf(radial.y, 0.2)
					pull = origin + radial * clampf((shoulder.y + rise - origin.y) / up, 0.0, origin.distance_to(anchor))
				point = point.lerp(pull, _reel_mix)
			# The slide: hands one over the other, no regrip (T6 § 2, row В).
			if _phase == GrappleHook.Phase.HANG and _slide_mix > 0.0:
				var held: Vector3 = Geometry3D.get_closest_point_to_segment(shoulder + radial * float(SLIDE_HANDS[side]), origin, anchor)
				point = point.lerp(held, _slide_mix)
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
	elif source_phase in ["perch", "climb_top"] and not hook.perch_pose.is_empty():
		# T6 § 3: the wrists on the arm at the two grip points; the pull-up carries them there from the rope.
		var pose: Dictionary = hook.perch_pose
		var progress: float = 1.0 if source_phase == "perch" else clampf(hook._climb_elapsed / maxf(hook.climb_top_seconds, 0.001), 0.0, 1.0)
		for side: String in ["Right", "Left"]:
			var on_arm: Vector3 = Vector3(pose.right if side == "Right" else pose.left) + Vector3.UP * PERCH_WRIST
			var on_rope: Vector3 = Geometry3D.get_closest_point_to_segment(on_arm, f.global_position + GrappleHook.HAND, hook.anchor_point)
			if _top_from.has(side):
				on_rope = f.global_position + Vector3(_top_from[side]) # where the hand was on the rope, carried with the body
			# The right hand reaches the arm first, the left follows (T6 § 3, frames 1–3); spread over 0.7 of the pull-up each
			# (0.6 swung the forearm past 30°/tick on the way, with the body rising under it).
			var own: float = smoothstep(0.0, 0.7, progress) if side == "Right" else smoothstep(0.3, 1.0, progress)
			if side == throw_side:
				# The throwing hand leaves the arm toward the shot's target (as the windup and the flight reach below).
				var shoulder_t: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Arm")).origin
				var aim: Vector3 = hook.aim_intent.get("point", hook.anchor_point) if hook.phase == GrappleHook.Phase.WINDUP else hook.anchor_point
				targets[side] = shoulder_t + (aim - shoulder_t).normalized() * 0.50
				continue
			var wanted: Vector3 = on_rope.lerp(on_arm, own)
			# The hand stays inside PERCH_REACH of this arm's reach: near full extension the elbow's bend swings tens of
			# degrees for a centimetre (a target past the reach straightened the arm in one tick, 32–39°).
			var shoulder: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Arm")).origin
			var elbow: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "ForeArm")).origin
			var wrist: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone(side + "Hand")).origin
			var reach: float = shoulder.distance_to(elbow) + elbow.distance_to(wrist)
			targets[side] = shoulder + (wanted - shoulder).limit_length(reach * PERCH_REACH)
		weight = smoothstep(0.0, 0.10, _entry_elapsed)
	elif source_phase == "reel_in":
		pass # Fish_Reel keeps both hands together at the waist (T6 § 5); no reach toward the rope's end.
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
		var supported_rope: bool = _active and ((_phase == GrappleHook.Phase.HANG and hook._responsive_traversal()) or source_phase in ["perch", "climb_top"]) and side != throw_side
		var city_arm: bool = supported_rope and hook.climb_enabled
		if supported_rope:
			weight = 1.0 # A caught rope is a support, including the authored catch gesture.
			# A wall-climb elbow twist is not a rope pull. Keep source regrip targets
			# and wrist orientation, but solve the supported arms from their rest plane.
			for bone: int in [a, b]:
				hero.set_bone_pose_rotation(bone, hero.get_bone_rest(bone).basis.orthonormalized().get_rotation_quaternion())
			if city_arm and arm_continuity and _arm_previous.has(side):
				# The city rope's arms go on from the arms solved on the tick before: the minimal arcs from the rest pose
				# flipped the forearm's roll when the hand came back near the shoulder (an arc near 180°).
				hero.set_bone_pose_rotation(a, _arm_previous[side][0])
				hero.set_bone_pose_rotation(b, _arm_previous[side][1])
		if city_arm:
			AuthoredHookMotion._solve_leg(hero, a, b, end, target, _elbow_pole(hero, f, side))
			# Only where a hand travels along a path of its own (the climb's stroke, the slide, the pull-up, the grip); on the
			# plain hang the hands keep the rope exactly (city_hook_gear_check: within 4 cm on every catch and pull tick).
			var capped: bool = _clamp_mix > 0.0 or source_phase in ["climb_top", "perch"]
			if capped and arm_continuity and _arm_previous.has(side) and Array(_arm_previous[side]).size() >= 4:
				for index: int in 2:
					var bone: int = [a, b][index]
					var before: Quaternion = _arm_previous[side][2 + index]
					var solved: Quaternion = AuthoredCombatMotion._global_rotation(hero, bone)
					var angle: float = before.angle_to(solved)
					if angle > ARM_TURN_CAP:
						AuthoredCombatMotion._set_global_rotation(hero, bone, before.slerp(solved, ARM_TURN_CAP / angle))
		else:
			AuthoredCombatMotion._solve_chain(hero, a, b, end, target)
		if supported_rope:
			AuthoredCombatMotion._set_global_rotation(hero, end, wrist_rotation)
		var side_weight: float = weight
		if side == throw_side:
			side_weight = smoothstep(0.0, 0.5, hook.windup_progress) if _phase == GrappleHook.Phase.WINDUP else 1.0
		for index: int in 3:
			var bone: int = [a, b, end][index]
			hero.set_bone_pose_rotation(bone, original[index].slerp(hero.get_bone_pose_rotation(bone), side_weight))
		if city_arm:
			_arm_memory[side] = [hero.get_bone_pose_rotation(a), hero.get_bone_pose_rotation(b), AuthoredCombatMotion._global_rotation(hero, a), AuthoredCombatMotion._global_rotation(hero, b)]
		else:
			_arm_memory.erase(side)
		var hand: Vector3 = hero.global_transform * hero.get_bone_global_pose(end).origin
		_grips[side] = hand
		_grips_origin = f.global_position
		if not grip.is_empty() and weight >= 0.999:
			grip_error = maxf(grip_error, hand.distance_to(Vector3(targets[side])))
	# The clamp fades over 0.1 s when the climb stops or the pull-up begins, never snaps (anim_traversal_check `rope_turn`).
	if _active and _clamp_mix > 0.0 and _phase in [GrappleHook.Phase.HANG, GrappleHook.Phase.CLIMB_TOP]:
		_clamp_feet(hero, f)


## The elbow's pole for the city rope's supported arms (ELBOW_HANG, ELBOW_CLIMB by _pole_mix), in skeleton space; the body's
## sides are read off its drawn shoulders (the pull-up turns the drawn body toward the arm over several ticks).
func _elbow_pole(hero: Skeleton3D, f: Fighter, side: String) -> Vector3:
	var across: Vector3 = hero.global_transform * hero.get_bone_global_pose(hero.find_bone("RightArm")).origin - hero.global_transform * hero.get_bone_global_pose(hero.find_bone("LeftArm")).origin
	across.y = 0.0
	if across.length() < 0.01:
		across = Vector3(f.forward.x, 0.0, f.forward.z).cross(Vector3.UP)
	var right_side := across.normalized()
	var forward := Vector3.UP.cross(right_side).normalized()
	var outward := right_side * (1.0 if side == "Right" else -1.0)
	var weights: Vector3 = ELBOW_HANG.lerp(ELBOW_CLIMB, smoothstep(0.0, 1.0, _pole_mix))
	return (hero.global_transform.basis.inverse() * (outward * weights.x - forward * weights.y + Vector3.DOWN * weights.z)).normalized()


## T6 § 1–2 (row Г, row В): the feet clamp the rope's line — FOOT_SIDE either side, FOOT_BEHIND behind it — lifted
## between FOOT_LOW and FOOT_HIGH in phase with the hands' regrip, or held at SLIDE_FEET on the slide.
func _clamp_feet(hero: Skeleton3D, f: Fighter) -> void:
	var forward := Vector3(f.forward.x, 0.0, f.forward.z).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var line: Vector3 = f.global_position + forward * ROPE_AHEAD
	for side: String in ["Right", "Left"]:
		var climb_lift: float = lerpf(FOOT_LOW, FOOT_HIGH, 0.5 - 0.5 * cos(TAU * (reel_cycle + (0.0 if side == "Right" or feet_in_phase else 0.5))))
		var lift: float = lerpf(climb_lift, float(SLIDE_FEET[side]), _slide_mix)
		var target: Vector3 = line - forward * FOOT_BEHIND + right * (FOOT_SIDE if side == "Right" else -FOOT_SIDE) + Vector3.UP * lift
		var a: int = hero.find_bone(side + "UpLeg")
		var b: int = hero.find_bone(side + "Leg")
		var end: int = hero.find_bone(side + "Foot")
		if a < 0 or b < 0 or end < 0:
			continue
		var original: Array[Quaternion] = [hero.get_bone_pose_rotation(a), hero.get_bone_pose_rotation(b), hero.get_bone_pose_rotation(end)]
		var to_local: Transform3D = hero.global_transform.affine_inverse()
		_solve_leg(hero, a, b, end, to_local * target, (to_local.basis * forward).normalized())
		for index: int in 3:
			var bone: int = [a, b, end][index]
			hero.set_bone_pose_rotation(bone, original[index].slerp(hero.get_bone_pose_rotation(bone), _clamp_mix))


## Two-bone IK with the knee pushed toward `pole` (the body's forward): a nearly straight leg never flips its knee from
## one tick to the next, as AuthoredCombatMotion._solve_chain's pose-derived bend can.
static func _solve_leg(skeleton: Skeleton3D, a: int, b: int, end: int, target: Vector3, pole: Vector3) -> void:
	var start: Vector3 = skeleton.get_bone_global_pose(a).origin
	var hinge: Vector3 = skeleton.get_bone_global_pose(b).origin
	var tip: Vector3 = skeleton.get_bone_global_pose(end).origin
	var end_rotation: Quaternion = AuthoredCombatMotion._global_rotation(skeleton, end)
	var upper: float = start.distance_to(hinge)
	var lower: float = hinge.distance_to(tip)
	var direction: Vector3 = (target - start).normalized()
	var distance: float = clampf(start.distance_to(target), absf(upper - lower) + 0.0001, upper + lower - 0.0001)
	var bend: Vector3 = pole - direction * pole.dot(direction)
	if bend.length_squared() < 0.0000001:
		return
	var along: float = (upper * upper - lower * lower + distance * distance) / (2.0 * distance)
	var knee: Vector3 = start + direction * along + bend.normalized() * sqrt(maxf(0.0, upper * upper - along * along))
	AuthoredCombatMotion._set_global_rotation(skeleton, a, Quaternion((hinge - start).normalized(), (knee - start).normalized()) * AuthoredCombatMotion._global_rotation(skeleton, a))
	hinge = skeleton.get_bone_global_pose(b).origin
	tip = skeleton.get_bone_global_pose(end).origin
	AuthoredCombatMotion._set_global_rotation(skeleton, b, Quaternion((tip - hinge).normalized(), (start + direction * distance - hinge).normalized()) * AuthoredCombatMotion._global_rotation(skeleton, b))
	AuthoredCombatMotion._set_global_rotation(skeleton, end, end_rotation)
