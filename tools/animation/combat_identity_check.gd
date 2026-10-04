extends SceneTree
## Guard against style collapse, knee overextension, and incomplete recovery across both sides.
var checks: int = 0
var failures: int = 0
var motion: GDScript
var rig_script: GDScript

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBAT_IDENTITY: " + label)

func drawing(hero: String, anim: String, phase: float) -> Node3D:
	var rig: Node3D = rig_script.new()
	for part: String in ["pelvis", "torso", "head", "upper_arm_l", "upper_arm_r", "forearm_l", "forearm_r", "thigh_l", "thigh_r", "shin_l", "shin_r"]:
		rig.target_pose[part] = Vector3.ZERO
	rig._guard(0.0)
	motion.apply(rig, anim, rig_script.attack_ext(phase), phase, hero)
	return rig

func run() -> void:
	await process_frame
	motion = load("res://scripts/fighter/LimbMotion.gd")
	rig_script = load("res://scripts/fighter/RigAnimator.gd")
	for hero: String in ["skea", "choko"]:
		for side: String in ["left", "right"]:
			var suffix: String = "l" if side == "left" else "r"
			for family: String in ["hand", "leg"]:
				var variants: Array = motion.HANDS if family == "hand" else motion.FEET
				for variant: String in variants:
					var anim: String = "limb_%s_%s_%s" % [side, family, variant]
					for phase: float in [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]:
						var rig: Node3D = drawing(hero, anim, phase)
						for part: String in rig.target_pose:
							var angle: Vector3 = rig.target_pose[part]
							check(angle.is_finite(), "%s %s finite %s" % [hero, anim, part])
							if part.begins_with("shin"):
								check(angle.z <= 0.001 and angle.z >= -2.5, "knee hinge " + anim)
						if phase == 3.0:
							var finished: Dictionary = rig.target_pose.duplicate()
							for part: String in rig.target_pose:
								rig.target_pose[part] = Vector3.ZERO
							rig._guard(0.0)
							motion.apply_guard(rig, hero)
							# Pelvis is neutral in the guard; _guard only writes the limbs/torso.
							rig.target_pose["pelvis"] = Vector3.ZERO
							for part: String in finished:
								check((finished[part] as Vector3).is_equal_approx(rig.target_pose[part]), "complete guard return " + anim + "/" + part)
							check(rig.target_root_offset.is_zero_approx(), "root settles " + anim)
						rig.free()
			var air: Node3D = drawing(hero, "limb_%s_leg_airkick" % side, 1.0)
			check(air.target_pose["shin_" + suffix].z < -1.8 if hero == "skea" else air.target_pose["shin_" + suffix].z > -0.5, "knee vs boot identity " + hero + side)
			air.free()
			var elbow: Node3D = drawing(hero, "limb_%s_hand_hammer" % side, 1.0)
			check(elbow.target_pose["forearm_" + suffix].z > 2.0 if hero == "skea" else elbow.target_pose["forearm_" + suffix].z < 2.0, "elbow vs hammer identity " + hero + side)
			if hero == "skea":
				var shoulder_direction: Vector3 = Basis.from_euler(elbow.target_pose["pelvis"]) * Basis.from_euler(elbow.target_pose["torso"]) * Basis.from_euler(elbow.target_pose["upper_arm_" + suffix]) * Vector3.DOWN
				check(shoulder_direction.x > 0.7, "elbow projects toward target, not across guard " + side)
			elbow.free()
	print("COMBAT_IDENTITY checks=%s failures=%s" % [checks, failures])
	quit(1 if failures else 0)
