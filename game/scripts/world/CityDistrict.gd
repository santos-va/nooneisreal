class_name CityDistrict
extends Node3D
## Functional geometry only. No combat routing or global stage mutation.
const Layout = preload("res://scripts/world/CityLayout.gd")
const Materials = preload("res://scripts/world/CityMaterials.gd")
const Architecture = preload("res://scripts/world/CityArchitecture.gd")
const Market = preload("res://scripts/world/CityMarket.gd")
const Interiors = preload("res://scripts/world/CityInteriors.gd")
const Backdrop = preload("res://scripts/world/CityBackdrop.gd")
var materials: Dictionary = {}
var geometry_count: int = 0

func _ready() -> void:
	materials = Materials.palette()
	for block: Dictionary in Layout.blocks():
		_box(block.id, block.center, block.size, block.material, int(block.layer))
	for ramp: Dictionary in Layout.ramps():
		_ramp(ramp)
	_roofs_and_rails()
	Architecture.populate(self)
	add_child(Market.new())
	add_child(Interiors.new())
	add_child(Backdrop.new())
	_street_details()
	_markers()

func _box(id: String, center: Vector3, size: Vector3, material_key: String, layer: int = 0) -> Node3D:
	var holder: Node3D = StaticBody3D.new() if layer != 0 else Node3D.new()
	holder.name = id
	holder.position = center
	add_child(holder)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var visible_mesh: MeshInstance3D = MeshInstance3D.new()
	visible_mesh.mesh = mesh
	visible_mesh.material_override = materials[material_key]
	holder.add_child(visible_mesh)
	geometry_count += 1
	if holder is StaticBody3D:
		var body: StaticBody3D = holder as StaticBody3D
		body.collision_layer = layer
		body.collision_mask = 0
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	return holder

func _ramp(spec: Dictionary) -> void:
	var x: float = spec.x
	var half_width: float = float(spec.width) * 0.5
	var low: float = spec.start_z
	var high: float = spec.end_z
	var height: float = spec.height
	var vertices: PackedVector3Array = PackedVector3Array([
		Vector3(x - half_width, -0.2, low), Vector3(x + half_width, -0.2, low),
		Vector3(x - half_width, -0.2, high), Vector3(x + half_width, -0.2, high),
		Vector3(x - half_width, 0, low), Vector3(x + half_width, 0, low),
		Vector3(x - half_width, height, high), Vector3(x + half_width, height, high)])
	var indices: Array[int] = [4, 5, 6, 5, 7, 6, 0, 4, 2, 4, 6, 2,
		1, 3, 5, 3, 7, 5, 2, 6, 3, 6, 7, 3, 0, 1, 4, 1, 5, 4, 0, 2, 1, 1, 2, 3]
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_smooth_group(-1) # Keep the structural top/side faces flat, including shared positions.
	# Godot front faces use clockwise winding (the geometric cross product is inverted).
	for triangle: int in range(0, indices.size(), 3):
		for offset: int in [0, 2, 1]:
			builder.add_vertex(vertices[indices[triangle + offset]])
	builder.generate_normals()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = builder.commit()
	mesh_instance.material_override = materials["stone"]
	var body: StaticBody3D = StaticBody3D.new()
	body.name = spec.id
	body.collision_layer = 9
	body.collision_mask = 0
	add_child(body)
	body.add_child(mesh_instance)
	var shape: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = vertices
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	geometry_count += 1

func _roofs_and_rails() -> void:
	for z: float in [-22.0, -18.0]:
		var parapet: Node3D = _box("BridgeParapet" + str(z), Vector3(0, 4.5, z), Vector3(20, 1, 0.2), "slate", 9)
		# Keep the exact safety collider; only the visible infill becomes an open railing.
		var infill: MeshInstance3D = parapet.get_child(0) as MeshInstance3D
		(infill.mesh as BoxMesh).size.y = 0.24
		infill.position.y = -0.38
	# North edges are guarded, while the ramps and bridge mouths stay open.
	for x: float in [-20.0, 20.0]:
		_box("NorthParapet" + str(x), Vector3(x, 4.45, -30), Vector3(20, 0.9, 0.22), "slate", 9)

func _street_details() -> void:
	# Shallow strips articulate street directions without introducing trip hazards.
	for x: float in [-5.0, 5.0]:
		_box("StreetSeam" + str(x), Vector3(x, 0.004, 0), Vector3(0.08, 0.008, 62), "ink")
	for z: float in [-5.0, 5.0]:
		_box("CrossStreetSeam" + str(z), Vector3(0, 0.006, z), Vector3(62, 0.008, 0.08), "ink")
	for index: int in range(Layout.anchors().size()):
		var point: Vector3 = Layout.anchors()[index]
		var pole_x: float = point.x + signf(point.x)
		_box("AnchorPost%d" % index, Vector3(pole_x, 3.4, point.z), Vector3(0.18, 6.8, 0.18), "ink", 9)
		_box("AnchorArm%d" % index, Vector3((pole_x + point.x) * 0.5, 6.8, point.z), Vector3(1.35, 0.15, 0.18), "brass")
		_box("AnchorCeramic%d" % index, point + Vector3(0, 0.25, 0), Vector3(0.35, 0.15, 0.3), "marker")
		var anchor: Marker3D = Marker3D.new()
		anchor.name = "StreetAnchor%d" % index
		anchor.position = point
		anchor.set_meta("lamp", false)
		anchor.add_to_group("grapple_anchor")
		add_child(anchor)

func _markers() -> void:
	var spawn: Marker3D = Marker3D.new()
	spawn.name = "Spawn"
	spawn.position = Layout.spawn_position()
	add_child(spawn)
	for pocket: Dictionary in Layout.combat_pockets():
		var marker: Marker3D = Marker3D.new()
		marker.name = pocket.id
		marker.position = pocket.center
		marker.set_meta("radius", pocket.radius)
		marker.set_meta("candidate_only", true)
		add_child(marker)
