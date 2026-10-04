class_name LimbMotion
extends RefCounted
## Original procedural drawings, not newly licensed clips or anatomical damage simulation.
## Art amplitudes are provisional. RigAnimator supplies the existing stepped anticipation/contact/recovery.
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
	var style: float = 0.78 if character_id == "choko" else 1.0
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
		rig._pose_set("torso", Vector3(0.0, mirror * twist * 0.7 * ext * style, (-0.25 if variant == "bodyhook" else -0.1) * ext))
	else:
		var thigh: float = 1.52
		var knee: float = -0.15
		var turn: float = 0.12
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
			thigh = 1.8
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
