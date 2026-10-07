class_name CityCameraProximity
extends RefCounted
## Camera-owned material policy. Never hides the Fighter/rig or changes gameplay.
## PLACEHOLDER presentation metres/seconds; supports the Compatibility renderer.
const FULLY_CLEAR_DISTANCE: float = 0.85
const INSIDE_DISTANCE: float = 0.35
const CLOTH_SHADER = preload("res://shaders/camera_cloth.gdshader")
const RESPONSE: float = 18.0
## Sketch-Cel rule (docs/Art/2026-10-07-Tight-Station-Readability-Criteria.md): the ink line stays,
## the fill thins. PLACEHOLDER floor pending T6 frame acceptance; tests may lower it to prove the old policy.
var fill_floor: float = 0.25
var keep_outline: bool = true
## Raw lens-to-body factor (0 at the head/torso, 1 when clear); the applied values follow below.
var visibility: float = 1.0
var fill_visibility: float = 1.0
var outline_visibility: float = 1.0
var _materials: Array[ShaderMaterial] = []
var _original: Array[Variant] = []
var _outlines: Array[ShaderMaterial] = []
var _outline_original: Array[Variant] = []
var _clothing: Array[Dictionary] = []
var _gear: Array[Dictionary] = []
var _player: Fighter

func setup(player: Fighter) -> void:
	restore()
	_player = player
	for material: ShaderMaterial in player.animator.materials:
		_collect(material)

func _collect(material: Material) -> void:
	if not material is ShaderMaterial or material in _materials or material in _outlines:
		return
	var shader_material := material as ShaderMaterial
	if _supports(shader_material, "camera_visibility"):
		_materials.append(shader_material)
		_original.append(shader_material.get_shader_parameter("camera_visibility"))
	elif _supports(shader_material, "camera_outline_visibility"):
		_outlines.append(shader_material)
		_outline_original.append(shader_material.get_shader_parameter("camera_outline_visibility"))
	if material.next_pass != null:
		_collect(material.next_pass)

static func _supports(material: ShaderMaterial, uniform_name: String) -> bool:
	if material.get_shader_parameter(uniform_name) != null:
		return true
	if material.shader == null:
		return false
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		if uniform.name == uniform_name:
			return true
	return false

func update(camera: Camera3D, delta: float) -> void:
	if not is_instance_valid(_player) or camera == null:
		return
	if not camera.is_current():
		reset()
		return
	# A weapon can create presentation materials after camera setup.
	for material: ShaderMaterial in _player.animator.materials:
		_collect(material)
	_prune_slots()
	_collect_clothing()
	_collect_gear()
	# The head/torso capsule measures lens proximity, not world collision.
	var near_body: Vector3 = Geometry3D.get_closest_point_to_segment(camera.global_position,
		_player.global_position + Vector3.UP * 0.55, _player.global_position + Vector3.UP * 1.9)
	var distance: float = camera.global_position.distance_to(near_body)
	var desired: float = smoothstep(INSIDE_DISTANCE, FULLY_CLEAR_DISTANCE, distance)
	visibility = lerpf(visibility, desired, 1.0 - exp(-RESPONSE * maxf(delta, 0.0)))
	if absf(visibility - desired) < 0.002:
		visibility = desired
	# The fill never thins below its floor and the ink line stays, so the hero never vanishes.
	fill_visibility = maxf(visibility, fill_floor)
	outline_visibility = 1.0 if keep_outline else fill_visibility
	for index: int in _materials.size():
		_materials[index].set_shader_parameter("camera_visibility", (1.0 if _original[index] == null else float(_original[index])) * fill_visibility)
	for index: int in _outlines.size():
		_outlines[index].set_shader_parameter("camera_outline_visibility", (1.0 if _outline_original[index] == null else float(_outline_original[index])) * outline_visibility)
	var faded: bool = fill_visibility < 0.999 or outline_visibility < 0.999
	for entry: Dictionary in _clothing:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh):
			continue
		if faded:
			entry.local.set_shader_parameter("albedo", entry.original.albedo_color)
			entry.local.set_shader_parameter("roughness", entry.original.roughness)
			entry.local.set_shader_parameter("albedo_tex", entry.original.albedo_texture)
			entry.local.set_shader_parameter("uv_scale", entry.original.uv1_scale)
			entry.local.set_shader_parameter("camera_visibility", fill_visibility)
			mesh.material_override = entry.local
		elif mesh.material_override == entry.local:
			mesh.material_override = entry.original

	for entry: Dictionary in _gear:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh):
			continue
		if faded:
			if entry.source is StandardMaterial3D:
				entry.local.set_shader_parameter("albedo",entry.source.albedo_color)
				entry.local.set_shader_parameter("roughness",entry.source.roughness)
				entry.local.set_shader_parameter("albedo_tex",entry.source.albedo_texture)
				entry.local.set_shader_parameter("uv_scale",entry.source.uv1_scale)
				entry.local.set_shader_parameter("camera_visibility",fill_visibility)
			else:
				_copy_shader(entry.local,entry.source,fill_visibility,outline_visibility)
			_set_slot(mesh,entry.slot,entry.local)
		elif _get_slot(mesh,entry.slot) == entry.local:
			_set_slot(mesh,entry.slot,entry.original)

