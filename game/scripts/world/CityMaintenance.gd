class_name CityMaintenance
extends Node3D
## Authored service court. Geometry consumes story state but never awards progress.
## All distances are PLACEHOLDER design metres, within the existing district bounds.
var _materials: Dictionary
var _points: Dictionary = {}
var _gate: StaticBody3D
var _weight: Node3D
var _lever: Node3D
var _latch: Node3D
var _opened: bool = false

func _ready() -> void:
	_materials = CityMaterials.palette()
	# Keep the original z=-20 roof route and clock checkpoint outside this court.
	_box("SouthWall", Vector3(-24.3, 5.1, -10.7), Vector3(6.4, 2.2, 0.2), "stone", true)
	_box("EastWall", Vector3(-21.2, 5.1, -13.9), Vector3(0.2, 2.2, 6.4), "stone", true)
	_box("NorthWall", Vector3(-24.3, 5.1, -17.3), Vector3(6.4, 2.2, 0.2), "stone", true)
	_box("WestNorthWall", Vector3(-27.4, 5.1, -16.15), Vector3(0.2, 2.2, 2.5), "stone", true)
	_box("WestSouthWall", Vector3(-27.4, 5.1, -11.85), Vector3(0.2, 2.2, 2.3), "stone", true)
	# A two-metre doorway; the visible leaf and its exact solid share one transform.
	_gate = _box("ServiceGate", Vector3(-27.4, 5.1, -13.95), Vector3(0.18, 2.2, 1.8), "wood", true) as StaticBody3D
	for height: float in [-0.75, 0.75]:
		_part(_gate, "GateStrap", Vector3(0, height, 0), Vector3(0.23, 0.1, 1.8), "iron")
	_box("GateLintel", Vector3(-27.4, 6.4, -13.95), Vector3(0.4, 0.25, 2.5), "stone", true)
	_box("LatchPlate", Vector3(-27.55, 5.2, -13.15), Vector3(0.14, 0.32, 0.35), "brass")
	_latch = _box("LatchBar", Vector3(-27.64, 5.2, -13.45), Vector3(0.12, 0.1, 0.8), "iron")
	# Both heroes can walk continuously over the wall and descend inside.
	_ramp("OuterServiceRamp", -19.0, 1.6, -11.0, -16.4, 4.0, 6.3)
	_box("ServiceGallery", Vector3(-22.3, 6.15, -17.3), Vector3(8.2, 0.3, 1.8), "stone", true)
	_ramp("InnerServiceRamp", -25.0, 1.6, -11.5, -16.4, 4.0, 6.3)
	# Rails have exactly matching visible and solid bars, with open entry mouths.
	_box("GalleryNorthRail", Vector3(-22.3, 6.95, -18.15), Vector3(8.2, 0.14, 0.12), "iron", true)
	for x: float in [-26.35, -24.0, -21.5, -18.25]:
		_box("GalleryPost", Vector3(x, 6.65, -18.15), Vector3(0.09, 0.7, 0.09), "iron", true)
	# Visible mechanical evidence stays separate from the moving gate leaf.
	_box("WeightGuide", Vector3(-27.15, 5.25, -12.0), Vector3(0.16, 2.2, 0.22), "iron")
	_box("GuideWear", Vector3(-27.04, 5.25, -12.0), Vector3(0.03, 1.7, 0.07), "brass")
	_weight = _box("Counterweight", Vector3(-26.96, 5.8, -12.0), Vector3(0.32, 0.45, 0.32), "brass")
	_box("LeverMount", Vector3(-27.16, 5.0, -15.25), Vector3(0.24, 0.5, 0.4), "wood")
	_lever = _box("ReleaseLever", Vector3(-26.97, 5.22, -15.25), Vector3(0.09, 0.6, 0.09), "brass")
	_lever.rotation.x = -0.5
	_box("MaintenanceBench", Vector3(-22.25, 4.75, -12.4), Vector3(1.3, 0.15, 2.1), "wood", true)
	for z: float in [-13.1, -11.7]:
		_box("BenchLeg", Vector3(-22.25, 4.35, z), Vector3(0.9, 0.7, 0.14), "iron", true)
	_box("ToolChest", Vector3(-22.25, 5.0, -12.8), Vector3(0.8, 0.35, 0.55), "copper", true)
	_sign("EntranceSign", "СЛУЖБОВИЙ ДВІР", Vector3(-27.65, 6.72, -13.95), -PI * 0.5)
	_sign("BypassSign", "ОБХІД ›", Vector3(-19, 4.9, -10.25), 0.0)   # no arrows in the built-in font
	_point("clue_a", Vector3(-27.66, 5.2, -13.15))
	_point("clue_b", Vector3(-26.92, 5.25, -12.0))
	_point("mechanism", Vector3(-26.85, 5.22, -15.25))
	set_story_shortcut_open(_opened)

