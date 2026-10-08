class_name CityPasserby
extends Node3D
## A temporary passer-by of the city events (plan 2026-10-08-City-Events-Stage-1, step 1): not one of the 12 residents,
## never saved, no hurtbox and no collider, removed when its event ends. The body is the procedural resident mannequin
## (NpcAppearance) until T6 gives the event people their own models. It walks straight legs on the ground: the floor
## under it is followed by a ray and a wall in front stops it (it never climbs and never walks through a wall).
## Props are procedural too: a knife (В1) and five flat leaves circling over the head (В2). All sizes PLACEHOLDER.
signal arrived

const INK := Color("2b2230")
## T7 § 5.1: the first version is a procedural grey one — flat leaf, one shade, a graphite line, no glow.
const LEAF_FILL := Color("8e9a86")
const LEAF_SHADE := Color("6f7a6a")
const LEAF_COUNT := 5            # Santos: «5 штук»
const LEAF_RING_RADIUS := 0.38   # PLACEHOLDER metres around the head
const LEAF_TURN_SPEED := 1.4     # PLACEHOLDER rad/s, constant (never pulses)
const LEAF_SIZE := 0.30          # PLACEHOLDER metres, tip to stem
const STEP_HEIGHT := 0.6         # the floor ray starts this far above the feet: ramps yes, walls and ledges no
const WALL_PROBE := 0.45         # how far ahead a wall stops the walk

var appearance_seed: int = 0
var visual: Node3D
var speech: Label3D
var knife: Node3D
var leaf_ring: Node3D
var pose: String = ""            # "" | threat | surrender | beckon | offer | shrug
var target := Vector3.INF
var speed: float = 0.0
var blocked: bool = false
var clock: float = 0.0
var speech_left: float = 0.0
var _height_scale: float = 1.0


func setup(seed_value: int) -> void:
	appearance_seed = seed_value
	visual = NpcAppearance.build({"appearance_seed": seed_value})
	visual.scale *= 0.92
	_height_scale = visual.scale.y
	add_child(visual)
	speech = Label3D.new()
	speech.name = "Speech"
	speech.position.y = 2.3 * _height_scale + 0.2
	speech.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	speech.font_size = 32
	speech.pixel_size = 0.008
	speech.outline_size = 8
	speech.modulate = Color("fff1d8")
	speech.visible = false
	add_child(speech)


## The top of the head in this node's space (the mannequin's hair cap ends near 1.97 m before its scale).
func head_top() -> float:
	return 1.97 * _height_scale


func say(text: String, seconds: float = 3.0) -> void:
	speech.text = text
	speech_left = seconds
	speech.visible = not text.is_empty()


func face(point: Vector3) -> void:
	var direction: Vector3 = point - global_position
	if Vector2(direction.x, direction.z).length_squared() > 0.0001:
		rotation.y = atan2(-direction.x, -direction.z)


func walk_to(point: Vector3, metres_per_second: float) -> void:
	target = point
	speed = metres_per_second
	blocked = false


func stop() -> void:
	target = Vector3.INF
	speed = 0.0


func walking() -> bool:
	return target.is_finite()


func show_knife(visible_now: bool) -> void:
	if visible_now and knife == null:
		var arms: Array = visual.get("_arms")
		if arms.size() < 2:
			return
		knife = Node3D.new()
		knife.name = "Knife"
		knife.position = Vector3(0.025, -0.62, -0.04)
		(arms[1] as Node3D).add_child(knife)
		_box(knife, "Handle", Vector3.ZERO, Vector3(0.035, 0.11, 0.03), Color("3b2f2c"))
		_box(knife, "Blade", Vector3(0, -0.14, 0), Vector3(0.028, 0.18, 0.008), Color("b9bdc0"))
	if knife != null:
		knife.visible = visible_now


## Five flat leaves on a ring over the head, turning at a constant rate (В2; procedural until T6's art).
func show_leaves(visible_now: bool) -> void:
	if visible_now and leaf_ring == null:
		leaf_ring = Node3D.new()
		leaf_ring.name = "LeafRing"
		leaf_ring.position.y = head_top() + 0.16
		add_child(leaf_ring)
		var fill := _flat_material(LEAF_FILL)
		var shade := _flat_material(LEAF_SHADE)
		var ink := _flat_material(INK)
		for index: int in LEAF_COUNT:
			var angle: float = TAU * float(index) / float(LEAF_COUNT)
			var holder := Node3D.new()
			holder.name = "Leaf%d" % index
			holder.position = Vector3(sin(angle), 0.0, cos(angle)) * LEAF_RING_RADIUS
			# Each leaf faces out from the head and leans back a little, so its silhouette reads from the street.
			holder.rotation = Vector3(-0.35, angle, 0.0)
			leaf_ring.add_child(holder)
			var outline := MeshInstance3D.new()
			outline.name = "Line"
			outline.mesh = leaf_mesh(LEAF_SIZE * 1.12, 0.0)
			outline.material_override = ink
			outline.position = Vector3(0, -0.012, -0.004)
			holder.add_child(outline)
			var body := MeshInstance3D.new()
			body.name = "Fill"
			body.mesh = leaf_mesh(LEAF_SIZE, 0.0)
			body.material_override = fill
			holder.add_child(body)
			var vein := MeshInstance3D.new()
			vein.name = "Shade"
			vein.mesh = leaf_mesh(LEAF_SIZE * 0.55, 0.0)
			vein.material_override = shade
			vein.position = Vector3(0, 0.0, 0.003)
			holder.add_child(vein)
	if leaf_ring != null:
		leaf_ring.visible = visible_now


