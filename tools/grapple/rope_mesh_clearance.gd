extends RefCounted
## The drawn hero's surface against the boxes CityDistrict builds for an anchor's support (AnchorArm / AnchorCeramic /
## AnchorStrut <n>): CPU linear-blend skinning of every visible skinned mesh under the hero, vertex = skeleton global
## transform × bone global pose × bind pose × vertex, summed by weight — the formula of T6's acceptance probe
## (docs/Audit/2026-10-15-T6-Rope-Climb-Acceptance.md, «Повторне приймання після T2-М»: the bone centres the first guards
## measured miss the hair and the sleeves). A vertex is inside a box when it lies strictly inside on all three axes.
## Groups by the vertex's heaviest bone: head (Head, head_end, headfront, neck), torso (Hips, Spine*, *Shoulder),
## upperarm (*Arm), forearm (*ForeArm), hand (*Hand), leg (the rest).
## Cost: vertices weighed by the same set of bones are one bucket; every vertex of a bucket lies in the convex hull of its
## bones' spheres (bone origin, |bind-space vertex| × the bone's largest stretch), so in one sphere around them; a bucket
## whose sphere misses every box is not skinned. Exact, not sampled: a culled vertex cannot be inside. Vertices whose
## weights do not sum to 1 are never culled.

const GROUPS: Array[String] = ["head", "torso", "upperarm", "forearm", "hand", "leg"]

var _meshes: Array[Dictionary] = []
## Vertices of the last count() that were skinned, and all vertices of the requested groups (the cull's saving).
var skinned: int = 0
var considered: int = 0
var vertices: int = 0


static func group_of(bone_name: String) -> String:
	if bone_name in ["Head", "head_end", "headfront", "neck"]:
		return "head"
	if bone_name.begins_with("Spine") or bone_name == "Hips" or bone_name.ends_with("Shoulder"):
		return "torso"
	if bone_name.ends_with("ForeArm"):
		return "forearm"
	if bone_name.ends_with("Arm"):
		return "upperarm"
	if bone_name.ends_with("Hand"):
		return "hand"
	return "leg"


## Reads every visible skinned MeshInstance3D under `hero`. Returns the number of meshes found.
func setup(hero: Node) -> int:
	_meshes.clear()
	vertices = 0
	var stack: Array[Node] = [hero]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var instance := node as MeshInstance3D
		if instance == null or instance.mesh == null or instance.skin == null or not instance.is_visible_in_tree():
			continue
		var skeleton := instance.get_node_or_null(instance.skeleton) as Skeleton3D
		if skeleton == null:
			continue
		for surface: int in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if verts.is_empty() or arrays[Mesh.ARRAY_BONES] == null or arrays[Mesh.ARRAY_WEIGHTS] == null:
				continue
			var bones := PackedInt32Array(arrays[Mesh.ARRAY_BONES])
			var weights := PackedFloat32Array(arrays[Mesh.ARRAY_WEIGHTS])
			var per: int = bones.size() / verts.size()
			var bind_bone := PackedInt32Array()
			var bind_pose: Array[Transform3D] = []
			for bind: int in instance.skin.get_bind_count():
				var bone: int = instance.skin.get_bind_bone(bind)
				if bone < 0:
					bone = skeleton.find_bone(instance.skin.get_bind_name(bind))
				bind_bone.append(bone)
				bind_pose.append(instance.skin.get_bind_pose(bind))
			var radius := PackedFloat32Array()
			radius.resize(bind_bone.size())
			var buckets: Dictionary = {}
			for v: int in verts.size():
				var top := -1
				var top_weight := 0.0
				var sum := 0.0
				var members := PackedInt32Array()
				for k: int in per:
					var weight: float = weights[v * per + k]
					if weight <= 0.0:
						continue
					var bind: int = bones[v * per + k]
					sum += weight
					if not members.has(bind):
						members.append(bind)
					radius[bind] = maxf(radius[bind], (bind_pose[bind] * verts[v]).length())
					if weight > top_weight:
						top_weight = weight
						top = bind
				members.sort()
				var exact: bool = absf(sum - 1.0) <= 0.001
				var key := "*" if not exact else ""
				for bind: int in members:
					key += "%d," % bind
				var bone_name: String = skeleton.get_bone_name(bind_bone[top]) if top >= 0 and bind_bone[top] >= 0 else ""
				var group: int = GROUPS.find(group_of(bone_name))
				if not buckets.has(key):
					var collect: Array = []
					for g: int in GROUPS.size():
						collect.append([])
					buckets[key] = {"binds": members, "exact": exact, "collect": collect}
				(buckets[key].collect[group] as Array).append(v)
			for bucket: Dictionary in buckets.values():
				var lists: Array[PackedInt32Array] = []
				for collected: Array in bucket.collect:
					lists.append(PackedInt32Array(collected))
				bucket.erase("collect")
				bucket["lists"] = lists
			vertices += verts.size()
			_meshes.append({"skeleton": skeleton, "verts": verts, "bones": bones, "weights": weights, "per": per,
				"bind_bone": bind_bone, "bind_pose": bind_pose, "radius": radius, "buckets": buckets.values()})
	return _meshes.size()


