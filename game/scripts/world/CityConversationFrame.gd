class_name CityConversationFrame
extends RefCounted
## Bounded conversation composition; world sweeps, never actor movement or input yaw.
const DISTANCE: float = 2.8 # PLACEHOLDER framing metres, device acceptance pending.
var _shape := SphereShape3D.new()

func _init() -> void:
	_shape.radius = 0.25

func safe_end(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, excluded: Array[RID]) -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform.origin = from
	query.motion = to - from
	query.collision_mask = 1
	query.exclude = excluded
	var fractions := space.cast_motion(query)
	return from.lerp(to, fractions[0]) if not fractions.is_empty() else to

func clear(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, excluded: Array[RID]) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = excluded
	query.hit_from_inside = true
	return space.intersect_ray(query).is_empty()

func choose(player: Node3D, target: Node3D, camera: Camera3D) -> Dictionary:
	var space := player.get_world_3d().direct_space_state
	var excluded: Array[RID] = [player.get_rid()]
	var focus := target.global_position + Vector3.UP * 1.45
	var front := player.global_position - target.global_position
	front.y = 0.0
	if front.length_squared() < 0.01:
		front = camera.global_basis.z
		front.y = 0.0
	front = front.normalized()
	var viewport := camera.get_viewport().get_visible_rect().size
	var aspect: float = viewport.x / maxf(viewport.y, 1.0)
	var best: Dictionary = {}
	var best_score: float = INF
	for degrees: float in [35.0, -35.0, 65.0, -65.0, 0.0, 90.0, -90.0, 180.0]:
		var outward := front.rotated(Vector3.UP, deg_to_rad(degrees))
		var desired := focus + outward * DISTANCE + Vector3.UP * 0.45
		var lens := safe_end(space, focus, desired, excluded)
		if lens.distance_squared_to(focus) < 0.12:
			continue
		var initial_basis := Basis.looking_at(focus - lens)
		# NPC sits near 35% screen width; the dialogue panel occupies the right.
		var offset: float = 0.30 * tan(deg_to_rad(camera.fov * 0.5)) * aspect * lens.distance_to(focus)
		var pivot := safe_end(space, focus, focus + initial_basis.x * offset, excluded)
		lens = safe_end(space, pivot, lens, excluded)
		var length: float = pivot.distance_to(lens)
		if length < 0.35:
			continue
		var basis := Basis.looking_at(pivot - lens)
		var score: float = absf(degrees) * 0.01 + absf(length - DISTANCE)
		for point: Vector3 in [target.global_position + Vector3.UP * 1.65, target.global_position + Vector3.UP, player.global_position + Vector3.UP * 1.65]:
			if not clear(space, lens, point, excluded):
				score += 20.0
		# Prefer a side that does not place the player's torso over the NPC's face.
		var closest := Geometry3D.get_closest_points_between_segments(lens, focus, player.global_position + Vector3.UP * 0.6, player.global_position + Vector3.UP * 1.8)
		if closest[0].distance_to(closest[1]) < 0.5:
			score += 10.0
		if score < best_score:
			best_score = score
			best = {"transform": Transform3D(basis, pivot), "length": length}
	return best
