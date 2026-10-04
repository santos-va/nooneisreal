class_name CityMarket
extends Node3D
## Reference-led market kit. Visuals batch by material; meaningful solids retain individual collision.
## PLACEHOLDER composition metres. No commerce, NPC, grapple-anchor or arena ownership.
var _materials: Dictionary = {}
var _builders: Dictionary = {}
var _authored_triangles: Dictionary = {}
var visual_parts: int = 0
var solid_count: int = 0


func _ready() -> void:
	name = "CityMarket"
	_materials = CityMaterials.palette()
	for side: float in [-1.0, 1.0]:
		for index: int in 2:
			var center := Vector3(side * 8.5, 0, 18.0 + float(index) * 7.0)
			var pose := Transform3D(Basis(Vector3.UP, -side * PI * 0.5), center)
			_stall(pose, "cloth_red" if (index == 0) == (side < 0) else "cloth_teal")
	for z: float in [15.2, 28.0]:
		_wire(Vector3(-10, 6.2, z), Vector3(10, 6.2, z), 0.65)
	var rendered_triangles: Dictionary = {}
	for key: String in _builders:
		var builder: SurfaceTool = _builders[key]
		builder.index()
		var instance := MeshInstance3D.new()
		instance.name = "MarketBatch_" + key
		instance.mesh = builder.commit()
		instance.material_override = _materials[key]
		var actual_count: int = int(instance.mesh.get_faces().size() / 3)
		rendered_triangles[key] = actual_count
		if actual_count != int(_authored_triangles[key]):
			push_error("CITY_MARKET: batch %s lost authored triangles: %d rendered / %d authored" % [key, actual_count, _authored_triangles[key]])
		add_child(instance)
	set_meta("visual_parts", visual_parts)
	set_meta("material_batches", _builders.size())
	set_meta("solid_count", solid_count)
	set_meta("authored_triangles", _authored_triangles.duplicate())
	set_meta("rendered_triangles", rendered_triangles)
	_builders.clear()


func _stall(pose: Transform3D, cloth: String) -> void:
	var marker := Marker3D.new()
	marker.name = "MarketStall"
	marker.transform = pose
	marker.set_meta("decorative_market", true)
	add_child(marker)
	# Front faces local +Z. The shallow shop zone leaves the street's centre open.
	_box(pose, Vector3(0, 0.5, 0.55), Vector3(3.2, 1, 0.85), "wood", "Counter")
	_box(pose, Vector3(0, 1.04, 0.55), Vector3(3.42, 0.12, 1.02), "wood", "CounterTop")
	for x: float in [-1.58, 1.58]:
		for z: float in [-1.05, 1.12]:
			var height: float = 3.28 if z < 0 else 2.73
			_box(pose, Vector3(x, height * 0.5, z), Vector3(0.105, height, 0.105), "wood", "TentPost")
		_rod(pose * Vector3(x, 3.25, -1.07), pose * Vector3(x, 2.74, 1.16), 0.045, "wood")
	for z: float in [-1.07, 1.16]:
		_rod(pose * Vector3(-1.65, 3.25 if z < 0 else 2.74, z),
			pose * Vector3(1.65, 3.25 if z < 0 else 2.74, z), 0.045, "wood")
	# Visible planks and crossed straps give the counter a timber silhouette at close range.
	for i: int in 7:
		_box(pose, Vector3(-1.38 + float(i) * 0.46, 0.5, 0.986), Vector3(0.025, 0.86, 0.014), "iron")
	for y: float in [0.16, 0.85]:
		_box(pose, Vector3(0, y, 1.0), Vector3(3.25, 0.095, 0.045), "wood")
	for fold: int in 4:
		var left: float = -0.72 + float(fold) * 0.36
		var right: float = left + 0.36
		_quad(cloth, pose * Vector3(left, 1.1, 1.075), pose * Vector3(right, 1.1, 1.075),
			pose * Vector3(right, 0.34 + 0.08 * absf(right), 1.1 + 0.025 * sin(float(fold + 1) * 2.0)),
			pose * Vector3(left, 0.34 + 0.08 * absf(left), 1.1 + 0.025 * sin(float(fold) * 2.0)))
	_canopy(pose, cloth)
	_crate(pose.translated_local(Vector3(-1.14, 0, -0.45)), Vector3(0.78, 0.72, 0.72))
	_crate(pose.translated_local(Vector3(-1.1, 0.73, -0.42)), Vector3(0.68, 0.55, 0.62))
	_barrel(pose.translated_local(Vector3(1.05, 0, -0.45)))
	for index: int in 3:
		_jar(pose.translated_local(Vector3(-0.9 + float(index) * 0.85, 1.1, 0.6)),
			"terracotta" if index != 1 else "cloth_teal", 0.8 + float(index) * 0.12)
	_lantern(pose * Vector3(1.3, 2.34, 0.72), 0.65)
	_rod(pose * Vector3(1.3, 2.73, 1.12), pose * Vector3(1.3, 2.73, 0.72), 0.018, "iron")
	_rod(pose * Vector3(1.3, 2.73, 0.72), pose * Vector3(1.3, 2.6, 0.72), 0.018, "iron")