## Upper bound of the largest stretch of `basis` (its spectral norm): the square root of Gershgorin's bound on BᵀB.
static func _stretch(basis: Basis) -> float:
	var columns: Array[Vector3] = [basis.x, basis.y, basis.z]
	var bound := 0.0
	for i: int in 3:
		var row := 0.0
		for j: int in 3:
			row += absf(columns[i].dot(columns[j]))
		bound = maxf(bound, row)
	return sqrt(bound) * 1.0001


## Per box node (AnchorArm<n> etc., its first child a BoxMesh): {"n": vertices of `groups` inside, "depth": the deepest,
## "<group>": count per group}. Boxes that are missing are left out.
func count(boxes: Array, groups: Array) -> Dictionary:
	var holders: Array = []
	var result: Dictionary = {}
	for item: Variant in boxes:
		var box := item as Node3D
		if box == null:
			continue
		var mesh := (box.get_child(0) as MeshInstance3D).mesh as BoxMesh
		var basis: Basis = box.global_transform.basis
		var rigid: bool = absf(basis.x.length() - 1.0) < 0.0001 and absf(basis.y.length() - 1.0) < 0.0001 and absf(basis.z.length() - 1.0) < 0.0001 \
			and absf(basis.x.dot(basis.y)) < 0.0001 and absf(basis.y.dot(basis.z)) < 0.0001 and absf(basis.z.dot(basis.x)) < 0.0001
		holders.append({"name": String(box.name), "inverse": box.global_transform.affine_inverse(), "half": mesh.size * 0.5, "rigid": rigid})
		result[String(box.name)] = {"n": 0, "depth": 0.0}
	skinned = 0
	considered = 0
	var wanted: Array[int] = []
	for g: String in groups:
		wanted.append(GROUPS.find(g))
	for mesh: Dictionary in _meshes:
		var skeleton: Skeleton3D = mesh.skeleton
		var global: Transform3D = skeleton.global_transform
		var bind_bone: PackedInt32Array = mesh.bind_bone
		var bind_pose: Array[Transform3D] = mesh.bind_pose
		var radius: PackedFloat32Array = mesh.radius
		var matrices: Array[Transform3D] = []
		var centres: Array[Vector3] = []
		var reach := PackedFloat32Array()
		for bind: int in bind_bone.size():
			var bone_global: Transform3D = global * skeleton.get_bone_global_pose(bind_bone[bind]) if bind_bone[bind] >= 0 else global
			matrices.append(bone_global * bind_pose[bind])
			centres.append(bone_global.origin)
			reach.append(_stretch(bone_global.basis) * radius[bind])
		var verts: PackedVector3Array = mesh.verts
		var bones: PackedInt32Array = mesh.bones
		var weights: PackedFloat32Array = mesh.weights
		var per: int = mesh.per
		for bucket: Dictionary in mesh.buckets:
			var lists: Array[PackedInt32Array] = bucket.lists
			var size := 0
			for g: int in wanted:
				size += lists[g].size()
			if size == 0:
				continue
			considered += size
			var near: Array = []
			if bool(bucket.exact):
				var binds: PackedInt32Array = bucket.binds
				var centre := Vector3.ZERO
				for bind: int in binds:
					centre += centres[bind]
				centre /= float(binds.size())
				var sphere := 0.0
				for bind: int in binds:
					sphere = maxf(sphere, centre.distance_to(centres[bind]) + reach[bind])
				for holder: Dictionary in holders:
					if not bool(holder.rigid):
						near.append(holder)
						continue
					var local: Vector3 = (holder.inverse as Transform3D) * centre
					var half: Vector3 = holder.half
					var gap := Vector3(maxf(absf(local.x) - half.x, 0.0), maxf(absf(local.y) - half.y, 0.0), maxf(absf(local.z) - half.z, 0.0)).length()
					if gap <= sphere + 0.0001:
						near.append(holder)
			else:
				near = holders
			if near.is_empty():
				continue
			for g: int in wanted:
				var list: PackedInt32Array = lists[g]
				skinned += list.size()
				for v: int in list:
					var world := Vector3.ZERO
					for k: int in per:
						var weight: float = weights[v * per + k]
						if weight > 0.0:
							world += matrices[bones[v * per + k]] * verts[v] * weight
					for holder: Dictionary in near:
						var local: Vector3 = (holder.inverse as Transform3D) * world
						var half: Vector3 = holder.half
						var dx := absf(local.x) - half.x
						var dy := absf(local.y) - half.y
						var dz := absf(local.z) - half.z
						if dx < 0.0 and dy < 0.0 and dz < 0.0:
							var entry: Dictionary = result[holder.name]
							entry.n = int(entry.n) + 1
							entry.depth = maxf(float(entry.depth), -maxf(dx, maxf(dy, dz)))
							entry[GROUPS[g]] = int(entry.get(GROUPS[g], 0)) + 1
	return result


## «Arm3 head:12/0.014; Ceramic3 -» for a log line.
static func describe(found: Dictionary) -> String:
	var parts: Array[String] = []
	for name: String in found:
		var entry: Dictionary = found[name]
		if int(entry.n) == 0:
			continue
		var by: Array[String] = []
		for g: String in GROUPS:
			if entry.has(g):
				by.append("%s:%d" % [g, entry[g]])
		parts.append("%s %s/%.3f" % [name.trim_prefix("Anchor"), ",".join(by), entry.depth])
	return "; ".join(parts) if not parts.is_empty() else "-"


static func inside(found: Dictionary) -> int:
	var total := 0
	for name: String in found:
		total += int(found[name].n)
	return total
