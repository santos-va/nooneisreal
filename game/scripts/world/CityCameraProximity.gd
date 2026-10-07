class_name CityCameraProximity
extends RefCounted
## Camera-owned material policy. Never hides the Fighter/rig or changes gameplay.
## PLACEHOLDER presentation metres/seconds; supports the Compatibility renderer.
const FULLY_CLEAR_DISTANCE: float = 0.85
const INSIDE_DISTANCE: float = 0.35
const CLOTH_SHADER = preload("res://shaders/camera_cloth.gdshader")
const RESPONSE: float = 18.0
const DEPTH_MASK = preload("res://shaders/camera_proximity_mask.gdshader")
## Opaque ink hull -> its camera-near depth-mask twin (same uniforms, depth_draw_never).
const NEAR_HULLS := {
	"res://shaders/hero_outline.gdshader": preload("res://shaders/hero_outline_near.gdshader"),
	"res://shaders/outline.gdshader": preload("res://shaders/outline_near.gdshader"),
}
## Sketch-Cel rule (docs/Art/2026-10-07-Tight-Station-Readability-Criteria.md): the ink line stays,
## the fill thins. PLACEHOLDER floor pending T6 frame acceptance; tests may lower it to prove the old policy.
var fill_floor: float = 0.25
var keep_outline: bool = true
## While the fill is thinned, each body -> hull chain becomes body -> depth mask -> near hull (T3 V3),
## so the ink hull no longer shows through the fill holes as a dark mass. At full visibility the
## original chain is untouched. Tests may switch it off to prove the dark-figure policy.
var depth_mask: bool = true
## Iteration-2 step 3 (T6: fade the occluder, never the hero): a resident whose body the lens nears
## dithers out through camera-local copies of its slot materials. Shared NPC materials, node
## visibility and the resident's shadow stay; the conversation partner is never faded.
## PLACEHOLDER metres pending T6 frame acceptance; tests may switch the policy off.
const RESIDENT_HIDDEN_DISTANCE: float = 0.45
const RESIDENT_CLEAR_DISTANCE: float = 1.25
var resident_fade: bool = true
## Raw lens-to-body factor (0 at the head/torso, 1 when clear); the applied values follow below.
var visibility: float = 1.0
var fill_visibility: float = 1.0
var outline_visibility: float = 1.0
var _materials: Array[ShaderMaterial] = []
var _original: Array[Variant] = []
var _outlines: Array[ShaderMaterial] = []
var _outline_original: Array[Variant] = []
var _hulls: Array[Dictionary] = []
var _clothing: Array[Dictionary] = []
var _gear: Array[Dictionary] = []
var _residents: Dictionary = {} # resident instance id -> {"actor", "visibility", "slots"}
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
		var hull: ShaderMaterial = shader_material.next_pass as ShaderMaterial
		if hull != null and hull.shader != null and NEAR_HULLS.has(hull.shader.resource_path):
			var chain: ShaderMaterial = _mask_chain(hull)
			_hulls.append({"body": shader_material, "hull": hull, "mask": chain})
	elif _supports(shader_material, "camera_outline_visibility"):
		_outlines.append(shader_material)
		_outline_original.append(shader_material.get_shader_parameter("camera_outline_visibility"))
	if material.next_pass != null:
		_collect(material.next_pass)

## Camera-local depth mask whose next_pass is the near twin of `hull`. Mask before hull in the
## alpha queue: alpha sorting is render_priority first (T3: rasterizer_scene_gles3.h:723-727).
static func _mask_chain(hull: ShaderMaterial) -> ShaderMaterial:
	var near := ShaderMaterial.new()
	near.shader = NEAR_HULLS[hull.shader.resource_path]
	near.render_priority = hull.render_priority + 1
	_sync_uniforms(near, hull)
	var mask := ShaderMaterial.new()
	mask.shader = DEPTH_MASK
	mask.render_priority = hull.render_priority
	mask.set_meta("camera_proximity_mask", true)
	mask.next_pass = near
	return mask

static func _sync_uniforms(target: ShaderMaterial, source: ShaderMaterial) -> void:
	for uniform: Dictionary in source.shader.get_shader_uniform_list():
		target.set_shader_parameter(uniform.name, source.get_shader_parameter(uniform.name))

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
	_apply_masks(depth_mask and fill_visibility < 0.999)
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
	_update_residents(camera, delta)

func _update_residents(camera: Camera3D, delta: float) -> void:
	var seen: Dictionary = {}
	var director: Node = null
	if resident_fade:
		for child: Node in _player.get_parent().get_children():
			if child is CityNpcDirector:
				director = child
	if director != null:
		for value: Variant in (director as CityNpcDirector).actors.values():
			if not is_instance_valid(value):
				continue
			var actor := value as CityNpcActor
			if actor == null or actor.conversing:
				continue
			var id: int = actor.get_instance_id()
			var near: Vector3 = Geometry3D.get_closest_point_to_segment(camera.global_position,
				actor.global_position + Vector3.UP * 0.2, actor.global_position + Vector3.UP * 1.65)
			var desired: float = smoothstep(RESIDENT_HIDDEN_DISTANCE, RESIDENT_CLEAR_DISTANCE, camera.global_position.distance_to(near))
			if not _residents.has(id):
				if desired >= 0.999:
					continue
				_residents[id] = {"actor": weakref(actor), "visibility": 1.0, "slots": []}
			var entry: Dictionary = _residents[id]
			entry.visibility = lerpf(entry.visibility, desired, 1.0 - exp(-RESPONSE * maxf(delta, 0.0)))
			if absf(entry.visibility - desired) < 0.002:
				entry.visibility = desired
			if entry.visibility < 0.999:
				seen[id] = true
				_fade_resident(actor, entry)
	for id: int in _residents.keys():
		if not seen.has(id):
			_restore_resident(_residents[id])
			_residents.erase(id)

