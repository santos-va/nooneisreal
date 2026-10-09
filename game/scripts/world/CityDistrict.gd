class_name CityDistrict
extends Node3D
## Functional geometry only. No combat routing or global stage mutation.
const Layout = preload("res://scripts/world/CityLayout.gd")
const Materials = preload("res://scripts/world/CityMaterials.gd")
const Architecture = preload("res://scripts/world/CityArchitecture.gd")
const Market = preload("res://scripts/world/CityMarket.gd")
const Interiors = preload("res://scripts/world/CityInteriors.gd")
const Backdrop = preload("res://scripts/world/CityBackdrop.gd")
const Props = preload("res://scripts/world/CityProps.gd")
## D1 (docs/Audit/2026-10-08-City-Tidy-Technical-Audit.md): the strut of a wall bracket starts 0.75 m under its arm,
## which put eight struts through the window panes below them. Brackets over a window get a short strut that stays
## above the window head (metres under the arm), and the three brackets only 0.15 m over a pane get a tie rod above
## the arm instead (a negative drop). Keys are anchor indices of CityLayout.anchor_supports(); the anchors, their
## points and mounts are unchanged. PLACEHOLDER metres.
const BRACE_DROP: Dictionary = {6: 0.3, 7: 0.3, 9: 0.3, 16: 0.35, 17: 0.35, 22: -0.75, 23: -0.75, 24: -0.75}
var materials: Dictionary = {}
var geometry_count: int = 0
var maintenance: CityMaintenance
var lower_gallery: CityLowerGallery
## The water pump on the edge of the market court (plan 2026-10-08-Thirst-Substances-Icons step 1): the city's free
## water, and the switch of the thirst scale (CityThirst stays off without a water source).
var water_pump: CityWaterPump

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
	# Phase 0 of docs/Plans/2026-10-09-City-Tidy-And-Modern-Props.md: barrels, crates to vault, urns, the steam main and
	# the steam vents — procedural, from the city's own materials.
	add_child(Props.new())
	_street_details()
	_parkour_steps()
	maintenance = CityMaintenance.new()
	maintenance.name = "CityMaintenance"
	add_child(maintenance)
	lower_gallery = CityLowerGallery.new()
	lower_gallery.name = "CityLowerGallery"
	add_child(lower_gallery)
	water_pump = CityWaterPump.new()
	add_child(water_pump)
	water_pump.build(materials)
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
	# North edges are guarded, while the ramps and bridge mouths stay open. D2/D13: the tall house (x 10–30) closes
	# the whole north edge of the east terrace, so it has no parapet; the west one stops at x −18.25, short of the
	# plaster house (x −18–−10) and its plinth, and guards the open edge west of it.
	_box("NorthParapet-20", Vector3(-24.125, 4.45, -30), Vector3(11.75, 0.9, 0.22), "slate", 9)

func _street_details() -> void:
	# Н1 (T6): the four 62 m `ink` strips are gone — ink is the outline, not a street surface. No rails either: the
	# tram is not decided (T7).
	var supports: Array[Dictionary] = Layout.anchor_supports()
	for index: int in range(supports.size()):
		var own: Array[Node] = _anchor_support(index, supports[index])
		var anchor: Marker3D = Marker3D.new()
		anchor.name = "StreetAnchor%d" % index
		anchor.position = supports[index].point
		anchor.set_meta("lamp", false)
		# The anchor's own solid support (a lamp post; brackets have no collider): the hanging rope never breaks on it
		# (GrappleHook._support_of, plan 2026-10-09 «Рішення T1 після кроків 1–4»).
		anchor.set_meta("support", own)
		anchor.add_to_group("grapple_anchor")
		add_child(anchor)

## Visible support of one rope anchor (CityLayout.anchor_supports): the anchor sits 0.25 m under its ceramic cap, the cap
## under an arm, the arm on a post or fixed into the wall / slab at `mount`. PLACEHOLDER sizes; look and colour are T6's.
## Returns the solid bodies of this support (the post), which the anchor's rope ignores while hanging from it.
func _anchor_support(index: int, spec: Dictionary) -> Array[Node]:
	var own: Array[Node] = []
	var point: Vector3 = spec.point
	var mount: Vector3 = spec.mount
	var kind: String = spec.kind
	if kind == "hanger":
		var top: float = mount.y
		_box("AnchorBracket%d" % index, Vector3(point.x, (top + point.y + 0.25) * 0.5, point.z), Vector3(0.08, top - point.y - 0.25, 0.08), "iron")
		_box("AnchorPlate%d" % index, Vector3(point.x, top - 0.03, point.z), Vector3(0.36, 0.06, 0.36), "iron")
		_box("AnchorCeramic%d" % index, point + Vector3(0, 0.25, 0), Vector3(0.35, 0.15, 0.3), "marker")
		return own
	var arm_y: float = point.y + 0.3 if kind == "post" else mount.y
	var flat: Vector3 = Vector3(point.x - mount.x, 0, point.z - mount.z)
	var yaw: float = 0.0 if absf(flat.z) < 0.000001 else atan2(-flat.z, flat.x)
	if kind == "post":
		own.append(_box("AnchorPost%d" % index, Vector3(mount.x, (mount.y + arm_y) * 0.5, mount.z), Vector3(0.18, arm_y - mount.y, 0.18), "ink", 9))
	# D14: the arm is 2 cm narrower than the post (its sides used to share the post's planes) and ends 1 cm inside the
	# ceramic cap (its end face used to share the cap's side plane).
	var arm: Node3D = _box("AnchorArm%d" % index, Vector3((mount.x + point.x) * 0.5, arm_y, (mount.z + point.z) * 0.5), Vector3(flat.length() + 0.33, 0.15, 0.16), "brass")
	arm.rotation.y = yaw
	if kind == "bracket":
		# Wall plate at the fixing and a strut from `drop` below it to the arm's middle (D1: a negative drop is a tie
		# rod from above the arm). The plate spans the fixing and the strut's foot.
		var drop: float = float(BRACE_DROP.get(index, 0.75))
		var plate: Node3D = _box("AnchorPlate%d" % index, mount + Vector3(0, 0.075 - drop * 0.5 if drop > 0.0 else -0.075 - drop * 0.5, 0), Vector3(0.12, absf(drop) + 0.15, 0.36), "iron")
		plate.rotation.y = yaw
		var low: Vector3 = mount + Vector3(0, -drop, 0)
		var high: Vector3 = Vector3((mount.x + point.x) * 0.5, arm_y + (-0.05 if drop > 0.0 else 0.05), (mount.z + point.z) * 0.5)
		var strut: Node3D = _box("AnchorStrut%d" % index, (low + high) * 0.5, Vector3(0.08, 0.08, low.distance_to(high)), "iron")
		strut.basis = Basis.looking_at((high - low).normalized(), Vector3.UP if absf((high - low).normalized().y) < 0.99 else Vector3.FORWARD)
	_box("AnchorCeramic%d" % index, point + Vector3(0, 0.25, 0), Vector3(0.35, 0.15, 0.3), "marker")
	return own

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
