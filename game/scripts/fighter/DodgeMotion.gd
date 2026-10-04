class_name DodgeMotion
extends RefCounted
## Presentation only: the physical hop and stamina are owned by Fighter.
static func apply(rig: RigAnimator, fighter: Fighter) -> void:
	var progress: float = fighter.dodge_progress()
	var flight: float = sin(PI * clampf(progress, 0.0, 1.0))
	var compact: bool = fighter.dodge_profile().compact
	var direction: Vector2 = fighter.dodge_local_direction()
	var lead: String = "l" if direction.y >= 0.0 else "r"
	var rear: String = "r" if lead == "l" else "l"
	rig._guard(0.0)
	LimbMotion.apply_guard(rig, fighter.data.id)
	# Choko stays low behind a closed guard; Skea gathers a checking knee and rebounds.
	rig._pose_set("torso", Vector3(direction.y * flight * 0.16, 0.0, -direction.x * flight * (0.3 if compact else 0.16)))
	rig._pose_set("head", Vector3(-direction.y * flight * 0.1, 0.0, direction.x * flight * 0.1))
	rig._pose_set("pelvis", Vector3(0.0, -direction.y * flight * 0.18, 0.0))
	rig._pose_set("thigh_" + lead, Vector3(-direction.y * flight * 0.15, 0.0, flight * (0.7 if compact else 1.15)))
	rig._pose_set("shin_" + lead, Vector3(0.0, 0.0, -flight * (1.15 if compact else 1.65)))
	rig._pose_set("thigh_" + rear, Vector3(0.0, 0.0, -direction.x * flight * 0.35))
	rig._pose_set("shin_" + rear, Vector3(0.0, 0.0, -flight * (0.8 if compact else 1.0)))
	rig.target_root_offset.y = -(0.1 if compact else 0.055) * flight
