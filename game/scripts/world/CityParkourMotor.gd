class_name CityParkourMotor
extends RefCounted
## City-only collision authority. Presentation receives copies and never drives this motor.
const Profile = preload("res://scripts/world/CityParkourProfile.gd")
var profile: Profile
var phase: String = ""
var elapsed: float = 0.0
var wall_spent: bool = false
var grip_spent: bool = false
var jump_released: bool = false
var normal: Vector3 = Vector3.ZERO
var wall_point: Vector3 = Vector3.ZERO
var hands: Array[Vector3] = []
var hang: Vector3 = Vector3.ZERO
var apex: Vector3 = Vector3.ZERO
var landing: Vector3 = Vector3.ZERO
var support: StaticBody3D
var support_transform: Transform3D
var revision: int = -1
var tick_start: Vector3 = Vector3.ZERO
var tick_delta: float = 1.0 / 60.0

func reset(actor: Fighter, recharge: bool = true) -> void:
	phase = ""
	elapsed = 0.0
	support = null
	hands.clear()
	actor.set_meta("parkour_presentation", {})
	if recharge:
		wall_spent = false
		grip_spent = false
	revision = actor.motion_revision

func prepare(actor: Fighter) -> void:
	if revision != actor.motion_revision:
		reset(actor)
	if actor.control_locked or actor.state != Fighter.State.JUMP:
		reset(actor, false)
	# Only a genuine new supported cycle replenishes airborne effort.
	if phase.is_empty() and actor.is_on_floor() and actor.velocity.y <= 0.0:
		wall_spent = false
		grip_spent = false

func tick(actor: Fighter, delta: float, intent: Dictionary) -> bool:
	tick_start = actor.global_position
	tick_delta = delta
	if actor.control_locked or actor.grapple.busy():
		reset(actor, false)
		return false
	if not phase.is_empty():
		if intent.block or intent.crouch or actor._pressed("grapple_detach"):
			reset(actor, false)
			actor.velocity.y = minf(actor.velocity.y, 0.0)
			return false
		if actor._pressed("dodge"):
			if actor._start_dodge(intent.axis):
				reset(actor, false)
				return true
		if not _support_valid(actor):
			reset(actor, false)
			return false
		if phase == "hang":
			elapsed += delta
			if elapsed > profile.hang_seconds:
				reset(actor, false)
				return false
			actor.velocity = Vector3.ZERO
			if not intent.jump_held:
				jump_released = true
			if actor._pressed("jump") and jump_released:
				if not _mantle_clear(actor):
					_publish(actor)
					return true
				phase = "mantle"
				elapsed = 0.0
			_publish(actor)
			return true
		if phase == "mantle":
			elapsed += delta
			var progress: float = minf(elapsed / profile.mantle_seconds, 1.0)
			var target: Vector3 = hang.lerp(apex, minf(progress * 2.0, 1.0)) if progress < 0.5 else apex.lerp(landing, (progress - 0.5) * 2.0)
			var before: Vector3 = actor.global_position
			if not _move_clear(actor, target):
				reset(actor, false)
				actor.velocity = Vector3.ZERO
				return false
			actor.velocity = (actor.global_position - before) / delta
			_publish(actor)
			if progress >= 1.0:
				reset(actor, false)
				actor.velocity = Vector3.ZERO
			return true
		if phase == "wall_run":
			if not intent.jump_held or actor.wish().dot(-normal) < profile.minimum_wall_approach:
				reset(actor, false)
				return false
			if not grip_spent and _try_grip(actor, -normal):
				return true
			elapsed += delta
			var wall: Dictionary = _wall(actor, -normal)
			if elapsed >= profile.wall_seconds or wall.is_empty() or wall.collider != support:
				reset(actor, false)
				actor.velocity.y = minf(actor.velocity.y, 0.0)
				return false
			wall_point = wall.position
			var along: Vector3 = actor.wish().slide(normal)
			actor.velocity = along * profile.wall_along_speed + Vector3.UP * profile.wall_up_speed - normal * 0.5
			actor.move_and_slide()
			_publish(actor)
			return true
	if not intent.jump_held or actor.wish().length() < profile.minimum_wall_approach or actor.velocity.y < -profile.maximum_catch_fall_speed:
		return false
	var direction: Vector3 = actor.wish().normalized()
	if not grip_spent and _try_grip(actor, direction):
		return true
	if actor.data.id != "skea" or wall_spent or actor.velocity.y < 0.0:
		return false
	var wall: Dictionary = _wall(actor, direction)
	if wall.is_empty() or direction.dot(-Vector3(wall.normal)) < profile.minimum_wall_approach:
		return false
	wall_spent = true
	phase = "wall_run"
	elapsed = 0.0
	_set_support(wall)
	actor._set_forward(-normal)
	_publish(actor)
	return true

func _ray(actor: Fighter, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, actor.collision_mask)
	query.exclude = [actor.get_rid()]
	return actor.get_world_3d().direct_space_state.intersect_ray(query)

