class_name RopeVisual
extends Node3D
## Bounded presentation-only Verlet cable. Endpoints/length come from authoritative hook/registry.
## Provisional art tuning; never feeds segments back to collision, inventory or fighter movement.
const SEGMENTS: int = 16
const ITERATIONS: int = 4
const MAX_LENGTH: float = 32.0
const RADIUS: float = 0.012
const SIDES: int = 6
const Burst = preload("res://scripts/fx/WaterBurst3D.gd")
var points: PackedVector3Array = []
var previous: PackedVector3Array = []
var water_entries: int = 0
var _mesh: ImmediateMesh
var _drawing: MeshInstance3D
var _ripple_cooldown: float = 0.0
var _ticks: int = 0
var _last_start: Vector3
var _last_end: Vector3

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_mesh = ImmediateMesh.new()
	_drawing = MeshInstance3D.new()
	_drawing.mesh = _mesh
	_drawing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_drawing.material_override = material
	add_child(_drawing)

func reset_rope(start: Vector3, end: Vector3) -> void:
	if _mesh != null:
		_mesh.clear_surfaces()
	points.resize(SEGMENTS + 1)
	previous.resize(SEGMENTS + 1)
	for i: int in SEGMENTS + 1:
		points[i] = start.lerp(end, float(i) / float(SEGMENTS))
		previous[i] = points[i]
	_last_start = start
	_last_end = end
	_ripple_cooldown = 0.0

func update_rope(start: Vector3, end: Vector3, rest_length: float, delta: float, water: WaveField = null, loose: bool = false) -> void:
	if not start.is_finite() or not end.is_finite() or not is_finite(rest_length) or not is_finite(delta):
		return
	if delta <= 0.0 and not points.is_empty():
		return  # Hitstop/pause holds the drawing, including constraint relaxation.
	var distance: float = start.distance_to(end)
	# Do not invent replacement authoritative endpoints for an invalid/out-of-contract shot.
	if distance > MAX_LENGTH:
		visible = false
		return
	visible = true
	global_transform = Transform3D.IDENTITY
	if points.size() != SEGMENTS + 1 or start.distance_to(_last_start) > 4.0 or end.distance_to(_last_end) > 4.0:
		reset_rope(start, end)
	var dt: float = clampf(delta, 0.0, 1.0 / 30.0)
	_ripple_cooldown = maxf(0.0, _ripple_cooldown - dt)
	_ticks += 1
	var length: float = clampf(maxf(distance, rest_length), 0.02, MAX_LENGTH)
	var spacing: float = length / float(SEGMENTS)
	for i: int in range(1, SEGMENTS):
		var point: Vector3 = points[i]
		var submerged: bool = water != null and point.y < water.height(point.x, point.z)
		var retention: float = pow(0.70 if submerged else 0.985, dt * 60.0)
		var inertia: Vector3 = (point - previous[i]) * retention if dt > 0.0 else Vector3.ZERO
		previous[i] = point
		points[i] = point + inertia + Vector3.DOWN * (2.8 if submerged else 9.8) * dt * dt
		var surface: float = water.height(point.x, point.z) if water != null else 0.0
		# Shallow river bottom is a bounded visual approximation, not a terrain collision query.
		points[i].y = maxf(points[i].y, surface - 1.5 if water != null else RADIUS)
		if water != null and point.y >= surface and points[i].y < surface:
			water_entries += 1
			if _ripple_cooldown <= 0.0 and is_inside_tree() and water == GameState.water:
				Burst.play(self, points[i], inertia / maxf(dt, 0.0001), Burst.Kind.STEP, _ticks * 31 + i)
				_ripple_cooldown = 0.3
	for iteration: int in ITERATIONS:
		points[0] = start
		points[SEGMENTS] = end
		for i: int in SEGMENTS:
			var difference: Vector3 = points[i + 1] - points[i]
			var span: float = difference.length()
			if span <= 0.000001:
				continue
			# Slack cable may compress; never push segments apart into unstable coils.
			if span <= spacing and loose:
				continue
			var correction: Vector3 = difference * ((span - spacing) / span)
			if i == 0:
				points[i + 1] -= correction
			elif i == SEGMENTS - 1:
				points[i] += correction
			else:
				points[i] += correction * 0.5
				points[i + 1] -= correction * 0.5
		for i: int in range(1, SEGMENTS):
			var surface: float = water.height(points[i].x, points[i].z) if water != null else 0.0
			points[i].y = maxf(points[i].y, surface - 1.5 if water != null else RADIUS)
			# Hard geometric envelope protects rendering from long-frame/teleport energy.
			var origin: Vector3 = start.lerp(end, float(i) / float(SEGMENTS))
			points[i] = origin + (points[i] - origin).limit_length(length)
	points[0] = start
	points[SEGMENTS] = end
	_last_start = start
	_last_end = end
	_draw()

func _draw() -> void:
	if _mesh == null:
		return
	_mesh.clear_surfaces()
	var has_span: bool = false
	for i: int in SEGMENTS:
		if points[i].distance_squared_to(points[i + 1]) > 0.000001:
			has_span = true
			break
	if not has_span:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in SEGMENTS:
		var axis: Vector3 = (points[segment + 1] - points[segment]).normalized()
		if axis.length_squared() < 0.01:
			continue
		var across: Vector3 = axis.cross(Vector3.UP if absf(axis.y) < 0.95 else Vector3.RIGHT).normalized()
		var up: Vector3 = axis.cross(across).normalized()
		for side: int in SIDES:
			var angle: float = TAU * float(side) / float(SIDES)
			var next_angle: float = TAU * float(side + 1) / float(SIDES)
			var offset: Vector3 = (across * cos(angle) + up * sin(angle)) * RADIUS
			var next_offset: Vector3 = (across * cos(next_angle) + up * sin(next_angle)) * RADIUS
			var a: Vector3 = points[segment] + offset
			var b: Vector3 = points[segment + 1] + offset
			var c: Vector3 = points[segment + 1] + next_offset
			var d: Vector3 = points[segment] + next_offset
			_mesh.surface_set_color(Color(0.72, 0.52, 0.24).darkened(0.18 * (side % 3)))
			for vertex: Vector3 in [a, b, c, a, c, d]:
				_mesh.surface_add_vertex(vertex)
	_mesh.surface_end()
