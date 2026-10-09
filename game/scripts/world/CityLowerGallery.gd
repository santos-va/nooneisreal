class_name CityLowerGallery
extends Node3D
## Upper-terrace archive, not an underground entrance. Geometry never awards story facts.
## Spatial/light values are PLACEHOLDER art and traversal tuning.
## D5 (docs/Audit/2026-10-08-City-Tidy-Technical-Audit.md): the plate's back is on the east wall (x −10.90); it used
## to hang 6 cm in front of it with nothing holding it.
const PLATE_CENTER := Vector3(-10.96, 5.45, -14.2)
const LAMP_CENTER := Vector3(-13.65, 5.45, -14.2)
var _materials: Dictionary
var _points: Dictionary = {}
var _lamp: Node3D
var _spot: SpotLight3D
var _record: Node3D
var _aligned: bool = false
var _delivered: bool = false

func _ready() -> void:
	_materials = CityMaterials.palette()
	# All geometry stays east of the existing x=-16 service-ramp approach.
	_box(self, "NorthWall", Vector3(-12.8,5.5,-17.2), Vector3(4,3,0.2), "stone", true)
	_box(self, "SouthWall", Vector3(-12.8,5.5,-11.2), Vector3(4,3,0.2), "stone", true)
	_box(self, "EastWall", Vector3(-10.8,5.5,-14.2), Vector3(0.2,3,6), "stone", true)
	_box(self, "EntryNorth", Vector3(-14.8,5.5,-16.35), Vector3(0.2,3,1.7), "stone", true)
	_box(self, "EntrySouth", Vector3(-14.8,5.5,-12.1), Vector3(0.2,3,1.8), "stone", true)
	_box(self, "EntryLintel", Vector3(-14.8,6.8,-14.25), Vector3(0.35,0.4,2.5), "stone", true)
	_box(self, "ArchiveCanopy", Vector3(-12.8,7.08,-14.2), Vector3(4.2,0.16,6.2), "slate", true)
	_box(self, "ArchiveFloor", Vector3(-12.8,4.012,-14.2), Vector3(3.8,0.024,5.8), "wood")
	var sign := _box(self, "ArchiveSign", Vector3(-15.02,6.45,-14.25), Vector3(0.1,0.34,2.4), "wood")
	_text(sign, "АРХІВНА ГАЛЕРЕЯ", Vector3(-0.065,0,0), -PI/2, 0.0055)
	_box(self, "RubbingDesk", Vector3(-12.7,4.8,-16.55), Vector3(2.3,0.14,0.65), "wood", true)
	for x: float in [-13.6,-11.8]:
		_box(self, "DeskLeg", Vector3(x,4.4,-16.55), Vector3(0.1,0.8,0.5), "iron", true)
	_box(self, "PaperStack", Vector3(-12.3,4.9,-16.55), Vector3(0.65,0.06,0.45), "cloth_cream")
	_box(self, "Charcoal", Vector3(-13,4.895,-16.55), Vector3(0.28,0.05,0.05), "ink")   # on the desk top (4.87)
	_build_plate()
	_build_lamp()
	_point("lamp", Vector3(-13.65,5.15,-14.48))
	_point("plate", Vector3(-11.16,5.25,-14.2))
	_build_delivered_record()
	set_lamp_aligned(_aligned)
	set_record_delivered(_delivered)

func lower_points() -> Dictionary:
	return _points.duplicate()

func lamp_aligned() -> bool:
	return _aligned

