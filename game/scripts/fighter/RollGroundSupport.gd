class_name RollGroundSupport
extends RefCounted
## Exact skin support with conservative bounds for groups of weighted influences.
## Bounds only reject groups that cannot beat the current minimum; surviving
## vertices retain every original weight. Repeated renders reuse one physics solve.
const CLEARANCE: float = 0.003
const GROUP_METRES: float = 0.12 # Spatial partition only; does not change the answer.
static var _cache: Dictionary = {}
var _groups: Array = []
var _serial: int = -1
var _best_group: int = 0
var lift: float = 0.0
var sample_count: int = 0
var vertex_count: int = 0
var influence_count: int = 0
var solve_usec: int = 0
var setup_usec: int = 0

func setup(hero: Skeleton3D, mesh: MeshInstance3D) -> void:
	var started: int = Time.get_ticks_usec()
	var names := PackedStringArray()
	for bone: int in hero.get_bone_count():
		names.append(hero.get_bone_name(bone))
	var key: String = str(mesh.mesh.get_instance_id()) + "/" + str(mesh.skin.get_instance_id()) + "/" + str(names)
	if _cache.has(key):
		_groups = _cache[key].groups
		vertex_count = _cache[key].vertices
		influence_count = _cache[key].influences
		setup_usec = Time.get_ticks_usec() - started
		return
	var groups: Dictionary = {}
	for surface: int in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride: int = bones.size() / vertices.size()
		for vertex: int in vertices.size():
			var influences: Array = []
			for index: int in stride:
				var offset: int = vertex * stride + index
				if weights[offset] <= 0.0:
					continue
				var bind: int = bones[offset]
				var bone: int = hero.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind) != &"" else mesh.skin.get_bind_bone(bind)
				if bone >= 0:
					influences.append([bone, (mesh.skin.get_bind_pose(bind) * vertices[vertex]) * weights[offset], weights[offset]])
			influences.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
			var ids := PackedInt32Array()
			for influence: Array in influences:
				ids.append(influence[0])
			var cell: Vector3 = (mesh.global_basis * vertices[vertex] / GROUP_METRES).floor()
			var group_key: String = str(ids) + "/" + str(cell)
			if not groups.has(group_key):
				var bounds: Array = []
				for influence: Array in influences:
					bounds.append([influence[0], Vector3.ZERO, Vector3.ZERO, influence[2], influence[2], Vector3(influence[1]) / float(influence[2])])
				groups[group_key] = {"vertices": [], "bounds": bounds, "weight_min":INF, "weight_max":-INF}
			var group: Dictionary = groups[group_key]
			group.vertices.append(influences)
			var total_weight: float = 0.0
			for index: int in influences.size():
				var bound: Array = group.bounds[index]
				var relative: Vector3 = Vector3(influences[index][1]) - Vector3(bound[5]) * float(influences[index][2])
				bound[1] = Vector3(bound[1]).min(relative)
				bound[2] = Vector3(bound[2]).max(relative)
				total_weight += float(influences[index][2])
				bound[3] = minf(bound[3], influences[index][2])
				bound[4] = maxf(bound[4], influences[index][2])
			group.weight_min = minf(group.weight_min, total_weight)
			group.weight_max = maxf(group.weight_max, total_weight)
			vertex_count += 1
			influence_count += influences.size()
	for group: Dictionary in groups.values():
		for bound: Array in group.bounds:
			var center: Vector3 = (Vector3(bound[1]) + Vector3(bound[2])) * 0.5
			bound[2] = (Vector3(bound[2]) - Vector3(bound[1])) * 0.5
			bound[1] = center
			var center_weight: float = (float(bound[3]) + float(bound[4])) * 0.5
			bound[4] = (float(bound[4]) - float(bound[3])) * 0.5
			bound[3] = center_weight
		var ends := PackedInt32Array()
		var indices := PackedInt32Array()
		var points := PackedVector3Array()
		var weights := PackedFloat32Array()
		for influences: Array in group.vertices:
			for influence: Array in influences:
				indices.append(influence[0])
				points.append(influence[1])
				weights.append(influence[2])
			ends.append(indices.size())
		group.erase("vertices")
		group["ends"] = ends
		group["indices"] = indices
		group["points"] = points
		group["weights"] = weights
		_groups.append(group)
	_cache[key] = {"groups": _groups, "vertices":vertex_count, "influences":influence_count}
	setup_usec = Time.get_ticks_usec() - started

func apply(hero: Skeleton3D, mesh: MeshInstance3D, snapshot: Dictionary, serial: int) -> void:
	if _groups.is_empty():
		setup(hero, mesh)
	if serial != _serial:
		var started: int = Time.get_ticks_usec()
		var floor_point: Vector3 = snapshot.floor_point
		var normal: Vector3 = Vector3(snapshot.floor_normal).normalized()
		var normals := PackedVector3Array()
		var absolutes := PackedVector3Array()
		var offsets := PackedFloat32Array()
		for bone: int in hero.get_bone_count():
			var pose: Transform3D = hero.global_transform * hero.get_bone_global_pose(bone)
			var local_normal: Vector3 = pose.basis.transposed() * normal
			normals.append(local_normal)
			absolutes.append(local_normal.abs())
			offsets.append((pose.origin - floor_point).dot(normal))
		sample_count = 0
		var minimum: float = _exact(_groups[_best_group], normals, offsets)
		for index: int in _groups.size():
			if index == _best_group:
				continue
			var group: Dictionary = _groups[index]
			var anchor: Array = group.bounds[0]
			var reference: float = Vector3(anchor[5]).dot(normals[anchor[0]]) + offsets[anchor[0]]
			var bound: float = reference * (float(group.weight_min) if reference >= 0.0 else float(group.weight_max))
			for term: Array in group.bounds:
				var bone: int = term[0]
				var relative_offset: float = Vector3(term[5]).dot(normals[bone]) + offsets[bone] - reference
				bound += Vector3(term[1]).dot(normals[bone]) - Vector3(term[2]).dot(absolutes[bone]) + float(term[3]) * relative_offset - float(term[4]) * absf(relative_offset)
			if bound - 0.00001 >= minimum:
				continue
			var distance: float = _exact(group, normals, offsets)
			if distance < minimum:
				minimum = distance
				_best_group = index
		# Grounded body contact follows the real plane in either direction.
		lift = (CLEARANCE - minimum) / maxf(normal.y, 0.95) if is_finite(minimum) else 0.0
		_serial = serial
		solve_usec = Time.get_ticks_usec() - started
	var hips: int = hero.find_bone("Hips")
	hero.set_bone_pose_position(hips, hero.get_bone_pose_position(hips) + hero.global_basis.inverse() * (Vector3.UP * lift))

func _exact(group: Dictionary, normals: PackedVector3Array, offsets: PackedFloat32Array) -> float:
	var minimum: float = INF
	var ends: PackedInt32Array = group.ends
	var indices: PackedInt32Array = group.indices
	var points: PackedVector3Array = group.points
	var weights: PackedFloat32Array = group.weights
	var index: int = 0
	for end: int in ends:
		var distance: float = 0.0
		while index < end:
			var bone: int = indices[index]
			distance += points[index].dot(normals[bone]) + offsets[bone] * weights[index]
			index += 1
		minimum = minf(minimum, distance)
	sample_count += ends.size()
	return minimum
