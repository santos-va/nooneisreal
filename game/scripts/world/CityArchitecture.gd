class_name CityArchitecture
extends RefCounted
## Architectural vocabulary from the existing Cronshift illustrations. Metres are design placeholders.
## Repeated facade details are batched by shared material; collision is reserved for structural volumes.
var _district: Node3D
var _batches: Dictionary = {}
var _authored_triangles: Dictionary = {}
var _serial: int = 0

static func populate(district: Node3D) -> void:
	var builder: CityArchitecture = CityArchitecture.new()
	builder._build(district)

func _build(district: Node3D) -> void:
	_district = district
	for spec: Dictionary in CityLayout.blocks():
		if spec.id in ["SouthWestBlock", "SouthEastWestWing", "SouthEastEastWing"]:
			var center: Vector3 = spec.center
			var size: Vector3 = spec.size
			_building(center, size, 4.0 if spec.id == "SouthWestBlock" else 0.0)
		elif spec.id in ["NorthWestRoof", "NorthEastRoof"]:
			# Low bodies are explicitly terraces, framed with stone arcades and coping.
			var center: Vector3 = spec.center
			_facade(Vector3(center.x, 0, -9.99), 20, 3.8, 0, false)
			_box(Vector3(center.x, 3.9, -9.96), Vector3(20, 0.2, 0.36), "stone")
	# Taller houses sit behind the upper walking court; its five-metre radius remains open.
	_box(Vector3(20, 10, -28), Vector3(20, 12, 4), "brick", Basis.IDENTITY, true)
	_building(Vector3(20, 10, -28), Vector3(20, 12, 4), 4.0)
	_box(Vector3(-14, 8.5, -28), Vector3(8, 9, 4), "plaster", Basis.IDENTITY, true)
	_building(Vector3(-14, 8.5, -28), Vector3(8, 9, 4), 4.0)
	_tower()
	_passage()
	_bridge()
	for x: float in [-20.0, 20.0]:
		_box(Vector3(x, 4.003, -20), Vector3(20, 0.006, 20), "paving")
	_flush()

func _building(center: Vector3, size: Vector3, bottom: float) -> void:
	var top: float = center.y + size.y * 0.5
	var height: float = top - bottom
	_facade(Vector3(center.x, bottom, center.z - size.z * 0.5 - 0.02), size.x, height, PI, true)
	_facade(Vector3(center.x, bottom, center.z + size.z * 0.5 + 0.02), size.x, height, 0, true)
	# Avoid balcony projections into the four-metre southeast passage.
	if center.x < 0 or center.x < 18:
		_facade(Vector3(center.x - size.x * 0.5 - 0.02, bottom, center.z), size.z, height, -PI * 0.5, false)
	if center.x < 0 or center.x > 22:
		_facade(Vector3(center.x + size.x * 0.5 + 0.02, bottom, center.z), size.z, height, PI * 0.5, false)
	_mansard(center, size, top)

func _facade(origin: Vector3, width: float, height: float, yaw: float, balconies: bool) -> void:
	var basis: Basis = Basis(Vector3.UP, yaw)
	var bays: int = maxi(1, floori(width / 3.5))
	var bay_width: float = width / float(bays)
	_local_box(origin, basis, Vector3(0, 0.38, 0.1), Vector3(width, 0.76, 0.2), "stone")
	_local_box(origin, basis, Vector3(0, height - 0.22, 0.18), Vector3(width + 0.2, 0.22, 0.46), "stone")
	_local_box(origin, basis, Vector3(0, height - 0.03, 0.22), Vector3(width + 0.3, 0.12, 0.56), "iron")
	for bay: int in range(bays + 1):
		var x: float = -width * 0.5 + float(bay) * bay_width
		_local_box(origin, basis, Vector3(x, height * 0.5, 0.08), Vector3(0.22, height - 0.3, 0.2), "stone")
		for level: int in range(1, ceili(height / 3.0)):
			_local_box(origin, basis, Vector3(x, float(level) * 3.0, 0.16), Vector3(0.42, 0.22, 0.32), "stone")
	for level: int in range(maxi(1, floori(height / 3.0))):
		var bottom: float = 0.9 + float(level) * 3.0
		if level > 0:
			_local_box(origin, basis, Vector3(0, bottom - 0.4, 0.12), Vector3(width, 0.13, 0.28), "stone")
		for bay: int in range(bays):
			var x: float = -width * 0.5 + (float(bay) + 0.5) * bay_width
			if level == 0:
				_window(origin, basis, Vector3(x, bottom, 0.07), 1.15, 1.55, (level + bay) % 4 == 0)
			else:
				_rectangular_window(origin, basis, Vector3(x, bottom, 0.07), 1.15, 1.55, (level + bay) % 4 == 0)
			if balconies and level == 1 and bay % 2 == 0:
				_balcony(origin, basis, Vector3(x, bottom - 0.12, 0), 1.8)
			elif level > 0 and bay % 3 == 1:
				for side: float in [-1.0, 1.0]:
					_local_box(origin, basis, Vector3(x + side * 0.79, bottom + 0.75, 0.12), Vector3(0.3, 1.5, 0.12), "roof_slate")