func _wall(actor: Fighter, direction: Vector3) -> Dictionary:
	var origin: Vector3 = actor.global_position + Vector3.UP * profile.minimum_grip_height
	var hit: Dictionary = _ray(actor, origin, origin + direction * profile.reach_distance)
	if hit.is_empty() or not hit.collider is StaticBody3D or absf(Vector3(hit.normal).y) > 0.15:
		return {}
	return hit

func _try_grip(actor: Fighter, direction: Vector3) -> bool:
	var wall: Dictionary = _wall(actor, direction)
	if wall.is_empty():
		return false
	var outward: Vector3 = wall.normal
	var inside: Vector3 = Vector3(wall.position) - outward * profile.top_inset
	var top_from: Vector3 = Vector3(inside.x, actor.global_position.y + profile.reach_height, inside.z)
	var top: Dictionary = _ray(actor, top_from, top_from - Vector3.UP * (profile.reach_height - profile.minimum_grip_height))
	if top.is_empty() or top.collider != wall.collider or Vector3(top.normal).dot(Vector3.UP) < 0.95:
		return false
	var edge: Vector3 = Vector3(top.position) + outward * profile.top_inset
	var side: Vector3 = outward.cross(Vector3.UP).normalized() * profile.grip_half_width
	for offset: Vector3 in [-side, side]:
		var grip: Vector3 = Vector3(top.position) + offset
		var contact: Dictionary = _ray(actor, grip + Vector3.UP * 0.08, grip - Vector3.UP * 0.08)
		if contact.is_empty() or contact.collider != wall.collider or Vector3(contact.normal).dot(Vector3.UP) < 0.95:
			return false
	normal = outward
	hang = edge + outward * profile.body_wall_offset - Vector3.UP * profile.hang_height
	apex = Vector3(hang.x, edge.y + profile.clearance, hang.z)
	landing = edge - outward * profile.landing_inset + Vector3.UP * profile.clearance
	# Ground beneath the complete landing capsule must exist, including its far edge.
	for offset: Vector3 in [Vector3.ZERO, side, -side, -outward * 0.3]:
		var point: Vector3 = landing + offset
		var floor_hit: Dictionary = _ray(actor, point + Vector3.UP * 0.1, point - Vector3.UP * 0.15)
		if floor_hit.is_empty() or floor_hit.collider != wall.collider or Vector3(floor_hit.normal).dot(Vector3.UP) < 0.95:
			return false
	if not _mantle_clear(actor) or not _move_clear(actor, hang):
		return false
	_set_support(wall)
	hands.assign([edge + side, edge - side])
	phase = "hang"
	elapsed = 0.0
	grip_spent = true
	jump_released = false
	actor._pressed("jump")
	actor.velocity = Vector3.ZERO
	actor._set_forward(-normal)
	_publish(actor)
	return true

func _set_support(hit: Dictionary) -> void:
	support = hit.collider as StaticBody3D
	support_transform = support.global_transform
	normal = hit.normal
	wall_point = hit.position

func _support_valid(actor: Fighter) -> bool:
	if not is_instance_valid(support) or not support.is_inside_tree() or not support.global_transform.is_equal_approx(support_transform):
		return false
	# Node lifetime alone is insufficient: collision may be disabled or its shape removed.
	if phase == "wall_run":
		var contact: Dictionary = _ray(actor, wall_point + normal * 0.08, wall_point - normal * 0.08)
		return not contact.is_empty() and contact.collider == support
	for hand: Vector3 in hands:
		var inside: Vector3 = hand - normal * profile.top_inset
		var contact: Dictionary = _ray(actor, inside + Vector3.UP * 0.08, inside - Vector3.UP * 0.08)
		if contact.is_empty() or contact.collider != support or Vector3(contact.normal).dot(Vector3.UP) < 0.95:
			return false
	return true

func _clear(actor: Fighter, from: Vector3, to: Vector3) -> bool:
	var pose: Transform3D = actor.global_transform
	pose.origin = from
	if actor.test_move(pose, to - from, null, profile.clearance):
		return false
	var shape: CollisionShape3D = actor.get_node("BodyShape") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	pose.origin = to
	query.transform = pose * shape.transform
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	query.margin = 0.005
	return actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _mantle_clear(actor: Fighter) -> bool:
	return _clear(actor, hang, apex) and _clear(actor, apex, landing)

func _move_clear(actor: Fighter, target: Vector3) -> bool:
	if not _clear(actor, actor.global_position, target):
		return false
	actor.move_and_collide(target - actor.global_position)
	return actor.global_position.distance_to(target) < 0.01

func _publish(actor: Fighter) -> void:
	var actual: Vector3 = (actor.global_position - tick_start) / maxf(tick_delta, 0.0001)
	actor.set_meta("parkour_presentation", {
		"phase": phase, "progress": clampf(elapsed / (profile.mantle_seconds if phase == "mantle" else profile.wall_seconds), 0.0, 1.0),
		"hold_remaining": maxf(0.0, (profile.hang_seconds if phase == "hang" else profile.wall_seconds) - elapsed),
		"left_hand": hands[0] if hands.size() == 2 else Vector3.ZERO,
		"right_hand": hands[1] if hands.size() == 2 else Vector3.ZERO,
		"wall_normal": normal, "wall_point": wall_point,
		"direction": actual.normalized(), "speed": actual.length()})