func _canopy(pose: Transform3D, color: String) -> void:
	var faces := PackedVector3Array()
	for stripe: int in 8:
		var key: String = "cloth_cream" if stripe % 2 == 0 else color
		var x0: float = -1.78 + float(stripe) * 0.445
		var x1: float = x0 + 0.445
		for segment: int in 8:
			var t0: float = float(segment) / 8.0
			var t1: float = float(segment + 1) / 8.0
			var a: Vector3 = pose * _cloth_point(x0, t0)
			var b: Vector3 = pose * _cloth_point(x1, t0)
			var c: Vector3 = pose * _cloth_point(x1, t1)
			var d: Vector3 = pose * _cloth_point(x0, t1)
			_quad(key, a, b, c, d)
			# Real underside: opposite winding plus a small physical cloth thickness.
			var thickness := Vector3(0, 0.022, 0)
			_quad(key, d - thickness, c - thickness, b - thickness, a - thickness)
			faces.append_array(PackedVector3Array([a, b, c, a, c, d]))
		for scallop: int in 4:
			var u0: float = float(scallop) / 4.0
			var u1: float = float(scallop + 1) / 4.0
			var upper_a: Vector3 = _cloth_point(lerpf(x0, x1, u0), 1.0)
			var upper_b: Vector3 = _cloth_point(lerpf(x0, x1, u1), 1.0)
			var lower_a: Vector3 = upper_a - Vector3(0, 0.15 + sin(u0 * PI) * 0.14, 0)
			var lower_b: Vector3 = upper_b - Vector3(0, 0.15 + sin(u1 * PI) * 0.14, 0)
			_quad(key, pose * upper_a, pose * upper_b, pose * lower_b, pose * lower_a)
			var back := Vector3(0, 0, -0.018)
			_quad(key, pose * (lower_a + back), pose * (lower_b + back), pose * (upper_b + back), pose * (upper_a + back))
	var roof := ConcavePolygonShape3D.new()
	roof.set_faces(faces)
	roof.backface_collision = true
	_solid("ClothCanopy", Transform3D.IDENTITY, roof)


func _cloth_point(x: float, t: float) -> Vector3:
	var sag: float = 0.13 * sin(t * PI) + 0.12 * (1.0 - pow(absf(x) / 1.78, 2.0))
	return Vector3(x, 3.3 - 0.56 * t - sag, lerpf(-1.25, 1.25, t))


func _crate(pose: Transform3D, size: Vector3) -> void:
	_box(pose, Vector3(0, size.y * 0.5, 0), size, "wood", "WoodCrate")
	for side: float in [-1.0, 1.0]:
		for y: float in [0.1, size.y - 0.1]:
			_box(pose, Vector3(0, y, side * (size.z * 0.5 + 0.012)), Vector3(size.x + 0.05, 0.09, 0.05), "wood")
		for x: float in [-size.x * 0.38, size.x * 0.38]:
			_box(pose, Vector3(x, size.y * 0.5, side * (size.z * 0.5 + 0.035)), Vector3(0.085, size.y, 0.05), "wood")
	for row: int in 3:
		_box(pose, Vector3(0, size.y * float(row + 1) / 4.0, size.z * 0.5 + 0.008), Vector3(size.x, 0.015, 0.012), "iron")
	var diagonal := pose.translated_local(Vector3(0, size.y * 0.5, size.z * 0.5 + 0.052)).rotated_local(Vector3.FORWARD, 0.6)
	_box(diagonal, Vector3.ZERO, Vector3(size.x * 1.03, 0.07, 0.045), "wood")


func _barrel(pose: Transform3D) -> void:
	_cylinder(pose, Vector3(0, 0.28, 0), 0.46, 0.35, 0.5, "wood")
	_cylinder(pose, Vector3(0, 0.77, 0), 0.35, 0.46, 0.5, "wood")
	for y: float in [0.16, 0.5, 0.86]:
		var hoop := TorusMesh.new()
		hoop.inner_radius = 0.38 if y != 0.5 else 0.444
		hoop.outer_radius = hoop.inner_radius + 0.033
		hoop.rings = 12
		hoop.ring_segments = 4
		_primitive(hoop, pose.translated_local(Vector3(0, y, 0)), "iron")
	_cylinder(pose, Vector3(0, 1.025, 0), 0.348, 0.348, 0.04, "wood")
	var shape := CylinderShape3D.new()
	shape.radius = 0.46
	shape.height = 1.04
	_solid("HoopedBarrel", pose.translated_local(Vector3(0, 0.52, 0)), shape)


