class_name HeroGarmentMask
extends RefCounted
## Explicit garment-bone whitelist, cached once; never edits UVs, skin, weights or bones.
const SHADER = preload("res://shaders/hero_garment.gdshader")
const CLOTH_BONES: Array[String] = ["Hips", "Spine02", "Spine01", "Spine", "LeftUpLeg", "RightUpLeg"]
static var _cache: Dictionary = {}
var original_mesh: Mesh
var selected_vertices: int = 0
var total_vertices: int = 0
var protected_vertices: int = 0
var mask_values: PackedColorArray
var rest_points: PackedVector3Array

func setup(f: Fighter, rig: SkeletalRig) -> void:
	var mesh: MeshInstance3D = rig.hero_mesh
	if mesh == null or mesh.skin == null or mesh.mesh.get_blend_shape_count() != 0:
		return
	original_mesh = mesh.mesh
	var key: String = "%s:%s" % [f.data.id,original_mesh.get_instance_id()]
	if _cache.has(key):
		var cached: Dictionary = _cache[key]
		mesh.mesh = cached.mesh
		selected_vertices = cached.selected
		total_vertices = cached.total
		protected_vertices = cached.protected
		mask_values = cached.values
		rest_points = cached.rest
		(mesh.material_override as ShaderMaterial).shader = SHADER
		return
	var result := ArrayMesh.new()
	for surface: int in original_mesh.get_surface_count():
		var arrays: Array = original_mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var stride: int = joints.size() / maxi(vertices.size(),1)
		var allowed := PackedByteArray()
		var blocked := PackedByteArray()
		rest_points.resize(vertices.size())
		allowed.resize(vertices.size())
		blocked.resize(vertices.size())
		for vertex: int in vertices.size():
			var cloth: float = 0.0
			var unsafe: bool = false
			var rest: Vector3 = Vector3.ZERO
			for j: int in stride:
				var offset: int = vertex * stride + j
				if weights[offset] <= 0.000001:
					continue
				var bind: int = joints[offset]
				var bone: int = rig.hero_skeleton.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
				if bone < 0:
					unsafe = true
					continue
				var name: String = rig.hero_skeleton.get_bone_name(bone)
				if name in CLOTH_BONES:
					cloth += weights[offset]
				else:
					unsafe = true
				rest += rig.hero_skeleton.get_bone_global_rest(bone) * mesh.skin.get_bind_pose(bind) * vertices[vertex] * weights[offset]
			# Skea's baked backpack stays original leather: front-only torso mask.
			var front: bool = true
			if f.data.id == "skea":
				var hip: Vector3 = rig.hero_skeleton.get_bone_global_rest(rig.hero_skeleton.find_bone("Hips")).origin
				front = rest.y < hip.y or rest.z >= hip.z
			rest_points[vertex] = rest
			allowed[vertex] = 1 if cloth >= 0.98 and not unsafe and front else 0
		# Every triangle touching protected anatomy has all its corners black.
		# No interpolated cloth grain can bleed across a head/hand boundary.
		for tri: int in indices.size() / 3:
			var a: int = indices[tri*3]
			var b: int = indices[tri*3+1]
			var c: int = indices[tri*3+2]
			if allowed[a] == 0 or allowed[b] == 0 or allowed[c] == 0:
				blocked[a] = 1
				blocked[b] = 1
				blocked[c] = 1
		var original_colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var colors := PackedColorArray()
		colors.resize(vertices.size())
		for vertex: int in vertices.size():
			var on: bool = allowed[vertex] == 1 and blocked[vertex] == 0
			var color: Color = original_colors[vertex] if original_colors.size() == vertices.size() else Color.WHITE
			color.g = 1.0 if on else 0.0
			colors[vertex] = color
			selected_vertices += 1 if on else 0
			protected_vertices += 0 if on else 1
		total_vertices += vertices.size()
		mask_values = colors
		arrays[Mesh.ARRAY_COLOR] = colors
		# Preserve imported decimation LODs; RenderingServer stores packed indices.
		var source: Dictionary = RenderingServer.mesh_get_surface(original_mesh.get_rid(),surface)
		var index_bytes: int = source.index_data.size() / maxi(indices.size(),1)
		var lods: Dictionary = {}
		for lod: Dictionary in source.get("lods",[]):
			var packed: PackedByteArray = lod.index_data
			var decoded := PackedInt32Array()
			decoded.resize(packed.size()/index_bytes)
			for i: int in decoded.size():
				decoded[i] = packed.decode_u16(i*2) if index_bytes == 2 else packed.decode_u32(i*4)
			lods[lod.edge_length] = decoded
		var flags: int = original_mesh.surface_get_format(surface) & (Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS | Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		result.add_surface_from_arrays(original_mesh.surface_get_primitive_type(surface),arrays,[],lods,flags)
	_cache[key] = {"source":original_mesh,"mesh":result,"selected":selected_vertices,"total":total_vertices,"protected":protected_vertices,"values":mask_values,"rest":rest_points}
	mesh.mesh = result
	(mesh.material_override as ShaderMaterial).shader = SHADER