func _window(origin: Vector3, basis: Basis, bottom: Vector3, width: float, height: float, warm: bool) -> void:
	var radius: float = width * 0.5
	var straight: float = height - radius
	var pane: String = "warm_window" if warm else "glass"
	_local_box(origin, basis, bottom + Vector3(0, straight * 0.5, 0), Vector3(width, straight, 0.045), pane)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.035
	disc.radial_segments = 12
	_mesh(disc, origin + basis * (bottom + Vector3(0, straight, -0.01)), pane, basis * Basis(Vector3.RIGHT, PI * 0.5))
	for side: float in [-1.0, 1.0]:
		_local_box(origin, basis, bottom + Vector3(side * (radius + 0.09), straight * 0.5, 0.065), Vector3(0.18, straight, 0.2), "stone")
	for segment: int in 9:
		var angle: float = PI * (float(segment) + 0.5) / 9.0
		var point: Vector3 = bottom + Vector3(cos(angle) * (radius + 0.09), straight + sin(angle) * (radius + 0.09), 0.065)
		_box(origin + basis * point, Vector3(0.24, 0.18, 0.2), "stone", basis * Basis(Vector3.BACK, angle + PI * 0.5))
	_local_box(origin, basis, bottom + Vector3(0, -0.06, 0.09), Vector3(width + 0.4, 0.16, 0.35), "stone")
	_local_box(origin, basis, bottom + Vector3(0, straight * 0.5, 0.045), Vector3(0.065, straight + 0.05, 0.05), "iron")
	_local_box(origin, basis, bottom + Vector3(0, straight, 0.045), Vector3(width, 0.06, 0.05), "iron")

func _rectangular_window(origin: Vector3, basis: Basis, bottom: Vector3, width: float, height: float, warm: bool) -> void:
	var pane: String = "warm_window" if warm else "glass"
	_local_box(origin, basis, bottom + Vector3(0, height * 0.5, 0), Vector3(width, height, 0.045), pane)
	for side: float in [-1.0, 1.0]:
		_local_box(origin, basis, bottom + Vector3(side * (width * 0.5 + 0.08), height * 0.5, 0.06), Vector3(0.16, height + 0.1, 0.19), "stone")
	_local_box(origin, basis, bottom + Vector3(0, height + 0.06, 0.06), Vector3(width + 0.32, 0.16, 0.21), "stone")
	_local_box(origin, basis, bottom + Vector3(0, -0.06, 0.09), Vector3(width + 0.4, 0.16, 0.35), "stone")
	_local_box(origin, basis, bottom + Vector3(0, height * 0.5, 0.04), Vector3(0.06, height, 0.045), "iron")
	_local_box(origin, basis, bottom + Vector3(0, height * 0.65, 0.04), Vector3(width, 0.06, 0.045), "iron")

func _balcony(origin: Vector3, basis: Basis, bottom: Vector3, width: float) -> void:
	_box(origin + basis * (bottom + Vector3(0, 0, 0.43)), Vector3(width, 0.16, 0.9), "stone", basis, true)
	_collider(origin + basis * (bottom + Vector3(0, 0.45, 0.88)), Vector3(width, 0.9, 0.07), basis)
	_local_box(origin, basis, bottom + Vector3(0, 0.88, 0.88), Vector3(width, 0.08, 0.08), "iron")
	for index: int in 7:
		_local_box(origin, basis, bottom + Vector3(-width * 0.5 + float(index) * width / 6.0, 0.43, 0.88), Vector3(0.045, 0.85, 0.045), "iron")
	for side: float in [-1.0, 1.0]:
		_collider(origin + basis * (bottom + Vector3(side * width * 0.5, 0.45, 0.47)), Vector3(0.07, 0.9, 0.85), basis)
		_local_box(origin, basis, bottom + Vector3(side * width * 0.5, 0.88, 0.47), Vector3(0.07, 0.08, 0.85), "iron")
		_box(origin + basis * (bottom + Vector3(side * width * 0.32, -0.2, 0.35)), Vector3(0.1, 0.48, 0.1), "iron", basis * Basis(Vector3.RIGHT, -0.7))

