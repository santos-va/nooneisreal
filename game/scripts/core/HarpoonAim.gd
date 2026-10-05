class_name HarpoonAim
extends Node
## Input adapter only. A fire snapshots this world intent; replay injects that snapshot.
## PLACEHOLDER UX tuning, pending device playtest.
@export var mouse_sensitivity: float = 0.004
@export var stick_speed: float = 1.8
@export var return_delay: float = 2.0
@export var return_speed: float = 2.0
@export var assist_degrees: float = 10.0
# PLACEHOLDER action assistance: visible anchors, movement intent, stable preview.
@export var traversal_assist_degrees: float = 42.0
@export var traversal_stickiness: float = 0.12
@export var pitch_limit: float = 1.25 # PLACEHOLDER: allow aiming at overhead street anchors.
var camera: Camera3D
var solo: bool = false
var yaw_offset: float = 0.0
var pitch_offset: float = 0.0
var manual_left: float = 0.0
var _drag: bool = false
var last_gamepad: bool = false
var _previous: Dictionary = {}

func setup(view: Camera3D, allow_orbit: bool) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera = view
	solo = allow_orbit
	camera.set_meta("harpoon_aim", self)
	reset()

func reset() -> void:
	yaw_offset = 0.0
	pitch_offset = 0.0
	manual_left = 0.0
	_drag = false
	_previous.clear()
	InputRouter.clear_view_basis(1)

