class_name LimbMotion
extends RefCounted
## Original procedural drawings, not newly licensed clips or anatomical damage simulation.
## PLACEHOLDER art angles only. Gameplay windows and hit volumes remain authoritative.
## Character identity is selected here; the phase/chamber pipeline is shared by future styles.
static var default_profile: CombatMotionProfile = CombatMotionProfile.new()
const PROFILES: Dictionary = {
	"skea": preload("res://data/motion/skea.tres"),
	"choko": preload("res://data/motion/choko.tres"),
}

const HANDS: Array[String] = ["jab", "cross", "bodyhook", "uppercut", "hammer", "lowhand", "airhand"]
const FEET: Array[String] = ["frontkick", "roundhouse", "spin", "hookspin", "lowkick", "airkick"]

static func supports(anim: String) -> bool:
	var pieces: PackedStringArray = anim.split("_")
	if pieces.size() != 4 or pieces[0] != "limb" or pieces[1] not in ["left", "right"]:
		return false
	return (pieces[2] == "hand" and pieces[3] in HANDS) or (pieces[2] == "leg" and pieces[3] in FEET)

static func apply(rig: RigAnimator, anim: String, extension: float, phase: float = -1.0, character_id: String = "skea") -> void:
	var pieces: PackedStringArray = anim.split("_")
	var side: String = "l" if pieces[1] == "left" else "r"
	var other: String = "r" if side == "l" else "l"
	var mirror: float = 1.0 if side == "l" else -1.0
	var variant: String = pieces[3]
	var ext: float = extension
	# PLACEHOLDER art identity: trained compact Choko vs full hip/shoulder Skea.
	var profile: CombatMotionProfile = PROFILES.get(character_id, default_profile)
	var compact: bool = profile.compact_guard
	var style: float = profile.hip_amplitude
	apply_guard(rig, character_id)
	var guard_pose: Dictionary = rig.target_pose.duplicate()
	var chamber: float = sin(PI * clampf(phase, 0.0, 1.0)) if phase >= 0.0 and phase < 1.0 else 0.0
	var return_chamber: float = sin(PI * clampf(phase - 2.0, 0.0, 1.0)) if phase >= 2.0 else 0.0
	# Keep the non-striking hand guarding. Rotation around Y is mirrored, never the knee hinge.
	rig._pose_set("upper_arm_" + other, Vector3(0.0, 0.0, 1.05))
	rig._pose_set("forearm_" + other, Vector3(0.0, 0.0, 1.55))
	if pieces[2] == "hand":
		var shoulder: float = 1.58
		var elbow: float = 0.12
		var twist: float = 0.24
		var shoulder_swing: float = 0.0
		if variant == "cross":
			twist = 0.55
		elif variant == "bodyhook":
			shoulder = 0.55
			elbow = 1.35
			twist = 0.62
			shoulder_swing = -mirror * 0.65
		elif variant == "uppercut":
			shoulder = 1.3
			elbow = 1.1
			twist = 0.4
		elif variant == "hammer":
			# Reverse-route finisher: descending forearm, distinct from a rising uppercut.
			shoulder = 0.85
			elbow = 1.5
			twist = 0.7
			shoulder_swing = mirror * 0.35
			if profile.elbow_finisher:
				# Folded descending elbow; Choko keeps the compact hammer-fist.
				shoulder = 1.45
				elbow = 2.45
				twist = 0.28
				shoulder_swing = 0.0
		elif variant == "lowhand":
			rig._crouch()
			shoulder = 1.35
		elif variant == "airhand":
			shoulder = 1.45
			rig._pose_set("thigh_" + side, Vector3(0.0, 0.0, 0.75))
			rig._pose_set("shin_" + side, Vector3(0.0, 0.0, -1.3))
		rig._pose_set("upper_arm_" + side, Vector3(shoulder_swing * ext, 0.0, lerpf(2.5 if variant == "hammer" else 0.9, shoulder, ext)))
		rig._pose_set("forearm_" + side, Vector3(0.0, 0.0, clampf(lerpf(1.3, elbow, ext), 0.05, 2.5)))
		rig._pose_set("pelvis", Vector3(0.0, mirror * twist * 0.3 * ext * style, 0.0))
		rig._pose_set("torso", Vector3(0.0, mirror * twist * 0.7 * ext * style, (-0.25 if variant == "bodyhook" or (variant == "hammer" and profile.elbow_finisher) else -0.1) * ext))
	else:
		var thigh: float = 1.52
		var knee: float = -0.15
		var turn: float = 0.12
		var knee_strike: bool = profile.airborne_knee and variant == "airkick"
		if variant == "roundhouse":
			turn = 0.7
			thigh = 1.75
		elif variant in ["spin", "hookspin"]:
			turn = PI * 1.85
			thigh = 1.62 if variant == "spin" else 1.9
			if variant == "hookspin":
				knee = -0.85
		elif variant == "lowkick":
			thigh = 0.65
			rig._crouch_t(0.3)
		elif variant == "airkick":
			thigh = 1.95 if knee_strike else 1.8
			if knee_strike:
				knee = -2.25
			rig._pose_set("thigh_" + other, Vector3(0.0, 0.0, 0.5))
			rig._pose_set("shin_" + other, Vector3(0.0, 0.0, -1.2))
		rig._pose_set("thigh_" + side, Vector3(0.0, 0.0, lerpf(0.05, thigh, ext)))
		rig._pose_set("shin_" + side, Vector3(0.0, 0.0, clampf(lerpf(-0.65, knee, ext), -2.4, -0.05)))
		rig._pose_set("torso", Vector3(0.0, mirror * minf(turn, 0.7) * 0.4 * ext, 0.22 * ext))
		if variant in ["spin", "hookspin"] and phase >= 0.0:
			# Complete the turn once; recovery must not reverse a completed spin.
			rig.spin = mirror * TAU * smoothstep(0.0, 1.0, phase)
			if variant == "hookspin":
				rig._pose_set("thigh_" + side, Vector3(-mirror * 0.45 * ext, 0.0, lerpf(0.05, thigh, ext)))
		else:
			rig.spin = mirror * turn * clampf(ext, 0.0, 1.0)
		# Counterbalance the striking leg without dropping both hands into a T-pose.
		rig._pose_set("upper_arm_" + side, Vector3(0.0, 0.0, lerpf(0.9, -0.35, ext)))

		# Chamber before extension, rechamber before planting: a leg never retracts as a rigid rod.
		var folded: float = maxf(chamber, return_chamber)
		var thigh_pose: Vector3 = rig.target_pose["thigh_" + side]
		var shin_pose: Vector3 = rig.target_pose["shin_" + side]
		thigh_pose.z = lerpf(thigh_pose.z, 1.05, folded * 0.8)
		shin_pose.z = lerpf(shin_pose.z, -1.85, folded)
		if variant in ["roundhouse", "lowkick"]:
			thigh_pose.x = -mirror * 0.55 * clampf(ext, 0.0, 1.0)
			rig._pose_set("pelvis", Vector3(0.0, mirror * 0.3 * ext, 0.0))
		# Supporting knee absorbs weight; planted leg does not copy the striking leg.
		if variant != "airkick":
			rig._pose_set("thigh_" + other, Vector3(0.0, mirror * 0.12 * ext, 0.14 + 0.13 * maxf(ext, 0.0)))
			rig._pose_set("shin_" + other, Vector3(0.0, 0.0, -0.28 - 0.2 * maxf(ext, 0.0)))
		rig._pose_set("thigh_" + side, thigh_pose)
		rig._pose_set("shin_" + side, shin_pose)
		if compact or knee_strike:
			rig._pose_set("upper_arm_" + side, Vector3(0.0, 0.0, 1.0 + 0.15 * ext))
			rig._pose_set("forearm_" + side, Vector3(0.0, 0.0, 1.65))
	# Pelvis leads, head stays on the target; a small vertical load sells body weight.
	var torso: Vector3 = rig.target_pose["torso"]
	rig._pose_set("head", Vector3(0.0, -torso.y * 0.55, -0.08))
	if variant not in ["lowhand", "lowkick", "airhand", "airkick"]:
		rig.target_root_offset.y = -0.035 * chamber - profile.weight_drop * maxf(ext, 0.0)
	if pieces[2] == "hand" and variant not in ["lowhand", "airhand"]:
		rig._pose_set("thigh_" + other, Vector3(0.0, 0.0, 0.18 + 0.16 * maxf(ext, 0.0)))
		rig._pose_set("shin_" + other, Vector3(0.0, 0.0, -0.3 - 0.24 * maxf(ext, 0.0)))
	# Recovery is its own trajectory, ending exactly in the character's guard.
	# Compact Choko closes the opening earlier; Skea completes a broader follow-through.
	if phase >= 2.0:
		var settle: float = smoothstep(profile.recovery_settle_start, 1.0, phase - 2.0)
		for part: String in guard_pose:
			rig.target_pose[part] = (rig.target_pose[part] as Vector3).lerp(guard_pose[part], settle)
		rig.target_root_offset *= 1.0 - settle


## Shared style entry point: new fighters can supply a guard without duplicating limb timing.
static func apply_guard(rig: RigAnimator, character_id: String) -> void:
	if not PROFILES.has(character_id):
		return
	var profile: CombatMotionProfile = PROFILES[character_id]
	var compact: bool = profile.compact_guard
	for side: String in ["l", "r"]:
		var lead: bool = side == "l"
		rig._pose_set("upper_arm_" + side, Vector3(0.0, 0.0, (0.9 if lead else 0.8) if compact else (1.2 if lead else 1.05)))
		rig._pose_set("forearm_" + side, Vector3(0.0, 0.0, 1.65 if compact else 1.8))
	rig._pose_set("torso", Vector3(0.0, 0.13 if compact else 0.0, 0.12 if compact else 0.02))
	rig._pose_set("head", Vector3(0.0, -0.08 if compact else 0.0, -0.08))