func _mansard(center: Vector3, size: Vector3, top: float) -> void:
	# Closed truncated hip: trapezoid facets meet at the same corners, without raised horns.
	var rise: float = 1.5
	var inset: float = minf(1.1, size.z * 0.22)
	var hx: float = size.x * 0.5 + 0.2
	var hz: float = size.z * 0.5 + 0.2
	var tx: float = size.x * 0.5 - inset
	var tz: float = size.z * 0.5 - inset
	var vertices: PackedVector3Array = PackedVector3Array([
		Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz),
		Vector3(-tx, rise, -tz), Vector3(tx, rise, -tz), Vector3(tx, rise, tz), Vector3(-tx, rise, tz)])
	var indices: Array[int] = [0, 1, 5, 0, 5, 4, 1, 2, 6, 1, 6, 5, 2, 3, 7, 2, 7, 6,
		3, 0, 4, 3, 4, 7, 4, 5, 6, 4, 6, 7, 0, 2, 1, 0, 3, 2]
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for index: int in indices:
		# Match the primitive mesh attribute format used by the material batch.
		surface.set_uv(Vector2(vertices[index].x, vertices[index].z))
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var roof: ArrayMesh = surface.commit()
	var roof_center: Vector3 = Vector3(center.x, top, center.z)
	_mesh(roof, roof_center, "roof_slate")
	_mesh_collider(roof, roof_center, "MansardSupport%d" % _serial)
	_serial += 1
	for index: int in range(maxi(1, floori(size.x / 6.0))):
		var x: float = center.x - size.x * 0.5 + 2.5 + float(index) * 6.0
		var z: float = center.z - size.z * 0.5 + 0.5
		_box(Vector3(x, top + 0.7, z), Vector3(1.1, 1.1, 0.55), "stone", Basis.IDENTITY, true)
		_local_box(Vector3(x, top + 0.7, z - 0.3), Basis.IDENTITY, Vector3.ZERO, Vector3(0.6, 0.75, 0.05), "warm_window")
		_box(Vector3(x, top + 1.29, z), Vector3(1.35, 0.13, 0.85), "roof_slate", Basis.IDENTITY, true)
	_box(Vector3(center.x + size.x * 0.32, top + 1.8, center.z + size.z * 0.15), Vector3(0.7, 2.2, 0.7), "brick", Basis.IDENTITY, true)
	_box(Vector3(center.x + size.x * 0.32, top + 2.92, center.z + size.z * 0.15), Vector3(0.96, 0.15, 0.96), "stone", Basis.IDENTITY, true)

func _tower() -> void:
	for yaw: float in [0.0, PI * 0.5, PI, -PI * 0.5]:
		var basis: Basis = Basis(Vector3.UP, yaw)
		var origin: Vector3 = Vector3(-24, 4, -25) + basis * Vector3(0, 0, 4.02)
		_facade(origin, 8, 8.0, yaw, false)
		var face: CylinderMesh = CylinderMesh.new()
		face.top_radius = 1.35
		face.bottom_radius = 1.35
		face.height = 0.17
		face.radial_segments = 32
		var center: Vector3 = origin + Vector3.UP * 9.2 + basis * Vector3(0, 0, 0.1)
		_mesh(face, center, "brass", basis * Basis(Vector3.RIGHT, PI * 0.5))
		for hour: int in 12:
			var angle: float = TAU * float(hour) / 12.0
			_box(center + basis * Vector3(sin(angle) * 1.1, cos(angle) * 1.1, 0.12), Vector3(0.08, 0.19, 0.045), "iron", basis * Basis(Vector3.BACK, -angle))
		_local_box(center, basis, Vector3(0, 0.35, 0.14), Vector3(0.09, 0.9, 0.05), "iron")
		_box(center + basis * Vector3(0.3, 0.05, 0.15), Vector3(0.73, 0.1, 0.05), "iron", basis * Basis(Vector3.BACK, -0.3))
	for height: float in [11.9, 15.7, 16.15]:
		_box(Vector3(-24, height, -25), Vector3(8.6, 0.18, 8.6), "stone", Basis.IDENTITY, true)
	var drum: CylinderMesh = CylinderMesh.new()
	drum.top_radius = 3.9
	drum.bottom_radius = 4.25
	drum.height = 0.9
	drum.radial_segments = 16
	_mesh(drum, Vector3(-24, 16.5, -25), "stone")
	_mesh_collider(drum, Vector3(-24, 16.5, -25), "TowerDrumSupport")
	var dome: SphereMesh = SphereMesh.new()
	dome.radius = 4.0
	dome.height = 5.0
	dome.is_hemisphere = true
	dome.radial_segments = 24
	dome.rings = 8
	_mesh(dome, Vector3(-24, 16.9, -25), "copper")
	_mesh_collider(dome, Vector3(-24, 16.9, -25), "TowerDomeSupport")
	var dome_top: float = dome.get_aabb().end.y
	for rib: int in 6:
		var bearing: float = TAU * float(rib) / 6.0
		for segment: int in 8:
			var angle_a: float = PI * 0.5 * float(segment) / 8.0
			var angle_b: float = PI * 0.5 * float(segment + 1) / 8.0
			var a: Vector3 = Vector3(-24, 16.9, -25) + Vector3(cos(bearing) * 4.03 * cos(angle_a), (dome_top + 0.025) * sin(angle_a), sin(bearing) * 4.03 * cos(angle_a))
			var b: Vector3 = Vector3(-24, 16.9, -25) + Vector3(cos(bearing) * 4.03 * cos(angle_b), (dome_top + 0.025) * sin(angle_b), sin(bearing) * 4.03 * cos(angle_b))
			_box((a + b) * 0.5, Vector3(0.06, 0.06, a.distance_to(b)), "brass", Basis.looking_at((b - a).normalized(), Vector3.UP))
	var finial: CylinderMesh = CylinderMesh.new()
	finial.top_radius = 0.0
	finial.bottom_radius = 0.22
	finial.height = 1.6
	finial.radial_segments = 8
	_mesh(finial, Vector3(-24, 16.9 + dome_top + 0.78, -25), "iron")

