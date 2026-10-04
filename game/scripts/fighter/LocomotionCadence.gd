class_name LocomotionCadence
extends RefCounted
## Distance-driven phase for the existing CC0 UAL in-place clips. Presentation only.
## Source stance speeds (m/s) measured from glTF FK; see tools/animation/measure_gait.py.
## These are animation calibration, not fighter speeds. Retarget leg scale is applied separately.
const WALK: Array[String] = ["Walk_Loop", "Walk_Fwd_R_Loop", "Walk_R_Loop", "Walk_Bwd_R_Loop", "Walk_Bwd_Loop", "Walk_Bwd_L_Loop", "Walk_L_Loop", "Walk_Fwd_L_Loop"]
const JOG: Array[String] = ["Jog_Fwd_Loop", "Jog_Fwd_R_Loop", "Jog_Right_Loop", "Jog_Bwd_R_Loop", "Jog_Bwd_Loop", "Jog_Bwd_L_Loop", "Jog_Left_Loop", "Jog_Fwd_L_Loop"]
const WALK_SPEED: Array[float] = [0.979, 0.979, 0.612, 1.126, 1.126, 1.126, 0.612, 0.979]
const JOG_SPEED: Array[float] = [5.899, 5.939, 1.920, 4.912, 4.996, 5.265, 1.979, 5.939]
var phase: float = 0.0

static func sector(velocity: Vector3, forward: Vector3) -> int:
	return posmod(roundi(atan2(velocity.dot(forward.cross(Vector3.UP)), velocity.dot(forward)) / (PI / 4.0)), 8)

static func choose(velocity: Vector3, forward: Vector3, leg_scale: float) -> String:
	var index: int = sector(velocity, forward)
	# PLACEHOLDER visual boundary: do not stretch the high-speed Jog into a slow walk.
	# Stateful runtime hysteresis and recovery forcing live in AuthoredLocomotion.
	return JOG[index] if Vector2(velocity.x, velocity.z).length() > 2.7 * leg_scale else WALK[index]

static func source_speed(name: String) -> float:
	if name in ["Sprint_Loop", "Sprint_Enter", "Sprint_Exit"]:
		return 8.905 # Source stance measurement from measure_gait.py, UAL1 Sprint_Loop.
	var index: int = WALK.find(name)
	if index >= 0:
		return WALK_SPEED[index]
	index = JOG.find(name)
	return JOG_SPEED[index] if index >= 0 else 1.0

func advance(distance: float, name: String, length: float, leg_scale: float) -> float:
	var stride: float = maxf(source_speed(name) * leg_scale * length, 0.0001)
	phase = fposmod(phase + maxf(distance, 0.0) / stride, 1.0)
	return phase * length
