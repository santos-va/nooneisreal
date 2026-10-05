extends RefCounted
## Independent full skinned-body/cloth triangle oracle, derived from T4 acceptance.
var pin_margin: float = INF
var invalid_shapes: int = 0
var cache: Dictionary={}
func sample(f, label: String) -> int:
	invalid_shapes = 0
	var mesh: MeshInstance3D=f.skeletal.hero_mesh
	var sk: Skeleton3D=f.skeletal.hero_skeleton
	if not cache.has(f.get_instance_id()):
		var surfaces: Array=[]
		for surface: int in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var ids: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
			var stride: int=ids.size()/vertices.size()
			var influences: Array=[]
			for vertex: int in vertices.size():
				var infl: Array=[]
				for j: int in stride:
					var offset: int=vertex*stride+j
					if weights[offset]<=0.000001:continue
					var bind: int=ids[offset]
					var bone: int=sk.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind)!=&"" else mesh.skin.get_bind_bone(bind)
					infl.append([bone,mesh.skin.get_bind_pose(bind)*vertices[vertex],weights[offset]])
				influences.append(infl)
			surfaces.append([influences,arrays[Mesh.ARRAY_INDEX]])
		cache[f.get_instance_id()]=surfaces
	var targets: Array=[]
	var pins: Array[Vector3] = []
	var nearest: Array[float] = []
	var signed_margin: Array[float] = []
	for tail: Dictionary in f.skeletal.gear._tails:
		pins.append(tail.anchor.global_position)
		nearest.append(INF)
		signed_margin.append(INF)
	var number: int=0
	for tail: Dictionary in f.skeletal.gear._tails:
		if tail.skin.is_empty():
			invalid_shapes += 1
		for segment: Node3D in tail.segments:
			var part: MeshInstance3D=segment.get_child(0)
			if not part.global_transform.is_finite() or part.global_basis.determinant() <= 0.99:
				invalid_shapes += 1
			var faces: PackedVector3Array=part.mesh.get_faces()
			for i: int in faces.size():faces[i]=part.global_transform*faces[i]
			for tri: int in faces.size()/3:
				if (faces[tri*3+1]-faces[tri*3]).cross(faces[tri*3+2]-faces[tri*3]).length_squared() < 1e-14:
					invalid_shapes += 1
			var box:=AABB(faces[0],Vector3.ZERO)
			for p: Vector3 in faces:box=box.expand(p)
			targets.append([faces,box,number,part.global_transform,tail.anchor.global_transform])
			number+=1
	if targets.size() != 6:
		invalid_shapes += 1
	var hits: Dictionary={}
	pin_margin = INF
	var hit_bones: Dictionary={}
	for surface: Array in cache[f.get_instance_id()]:
		var world:=PackedVector3Array()
		for influences: Array in surface[0]:
			var p:=Vector3.ZERO
			for influence: Array in influences:p+=(sk.get_bone_global_pose(influence[0])*influence[1])*influence[2]
			world.append(sk.global_transform*p)
		var indices: PackedInt32Array=surface[1]
		for triangle: int in indices.size()/3:
			var a: Vector3=world[indices[triangle*3]]
			var b: Vector3=world[indices[triangle*3+1]]
			var c: Vector3=world[indices[triangle*3+2]]
			var bounds:=AABB(a,Vector3.ZERO).expand(b).expand(c)
			for pin: int in pins.size():
				if not bounds.grow(0.02).has_point(pins[pin]):
					continue
				var closest: Vector3 = closest_triangle(pins[pin],a,b,c)
				var gap: float = closest.distance_to(pins[pin])
				if gap < nearest[pin]:
					nearest[pin] = gap
					# Clockwise front faces are Godot's mesh convention.
					var outward: Vector3 = (c-a).cross(b-a).normalized()
					signed_margin[pin] = gap * signf((pins[pin]-closest).dot(outward))
			for target: Array in targets:
				if not bounds.grow(.000001).intersects(target[1].grow(.000001)):continue
				var faces: PackedVector3Array=target[0]
				for t: int in faces.size()/3:
					var x: Vector3=faces[t*3]
					var y: Vector3=faces[t*3+1]
					var z: Vector3=faces[t*3+2]
					for edge: Array in [[x,y],[y,z],[z,x]]:
						var p: Variant=Geometry3D.segment_intersects_triangle(edge[0],edge[1],a,b,c)
						if p!=null:
							hits[str(target[2])+"/"+str(p)]=[target[2],p.x,p.y,p.z]
							for vi: int in [indices[triangle*3],indices[triangle*3+1],indices[triangle*3+2]]:
								for inf: Array in surface[0][vi]:hit_bones[sk.get_bone_name(inf[0])]=true
					for edge: Array in [[a,b],[b,c],[c,a]]:
						var p: Variant=Geometry3D.segment_intersects_triangle(edge[0],edge[1],x,y,z)
						if p!=null:
							hits[str(target[2])+"/"+str(p)]=[target[2],p.x,p.y,p.z]
							for vi: int in [indices[triangle*3],indices[triangle*3+1],indices[triangle*3+2]]:
								for inf: Array in surface[0][vi]:hit_bones[sk.get_bone_name(inf[0])]=true
	if not hits.is_empty():
		print("T4_CLOTH_BODY_BONES ",hit_bones.keys())
		for target: Array in targets:
			for contact: Array in hits.values():
				if contact[0]!=target[2]:continue
				var point:=Vector3(contact[1],contact[2],contact[3])
				print("T4_CLOTH_CONTACT_LOCAL part=",target[2]," mesh=",target[3].affine_inverse()*point," anchor=",target[4].affine_inverse()*point)
	for value: float in signed_margin:
		pin_margin = minf(pin_margin,value)
	print("HERO_CLOTH_SKIN label=",label," state=",f.state," intersections=",hits.size()," pin_margin=",pin_margin," invalid_shapes=",invalid_shapes)
	return hits.size()

static func closest_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab: Vector3 = b-a
	var ac: Vector3 = c-a
	var ap: Vector3 = p-a
	var d1: float = ab.dot(ap)
	var d2: float = ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp: Vector3 = p-b
	var d3: float = ab.dot(bp)
	var d4: float = ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc: float = d1*d4-d3*d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a+ab*d1/(d1-d3)
	var cp: Vector3 = p-c
	var d5: float = ab.dot(cp)
	var d6: float = ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb: float = d5*d2-d1*d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a+ac*d2/(d2-d6)
	var va: float = d3*d6-d5*d4
	if va <= 0.0 and d4-d3 >= 0.0 and d5-d6 >= 0.0:
		return b+(c-b)*(d4-d3)/((d4-d3)+(d5-d6))
	var denom: float = va+vb+vc
	if absf(denom) < 1e-20:
		return a
	return a+ab*vb/denom+ac*vc/denom
