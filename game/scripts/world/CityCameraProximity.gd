class_name CityCameraProximity
extends RefCounted
## Camera-owned material policy. Never hides the Fighter/rig or changes gameplay.
## PLACEHOLDER presentation metres/seconds; supports the Compatibility renderer.
const FULLY_CLEAR_DISTANCE: float = 0.85
const INSIDE_DISTANCE: float = 0.35
const CLOTH_SHADER = preload("res://shaders/camera_cloth.gdshader")
const RESPONSE: float = 18.0
var visibility: float = 1.0
var _materials: Array[ShaderMaterial] = []
var _original: Array[Variant] = []
var _clothing: Array[Dictionary] = []
var _player: Fighter

func setup(player: Fighter) -> void:
	restore()
	_player = player
	for material: ShaderMaterial in player.animator.materials:
		_collect(material)

func _collect(material: Material) -> void:
	if not material is ShaderMaterial or material in _materials:
		return
	var shader_material := material as ShaderMaterial
	var value: Variant = shader_material.get_shader_parameter("camera_visibility")
	var supported: bool = value != null
	if not supported and shader_material.shader != null:
		for uniform: Dictionary in shader_material.shader.get_shader_uniform_list():
			if uniform.name == "camera_visibility":
				supported = true
				break
	if supported:
		_materials.append(shader_material)
		_original.append(value)
	if material.next_pass != null:
		_collect(material.next_pass)

func update(camera: Camera3D, delta: float) -> void:
	if not is_instance_valid(_player) or camera == null:
		return
	if not camera.is_current():
		reset()
		return
	# A weapon can create presentation materials after camera setup.
	for material: ShaderMaterial in _player.animator.materials:
		_collect(material)
	_collect_clothing()
	# The head/torso capsule measures lens proximity, not world collision.
	var near_body: Vector3 = Geometry3D.get_closest_point_to_segment(camera.global_position,
		_player.global_position + Vector3.UP * 0.55, _player.global_position + Vector3.UP * 1.9)
	var distance: float = camera.global_position.distance_to(near_body)
	var desired: float = smoothstep(INSIDE_DISTANCE, FULLY_CLEAR_DISTANCE, distance)
	visibility = lerpf(visibility, desired, 1.0 - exp(-RESPONSE * maxf(delta, 0.0)))
	if absf(visibility - desired) < 0.002:
		visibility = desired
	for index: int in _materials.size():
		_materials[index].set_shader_parameter("camera_visibility", (1.0 if _original[index] == null else float(_original[index])) * visibility)
	for entry: Dictionary in _clothing:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh):
			continue
		if visibility < 0.999:
			entry.local.set_shader_parameter("albedo", entry.original.albedo_color)
			entry.local.set_shader_parameter("roughness", entry.original.roughness)
			entry.local.set_shader_parameter("camera_visibility", visibility)
			mesh.material_override = entry.local
		elif mesh.material_override == entry.local:
			mesh.material_override = entry.original

func _collect_clothing() -> void:
	# CityCosmetics is a sibling created after camera setup, tied to this hero.
	# Its original StandardMaterial stays untouched so palette changes keep working.
	for child: Node in _player.get_parent().get_children():
		if not child is CityCosmetics or child.fighter != _player:
			continue
		for node: Node in child.get_children():
			var mesh := node as MeshInstance3D
			if mesh == null or not mesh.material_override is StandardMaterial3D:
				continue
			var known: bool = false
			for entry: Dictionary in _clothing:
				if entry.mesh.get_ref() == mesh:
					known = true
					break
			if known:
				continue
			var local := ShaderMaterial.new()
			local.shader = CLOTH_SHADER
			_clothing.append({"mesh": weakref(mesh), "original": mesh.material_override, "local": local})

func reset() -> void:
	visibility = 1.0
	for index: int in _materials.size():
		_materials[index].set_shader_parameter("camera_visibility", _original[index])
	for entry: Dictionary in _clothing:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if is_instance_valid(mesh) and mesh.material_override == entry.local:
			mesh.material_override = entry.original

func restore() -> void:
	reset()
	_materials.clear()
	_original.clear()
	_clothing.clear()
	_player = null
