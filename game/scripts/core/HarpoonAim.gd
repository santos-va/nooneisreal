class_name HarpoonAim
extends Node
## Input adapter only. A fire snapshots this world intent; replay injects that snapshot.
## PLACEHOLDER UX tuning, pending device playtest.
@export var mouse_sensitivity: float = 0.004
@export var stick_speed: float = 1.8
@export var return_delay: float = 2.0
@export var return_speed: float = 2.0
@export var assist_degrees: float = 10.0
## Traversal selection for the human P1 parkour shot and transfer (T8 variant Г, docs/GDD/06-UI-UX.md § «Трос без
## прицілювання»): the world selects around the hero and the camera only weighs; there is no cone. A press without a
## target is no shot. Every number below is a PLACEHOLDER until the device playtest.
@export var traversal_stickiness: float = 0.12
@export var traversal_switch_delay: float = 0.25 # s before a new target may replace a still-valid one
@export var traversal_behind: float = -0.2 # travel alignment below this is "behind": a candidate only in the frame
@export var traversal_air_speed: float = 2.0 # m/s: swinging or airborne, this flat speed becomes the travel axis
@export var traversal_too_far: float = 1.5 # × range: the grey TOO FAR ring and reason
@export var traversal_camera_hidden_cost: float = 0.25
## Score weights [distance, direction, height, visibility]; lower total is better.
const TRAVERSAL_WEIGHTS := {"moving": [0.25, 0.40, 0.10, 0.25], "standing": [0.25, 0.20, 0.10, 0.45], "manual": [0.25, 0.0, 0.10, 0.65]}
## Reason codes of a traversal packet without a target, in the order the first matching one wins.
const REASONS := ["no_harpoons", "behind", "above", "too_far", "none"]
@export var pitch_limit: float = 1.25 # PLACEHOLDER: allow aiming at overhead street anchors.
var camera: Camera3D
var solo: bool = false
var yaw_offset: float = 0.0
var pitch_offset: float = 0.0
var manual_left: float = 0.0
var _drag: bool = false
var last_gamepad: bool = false
var _previous: Dictionary = {}
var _changed_at: Dictionary = {}
## One traversal packet per physics tick, published by the camera (CityCamera): the marker, the label and the press
## all read it. `_published_before` is the packet of the tick before.
var published: Dictionary = {}
var _published_before: Dictionary = {}

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
	_changed_at.clear()
	published = {}
	_published_before = {}
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

## `anchors_only` (traversal only): skip existing spans, for a re-selection that must launch a device (GrappleHook).
func capture(f: Fighter, enemy_mode: bool, remember: bool = true, anchors_only: bool = false) -> Dictionary:
	var origin := f.global_position + Vector3(0, 1.25, 0)
	var manual := is_manual() and f.player_index == 1 and not f.is_cpu
	# Solo traversal targets the current camera even after orbit input settles.
	var camera_aim := camera != null and (manual or (not enemy_mode and solo and f.player_index == 1 and not f.is_cpu))
	if camera_aim and not enemy_mode:
		return _capture_traversal(f, origin, manual, remember, anchors_only)
	# Enemy shots, CPU, the side camera and SHARED P2 keep this selection unchanged (T8: bit for bit as the base).
	var wish := f.wish()
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
			if alignment < cos(deg_to_rad(assist_degrees)):
				continue
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
			if candidate.id == _previous.get(key, "") and candidate.score <= chosen.score + (0.15 if manual else 0.5):
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