func _fade_resident(actor: CityNpcActor, entry: Dictionary) -> void:
	var slots: Array = entry.slots
	# A rebuilt or replaced slot (work prop, clothing) owns its new value; dead meshes are released.
	for i: int in range(slots.size() - 1, -1, -1):
		var slot_entry: Dictionary = slots[i]
		var mesh: MeshInstance3D = slot_entry.mesh.get_ref()
		var current: Material = _get_slot(mesh, slot_entry.slot) if is_instance_valid(mesh) else null
		if not is_instance_valid(mesh) or (current != slot_entry.local and current != slot_entry.original):
			slots.remove_at(i)
	for node: Node in actor.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var ids: Array[int] = []
		if mesh.material_override != null:
			ids.append(-1)
		else:
			for surface: int in mesh.mesh.get_surface_count():
				ids.append(surface)
		for slot: int in ids:
			var known: bool = false
			for slot_entry: Dictionary in slots:
				if slot_entry.mesh.get_ref() == mesh and slot_entry.slot == slot:
					known = true
					break
			if known:
				continue
			var source: Material = mesh.material_override if slot < 0 else mesh.get_active_material(slot)
			var local: ShaderMaterial = null
			if source is StandardMaterial3D:
				local = ShaderMaterial.new()
				local.shader = CLOTH_SHADER
			elif source is ShaderMaterial and _supports(source as ShaderMaterial, "camera_visibility") and source.next_pass == null:
				# Not duplicate(): in a rendering build it reads the property list, which writes every
				# unset uniform default into the shared source (measured: null -> 1.0). _copy_shader fills it.
				local = ShaderMaterial.new()
				local.shader = (source as ShaderMaterial).shader
				local.render_priority = source.render_priority
			if local != null:
				slots.append({"mesh": weakref(mesh), "slot": slot, "original": _get_slot(mesh, slot), "source": source, "local": local})
	for slot_entry: Dictionary in slots:
		var mesh: MeshInstance3D = slot_entry.mesh.get_ref()
		if slot_entry.source is StandardMaterial3D:
			var standard: StandardMaterial3D = slot_entry.source
			slot_entry.local.set_shader_parameter("albedo", standard.albedo_color)
			slot_entry.local.set_shader_parameter("roughness", standard.roughness)
			slot_entry.local.set_shader_parameter("albedo_tex", standard.albedo_texture)
			slot_entry.local.set_shader_parameter("uv_scale", standard.uv1_scale)
			slot_entry.local.set_shader_parameter("camera_visibility", entry.visibility)
		else:
			_copy_shader(slot_entry.local, slot_entry.source, entry.visibility, entry.visibility)
		_set_slot(mesh, slot_entry.slot, slot_entry.local)

func _restore_resident(entry: Dictionary) -> void:
	for slot_entry: Dictionary in entry.slots:
		var mesh: MeshInstance3D = slot_entry.mesh.get_ref()
		if is_instance_valid(mesh) and _get_slot(mesh, slot_entry.slot) == slot_entry.local:
			_set_slot(mesh, slot_entry.slot, slot_entry.original)
	entry.slots.clear()

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

func _apply_masks(masked: bool) -> void:
	# Only a slot that still holds our original hull (or our mask) is ours: a presenter that set its
	# own next_pass (sword dissolve sets null) keeps it, and the swap resumes when the hull returns.
	for entry: Dictionary in _hulls:
		var body: ShaderMaterial = entry.body
		var mask: ShaderMaterial = entry.mask
		if masked:
			if body.next_pass == entry.hull:
				body.next_pass = mask
			if body.next_pass == mask:
				_sync_uniforms(mask.next_pass as ShaderMaterial, entry.hull)
		elif body.next_pass == mask:
			body.next_pass = entry.hull

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
	var local_next: Material = local.next_pass
	if local_next != null and local_next.has_meta("camera_proximity_mask"):
		local_next = local_next.next_pass # Our depth mask sits between a gear body and its near hull.
	if local_next is ShaderMaterial and source.next_pass is ShaderMaterial:
		_copy_shader(local_next,source.next_pass,fade,outline_fade)

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
					var local_hull: ShaderMaterial = local.next_pass as ShaderMaterial
					# Gear locals are only shown while faded, so their ink is always the masked chain.
					if depth_mask and local_hull != null and local_hull.shader != null and NEAR_HULLS.has(local_hull.shader.resource_path):
						local.next_pass = _mask_chain(local_hull)
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
	_apply_masks(false)
	for entry: Dictionary in _clothing:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if is_instance_valid(mesh) and mesh.material_override == entry.local:
			mesh.material_override = entry.original

	for entry: Dictionary in _gear:
		var mesh: MeshInstance3D = entry.mesh.get_ref()
		if is_instance_valid(mesh) and _get_slot(mesh,entry.slot) == entry.local:
			_set_slot(mesh,entry.slot,entry.original)
	for id: int in _residents:
		_restore_resident(_residents[id])
	_residents.clear()

func restore() -> void:
	reset()
	_materials.clear()
	_original.clear()
	_outlines.clear()
	_outline_original.clear()
	_hulls.clear()
	_clothing.clear()
	_gear.clear()
	_player = null