## A flat seven-fingered leaf in the XY plane (stem at the origin, tip up): seven lanceolate leaflets fanned from
## the stem, the middle one longest — the silhouette Santos named, drawn without any texture or credits.
static func leaf_mesh(size: float, _seed: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spread: Array[float] = [-1.25, -0.82, -0.40, 0.0, 0.40, 0.82, 1.25]
	var lengths: Array[float] = [0.42, 0.68, 0.88, 1.0, 0.88, 0.68, 0.42]
	for leaflet: int in spread.size():
		var direction := Vector2(sin(spread[leaflet]), cos(spread[leaflet]))
		var side := Vector2(direction.y, -direction.x)
		var length: float = size * lengths[leaflet]
		var width: float = length * 0.16
		var points: Array[Vector2] = [Vector2.ZERO,
			direction * length * 0.30 + side * width, direction * length * 0.62 + side * width * 0.8, direction * length,
			direction * length * 0.62 - side * width * 0.8, direction * length * 0.30 - side * width]
		for corner: int in range(1, points.size() - 1):
			for point: Vector2 in [points[0], points[corner], points[corner + 1]]:
				surface.set_normal(Vector3.BACK)
				surface.add_vertex(Vector3(point.x, point.y, 0.0))
	return surface.commit()


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	return material


func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _flat_material(color)
	mesh.position = at
	parent.add_child(mesh)


func _physics_process(delta: float) -> void:
	clock += delta
	speech_left = maxf(0.0, speech_left - delta)
	speech.visible = speech_left > 0.0 and not speech.text.is_empty()
	var moved: float = 0.0
	if target.is_finite() and speed > 0.0:
		var flat := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
		if flat.length() <= 0.02:
			stop()
			arrived.emit()
		else:
			var step: Vector3 = flat.normalized() * minf(flat.length(), speed * delta)
			blocked = _wall_ahead(flat.normalized())
			if not blocked:
				var before := global_position
				global_position += step
				_follow_floor()
				moved = (global_position - before).length()
				face(global_position + step)
	if leaf_ring != null and leaf_ring.visible:
		leaf_ring.rotation.y = wrapf(leaf_ring.rotation.y + LEAF_TURN_SPEED * delta, -PI, PI)
	if visual != null and visual.has_method("set_motion"):
		visual.call("set_motion", moved / maxf(delta, 0.0001), clock)
		_apply_pose()
		if visual.has_method("step_clothing"):
			visual.call("step_clothing", delta)


func _apply_pose() -> void:
	var arms: Array = visual.get("_arms")
	if arms.size() < 2 or pose.is_empty():
		return
	match pose:
		"threat":
			(arms[1] as Node3D).rotation = Vector3(1.35, 0.0, 0.08)
		"surrender":
			(arms[0] as Node3D).rotation = Vector3(2.85, 0.0, -0.3)
			(arms[1] as Node3D).rotation = Vector3(2.85, 0.0, 0.3)
		"beckon":
			(arms[1] as Node3D).rotation = Vector3(1.9, 0.0, 0.5 + sin(clock * 11.0) * 0.2)
		"offer":
			(arms[0] as Node3D).rotation = Vector3(1.05, 0.0, 0.15)
		"shrug":
			(arms[0] as Node3D).rotation = Vector3(0.5, 0.0, -0.55)
			(arms[1] as Node3D).rotation = Vector3(0.5, 0.0, 0.55)


func _wall_ahead(direction: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var origin: Vector3 = global_position + Vector3.UP * 0.9
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * WALL_PROBE, 1)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _follow_floor() -> void:
	var origin: Vector3 = global_position + Vector3.UP * STEP_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * (STEP_HEIGHT + 3.0), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and Vector3(hit.normal).dot(Vector3.UP) > 0.5:
		global_position.y = float(hit.position.y)
