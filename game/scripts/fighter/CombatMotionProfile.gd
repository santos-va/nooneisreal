class_name CombatMotionProfile
extends Resource
## PLACEHOLDER presentation tuning, independent of move timing, damage and collision.
@export var compact_guard: bool = false
@export var elbow_finisher: bool = false
@export var airborne_knee: bool = false
@export_range(0.0, 1.5) var hip_amplitude: float = 1.0
@export_range(0.0, 0.9) var recovery_settle_start: float = 0.32
@export_range(0.0, 0.15) var weight_drop: float = 0.065