func plate_is_lit() -> bool:
	# Physical aim/occlusion, not a renderer brightness threshold. Called only on inspection.
	if not _aligned or not is_instance_valid(_spot) or not _spot.is_visible_in_tree() or _spot.light_energy <= 0.0:
		return false
	var offset: Vector3 = to_global(PLATE_CENTER) - _spot.global_position
	if offset.length() > _spot.spot_range or offset.length_squared() < 0.0001:
		return false
	if (-_spot.global_basis.z).dot(offset.normalized()) < cos(deg_to_rad(_spot.spot_angle)):
		return false
	var mesh: MeshInstance3D = get_node("RoutePlate/Visible")
	if (_spot.light_cull_mask & mesh.layers) == 0:
		return false
	var query := PhysicsRayQueryParameters3D.create(_spot.global_position, to_global(PLATE_CENTER), 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == get_node("RoutePlate")

func set_lamp_aligned(value: bool) -> void:
	_aligned = value
	if is_instance_valid(_lamp):
		# The physical lens and real light share one pivot; no separate fake beam pose.
		var target: Vector3 = PLATE_CENTER if value else Vector3(-13.65,5.45,-11.4)
		_lamp.look_at(to_global(target), Vector3.UP)

func set_record_delivered(value: bool) -> void:
	_delivered = value
	if is_instance_valid(_record):
		_record.visible = value

func record_delivered() -> bool:
	return _delivered

func lamp_light() -> SpotLight3D:
	return _spot

func _build_lamp() -> void:
	_box(self, "LampFoot", Vector3(-13.65,4.08,-14.2), Vector3(0.45,0.16,0.45), "iron", true)
	_box(self, "LampPost", Vector3(-13.65,4.7,-14.2), Vector3(0.12,1.4,0.12), "iron", true)
	_lamp = Node3D.new()
	_lamp.name = "InspectionLamp"
	_lamp.position = LAMP_CENTER
	add_child(_lamp)
	# D23: the hood hangs 0.13 m past its post at head height, so it is solid; it turns with the lamp.
	_box(_lamp, "Hood", Vector3.ZERO, Vector3(0.38,0.32,0.38), "brass", true)
	_box(_lamp, "Lens", Vector3(0,0,-0.2), Vector3(0.3,0.24,0.025), "warm_window")
	_box(_lamp, "Handle", Vector3(0,0.19,0), Vector3(0.44,0.065,0.065), "iron")   # on the hood (top 0.16)
	_spot = SpotLight3D.new()
	_spot.name = "InspectionBeam"
	_spot.position = Vector3(0,0,-0.24)
	_spot.light_color = Color("ffe0a1")
	_spot.light_energy = 3.4
	_spot.spot_range = 4.8
	_spot.spot_angle = 34.0
	_spot.spot_angle_attenuation = 0.6
	_spot.shadow_enabled = true
	# The local plate uses ordinary attenuated lighting; the city cel shader has a painted fill.
	# Restrict this inspection light to the plate/blank receiver, not the whole district.
	_spot.light_cull_mask = 8
	_lamp.add_child(_spot)
	var receiver := _box(self, "AwayLightReceiver", Vector3(-13.65,5.45,-11.32), Vector3(1.4,1.8,0.035), "stone")
	_lit_surface(receiver, Color("6c6862"))

func _build_plate() -> void:
	var plate := _box(self, "RoutePlate", PLATE_CENTER, Vector3(0.12,2.1,2.5), "plaster", true)
	_lit_surface(plate, Color("a79b7f"))
	# Permanent large carved/painted route symbols, present in both lamp orientations.
	# Local X is depth; Z is the viewer's horizontal axis on this west-facing plate.
	for z: float in [-0.95,-0.53]:
		_ink(plate, Vector3(-0.073,0.16,z), Vector3(0.022,0.34,0.06))
	for y: float in [-0.01,0.33]:
		_ink(plate, Vector3(-0.073,y,-0.74), Vector3(0.022,0.06,0.42))
	_ink(plate, Vector3(-0.073,0.19,0.74), Vector3(0.022,0.46,0.3))
	for z: float in [0.58,0.74,0.90]:
		_ink(plate, Vector3(-0.073,0.46,z), Vector3(0.022,0.12,0.09))
	for step: int in 4:
		_ink(plate, Vector3(-0.073,0.36-float(step)*0.12,-0.15+float(step)*0.1), Vector3(0.022,0.075,0.18))
	for z: float in [-0.43,0.43]:
		_ink(plate, Vector3(-0.073,-0.28,z), Vector3(0.022,0.065,0.24))
		var arrow := _ink(plate, Vector3(-0.073,-0.22,z+0.09), Vector3(0.022,0.06,0.15))
		arrow.rotation.x = 0.55
		arrow = _ink(plate, Vector3(-0.073,-0.34,z+0.09), Vector3(0.022,0.06,0.15))
		arrow.rotation.x = -0.55
	_text(plate, "ДВІР › НИЖНІ СХОДИ › ВЕЖА", Vector3(-0.085,-0.65,0), -PI/2, 0.0039, true)   # no `→` in the font
	_text(plate, "СЛУЖБОВА СХЕМА", Vector3(-0.085,0.75,0), -PI/2, 0.0048, true)

func _build_delivered_record() -> void:
	# Wall space to the right of the stock shelf and below the existing workshop clock.
	# Decoration only: it cannot obstruct the worker's service aisle or become another objective.
	var workshop: Vector3 = CityPlaces.shops()[2].door
	_record = Node3D.new()
	_record.name = "DeliveredRouteCopy"
	_record.position = workshop + Vector3(1.55,1.8,7.76)   # its back on the back wall's face (z 7.8)
	add_child(_record)
	_box(_record, "CopyBoard", Vector3.ZERO, Vector3(1.4,1.05,0.08), "wood")
	_box(_record, "Paper", Vector3(0,0,-0.055), Vector3(1.24,0.88,0.02), "cloth_cream")
	_text(_record, "КОПІЯ СЛУЖБОВОЇ СХЕМИ", Vector3(0,0.31,-0.073), PI, 0.0022)
	_text(_record, "ДВІР › НИЖНІ СХОДИ › ВЕЖА", Vector3(0,-0.28,-0.073), PI, 0.0022)
	# Repeat the three physical symbols, rather than substituting a quest marker.
	for x: float in [0.47,0.27]:
		_box(_record,"CopyCourt",Vector3(x,0.04,-0.073),Vector3(0.025,0.18,0.018),"ink")
	for y: float in [-0.05,0.13]:
		_box(_record,"CopyCourt",Vector3(0.37,y,-0.073),Vector3(0.2,0.025,0.018),"ink")
	for step: int in 4:
		_box(_record,"CopyStair",Vector3(0.065-float(step)*0.045,0.13-float(step)*0.05,-0.073),Vector3(0.08,0.03,0.018),"ink")
	_box(_record,"CopyTower",Vector3(-0.37,0.05,-0.073),Vector3(0.15,0.23,0.018),"ink")
	for x: float in [-0.29,-0.37,-0.45]:
		_box(_record,"CopyTowerCrown",Vector3(x,0.19,-0.073),Vector3(0.045,0.065,0.018),"ink")
	for x: float in [-0.53,0.53]:
		_box(_record, "Pin", Vector3(x,0.35,-0.085), Vector3(0.055,0.055,0.025), "brass")

func _point(id: String, point: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = id
	marker.position = point
	add_child(marker)
	_points[id] = marker

func _ink(parent: Node3D, point: Vector3, size: Vector3) -> Node3D:
	var part := _box(parent, "RouteMark", point, size, "ink")
	_lit_surface(part, Color("302934"))
	return part

func _lit_surface(node: Node3D, color: Color) -> void:
	var mesh: MeshInstance3D = node.get_node("Visible")
	mesh.layers = 8
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.disable_ambient_light = true
	mesh.material_override = material

func _box(parent: Node3D, id: String, point: Vector3, size: Vector3, material: String, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = id
	node.position = point
	parent.add_child(node)
	var visible := MeshInstance3D.new()
	visible.name = "Visible"
	var mesh := BoxMesh.new()
	mesh.size = size
	visible.mesh = mesh
	visible.material_override = _materials[material]
	node.add_child(visible)
	if solid:
		(node as StaticBody3D).collision_layer = 9
		(node as StaticBody3D).collision_mask = 0
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		node.add_child(collision)
	return node

func _text(parent: Node3D, content: String, point: Vector3, yaw: float, pixel_size: float, lit: bool = false) -> void:
	var label := Label3D.new()
	label.text = content
	label.position = point
	label.rotation.y = yaw
	label.pixel_size = pixel_size
	label.font_size = 32
	label.modulate = Color("ead6b2") if not lit else Color("302934")
	label.outline_size = 2 if not lit else 0
	label.shaded = lit
	label.layers = 8 if lit else 1
	parent.add_child(label)
