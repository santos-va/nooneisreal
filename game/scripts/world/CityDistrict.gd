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
var maintenance: CityMaintenance
var lower_gallery: CityLowerGallery

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
	_parkour_steps()
	maintenance = CityMaintenance.new()
	maintenance.name = "CityMaintenance"
	add_child(maintenance)
	lower_gallery = CityLowerGallery.new()
	lower_gallery.name = "CityLowerGallery"
	add_child(lower_gallery)
	_markers()

func _parkour_steps() -> void:
	# PLACEHOLDER solid service terraces: broad landings with visible stone/brass lips.
	# The existing street centre and east ramp remain open. Each rise is reachable by both heroes.
	# PracticeLedge faces the spawn with ~15 m of open street behind its grip face (z 17.0), so the
	# follow camera is not pinned between the ledge and SouthBoundary as at the old z 30.2 face.
	# PLACEHOLDER layout: >= 3 m camera space per docs/Plans/2026-10-07-Tight-Support-Camera.md;
	# 1.0 m clear of the nearest resident lane and 1.85 m of the east market stall.
	var steps: Array[Dictionary] = [
		{"name": "PracticeLedge", "center": Vector3(4, 1.4, 15.8), "size": Vector3(2.8, 2.8, 2.4)},
		{"name": "RoofApproachLow", "center": Vector3(12, 1.0, -5.8), "size": Vector3(3.0, 2.0, 2.8)},
		{"name": "RoofApproachHigh", "center": Vector3(12, 2.0, -8.6), "size": Vector3(3.0, 4.0, 2.8)},
	]
	for step: Dictionary in steps:
		_box(step.name, step.center, step.size, "stone", 9)
		var lip: Vector3 = step.center + Vector3(0, Vector3(step.size).y * 0.5 - 0.06, Vector3(step.size).z * 0.5 + 0.006)
		_box(String(step.name) + "GripLip", lip, Vector3(Vector3(step.size).x, 0.12, 0.012), "brass")

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
	var supports: Array[Dictionary] = Layout.anchor_supports()
	for index: int in range(supports.size()):
		_anchor_support(index, supports[index])
		var anchor: Marker3D = Marker3D.new()
		anchor.name = "StreetAnchor%d" % index
		anchor.position = supports[index].point
		anchor.set_meta("lamp", false)
		anchor.add_to_group("grapple_anchor")
		add_child(anchor)

## Visible support of one rope anchor (CityLayout.anchor_supports): the anchor sits 0.25 m under its ceramic cap, the cap
## under an arm, the arm on a post or fixed into the wall / slab at `mount`. PLACEHOLDER sizes; look and colour are T6's.
func _anchor_support(index: int, spec: Dictionary) -> void:
	var point: Vector3 = spec.point
	var mount: Vector3 = spec.mount
	var kind: String = spec.kind
	if kind == "hanger":
		var top: float = mount.y
		_box("AnchorBracket%d" % index, Vector3(point.x, (top + point.y + 0.25) * 0.5, point.z), Vector3(0.08, top - point.y - 0.25, 0.08), "iron")
		_box("AnchorPlate%d" % index, Vector3(point.x, top - 0.03, point.z), Vector3(0.36, 0.06, 0.36), "iron")
		_box("AnchorCeramic%d" % index, point + Vector3(0, 0.25, 0), Vector3(0.35, 0.15, 0.3), "marker")
		return
	var arm_y: float = point.y + 0.3 if kind == "post" else mount.y
	var flat: Vector3 = Vector3(point.x - mount.x, 0, point.z - mount.z)
	var yaw: float = 0.0 if absf(flat.z) < 0.000001 else atan2(-flat.z, flat.x)
	if kind == "post":
		_box("AnchorPost%d" % index, Vector3(mount.x, (mount.y + arm_y) * 0.5, mount.z), Vector3(0.18, arm_y - mount.y, 0.18), "ink", 9)
	var arm: Node3D = _box("AnchorArm%d" % index, Vector3((mount.x + point.x) * 0.5, arm_y, (mount.z + point.z) * 0.5), Vector3(flat.length() + 0.35, 0.15, 0.18), "brass")
	arm.rotation.y = yaw
	if kind == "bracket":
		# Wall plate at the fixing and a strut from 0.9 m below it to the arm's middle.
		var plate: Node3D = _box("AnchorPlate%d" % index, mount + Vector3(0, -0.3, 0), Vector3(0.12, 0.9, 0.36), "iron")
		plate.rotation.y = yaw
		var low: Vector3 = mount + Vector3(0, -0.75, 0)
		var high: Vector3 = Vector3((mount.x + point.x) * 0.5, arm_y - 0.05, (mount.z + point.z) * 0.5)
		var strut: Node3D = _box("AnchorStrut%d" % index, (low + high) * 0.5, Vector3(0.08, 0.08, low.distance_to(high)), "iron")
		strut.basis = Basis.looking_at((high - low).normalized(), Vector3.UP if absf((high - low).normalized().y) < 0.99 else Vector3.FORWARD)
	_box("AnchorCeramic%d" % index, point + Vector3(0, 0.25, 0), Vector3(0.35, 0.15, 0.3), "marker")

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
