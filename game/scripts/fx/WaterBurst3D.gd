class_name WaterBurst3D
extends Node3D
## Presentation-only water contact. Two draw submissions per burst, no global RNG,
## particles, lights, collision or gameplay writes. All dimensions are visual PLACEHOLDERs.

const MAX_ACTIVE := 18
const MAX_DROPS := 14
const RING_SEGMENTS := 24
const GROUP := &"water_burst_3d"

enum Kind { STEP, DASH, LIGHT, MEDIUM, HEAVY }

var kind: int = Kind.STEP
var age: float = 0.0
var duration: float = 0.65
var field: WaveField
var _owner: WeakRef
var _origin := Vector3.ZERO
var _velocities: Array[Vector3] = []
var _sizes: Array[float] = []
var _drops: MultiMesh
var _lines: ImmediateMesh
var _material: StandardMaterial3D
var _radius: float = 0.6
var _lift: float = 0.4


static func play(near: Node, at: Vector3, velocity: Vector3, event: int, seed_value: int) -> WaterBurst3D:
	if not Fx.enabled or GameState.water == null or near == null or not near.is_inside_tree():
		return null
	if near.get_tree().get_nodes_in_group(GROUP).size() >= MAX_ACTIVE:
		return null
	var burst := WaterBurst3D.new()
	burst.kind = clampi(event, Kind.STEP, Kind.HEAVY)
	burst.field = GameState.water
	burst._owner = weakref(near)
	burst._origin = Vector3(at.x, burst.field.height(at.x, at.z), at.z)
	Fx.root(near).add_child(burst)
	burst.add_to_group(GROUP)
	burst.global_position = burst._origin
	burst._build(velocity, seed_value)
	burst._draw()
	return burst


func _build(velocity: Vector3, seed_value: int) -> void:
	var power: float = [0.35, 0.7, 0.5, 1.0, 1.35][kind]
	duration = 0.48 + power * 0.3
	_radius = 0.3 + power * 0.85
	_lift = 0.18 + power * 0.35
	var count: int = [4, 7, 5, 10, MAX_DROPS][kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_material = Fx.mat(Color(0.68, 0.9, 0.92, 0.85), false)
	var drop_mesh := SphereMesh.new()
	drop_mesh.radius = 1.0
	drop_mesh.height = 2.0
	drop_mesh.radial_segments = 6
	drop_mesh.rings = 3
	_drops = MultiMesh.new()
	_drops.transform_format = MultiMesh.TRANSFORM_3D
	_drops.mesh = drop_mesh
	_drops.instance_count = count
	var drops_node := MultiMeshInstance3D.new()
	drops_node.multimesh = _drops
	drops_node.material_override = _material
	drops_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(drops_node)
	var drift := Vector3(velocity.x, 0.0, velocity.z).limit_length(12.0) * 0.08
	for i in count:
		var angle := TAU * float(i) / float(count) + rng.randf_range(-0.2, 0.2)
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		_velocities.append(outward * rng.randf_range(0.5, 1.0) * _radius * 2.0 + drift + Vector3.UP * rng.randf_range(1.3, 2.2) * sqrt(power))
		_sizes.append(rng.randf_range(0.025, 0.045) * (0.75 + power * 0.5))
	_lines = ImmediateMesh.new()
	add_child(Fx.mesh(_lines, _material))


func _process(dt: float) -> void:
	if not Fx.enabled or GameState.water != field:
		queue_free()
		return
	var source: Node = _owner.get_ref() as Node
	if source is Fighter and (source.frozen_frames > 0 or source.hitstop_frames > 0):
		return
	age += dt
	if age >= duration:
		queue_free()
		return
	_draw()


func _draw() -> void:
	var progress := clampf(age / duration, 0.0, 1.0)
	_material.albedo_color.a = 0.85 * (1.0 - smoothstep(0.5, 1.0, progress))
	for i in _velocities.size():
		var point := _velocities[i] * age + Vector3.DOWN * 4.9 * age * age
		var surface := field.height(_origin.x + point.x, _origin.z + point.z) - _origin.y
		var size := _sizes[i] * (1.0 - progress * 0.45)
		if point.y < surface - 0.02:
			size = 0.0
		var basis := Basis.IDENTITY.scaled(Vector3(size, size * 1.7, size))
		_drops.set_instance_transform(i, Transform3D(basis, point + Vector3.UP * 0.035))
	_lines.clear_surfaces()
	_lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := lerpf(0.12, _radius, progress)
	var width := lerpf(0.035, 0.009, progress)
	for i in RING_SEGMENTS:
		var a := TAU * float(i) / RING_SEGMENTS
		var b := TAU * float(i + 1) / RING_SEGMENTS
		_quad(_surface(a, radius), _surface(b, radius), _surface(b, radius + width), _surface(a, radius + width))
	# Short vertical crowns, never chest-high curtains. Steps need only drops/ring.
	if kind != Kind.STEP and progress < 0.65:
		for arc in 3:
			var angle := float(arc) * TAU / 3.0
			var side := Vector3(-sin(angle), 0.0, cos(angle)) * width
			for segment in 5:
				var a := _arc(angle, float(segment) / 5.0, progress)
				var b := _arc(angle, float(segment + 1) / 5.0, progress)
				_quad(a - side, b - side, b + side, a + side)
	_lines.surface_end()


func _surface(angle: float, radius: float) -> Vector3:
	var p := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	p.y = field.height(_origin.x + p.x, _origin.z + p.z) - _origin.y + 0.025
	return p


func _arc(angle: float, u: float, progress: float) -> Vector3:
	var p := _surface(angle, (0.12 + u * _radius) * (0.4 + progress))
	p.y += sin(u * PI) * _lift * (1.0 - progress / 0.65)
	return p


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex in [a, b, c, a, c, d]:
		_lines.surface_add_vertex(vertex)
