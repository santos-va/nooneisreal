class_name CityBackdrop
extends CityMarket
## Bounded non-interactive skyline. All authored volumes remain beyond the district boundary.
const BUILDING_LIMIT: int = 10
const TRIANGLE_LIMIT: int = 16000

static func skyline() -> Array[Dictionary]:
	return [
		{"center": Vector3(-42, 0, -68), "size": Vector3(16, 14, 12), "paint": "plaster"},
		{"center": Vector3(-21, 0, -71), "size": Vector3(17, 18, 12), "paint": "slate"},
		{"center": Vector3(0, 0, -66), "size": Vector3(16, 12, 10), "paint": "terracotta"},
		{"center": Vector3(21, 0, -74), "size": Vector3(18, 21, 12), "paint": "plaster"},
		{"center": Vector3(43, 0, -69), "size": Vector3(16, 16, 12), "paint": "slate"},
		{"center": Vector3(-66, 0, -15), "size": Vector3(12, 17, 16), "paint": "terracotta"},
		{"center": Vector3(-65, 0, 17), "size": Vector3(12, 13, 18), "paint": "slate"},
		{"center": Vector3(67, 0, -15), "size": Vector3(12, 15, 17), "paint": "plaster"},
		{"center": Vector3(67, 0, 18), "size": Vector3(12, 19, 16), "paint": "terracotta"},
		{"center": Vector3(0, 0, 65), "size": Vector3(20, 15, 12), "paint": "slate"},
	]

func _ready() -> void:
	name = "CityBackdrop"
	_materials = CityMaterials.palette()
	for key: String in _materials:
		var paint: Color = _materials[key].get_shader_parameter("albedo")
		_materials[key].set_shader_parameter("albedo", paint.lerp(Color("738089"), 0.5))
		_materials[key].set_shader_parameter("key_gain", 1.35)
		_materials[key].set_shader_parameter("painted_fill", 0.2)
	for spec: Dictionary in skyline():
		_house(spec)
	_ground_skirt()
	_boundary_coping()
	_flush_batches()
	set_meta("skyline_buildings", skyline().size())
	set_meta("non_interactive_backdrop", true)
	# Each material is one mesh node, irrespective of the number of architectural details.
	var triangles: int = 0
	for count: int in _authored_triangles.values():
		triangles += count
	set_meta("triangle_count", triangles)
	assert(skyline().size() <= BUILDING_LIMIT and triangles <= TRIANGLE_LIMIT)

func _house(spec: Dictionary) -> void:
	var center: Vector3 = spec.center
	var size: Vector3 = spec.size
	var pose := Transform3D(Basis.IDENTITY, center)
	_box(pose, Vector3(0, size.y * 0.5, 0), size, spec.paint)
	for y: float in [size.y * 0.48, size.y - 0.18]:
		_box(pose, Vector3(0, y, 0), Vector3(size.x + 0.3, 0.23, size.z + 0.3), "stone")
	# Low-poly hipped roof, no physics and no grapple anchors in the backdrop.
	var roof := PrismMesh.new()
	roof.size = Vector3(size.x + 0.7, 2.6, size.z + 0.7)
	_primitive(roof, pose.translated_local(Vector3(0, size.y + 1.3, 0)), "roof_slate")
	for side: float in [-1.0, 1.0]:
		_box(pose, Vector3(side * size.x * 0.28, size.y + 2, size.z * 0.15), Vector3(0.65, 2.8, 0.75), "stone")
		_box(pose, Vector3(side * size.x * 0.28, size.y + 3.44, size.z * 0.15), Vector3(0.95, 0.18, 1.05), "roof_slate")
	# Window rhythms on all four sides make an orbit reveal volume, not a flat billboard.
	for face: int in 4:
		var yaw: float = float(face) * PI * 0.5
		var width: float = size.x if face % 2 == 0 else size.z
		var depth: float = size.z if face % 2 == 0 else size.x
		var facade := pose.rotated_local(Vector3.UP, yaw).translated_local(Vector3(0, 0, depth * 0.5 + 0.025))
		for level: int in maxi(2, floori(size.y / 3.5)):
			for bay: int in maxi(2, floori(width / 3.5)):
				var x: float = -width * 0.5 + 2.0 + float(bay) * 3.5
				_box(facade, Vector3(x, 2.4 + float(level) * 3.5, 0), Vector3(0.85, 1.5, 0.045), "glass")

func _ground_skirt() -> void:
	# Visual terrain behind the safety boundary grounds distant houses; it is not walkable.
	# Four strips leave the complete playable square untouched and end at 100 metres.
	for side: float in [-1.0, 1.0]:
		_box(Transform3D.IDENTITY, Vector3(0, -0.2, side * 66.5), Vector3(200, 0.4, 67), "stone")
		_box(Transform3D.IDENTITY, Vector3(side * 66.5, -0.2, 0), Vector3(67, 0.4, 66), "stone")

func _boundary_coping() -> void:
	# Above/outside the existing four-metre boundary; not a new ledge or passable region.
	for side: float in [-1.0, 1.0]:
		_box(Transform3D.IDENTITY, Vector3(0, 4.12, side * 32.65), Vector3(64, 0.24, 0.9), "stone")
		_box(Transform3D.IDENTITY, Vector3(side * 32.65, 4.12, 0), Vector3(0.9, 0.24, 64), "stone")
		for index: int in 9:
			var along: float = -30 + float(index) * 7.5
			_box(Transform3D.IDENTITY, Vector3(along, 2.25, side * 32.65), Vector3(0.45, 4.5, 0.8), "stone")
			_box(Transform3D.IDENTITY, Vector3(side * 32.65, 2.25, along), Vector3(0.8, 4.5, 0.45), "stone")