func _passage() -> void:
	# Frame remains outside the existing 4m x 4.5m opening; no fake new doorway.
	for x: float in [18.025, 21.975]:
		_box(Vector3(x, 0.23, 21), Vector3(0.05, 0.46, 18), "stone")
		_box(Vector3(x, 3.3, 21), Vector3(0.05, 0.12, 18), "stone")
	for z: float in [11.92, 16.08]:
		for side: float in [-1.0, 1.0]:
			_box(Vector3(20 + side * 2.16, 2.25, z), Vector3(0.3, 4.5, 0.3), "stone")
		_box(Vector3(20, 4.67, z), Vector3(4.62, 0.3, 0.32), "stone")
		for index: int in 7:
			_box(Vector3(17.99 + float(index) * 0.67, 5.1, z), Vector3(0.62, 0.5, 0.2), "stone")

func _bridge() -> void:
	for z: float in [-22.0, -18.0]:
		_box(Vector3(0, 5.03, z), Vector3(20, 0.12, 0.3), "stone")
		for x: float in [-8.0, -4.0, 0.0, 4.0, 8.0]:
			_box(Vector3(x, 4.55, z), Vector3(0.28, 1.2, 0.38), "stone")

func _local_box(origin: Vector3, basis: Basis, center: Vector3, size: Vector3, material: String) -> void:
	_box(origin + basis * center, size, material, basis)

func _box(center: Vector3, size: Vector3, material: String, basis: Basis = Basis.IDENTITY, solid: bool = false) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	_mesh(mesh, center, material, basis)
	if solid:
		_collider(center, size, basis)

func _collider(center: Vector3, size: Vector3, basis: Basis) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "ArchitectureSolid%d" % _serial
	_serial += 1
	body.transform = Transform3D(basis, center)
	body.collision_layer = 9
	body.collision_mask = 0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	_district.add_child(body)

func _mesh(mesh: Mesh, center: Vector3, material: String, basis: Basis = Basis.IDENTITY) -> void:
	if not _batches.has(material):
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[material] = surface
	var builder: SurfaceTool = _batches[material]
	# Normalize all source triangles before batching: procedural roofs and primitive meshes
	# must share one draw stream, irrespective of whether the source mesh was indexed.
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var count: int = indices.size() if not indices.is_empty() else vertices.size()
	_authored_triangles[material] = int(_authored_triangles.get(material, 0)) + int(count / 3)
	for offset: int in count:
		var index: int = indices[offset] if not indices.is_empty() else offset
		builder.set_normal((basis * normals[index]).normalized())
		builder.set_uv(uvs[index] if not uvs.is_empty() else Vector2.ZERO)
		builder.add_vertex(center + basis * vertices[index])

func _mesh_collider(mesh: Mesh, center: Vector3, id: String) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = id
	body.position = center
	body.collision_layer = 9
	body.collision_mask = 0
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = mesh.create_convex_shape()
	body.add_child(collision)
	_district.add_child(body)

func _flush() -> void:
	var rendered: Dictionary = {}
	for key: String in _batches:
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.name = "Architecture_" + key
		(_batches[key] as SurfaceTool).index()
		mesh_instance.mesh = (_batches[key] as SurfaceTool).commit()
		rendered[key] = int(mesh_instance.mesh.get_faces().size() / 3)
		if rendered[key] != _authored_triangles[key]:
			push_error("CITY_ARCHITECTURE: mixed batch lost triangles for " + key)
		mesh_instance.material_override = _district.materials[key]
		_district.add_child(mesh_instance)
		_district.geometry_count += 1
	_district.set_meta("architecture_authored_triangles", _authored_triangles)
	_district.set_meta("architecture_rendered_triangles", rendered)