func _process(_delta: float) -> void:
	if InputRouter.ui_suppressed() or get_tree().paused:
		_drag = false
		InputRouter.clear_view_basis(1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.device == 0 and event.pressed:
		last_gamepad = true
	elif event is InputEventJoypadMotion and event.device == 0 and absf(event.axis_value) > 0.2:
		last_gamepad = true
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		last_gamepad = false
	if InputRouter.ui_suppressed() or get_tree().paused or not solo:
		_drag = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_drag = event.pressed
	if event is InputEventMouseMotion and _drag:
		apply_look(event.relative * mouse_sensitivity)

func apply_look(amount: Vector2) -> void:
	if not solo or InputRouter.ui_suppressed() or get_tree().paused or amount.length_squared() < 0.000001:
		return
	yaw_offset = wrapf(yaw_offset - amount.x, -PI, PI)
	pitch_offset = clampf(pitch_offset - amount.y, -pitch_limit, pitch_limit)
	manual_left = return_delay

func step(delta: float) -> void:
	if InputRouter.ui_suppressed() or get_tree().paused:
		_drag = false
		InputRouter.clear_view_basis(1)
		return
	if InputRouter.has_method("look_axis"):
		apply_look(InputRouter.call("look_axis", 1) * stick_speed * delta)
	manual_left = maxf(0.0, manual_left - delta)
	if manual_left <= 0.0 and not _drag:
		yaw_offset = lerp_angle(yaw_offset, 0.0, 1.0 - exp(-return_speed * delta))
		pitch_offset = lerpf(pitch_offset, 0.0, 1.0 - exp(-return_speed * delta))
	# DuelCamera publishes its physics yaw after applying this adapter's look input.
	# Publishing a rendered transform here would reintroduce a stale/manual-only basis.

func is_manual() -> bool:
	return solo and (manual_left > 0.0 or _drag)

func resolve_anchor(id: String) -> Node3D:
	return get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null

func _clear(f: Fighter, origin: Vector3, point: Vector3) -> bool:
	return f.grapple.line_clear(origin, point)

func capture(f: Fighter, enemy_mode: bool, remember: bool = true) -> Dictionary:
	var origin := f.global_position + Vector3(0, 1.25, 0)
	var manual := is_manual() and f.player_index == 1 and not f.is_cpu
	# Solo traversal targets the current camera even after orbit input settles.
	var camera_aim := camera != null and (manual or (not enemy_mode and solo and f.player_index == 1 and not f.is_cpu))
	var traversal_assist := camera_aim and not enemy_mode
	var wish := f.wish()
	var travel_axis := Vector3(wish.x, 0.0, wish.z)
	var moving := travel_axis.length_squared() > 0.01
	if not moving:
		travel_axis = Vector3(f.forward.x, 0.0, f.forward.z)
	travel_axis = travel_axis.normalized()
	var grab: Dictionary = f.grapple.rope_grab_candidate() if not enemy_mode else {}
	var ray_origin := origin
	var direction := f.forward
	var distance: float = f.grapple.range_m
	if camera_aim:
		var center := camera.get_viewport().get_visible_rect().size * 0.5
		ray_origin = camera.project_ray_origin(center)
		direction = camera.project_ray_normal(center)
	else:
		if wish.length_squared() > 0.01:
			direction = wish.normalized()
	var point := origin + direction * distance
	if camera_aim:
		# Camera depth is longer than hand range; clamp the final hand segment below.
		var ray := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + direction * 100.0, 1 | ArenaLayout.COVER_LAYER | 4)
		ray.collide_with_areas = true
		ray.exclude = [f.get_rid(), f.hurtbox.get_rid()]
		var hit := f.get_world_3d().direct_space_state.intersect_ray(ray)
		point = hit.position if not hit.is_empty() else ray_origin + direction * distance
	var nodes: Array[Node] = get_tree().get_nodes_in_group("fighters" if enemy_mode else "grapple_anchor")
	if not enemy_mode:
		nodes.append_array(get_tree().get_nodes_in_group("deployed_rope"))
	var candidates: Array[Dictionary] = []
	for node in nodes:
		var target := node as Node3D
		if target == null or target == f:
			continue
		if not enemy_mode and target.is_in_group("grapple_anchor") and f.grapple.registry.occupied(target.global_position):
			continue # Reuse the deployed rope candidate; never suggest a second shot at this point.
		if f.grapple.charges <= 0 and not target.is_in_group("deployed_rope"):
			continue
		var rope_token := int(target.get_meta("rope_token", 0))
		if rope_token != 0 and rope_token == f.grapple._deployed_token:
			continue
		if enemy_mode and (not target is Fighter or not target.hurtbox_enabled()):
			continue
		var position: Vector3 = target.global_position + (Vector3.UP if enemy_mode else Vector3.ZERO)
		if rope_token != 0:
			var record: Dictionary = f.grapple.registry.records.get(rope_token, {})
			if record.is_empty():
				continue
			var grip: Dictionary = f.grapple.registry.closest_grip(rope_token, origin)
			if grip.is_empty():
				continue
			position = grip.point
		var offset := position - origin
		var length := offset.length()
		if length > distance or length < 0.1 or not _clear(f, origin, position):
			continue
		if not enemy_mode and not target.is_in_group("deployed_rope") and offset.y < 1.5:
			continue
		var score := length
		if camera_aim:
			var alignment := direction.dot((position - ray_origin).normalized())
			var cone := traversal_assist_degrees if traversal_assist else assist_degrees
			if alignment < cos(deg_to_rad(cone)):
				continue
			if traversal_assist:
				# Only suggest a target that the on-screen cue can actually show.
				if camera.is_position_behind(position) or not camera.get_viewport().get_visible_rect().has_point(camera.unproject_position(position)):
					continue
				if not _clear(f, ray_origin, position):
					continue
				var flat := Vector3(offset.x, 0.0, offset.z)
				var travel_alignment := flat.normalized().dot(travel_axis) if flat.length() > 1.5 else 1.0
				# Orbit is an explicit override; ordinary action follows travel/facing.
				if not manual and travel_alignment < -0.2:
					continue
				var screen_cost := (1.0 - alignment) / maxf(0.001, 1.0 - cos(deg_to_rad(cone)))
				var travel_weight := 0.0 if manual else (0.6 if moving else 0.3)
				score = screen_cost * (1.0 - travel_weight) + (1.0 - travel_alignment) * travel_weight + length / distance * 0.1
			else:
				score = (1.0 - alignment) * 1000.0 + length * 0.01
		else:
			var flat := Vector3(offset.x, 0, offset.z)
			var axis := Vector3(direction.x, 0, direction.z).normalized()
			if flat.length() > 0.05 and flat.normalized().dot(axis) < cos(deg_to_rad(f.grapple.cone_deg)):
				continue
		candidates.append({"id": String(target.get_path()), "point": position, "score": score,
			"kind": "rope" if rope_token != 0 else ("enemy" if enemy_mode else "anchor"),
			"rope_token": rope_token, "reachable": rope_token == 0 or rope_token == int(grab.get("token", 0))})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.id < b.id if is_equal_approx(a.score, b.score) else a.score < b.score)
	# A span already within hand reach has priority over firing another device.
	if not grab.is_empty():
		var record: Dictionary = f.grapple.registry.records[grab.token]
		candidates.push_front({"id": String(record.marker.get_path()), "point": grab.point,
			"score": -INF, "kind": "rope", "rope_token": grab.token, "reachable": true})
	var id := ""
	var kind := ""
	var selected_token := 0
	var reachable := false
	var key := "%d:%s" % [f.player_index, enemy_mode]
	if not candidates.is_empty():
		var chosen: Dictionary = candidates[0]
		for candidate in candidates:
			if candidate.id == _previous.get(key, "") and candidate.score <= chosen.score + (traversal_stickiness if traversal_assist else (0.15 if manual else 0.5)):
				chosen = candidate
		id = chosen.id
		point = chosen.point
		kind = chosen.kind
		selected_token = chosen.rope_token
		reachable = chosen.reachable
	if remember:
		_previous[key] = id
	point = origin + (point - origin).limit_length(distance)
	return {"tick": InputRouter.frame(), "player": f.player_index, "enemy_mode": enemy_mode,
		"origin": origin, "point": point, "direction": (point - origin).normalized(), "target_id": id, "manual": manual, "camera_aim": camera_aim,
		"candidate_kind": kind, "rope_token": selected_token, "reachable": reachable,
		"contact_distance": origin.distance_to(point)}

func _exit_tree() -> void:
	InputRouter.clear_view_basis(1)