## T8 Г. Hard filters: a free anchor (stock left) or an existing span under the unchanged GRAB/APPROACH ROPE rules;
## hand range now and at contact; 1.5 m above the hand; a clear line from the hand. A point behind the travel axis is a
## candidate only inside the frame. The camera line and the frame are weights, never filters.
func _capture_traversal(f: Fighter, origin: Vector3, manual: bool, remember: bool, anchors_only: bool) -> Dictionary:
	var hook: GrappleHook = f.grapple
	var distance: float = hook.range_m
	var swinging := hook.attached and hook.phase == GrappleHook.Phase.HANG
	var flat_velocity := Vector3(f.velocity.x, 0.0, f.velocity.z)
	var wish := f.wish()
	var travel_axis := Vector3(wish.x, 0.0, wish.z)
	var moving := travel_axis.length_squared() > 0.01
	if (swinging or not f.on_ground()) and flat_velocity.length() >= traversal_air_speed:
		travel_axis = flat_velocity
		moving = true
	elif not moving:
		travel_axis = Vector3(f.forward.x, 0.0, f.forward.z)
	travel_axis = travel_axis.normalized()
	var weights: Array = TRAVERSAL_WEIGHTS["manual" if manual else ("moving" if moving else "standing")]
	var view := camera.get_viewport().get_visible_rect()
	var eye := camera.global_position
	var grab: Dictionary = hook.rope_grab_candidate() if not anchors_only else {}
	var nodes: Array[Node] = get_tree().get_nodes_in_group("grapple_anchor")
	if not anchors_only:
		nodes.append_array(get_tree().get_nodes_in_group("deployed_rope"))
	var candidates: Array[Dictionary] = []
	var behind_off_frame := false
	var low_in_reach := false
	var far_any := false
	var far_distance := INF
	var far_point := Vector3.ZERO
	for node in nodes:
		var target := node as Node3D
		if target == null or target == f:
			continue
		var is_rope := target.is_in_group("deployed_rope")
		if not is_rope and hook.registry.occupied(target.global_position):
			continue # Reuse the deployed rope candidate; never suggest a second shot at this point.
		if hook.charges <= 0 and not is_rope:
			continue
		var rope_token := int(target.get_meta("rope_token", 0))
		if rope_token != 0 and rope_token == hook._deployed_token:
			continue
		var position: Vector3 = target.global_position
		if rope_token != 0:
			var record: Dictionary = hook.registry.records.get(rope_token, {})
			if record.is_empty():
				continue
			var grip: Dictionary = hook.registry.closest_grip(rope_token, origin)
			if grip.is_empty():
				continue
			position = grip.point
		var offset := position - origin
		var length := offset.length()
		if length < 0.1:
			continue
		if rope_token == 0:
			# Range from the hand now and from the hand at contact: a transfer in the swing has no windup (T8), a fresh
			# shot travels through it; both coast during the flight (GrappleHook.contact_hand).
			var launch_length := maxf(length, position.distance_to(hook.contact_hand(position, not swinging)))
			if launch_length > distance:
				if launch_length <= distance * traversal_too_far and offset.y >= 1.5 and _clear(f, origin, position):
					far_any = true
					if launch_length < far_distance and _in_frame(position, view):
						far_distance = launch_length
						far_point = position
				continue
			if offset.y < 1.5:
				low_in_reach = true
				continue
		elif length > distance:
			continue
		if not _clear(f, origin, position):
			continue
		var in_frame := _in_frame(position, view)
		var flat := Vector3(offset.x, 0.0, offset.z)
		var travel_alignment := flat.normalized().dot(travel_axis) if flat.length() > 1.5 else 1.0
		if travel_alignment < traversal_behind and not in_frame:
			behind_off_frame = true
			continue
		var camera_hidden := in_frame and not _clear(f, eye, position)
		var visibility := 1.0
		if in_frame:
			visibility = (camera.unproject_position(position) - view.get_center()).length() / maxf(1.0, view.size.length() * 0.5) * 0.5
			if camera_hidden:
				visibility += traversal_camera_hidden_cost
		var elevation := rad_to_deg(atan2(offset.y, flat.length()))
		var height_cost := clampf((30.0 - elevation) / 30.0, 0.0, 1.0) if elevation < 30.0 else clampf((elevation - 70.0) / 20.0, 0.0, 1.0)
		var score: float = float(weights[0]) * length / distance + float(weights[1]) * (1.0 - travel_alignment) * 0.5 \
			+ float(weights[2]) * height_cost + float(weights[3]) * visibility
		candidates.append({"id": String(target.get_path()), "point": position, "score": score,
			"kind": "rope" if rope_token != 0 else "anchor", "rope_token": rope_token,
			"reachable": rope_token == 0 or rope_token == int(grab.get("token", 0)), "in_frame": in_frame, "camera_hidden": camera_hidden})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.id < b.id if is_equal_approx(a.score, b.score) else a.score < b.score)
	# A span already within hand reach has priority over firing another device.
	if not grab.is_empty():
		var record: Dictionary = hook.registry.records[grab.token]
		candidates.push_front({"id": String(record.marker.get_path()), "point": grab.point, "score": -INF, "kind": "rope",
			"rope_token": grab.token, "reachable": true, "in_frame": _in_frame(grab.point, view), "camera_hidden": false})
	var key := "%d:%s" % [f.player_index, false]
	var previous_id: String = _previous.get(key, "")
	var now := InputRouter.frame()
	var chosen: Dictionary = {}
	if not candidates.is_empty():
		chosen = candidates[0]
		if not is_inf(float(chosen.score)) and chosen.id != previous_id:
			for candidate in candidates:
				if candidate.id != previous_id:
					continue
				# The current target stays while valid and nearly as good, and for traversal_switch_delay after any
				# change: the marker never flickers between two close anchors (T8, the veteran's view).
				var locked := now - int(_changed_at.get(key, -1000000)) < roundi(traversal_switch_delay * Engine.physics_ticks_per_second)
				if candidate.score <= chosen.score + traversal_stickiness or locked:
					chosen = candidate
	var id: String = chosen.get("id", "")
	if remember:
		if id != previous_id:
			_changed_at[key] = now
		_previous[key] = id
	var point: Vector3 = chosen.get("point", origin + travel_axis * distance)
	point = origin + (point - origin).limit_length(distance)
	var reason := ""
	if id.is_empty():
		if hook.charges <= 0:
			reason = "no_harpoons"
		elif behind_off_frame:
			reason = "behind"
		elif low_in_reach:
			reason = "above"
		elif far_any:
			reason = "too_far"
		else:
			reason = "none"
	return {"tick": now, "player": f.player_index, "enemy_mode": false,
		"origin": origin, "point": point, "direction": (point - origin).normalized(), "target_id": id, "manual": manual, "camera_aim": true,
		"candidate_kind": chosen.get("kind", ""), "rope_token": int(chosen.get("rope_token", 0)), "reachable": bool(chosen.get("reachable", false)),
		"contact_distance": origin.distance_to(point), "assist": true, "reason": reason,
		"in_frame": bool(chosen.get("in_frame", false)), "camera_hidden": bool(chosen.get("camera_hidden", false)),
		"far_point": far_point, "far_distance": far_distance if id.is_empty() and not is_inf(far_distance) else 0.0}


func _in_frame(position: Vector3, view: Rect2) -> bool:
	return not camera.is_position_behind(position) and view.has_point(camera.unproject_position(position))


## The camera's one packet for this physics tick (T8: a single sample feeds the marker, the label and the press).
func publish(f: Fighter) -> Dictionary:
	var packet := capture(f, false)
	if int(published.get("tick", -1)) != int(packet.tick):
		_published_before = published
	published = packet
	return packet


## What a press on this tick fires at: the traversal packet the player saw, published on an earlier tick, so a stick
## twitch in the press tick (L3) cannot change the target (T8). Without a publishing camera: a fresh capture.
func press_packet(f: Fighter, enemy_mode: bool) -> Dictionary:
	if not enemy_mode:
		var now := InputRouter.frame()
		for packet: Dictionary in [published, _published_before]:
			if not packet.is_empty() and int(packet.player) == f.player_index and int(packet.tick) < now and int(packet.tick) >= now - 2:
				return packet.duplicate(true)
	return capture(f, enemy_mode)

func _exit_tree() -> void:
	InputRouter.clear_view_basis(1)
