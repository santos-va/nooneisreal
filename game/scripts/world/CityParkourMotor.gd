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
var kick_spent: bool = false
var kick_release_frame: int = -1
var input_revision: int = -1
var floor_point: Vector3 = Vector3.ZERO
var floor_normal: Vector3 = Vector3.UP

func reset(actor: Fighter, recharge: bool = true) -> void:
	phase = ""
	elapsed = 0.0
	support = null
	hands.clear()
	kick_release_frame = -1
	actor.set_meta("parkour_presentation", {})
	if recharge:
		wall_spent = false
		grip_spent = false
		kick_spent = false
	revision = actor.motion_revision
	input_revision = InputRouter.press_history_revision(actor.player_index)

func prepare(actor: Fighter) -> void:
	if revision != actor.motion_revision:
		reset(actor)
	var rolling: bool = phase == "landing_roll" and actor.state in [Fighter.State.IDLE, Fighter.State.WALK]
	if actor.control_locked or InputRouter.ui_suppressed() or input_revision != InputRouter.press_history_revision(actor.player_index) or (actor.state != Fighter.State.JUMP and not rolling):
		reset(actor, false)
	# Only a genuine new supported cycle replenishes airborne effort.
	if phase.is_empty() and actor.is_on_floor() and actor.velocity.y <= 0.0:
		wall_spent = false
		grip_spent = false
		kick_spent = false

func tick(actor: Fighter, delta: float, intent: Dictionary) -> bool:
	tick_start = actor.global_position
	tick_delta = delta
	if actor.control_locked or InputRouter.ui_suppressed() or actor.grapple.busy():
		reset(actor, false)
		return false
	if not intent.jump_held:
		kick_release_frame = InputRouter.frame()
	if phase == "wall_kick":
		# The ordinary air controller owns gravity, steering, actions and swept collision.
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
		if phase == "hang" and _try_kick(actor, delta, intent, {"collider":support,"normal":normal,"position":wall_point}):
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
				# An obstructed away-kick must not turn into an opposite mantle.
				if actor.wish().dot(normal) >= profile.minimum_kick_away:
					_publish(actor)
					return true
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
				if not intent.jump_held:
					kick_release_frame = InputRouter.frame()
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
	if not kick_spent and kick_release_frame >= 0 and intent.jump_held and not intent.block and not intent.crouch and actor.wish().length() >= profile.minimum_kick_away:
		if _try_kick(actor, delta, intent, _wall(actor, -actor.wish().normalized())):
			return false
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

func _try_kick(actor: Fighter, delta: float, intent: Dictionary, wall: Dictionary) -> bool:
	if kick_spent or kick_release_frame < 0 or not intent.jump_held or wall.is_empty():
		return false
	var age: int = InputRouter.buffered_age(actor.player_index, "jump")
	# A press can follow release observation within the same router frame. Older
	# buffered presses are rejected; holding the initial jump never arms this path.
	if age < 0 or age > InputRouter.BUFFER_FRAMES or InputRouter.frame() - age < kick_release_frame:
		return false
	var outward: Vector3 = wall.normal
	if actor.wish().dot(outward) < profile.minimum_kick_away:
		return false
	var launch: Vector3 = outward * profile.wall_kick_out_speed + Vector3.UP * profile.wall_kick_up_speed
	if not _clear(actor, actor.global_position, actor.global_position + launch * delta) or not actor._pressed("jump"):
		return false
	kick_spent = true
	wall_spent = true
	grip_spent = true
	kick_release_frame = -1
	hands.clear()
	_set_support(wall)
	phase = "wall_kick"
	elapsed = 0.0
	actor.velocity = launch
	actor._set_forward(outward)
	return true

