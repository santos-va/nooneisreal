class_name HeroGarmentMask
extends RefCounted
## Explicit garment-bone whitelist, cached once; never edits UVs, skin, weights or bones.
const SHADER = preload("res://shaders/hero_garment.gdshader")
const Face = preload("res://scripts/fighter/HeroFacePresentation.gd")
const CLOTH_BONES: Array[String] = ["Hips", "Spine02", "Spine01", "Spine", "LeftUpLeg", "RightUpLeg"]
const SLEEVE_BONES: Array[String] = ["LeftShoulder", "RightShoulder", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm"]
static var _cache: Dictionary = {}
var original_mesh: Mesh
var selected_vertices: int = 0
var total_vertices: int = 0
var protected_vertices: int = 0
var delighted_vertices: int = 0
var face_vertices: int = 0
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
		delighted_vertices = cached.delighted
		face_vertices = cached.face
		mask_values = cached.values
		rest_points = cached.rest
		(mesh.material_override as ShaderMaterial).shader = SHADER
		return
	var atlas: Texture2D = (mesh.material_override as ShaderMaterial).get_shader_parameter("albedo_tex")
	var atlas_image: Image = atlas.get_image() if atlas != null else null
	if atlas_image != null and atlas_image.is_compressed():
		atlas_image.decompress()
	var result := ArrayMesh.new()
	for surface: int in original_mesh.get_surface_count():
		var arrays: Array = original_mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var lods: Dictionary = _surface_lods(original_mesh,surface,indices.size())
		var stride: int = joints.size() / maxi(vertices.size(),1)
		var allowed := PackedByteArray()
		var delight := PackedByteArray()
		var face := PackedByteArray()
		rest_points.resize(vertices.size())
		allowed.resize(vertices.size())
		delight.resize(vertices.size())
		face.resize(vertices.size())
		var hip: Vector3 = rig.hero_skeleton.get_bone_global_rest(rig.hero_skeleton.find_bone("Hips")).origin
		var skeleton_scale: float = rig.hero_skeleton.global_transform.basis.get_scale().x
		for vertex: int in vertices.size():
			var cloth: float = 0.0
			var sleeve: float = 0.0
			var hand_weight: float = 0.0
			var head_weight: float = 0.0
			var unsafe: bool = false
			var delight_unsafe: bool = false
			var rest: Vector3 = Vector3.ZERO
			for j: int in stride:
				var offset: int = vertex * stride + j
				if weights[offset] <= 0.000001:
					continue
				var bind: int = joints[offset]
				var bone: int = rig.hero_skeleton.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
				if bone < 0:
					unsafe = true
					delight_unsafe = true
					continue
				var name: String = rig.hero_skeleton.get_bone_name(bone)
				if name in ["Head","head_end","headfront"]:
					head_weight += weights[offset]
				if name in CLOTH_BONES:
					cloth += weights[offset]
				else:
					unsafe = true
				if f.data.id == "skea" and name in SLEEVE_BONES:
					sleeve += weights[offset]
				elif f.data.id == "skea" and name in ["LeftHand","RightHand"]:
					hand_weight += weights[offset]
				elif name not in CLOTH_BONES:
					delight_unsafe = true
				rest += rig.hero_skeleton.get_bone_global_rest(bone) * mesh.skin.get_bind_pose(bind) * vertices[vertex] * weights[offset]
			# Skea's baked backpack stays original leather: front-only torso mask.
			var front: bool = true
			if f.data.id == "skea":
				front = rest.y < hip.y or rest.z >= hip.z
			rest_points[vertex] = rest
			allowed[vertex] = 1 if cloth >= 0.98 and not unsafe and front else 0
			# Actual atlas/geometry audit: bare neckline occupies the central upper
			# chest and has shoulder weights. Bone names alone cannot protect it.
			# Actual hand skin begins beyond 520 mm lateral offset in this model.
			# A 500 mm sleeve limit retains a 20 mm margin even with hand skin weights.
			# Conservative 280 mm torso / 160 mm sleeve / 35 mm zipper limits are
			# PLACEHOLDER art boundaries measured in the unposed model's metre scale.
			var side_m: float = absf(rest.x-hip.x)*skeleton_scale
			var height_m: float = (rest.y-hip.y)*skeleton_scale
			var torso: bool = height_m >= 0.0 and height_m < 0.28 and rest.z >= hip.z and side_m > 0.035 and side_m < 0.18
			var sleeve_region: bool = sleeve+hand_weight >= 0.98 and side_m > 0.16 and side_m < 0.50
			delight[vertex] = 1 if f.data.id == "skea" and cloth+ sleeve+hand_weight >= 0.98 and not delight_unsafe and (sleeve_region or torso) and not _skin_texel(atlas_image,uv[vertex]) else 0
			face[vertex] = 1 if Face.mask_vertex(f.data.id,rest,uv[vertex],head_weight) > 0.5 else 0
		var blocked: PackedByteArray = _protected_corners(allowed,indices,lods)
		var delight_blocked: PackedByteArray = _protected_corners(delight,indices,lods)
		var face_blocked: PackedByteArray = _protected_corners(face,indices,lods)
		var original_colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var colors := PackedColorArray()
		colors.resize(vertices.size())
		for vertex: int in vertices.size():
			var on: bool = allowed[vertex] == 1 and blocked[vertex] == 0
			var color: Color = original_colors[vertex] if original_colors.size() == vertices.size() else Color.WHITE
			# R face, G cloth, B de-light, A original. Current outline ignores COLOR.
			color.r = 1.0 if face[vertex] != 0 and face_blocked[vertex] == 0 else 0.0
			color.g = 1.0 if on else 0.0
			color.b = 1.0 if delight[vertex] != 0 and delight_blocked[vertex] == 0 else 0.0
			colors[vertex] = color
			selected_vertices += 1 if on else 0
			protected_vertices += 0 if on else 1
			delighted_vertices += 1 if color.b > 0.0 else 0
			face_vertices += 1 if color.r > 0.0 else 0
		total_vertices += vertices.size()
		mask_values = colors
		arrays[Mesh.ARRAY_COLOR] = colors
		var flags: int = original_mesh.surface_get_format(surface) & (Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS | Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
		result.add_surface_from_arrays(original_mesh.surface_get_primitive_type(surface),arrays,[],lods,flags)
	_cache[key] = {"source":original_mesh,"mesh":result,"selected":selected_vertices,"total":total_vertices,"protected":protected_vertices,"delighted":delighted_vertices,"face":face_vertices,"values":mask_values,"rest":rest_points}
	mesh.mesh = result
	(mesh.material_override as ShaderMaterial).shader = SHADER


## Any triangle touching ineligible anatomy blocks all of its corners, at every LOD.
static func _protected_corners(allowed: PackedByteArray, indices: PackedInt32Array, lods: Dictionary) -> PackedByteArray:
	var blocked := PackedByteArray()
	blocked.resize(allowed.size())
	var index_sets: Array = [indices]
	index_sets.append_array(lods.values())
	for triangles: PackedInt32Array in index_sets:
		for tri: int in triangles.size()/3:
			var a: int = triangles[tri*3]
			var b: int = triangles[tri*3+1]
			var c: int = triangles[tri*3+2]
			if allowed[a] == 0 or allowed[b] == 0 or allowed[c] == 0:
				blocked[a] = 1
				blocked[b] = 1
				blocked[c] = 1
	return blocked


static func _surface_lods(mesh: Mesh, surface: int, index_count: int) -> Dictionary:
	var source: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(),surface)
	var index_bytes: int = source.index_data.size()/maxi(index_count,1)
	var lods: Dictionary = {}
	for lod: Dictionary in source.get("lods",[]):
		var packed: PackedByteArray = lod.index_data
		var decoded := PackedInt32Array()
		decoded.resize(packed.size()/index_bytes)
		for i: int in decoded.size():
			decoded[i] = packed.decode_u16(i*2) if index_bytes == 2 else packed.decode_u32(i*4)
		lods[lod.edge_length] = decoded
	return lods


## Secondary protection for pink complexion texels, including blended shoulder skin.
## Geometry remains the primary guard for pure-white skin highlights and teeth.
static func _skin_texel(atlas: Image, uv: Vector2) -> bool:
	if atlas == null:
		return true
	var pixel := Vector2i(uv*Vector2(atlas.get_size()))
	var color: Color = atlas.get_pixel(clampi(pixel.x,0,atlas.get_width()-1),clampi(pixel.y,0,atlas.get_height()-1))
	return color.r > 0.55 and color.g > 0.32 and color.r-color.g > 0.09 and color.r-color.b > 0.07