func _jar(pose: Transform3D, color: String, scale_factor: float) -> void:
	_cylinder(pose, Vector3(0, 0.18 * scale_factor, 0), 0.2 * scale_factor, 0.12 * scale_factor, 0.36 * scale_factor, color)
	_cylinder(pose, Vector3(0, 0.4 * scale_factor, 0), 0.09 * scale_factor, 0.2 * scale_factor, 0.09 * scale_factor, color)
	_cylinder(pose, Vector3(0, 0.46 * scale_factor, 0), 0.11 * scale_factor, 0.1 * scale_factor, 0.05 * scale_factor, color)
	_cylinder(pose, Vector3(0, 0.488 * scale_factor, 0), 0.075 * scale_factor, 0.075 * scale_factor, 0.006, "iron")
	var shape := CylinderShape3D.new()
	shape.radius = 0.2 * scale_factor
	shape.height = 0.49 * scale_factor
	_solid("CounterPottery", pose.translated_local(Vector3(0, shape.height * 0.5, 0)), shape)


func _wire(a: Vector3, b: Vector3, sag: float) -> void:
	var previous: Vector3 = a
	for i: int in range(1, 25):
		var t: float = float(i) / 24.0
		var point: Vector3 = a.lerp(b, t) - Vector3(0, sin(t * PI) * sag, 0)
		_rod(previous, point, 0.018, "iron")
		previous = point
	for t: float in [0.25, 0.5, 0.75]:
		var point: Vector3 = a.lerp(b, t) - Vector3(0, sin(t * PI) * sag, 0)
		_rod(point, point - Vector3(0, 0.25, 0), 0.018, "iron")
		_lantern(point - Vector3(0, 0.48, 0), 0.7)


func _lantern(center: Vector3, scale_factor: float) -> void:
	var pose := Transform3D(Basis.IDENTITY, center)
	_box(pose, Vector3.ZERO, Vector3(0.32, 0.5, 0.32) * scale_factor, "warm_window")
	for x: float in [-0.18, 0.18]:
		for z: float in [-0.18, 0.18]:
			_box(pose, Vector3(x, 0, z) * scale_factor, Vector3(0.035, 0.57, 0.035) * scale_factor, "iron")
	for y: float in [-0.29, 0.29]:
		_box(pose, Vector3(0, y, 0) * scale_factor, Vector3(0.43, 0.06, 0.43) * scale_factor, "iron")
	_cylinder(pose, Vector3(0, 0.39, 0) * scale_factor, 0.03 * scale_factor, 0.28 * scale_factor, 0.18 * scale_factor, "iron", 4)


func _box(pose: Transform3D, center: Vector3, size: Vector3, material: String, solid_name: String = "") -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var transform_value: Transform3D = pose.translated_local(center)
	_primitive(mesh, transform_value, material)
	if not solid_name.is_empty():
		var shape := BoxShape3D.new()
		shape.size = size
		_solid(solid_name, transform_value, shape)


func _cylinder(pose: Transform3D, center: Vector3, top: float, bottom: float, height: float, material: String, sides: int = 12) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	_primitive(mesh, pose.translated_local(center), material)


func _rod(a: Vector3, b: Vector3, radius: float, material: String) -> void:
	var offset: Vector3 = b - a
	var pose := Transform3D(Basis(Quaternion(Vector3.UP, offset.normalized())), (a + b) * 0.5)
	_cylinder(pose, Vector3.ZERO, radius, radius, offset.length(), material, 6)


func _primitive(mesh: Mesh, pose: Transform3D, material: String) -> void:
	# Flatten source indices before batching: append_from introduces an index buffer that
	# would leave previously authored (unindexed) cloth vertices outside the draw list.
	var builder: SurfaceTool = _builder(material)
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count: int = indices.size() if not indices.is_empty() else vertices.size()
	_authored_triangles[material] = int(_authored_triangles.get(material, 0)) + int(count / 3)
	for offset: int in count:
		var index: int = indices[offset] if not indices.is_empty() else offset
		builder.set_normal((pose.basis * normals[index]).normalized())
		builder.set_uv(uvs[index])
		builder.add_vertex(pose * vertices[index])
	visual_parts += 1


func _builder(key: String) -> SurfaceTool:
	if not _builders.has(key):
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		_builders[key] = builder
	return _builders[key] as SurfaceTool


func _quad(material: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var builder: SurfaceTool = _builder(material)
	_authored_triangles[material] = int(_authored_triangles.get(material, 0)) + 2
	for triangle: PackedVector3Array in [PackedVector3Array([a, b, c]), PackedVector3Array([a, c, d])]:
		# Clockwise triangles face outward in Godot; retain authored normals for both cloth sides.
		var normal: Vector3 = -(triangle[1] - triangle[0]).cross(triangle[2] - triangle[0]).normalized()
		for vertex: Vector3 in triangle:
			builder.set_normal(normal)
			builder.set_uv(Vector2.ZERO)
			builder.add_vertex(vertex)
	visual_parts += 1


func _solid(id: String, pose: Transform3D, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	body.name = id
	body.transform = pose
	body.collision_layer = 1 | 8
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	solid_count += 1