func after_air(actor: Fighter, delta: float, intent: Dictionary, previous_velocity: Vector3) -> void:
	if phase == "wall_kick":
		elapsed += delta
		if actor.state != Fighter.State.JUMP or actor.grapple.busy() or elapsed >= profile.wall_kick_seconds:
			reset(actor, false)
		else:
			_publish(actor)
	if actor.state != Fighter.State.IDLE or not actor.is_on_floor() or actor.control_locked or actor.grapple.busy():
		return
	if not intent.crouch or intent.block or previous_velocity.y > -profile.roll_min_fall_speed:
		return
	var travel := Vector3(actor.velocity.x, 0.0, actor.velocity.z)
	if travel.length() < profile.roll_min_speed or actor.wish().dot(travel.normalized()) < profile.minimum_wall_approach:
		return
	if not _roll_support(actor, actor.global_position):
		return
	phase = "landing_roll"
	elapsed = 0.0
	actor.velocity = travel.limit_length(profile.roll_max_speed)
	actor.land_lag = 0
	actor._set_forward(travel.normalized())
	_publish(actor)

func tick_ground(actor: Fighter, delta: float, intent: Dictionary) -> bool:
	if phase != "landing_roll":
		return false
	if actor.control_locked or InputRouter.ui_suppressed() or actor.grapple.busy() or not intent.crouch or intent.block:
		reset(actor, false)
		return false
	# Preserve normal action priority and queued presses; the parent consumes them.
	for action: String in ["jump", "dodge", "dash", "grapple", "grapple_parkour", "left_hand", "right_hand", "left_leg", "right_leg", "light", "heavy", "weapon_swap"]:
		var age: int = InputRouter.buffered_age(actor.player_index, action)
		if age >= 0 and age <= InputRouter.BUFFER_FRAMES:
			reset(actor, false)
			return false
	tick_start = actor.global_position
	tick_delta = delta
	var travel := Vector3(actor.velocity.x, 0.0, actor.velocity.z).move_toward(Vector3.ZERO, profile.roll_deceleration * delta)
	if not actor.is_on_floor() or not _roll_support(actor, actor.global_position + travel * delta):
		reset(actor, false)
		return false
	actor.velocity = travel - Vector3.UP * Fighter.GRAVITY * delta
	actor.move_and_slide()
	elapsed += delta
	if not actor.is_on_floor() or actor.is_on_wall() or elapsed >= profile.roll_seconds or travel.length() < profile.roll_min_speed * 0.25:
		reset(actor, false)
		return true
	_roll_support(actor, actor.global_position)
	_publish(actor)
	return true

func _roll_support(actor: Fighter, point: Vector3) -> bool:
	if actor.get_floor_normal().dot(Vector3.UP) < profile.roll_min_floor_dot:
		return false
	var shape: CapsuleShape3D = (actor.get_node("BodyShape") as CollisionShape3D).shape as CapsuleShape3D
	if shape == null:
		return false
	var radius: float = shape.radius
	var center: Dictionary = {}
	for offset: Vector3 in [Vector3.ZERO, Vector3.RIGHT * radius, Vector3.LEFT * radius, Vector3.FORWARD * radius, Vector3.BACK * radius]:
		var hit: Dictionary = _ray(actor, point + offset + Vector3.UP * 0.04, point + offset - Vector3.UP * profile.roll_support_depth)
		if hit.is_empty() or Vector3(hit.normal).dot(Vector3.UP) < profile.roll_min_floor_dot:
			return false
		if offset == Vector3.ZERO:
			center = hit
	floor_point = center.position
	floor_normal = center.normal
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
	var duration: float = profile.wall_seconds
	if phase == "mantle":
		duration = profile.mantle_seconds
	elif phase == "wall_kick":
		duration = profile.wall_kick_seconds
	elif phase == "landing_roll":
		duration = profile.roll_seconds
	actor.set_meta("parkour_presentation", {
		"phase": phase, "progress": clampf(elapsed / maxf(duration, 0.0001), 0.0, 1.0), "duration":duration,
		"hold_remaining": maxf(0.0, (profile.hang_seconds if phase == "hang" else profile.wall_seconds) - elapsed),
		"left_hand": hands[0] if hands.size() == 2 else Vector3.ZERO,
		"right_hand": hands[1] if hands.size() == 2 else Vector3.ZERO,
		"wall_normal": normal, "wall_point": wall_point,
		"floor_point": floor_point, "floor_normal":floor_normal,
		"direction": actual.normalized(), "speed": actual.length()})