func _prune_slots() -> void:
	# A cosmetic rebuild or explicit replacement owns the new slot value. Do not
	# resurrect an old material, and release dead meshes' material chains promptly.
	for i: int in range(_clothing.size()-1,-1,-1):
		var entry: Dictionary = _clothing[i]
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh) or (mesh.material_override != entry.local and mesh.material_override != entry.original):
			_clothing.remove_at(i)
	for i: int in range(_gear.size()-1,-1,-1):
		var entry: Dictionary = _gear[i]
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if not is_instance_valid(mesh):
			_gear.remove_at(i)
			continue
		if mesh.mesh == null or entry.slot >= mesh.mesh.get_surface_count():
			if entry.slot < 0 and mesh.material_override == entry.local:
				mesh.material_override = entry.original
			_gear.remove_at(i)
			continue
		var current: Material = _get_slot(mesh,entry.slot)
		var active: Material = mesh.get_active_material(entry.slot) if entry.slot >= 0 else current
		if (current != entry.local and current != entry.original) or (current == null and active != entry.source):
			_gear.remove_at(i)

static func _get_slot(mesh: MeshInstance3D, slot: int) -> Material:
	if slot < 0:
		return mesh.material_override
	if mesh.mesh == null or slot >= mesh.mesh.get_surface_count():
		return null
	return mesh.get_surface_override_material(slot)

static func _set_slot(mesh: MeshInstance3D, slot: int, material: Material) -> void:
	if slot < 0:
		mesh.material_override = material
	elif mesh.mesh != null and slot < mesh.mesh.get_surface_count():
		mesh.set_surface_override_material(slot,material)

static func _duplicate_chain(source: Material) -> Material:
	var local: Material = source.duplicate()
	if source.next_pass != null:
		local.next_pass = _duplicate_chain(source.next_pass)
	return local

static func _copy_shader(local: ShaderMaterial, source: ShaderMaterial, fade: float, outline_fade: float) -> void:
	for uniform: Dictionary in source.shader.get_shader_uniform_list():
		var value: Variant = source.get_shader_parameter(uniform.name)
		if uniform.name == "camera_visibility":
			value = (1.0 if value == null else float(value))*fade
		elif uniform.name == "camera_outline_visibility":
			value = (1.0 if value == null else float(value))*outline_fade
		local.set_shader_parameter(uniform.name,value)
	if local.next_pass is ShaderMaterial and source.next_pass is ShaderMaterial:
		_copy_shader(local.next_pass,source.next_pass,fade,outline_fade)

func _collect_gear() -> void:
	var roots: Array[Node] = []
	if _player.skeletal != null and _player.skeletal.gear != null:
		roots.append(_player.skeletal.gear)
	for child: Node in _player.get_parent().get_children():
		if child is CityCosmetics and child.fighter == _player:
			roots.append(child)
	# Traverse late/nested geometry and every material slot. Shared source
	# resources stay immutable; camera-local replacements restore exact pointers.
	for holder: Node in roots:
		for node: Node in holder.find_children("*","MeshInstance3D",true,false):
			var mesh := node as MeshInstance3D
			var direct_cloth: bool = false
			for entry: Dictionary in _clothing:
				if entry.mesh.get_ref() == mesh:
					direct_cloth = true
					break
			if direct_cloth or mesh.mesh == null:
				continue
			var slots: Array[int] = []
			if mesh.material_override != null:
				slots.append(-1)
			if slots.is_empty():
				for surface: int in mesh.mesh.get_surface_count():
					slots.append(surface)
			for slot: int in slots:
				var source: Material = mesh.material_override if slot < 0 else mesh.get_active_material(slot)
				if source == null or (source is ShaderMaterial and source in _player.animator.materials):
					continue
				var known: bool = false
				for entry: Dictionary in _gear:
					if entry.mesh.get_ref() == mesh and entry.slot == slot:
						known = true
						break
				if known:
					continue
				var local: ShaderMaterial
				if source is StandardMaterial3D:
					local = ShaderMaterial.new()
					local.shader = CLOTH_SHADER
				elif source is ShaderMaterial and source.shader != null:
					var supported: bool = false
					for info: Dictionary in source.shader.get_shader_uniform_list():
						if info.name == "camera_visibility":
							supported = true
					if not supported:
						continue
					local = _duplicate_chain(source)
				else:
					continue
				_gear.append({"mesh":weakref(mesh),"slot":slot,"original":_get_slot(mesh,slot),"source":source,"local":local})

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
	fill_visibility = 1.0
	outline_visibility = 1.0
	for index: int in _materials.size():
		_materials[index].set_shader_parameter("camera_visibility", _original[index])
	for index: int in _outlines.size():
		_outlines[index].set_shader_parameter("camera_outline_visibility", _outline_original[index])
	for entry: Dictionary in _clothing:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if is_instance_valid(mesh) and mesh.material_override == entry.local:
			mesh.material_override = entry.original

	for entry: Dictionary in _gear:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if is_instance_valid(mesh) and _get_slot(mesh,entry.slot) == entry.local:
			_set_slot(mesh,entry.slot,entry.original)

func restore() -> void:
	reset()
	_materials.clear()
	_original.clear()
	_outlines.clear()
	_outline_original.clear()
	_clothing.clear()
	_gear.clear()
	_player = null