func story_points() -> Dictionary:
	return _points.duplicate()

func story_shortcut_open() -> bool:
	return _opened

func set_story_shortcut_open(value: bool) -> void:
	_opened = value
	if not is_instance_valid(_gate):
		return
	# A raised gate cannot leave an invisible barrier or a closing sweep in the aisle.
	_gate.position.y = 7.65 if value else 5.1
	_weight.position.y = 4.45 if value else 5.8
	_lever.rotation.x = 0.65 if value else -0.5
	_latch.position.z = -12.65 if value else -13.45

static func safe_checkpoint_position() -> Vector3:
	# Available before and after opening, on the existing west roof promenade.
	return Vector3(-29, 4, -14)

static func bypass_route() -> Array[Vector3]:
	return [Vector3(-19, 4, -11.0), Vector3(-19, 6.3, -17.3),
		Vector3(-25, 6.3, -17.3), Vector3(-25, 6.3, -16.4),
		Vector3(-25, 4, -11.5), Vector3(-26.4, 4, -11.5), Vector3(-26.4, 4, -13.95)]

func _point(id: String, point: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = id
	marker.position = point
	add_child(marker)
	_points[id] = marker

func _box(id: String, point: Vector3, size: Vector3, material: String, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = id
	node.position = point
	add_child(node)
	_part(node, "Visible", Vector3.ZERO, size, material)
	if solid:
		(node as StaticBody3D).collision_layer = 9
		(node as StaticBody3D).collision_mask = 0
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)
	return node

func _part(parent: Node3D, id: String, point: Vector3, size: Vector3, material: String) -> void:
	var visible := MeshInstance3D.new()
	visible.name = id
	var mesh := BoxMesh.new()
	mesh.size = size
	visible.mesh = mesh
	visible.material_override = _materials[material]
	visible.position = point
	parent.add_child(visible)

func _ramp(id: String, x: float, width: float, low_z: float, high_z: float, low_y: float, high_y: float) -> void:
	var vertices := PackedVector3Array([
		Vector3(x-width/2, low_y-0.15, low_z), Vector3(x+width/2, low_y-0.15, low_z),
		Vector3(x-width/2, low_y-0.15, high_z), Vector3(x+width/2, low_y-0.15, high_z),
		Vector3(x-width/2, low_y, low_z), Vector3(x+width/2, low_y, low_z),
		Vector3(x-width/2, high_y, high_z), Vector3(x+width/2, high_y, high_z)])
	var indices: Array[int] = [4,5,6,5,7,6,0,4,2,4,6,2,1,3,5,3,7,5,2,6,3,6,7,3,0,1,4,1,5,4,0,2,1,1,2,3]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for tri: int in range(0, indices.size(), 3):
		for offset: int in [0,2,1]:
			surface.add_vertex(vertices[indices[tri+offset]])
	surface.generate_normals()
	var visible := MeshInstance3D.new()
	visible.mesh = surface.commit()
	visible.material_override = _materials["stone"]
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = 9
	body.collision_mask = 0
	add_child(body)
	body.add_child(visible)
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	collision.shape = shape
	body.add_child(collision)

func _sign(id: String, title: String, point: Vector3, yaw: float) -> void:
	var plaque := _box(id + "Plaque", point - Basis(Vector3.UP, yaw).z * 0.04, Vector3(2.7, 0.42, 0.08), "wood")
	plaque.rotation.y = yaw
	_box(id + "Support", point + Vector3(0,-0.6,0), Vector3(0.08,1.2,0.08), "iron")
	var sign := Label3D.new()
	sign.name = id
	sign.text = title
	sign.font_size = 32
	sign.pixel_size = 0.01
	sign.modulate = Color("f0d8aa")
	sign.outline_modulate = Color("2b2230")
	sign.position = point
	sign.rotation.y = yaw
	add_child(sign)
