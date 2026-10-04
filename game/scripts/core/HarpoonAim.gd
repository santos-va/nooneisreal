class_name HarpoonAim
extends Node
## Input adapter only. A fire snapshots this world intent; replay injects that snapshot.
## PLACEHOLDER UX tuning, pending device playtest.
@export var mouse_sensitivity: float = 0.004
@export var stick_speed: float = 1.8
@export var return_delay: float = 2.0
@export var return_speed: float = 2.0
@export var assist_degrees: float = 10.0
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
	pitch_offset = clampf(pitch_offset - amount.y, -0.55, 0.55)
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
	if solo and (is_manual() or absf(yaw_offset) > 0.001 or absf(pitch_offset) > 0.001):
		var forward := -camera.global_basis.z
		forward.y = 0.0
		InputRouter.set_view_basis(1, forward.normalized())
	else:
		InputRouter.clear_view_basis(1)

func is_manual() -> bool:
	return solo and (manual_left > 0.0 or _drag)

func resolve_anchor(id: String) -> Node3D:
	return get_node_or_null(NodePath(id)) as Node3D if not id.is_empty() else null

func _clear(f: Fighter, origin: Vector3, point: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(origin, point, ArenaLayout.COVER_LAYER | 1)
	ray.exclude = [f.get_rid(), f.hurtbox.get_rid()]
	return f.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func capture(f: Fighter, enemy_mode: bool, remember: bool = true) -> Dictionary:
	var origin := f.global_position + Vector3(0, 1.25, 0)
	var manual := is_manual() and f.player_index == 1 and not f.is_cpu
	var ray_origin := origin
	var direction := f.forward
	var distance: float = f.grapple.range_m
	if manual:
		var center := camera.get_viewport().get_visible_rect().size * 0.5
		ray_origin = camera.project_ray_origin(center)
		direction = camera.project_ray_normal(center)
	else:
		var wish := f.wish()
		if wish.length_squared() > 0.01:
			direction = wish.normalized()
	var point := origin + direction * distance
	if manual:
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
		if f.grapple.charges <= 0 and not target.is_in_group("deployed_rope"):
			continue
		if target.is_in_group("deployed_rope") and int(target.get_meta("rope_token", 0)) != f.grapple.reusable_rope():
			continue
		if enemy_mode and (not target is Fighter or not target.hurtbox_enabled()):
			continue
		var position: Vector3 = target.global_position + (Vector3.UP if enemy_mode else Vector3.ZERO)
		var offset := position - origin
		var length := offset.length()
		if length > distance or length < 0.1 or not _clear(f, origin, position):
			continue
		if not enemy_mode and not target.is_in_group("deployed_rope") and offset.y < 1.5:
			continue
		var score := length
		if manual:
			var alignment := direction.dot((position - ray_origin).normalized())
			if alignment < cos(deg_to_rad(assist_degrees)):
				continue
			score = (1.0 - alignment) * 1000.0 + length * 0.01
		else:
			var flat := Vector3(offset.x, 0, offset.z)
			var axis := Vector3(direction.x, 0, direction.z).normalized()
			if flat.length() > 0.05 and flat.normalized().dot(axis) < cos(deg_to_rad(f.grapple.cone_deg)):
				continue
		candidates.append({"id": String(target.get_path()), "point": position, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.id < b.id if is_equal_approx(a.score, b.score) else a.score < b.score)
	var id := ""
	var key := "%d:%s" % [f.player_index, enemy_mode]
	if not candidates.is_empty():
		var chosen: Dictionary = candidates[0]
		for candidate in candidates:
			if candidate.id == _previous.get(key, "") and candidate.score <= chosen.score + (0.15 if manual else 0.5):
				chosen = candidate
		id = chosen.id
		point = chosen.point
	if remember:
		_previous[key] = id
	point = origin + (point - origin).limit_length(distance)
	return {"tick": InputRouter.frame(), "player": f.player_index, "enemy_mode": enemy_mode,
		"origin": origin, "point": point, "direction": (point - origin).normalized(), "target_id": id, "manual": manual}

func _exit_tree() -> void:
	InputRouter.clear_view_basis(1)
