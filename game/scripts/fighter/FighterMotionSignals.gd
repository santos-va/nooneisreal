class_name FighterMotionSignals
extends RefCounted
## Read-only physics-to-presentation sample. Explicit lifecycle revisions exclude
## teleports; supported travel follows the floor tangent, not flattened velocity.
var distance: float = 0.0
var actual_velocity: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var support_normal: Vector3 = Vector3.UP
var grounded: bool = false
var discontinuous: bool = true
var _position: Vector3 = Vector3.ZERO
var _revision: int = -1
var _valid: bool = false

func update(f: Fighter, delta: float) -> void:
	grounded = f.on_ground()
	support_normal = f.get_floor_normal() if f.is_on_floor() else Vector3.UP
	discontinuous = not _valid or _revision != f.motion_revision
	var displacement: Vector3 = f.global_position - _position
	_position = f.global_position
	_revision = f.motion_revision
	_valid = true
	if discontinuous or delta <= 0.0:
		distance = 0.0
		actual_velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		return
	var previous_velocity: Vector3 = actual_velocity
	actual_velocity = displacement / delta
	acceleration = (actual_velocity - previous_velocity) / delta
	# Airborne vertical motion is not a stride. Real grounded slopes keep their
	# uphill/downhill component while contact correction along the normal is excluded.
	distance = displacement.slide(support_normal).length()
