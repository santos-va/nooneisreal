class_name CityWaterPump
extends Node3D
## The water pump on the edge of the market court (plan 2026-10-08-Thirst-Substances-Icons step 1; T5
## docs/GDD/2026-10-08-Thirst-Numbers.md § 4 «Н2»; T7 PROPOSAL-Substances-And-Healthy-Food Л4). A procedural cast-iron
## hand pump — lever, spout, a ladle on a chain, a puddle — until T6 gives its form (0 credits). Free water: the existing
## `interact` at the spout (CityWorld), no menu. Its presence is what switches the thirst scale on (CityThirst: no water
## source, no thirst effects).
## Place: T5 suggested ≈ (0, 0, 17), which lies on the spawn → central court route that city_geometry_check probes and
## auto_hook_check stands the hero on (0, 0, 17.25). Moved 2.2 m west, 0.8 m south: 1.5 m from resident 6's lane corner
## (−3.5, 17), 1.8 m from resident 7's (−3.5, 19), 3.1 m from the court's centre (r 3). PLACEHOLDER metres (T2/T6).
const POSITION := Vector3(-2.2, 0.0, 17.8)
const YAW := PI * 0.5                    # the spout faces +X, the street from the spawn to the pocket
const SPOUT_LOCAL := Vector3(0.0, 0.86, 0.34)
## Hand reach at the spout, as the story points' (CityWorld.can_inspect_story): no cross-floor, no through-wall drink.
const REACH := 1.35
const REACH_VERTICAL := 0.75
## The form (PLACEHOLDER metres, T6 крок A): lever length and tilt, the handle at its back end, the ladle off the column.
const LEVER_LENGTH := 0.62
const LEVER_TILT := 0.42
const HANDLE_LOCAL := Vector3(0, 1.4, -0.53)
const LADLE_X := 0.21
const LADLE_RADIUS := 0.06

var spout: Marker3D
var body: StaticBody3D


func build(materials: Dictionary) -> void:
	name = "WaterPump"
	position = POSITION
	rotation.y = YAW
	add_to_group("water_source")
	body = StaticBody3D.new()
	body.name = "PumpBody"
	body.collision_layer = 9   # walking and the camera, like the district's solids (CityDistrict._box)
	body.collision_mask = 0
	add_child(body)
	var column := CylinderShape3D.new()
	column.radius = 0.2
	column.height = 1.3
	var shape := CollisionShape3D.new()
	shape.shape = column
	shape.position = Vector3(0, 0.65, 0)
	body.add_child(shape)
	# The spout and the lever with its handle stop a hero like every other mesh he walks into (C5 of
	# tools/world/city_tidy_check.gd, T1 after steps 1–4 of plan 2026-10-09): each shape is exactly its mesh. They are
	# shapes of PumpBody, so the drink ray that meets them still counts as reaching the pump (CityThirst.can_drink).
	_solid("SpoutPipe", Vector3(0, 0.9, 0.2), Vector3(0.07, 0.07, 0.3))
	_solid("SpoutMouth", Vector3(0, 0.86, 0.34), Vector3(0.075, 0.1, 0.075))
	_solid("LeverBar", Vector3(0, 1.27, -0.25), Vector3(0.045, 0.045, LEVER_LENGTH), LEVER_TILT)
	var grip := CylinderShape3D.new()
	grip.radius = 0.035
	grip.height = 0.12
	var grip_shape := CollisionShape3D.new()
	grip_shape.name = "HandleGrip"
	grip_shape.shape = grip
	grip_shape.position = HANDLE_LOCAL
	body.add_child(grip_shape)
	_box(materials, "stone", Vector3(0, 0.06, 0), Vector3(0.56, 0.12, 0.56))
	_cylinder(materials, "iron", Vector3(0, 0.62, 0), 0.115, 0.13, 1.0).name = "Column"
	for y: float in [0.3, 0.95]:
		_cylinder(materials, "iron", Vector3(0, y, 0), 0.145, 0.145, 0.05)
	_cylinder(materials, "iron", Vector3(0, 1.16, 0), 0.07, 0.16, 0.08).name = "Cap"
	_cylinder(materials, "brass", Vector3(0, 1.23, 0), 0.05, 0.05, 0.06).name = "Knob"
	# The spout: a short square pipe toward the street, turned down at its end.
	_box(materials, "iron", Vector3(0, 0.9, 0.2), Vector3(0.07, 0.07, 0.3))
	_box(materials, "iron", Vector3(0, 0.86, 0.34), Vector3(0.075, 0.1, 0.075))
	# The lever: up and back from the cap, a knob at its end. Turned about X by +LEVER_TILT its front end sits in the cap
	# (y 1.144, z 0.033) and its back end in the wooden handle (y 1.396, z −0.533 against 1.40, −0.53): T6
	# docs/Art/2026-10-08-Thirst-Items-Frames-Review.md § Колонка, крок A1 (the old −0.42 left both ends in the air).
	var lever := MeshInstance3D.new()
	lever.name = "Lever"
	var lever_mesh := BoxMesh.new()
	lever_mesh.size = Vector3(0.045, 0.045, LEVER_LENGTH)
	lever.mesh = lever_mesh
	lever.material_override = materials.get("iron")
	lever.position = Vector3(0, 1.27, -0.25)
	lever.rotation.x = LEVER_TILT
	add_child(lever)
	_cylinder(materials, "wood", HANDLE_LOCAL, 0.035, 0.035, 0.12).name = "Handle"
	# The ladle on its chain, hanging from a short hook off the upper ring; at x 0.21 its rim clears the column (r ≈ 0.122
	# at its height) by 0.037 m instead of sinking 0.020 m into it at x 0.15 (city_thirst_check T15; T6 крок A3, the
	# position only: T6's tin #B9BDC0 would be a new palette key, an art call left to T6/T1; the cast iron's colour is
	# Santos's fork Р6).
	_box(materials, "iron", Vector3(0.17, 0.94, 0.06), Vector3(0.09, 0.02, 0.02)).name = "LadleHook"
	_box(materials, "iron", Vector3(LADLE_X, 0.82, 0.06), Vector3(0.02, 0.24, 0.02)).name = "LadleChain"
	_cylinder(materials, "iron", Vector3(LADLE_X, 0.66, 0.06), LADLE_RADIUS, 0.045, 0.08).name = "Ladle"
	# The puddle under the spout (flat, no collider, no reflection).
	var puddle := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.34
	disc.bottom_radius = 0.34
	disc.height = 0.006
	puddle.mesh = disc
	puddle.material_override = materials.get("glass")
	puddle.position = Vector3(0, 0.004, 0.42)
	puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(puddle)
	spout = Marker3D.new()
	spout.name = "Spout"
	spout.position = SPOUT_LOCAL
	add_child(spout)


func spout_point() -> Vector3:
	return spout.global_position if spout != null and spout.is_inside_tree() else POSITION + SPOUT_LOCAL.rotated(Vector3.UP, YAW)


## A box collision shape of PumpBody at `at`, turned about X by `tilt`.
func _solid(id: String, at: Vector3, size: Vector3, tilt: float = 0.0) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.name = id
	shape.shape = box
	shape.position = at
	shape.rotation.x = tilt
	body.add_child(shape)


func _box(materials: Dictionary, key: String, at: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = materials.get(key)
	instance.position = at
	add_child(instance)
	return instance


func _cylinder(materials: Dictionary, key: String, at: Vector3, top: float, bottom: float, height: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = materials.get(key)
	instance.position = at
	add_child(instance)
	return instance
