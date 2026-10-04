class_name GrappleMotion
extends RefCounted
## Whole-body presentation of the simulated hook phases; never changes rope or fighter authority.
## Provisional art angles. Aim derives from the actual anchor, not a fixed screen direction.

static func apply(rig: RigAnimator, fighter: Fighter) -> void:
	var hook: GrappleHook = fighter.grapple
	var local: Vector3 = rig.global_basis.inverse() * (hook.anchor_point - fighter.global_position)
	var elevation: float = atan2(local.y, Vector2(local.x, local.z).length())
	var aim_yaw: float = atan2(-local.z, local.x)
	var aim: float = PI * 0.5 + elevation
	if hook.phase == GrappleHook.Phase.WINDUP:
		var t: float = clampf(hook.windup_progress, 0.0, 1.0)
		# Load through knees/hips first; the last third follows through into the release.
		var load_amount: float = sin(PI * minf(t / 0.75, 1.0))
		var release: float = smoothstep(0.6, 1.0, t)
		rig._crouch_t(0.6 * load_amount)
		rig._pose_set("pelvis", Vector3(0.0, -0.4 * load_amount + aim_yaw * 0.2 * release, 0.0))
		rig._pose_set("torso", Vector3(0.0, -0.55 * load_amount + aim_yaw * 0.3 * release, 0.28 * load_amount - 0.15 * release))
		rig._pose_set("head", Vector3(0.0, aim_yaw * 0.3, -0.25 * elevation))
		rig._pose_set("upper_arm_r", Vector3(0.0, aim_yaw * 0.5 * release, lerpf(0.35 - 0.5 * load_amount, aim, release)))
		rig._pose_set("forearm_r", Vector3(0.0, 0.0, lerpf(2.0, 0.08, release)))
		rig._pose_set("upper_arm_l", Vector3(0.0, 0.0, 1.1 + 0.2 * load_amount))
		rig._pose_set("forearm_l", Vector3(0.0, 0.0, 1.1))
		return
	# During flight the reaching arm remains extended; after attachment the second hand supports it.
	var hanging: bool = hook.phase == GrappleHook.Phase.HANG
	var local_velocity: Vector3 = rig.global_basis.inverse() * fighter.velocity
	var lean: float = clampf(local_velocity.x * 0.025, -0.3, 0.3)
	rig._pose_set("pelvis", Vector3(0.0, aim_yaw * 0.25, 0.0))
	rig._pose_set("torso", Vector3(0.0, aim_yaw * 0.25, -lean if hanging else 0.1))
	rig._pose_set("head", Vector3(0.0, aim_yaw * 0.2, -0.3 * elevation))
	rig._pose_set("upper_arm_r", Vector3(0.0, aim_yaw * 0.5, aim + lean))
	rig._pose_set("forearm_r", Vector3(0.0, 0.0, 0.08))
	rig._pose_set("upper_arm_l", Vector3(0.0, aim_yaw * 0.5, aim - 0.18 if hanging else 0.8))
	rig._pose_set("forearm_l", Vector3(0.0, 0.0, 0.4 if hanging else 1.2))
	rig._pose_set("thigh_l", Vector3(0.0, 0.0, 0.25 + lean))
	rig._pose_set("thigh_r", Vector3(0.0, 0.0, 0.45 + lean))
	rig._pose_set("shin_l", Vector3(0.0, 0.0, -0.7 if hanging else -0.4))
	rig._pose_set("shin_r", Vector3(0.0, 0.0, -1.0 if hanging else -0.65))
