class_name NpcClothMotion
extends RefCounted
## Pinned presentation hinges. No actor, skeleton, collision or RNG writes.
## PLACEHOLDER art limits fixed in Equipment-And-Cloth CP1 before implementation.
const CLOTH_ANGLE: float = 0.24
const LEATHER_ANGLE: float = 0.10
const MAX_ACCELERATION: float = 20.0
const MAX_YAW_RATE: float = 6.0
const TELEPORT_DISTANCE: float = 0.75
const TELEPORT_ANGLE: float = 0.8
var parts: Array[Dictionary] = []
var ticks: int = 0
var resets: int = 0
var _valid: bool = false
var _owner_id: int = 0
var _last_position := Vector3.ZERO
var _last_velocity := Vector3.ZERO
var _last_yaw: float = 0.0

func add(pivot: Node3D, kind: String, outward_sign: float = 1.0) -> void:
	parts.append({"node":pivot,"rest":pivot.transform,"angle":0.0,"speed":0.0,
		"kind":kind,"sign":outward_sign})

func reset() -> void:
	_valid = false
	_owner_id = 0
	_last_velocity = Vector3.ZERO
	resets += 1
	for part: Dictionary in parts:
		part.angle = 0.0
		part.speed = 0.0
		if is_instance_valid(part.node): part.node.transform = part.rest

func step(owner: Node3D, delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta) or owner.get_tree().paused:
		return
	ticks += 1
	var position: Vector3 = owner.global_position
	var yaw: float = atan2(owner.global_basis.z.x,owner.global_basis.z.z)
	var turn: float = wrapf(yaw-_last_yaw,-PI,PI)
	if not _valid or owner.get_instance_id() != _owner_id or position.distance_to(_last_position) > TELEPORT_DISTANCE or absf(turn) > TELEPORT_ANGLE or delta > 0.1:
		reset()
		_valid = true
		_owner_id = owner.get_instance_id()
		_last_position = position
		_last_yaw = yaw
		return
	var velocity: Vector3 = (position-_last_position)/delta
	var acceleration: Vector3 = ((velocity-_last_velocity)/delta).limit_length(MAX_ACCELERATION)
	var local_acceleration: Vector3 = owner.global_basis.orthonormalized().inverse()*acceleration
	var yaw_rate: float = clampf(turn/delta,-MAX_YAW_RATE,MAX_YAW_RATE)
	_last_position = position
	_last_velocity = velocity
	_last_yaw = yaw
	for part: Dictionary in parts:
		if not is_instance_valid(part.node): continue
		var leather: bool = part.kind == "leather"
		var limit: float = LEATHER_ANGLE if leather else CLOTH_ANGLE
		var omega: float = 18.0 if leather else 12.0
		# A conservative outward hinge keeps the free edge outside the body.
		# Turns also impart inertia, but there is no perpetual idle sine/wind.
		var target: float = clampf(-local_acceleration.z*float(part.sign)*0.018+absf(local_acceleration.x)*0.006+absf(yaw_rate)*0.018,0.0,limit)
		var offset: float = float(part.angle)-target
		var impulse: float = float(part.speed)+omega*offset
		var decay: float = exp(-omega*delta)
		var angle: float = target+(offset+impulse*delta)*decay
		var speed: float = (float(part.speed)-omega*impulse*delta)*decay
		if angle < 0.0 or angle > limit:
			angle = clampf(angle,0.0,limit)
			speed = 0.0
		part.angle = angle
		part.speed = speed
		var rest: Transform3D = part.rest
		part.node.transform = Transform3D(rest.basis*Basis(Vector3.RIGHT,angle*float(part.sign)),rest.origin)
