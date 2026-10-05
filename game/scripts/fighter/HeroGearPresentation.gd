class_name HeroGearPresentation
extends Node3D
## Additional objects only: final bone attachments and physics-rate free-edge motion.
const Surface = preload("res://scripts/core/GearSurface.gd")
const Garment = preload("res://scripts/fighter/HeroGarmentMask.gd")
# PLACEHOLDER art bounds, frozen before candidate in Hero-Equipment-And-Cloth Fix.
const RESPONSE: float = 0.12
const MAX_BEND: float = deg_to_rad(12.0)
const MAX_SIDE: float = deg_to_rad(8.0)
const MAX_ACCEL: float = 18.0
# 4mm cloth thickness: calibrated inner clearance of 1mm (Choko), 1.2mm (Skea).
const PIN_STANDOFF_CHOKO: float = 0.003
const PIN_STANDOFF_SKEA: float = 0.0032
const MAX_TOTAL_FOLD: float = deg_to_rad(15.0)
var fighter: Fighter
var rig: SkeletalRig
var garment = Garment.new()
var materials: Array[ShaderMaterial] = []
var cloth_material: ShaderMaterial
var cover_material: ShaderMaterial
var spring: Vector2 = Vector2.ZERO
var spring_velocity: Vector2 = Vector2.ZERO
var serial: int = 0
var unsupported_tabs: int = 0
var _revision: int = -1
var _tails: Array[Dictionary] = []
var _watch_local := Transform3D.IDENTITY
var _watch: Node3D
var _body: Node3D
var _hips: Node3D
var _indices: Dictionary = {}

func setup(f: Fighter, owner_rig: SkeletalRig) -> void:
	fighter = f
	rig = owner_rig
	top_level = true
	for name: String in ["Hips","Spine02","Spine","neck","LeftArm","RightArm","LeftForeArm","LeftHand"]:
		_indices[name] = rig.hero_skeleton.find_bone(name)
	garment.setup(f,rig)
	var cloth_color := Color("b2633d") if f.data.id == "choko" else Color("3c244c")
	cloth_material = _material("cloth",cloth_color,Color("cec2a7"))
	var leather := _material("leather",Color("352b28") if f.data.id == "choko" else Color("251c30"),Color("68546c"))
	var trim := _material("metal",Color("b19153") if f.data.id == "choko" else Color("8d93a2"),Color("dbcfac"))
	_body = Node3D.new()
	_body.name = "TorsoGear"
	add_child(_body)
	_hips = Node3D.new()
	_hips.name = "HipGarments"
	add_child(_hips)
	# Two short free tabs are pinned to actual skinned garment vertices.
	for side: float in [-1.0,1.0]:
		_tail(_body,Vector3(side*0.045,0.08,0.14),0.015,0.06 if f.data.id == "choko" else 0.025,side)
	if f.data.id == "choko":
		_build_watch(leather,trim)
	else:
		_build_book(leather,trim)
		_build_kunai(leather,trim)
	update_pose()

func _material(kind: String, color: Color, accent: Color) -> ShaderMaterial:
	var material: ShaderMaterial = Surface.make(kind,color,accent)
	materials.append(material)
	fighter.animator.materials.append(material)
	return material

func _mesh(parent: Node3D, shape: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = material
	item.position = at
	parent.add_child(item)
	return item

func _box(parent: Node3D, size: Vector3, material: Material, at: Vector3) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent,shape,material,at)

func _ring(parent: Node3D, radius: float, thickness: float, material: Material, at: Vector3) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius-thickness
	shape.outer_radius = radius+thickness
	shape.rings = 20
	shape.ring_segments = 5
	return _mesh(parent,shape,material,at)

func _tail(parent: Node3D, at: Vector3, width: float, length: float, side: float) -> void:
	var skin_pin: Array = _skin_pin(at)
	if skin_pin.is_empty():
		unsupported_tabs += 1
		push_warning("Hero garment tab has no supported chest surface: " + fighter.data.id)
		return
	var anchor := Node3D.new()
	anchor.name = "PinnedClothEdge"
	anchor.position = at
	parent.add_child(anchor)
	var segments: Array[Node3D] = []
	var link: Node3D = anchor
	for index: int in 3:
		var hinge := Node3D.new()
		if index > 0:
			hinge.position.y = -length/3.0
		link.add_child(hinge)
		_box(hinge,Vector3(width,length/3.0,0.004),cloth_material,Vector3(0,-length/6.0,0))
		segments.append(hinge)
		link = hinge
	_tails.append({"anchor":anchor,"segments":segments,"length":length,"side":side,"pin":at,"skin":skin_pin})

func _build_watch(leather: Material, metal: Material) -> void:
	_watch = Node3D.new()
	_watch.name = "ChokoAnalogWatch"
	add_child(_watch)
	var face := _material("metal",Color("ded6b9"),Color("efdfb9"))
	var ink := _material("leather",Color("252b28"),Color("5b6659"))
	_box(_watch,Vector3(0.053,0.11,0.018),leather,Vector3.ZERO)
	var bezel := CylinderMesh.new()
	bezel.top_radius = 0.046
	bezel.bottom_radius = 0.046
	bezel.height = 0.016
	bezel.radial_segments = 20
	_mesh(_watch,bezel,metal,Vector3(0,0,0.017)).rotation.x = PI/2.0
	var dial := CylinderMesh.new()
	dial.top_radius = 0.038
	dial.bottom_radius = 0.038
	dial.height = 0.003
	dial.radial_segments = 20
	_mesh(_watch,dial,face,Vector3(0,0,0.027)).rotation.x = PI/2.0
	for tick: int in 12:
		var angle: float = TAU*float(tick)/12.0
		var line := _box(_watch,Vector3(0.003,0.007,0.002),ink,Vector3(sin(angle)*0.030,cos(angle)*0.030,0.03))
		line.rotation.z = -angle
	_box(_watch,Vector3(0.003,0.027,0.003),ink,Vector3(0,0.010,0.033)).rotation.z = -0.65
	_box(_watch,Vector3(0.003,0.019,0.003),ink,Vector3(0.008,0.005,0.034)).rotation.z = 0.8
	var hand: Transform3D = _bone("LeftHand",true)
	var arm: Vector3 = _bone("LeftForeArm",true).origin
	var y: Vector3 = (arm-hand.origin).normalized()
	var z: Vector3 = Vector3.RIGHT.slide(y).normalized()
	var x: Vector3 = y.cross(z).normalized()
	z = x.cross(y).normalized()
	_watch_local = hand.affine_inverse() * Transform3D(Basis(x,y,z),hand.origin.lerp(arm,0.17)+z*0.036)

func _build_book(leather: Material, metal: Material) -> void:
	var paper := _material("cloth",Color("918b7f"),Color("b7ad98"))
	# A slim bound cover lies on the existing baked backpack, not a second pack.
	_box(_body,Vector3(0.265,0.305,0.028),paper,Vector3(0,-0.09,-0.342))
	var page_division := _material("cloth",Color("625b56"),Color("85766c"))
	for depth: float in [-0.337,-0.346]:
		_box(_body,Vector3(0.266,0.306,0.001),page_division,Vector3(0,-0.09,depth))
	_box(_body,Vector3(0.285,0.325,0.014),leather,Vector3(0,-0.09,-0.365))
	# The rear face has an independent square UV, not BoxMesh's six-face atlas.
	# It renders the plain fallback now; admitted cover art can use the whole map.
	cover_material = _material("leather",Color("251c30"),Color("68546c"))
	cover_material.set_shader_parameter("pattern_mode",1)
	var cover := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.1425,0.1625,0),Vector3(-0.1425,-0.1625,0),Vector3(0.1425,-0.1625,0),Vector3(0.1425,0.1625,0)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(1,0)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,2,1,0,3,2])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD,Vector3.FORWARD])
	cover.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	_mesh(_body,cover,cover_material,Vector3(0,-0.09,-0.3722)).name = "GrimoireCoverFace"
	_box(_body,Vector3(0.025,0.325,0.048),leather,Vector3(-0.14,-0.09,-0.348))
	for side: float in [-1.0,1.0]:
		_box(_body,Vector3(0.027,0.355,0.018),leather,Vector3(side*0.108,-0.09,-0.379))
		for height: float in [-0.13,0.13]:
			_box(_body,Vector3(0.049,0.025,0.014),metal,Vector3(side*0.108,height-0.09,-0.392))
	# Signed Skea reference: ONE horizontal infinity-eight, not stacked rings.
	var sigil := ShaderMaterial.new()
	sigil.shader = preload("res://shaders/grimoire_sigil.gdshader")
	sigil.set_shader_parameter("albedo",Color("9e4cf2"))
	materials.append(sigil)
	fighter.animator.materials.append(sigil)
	_mesh(_body,_infinity_eight(),sigil,Vector3(0,-0.09,-0.38)).name = "GrimoireEightSigil"

static func _infinity_eight() -> ArrayMesh:
	# Continuous Gerono curve: exactly two side loops and one central crossing.
	# Width/height incl stroke are 48.6% / 25.1% of the existing rear cover.
	const STEPS: int = 96
	const HALF_WIDTH: float = 0.0675
	const HALF_HEIGHT: float = 0.039
	const HALF_STROKE: float = 0.00175
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i: int in STEPS+1:
		var t: float = TAU*float(i)/STEPS
		var center := Vector2(sin(t)*HALF_WIDTH,sin(2.0*t)*HALF_HEIGHT)
		var tangent := Vector2(cos(t)*HALF_WIDTH,2.0*cos(2.0*t)*HALF_HEIGHT).normalized()
		var outward := Vector2(-tangent.y,tangent.x)
		for side: float in [-1.0,1.0]:
			var point: Vector2 = center+outward*HALF_STROKE*side
			vertices.append(Vector3(point.x,point.y,0))
			normals.append(Vector3.FORWARD)
			uv.append(Vector2(float(i)/STEPS,(side+1.0)*0.5))
		if i < STEPS:
			var at: int = i*2
			indices.append_array(PackedInt32Array([at,at+2,at+1,at+1,at+2,at+3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _build_kunai(leather: Material, metal: Material) -> void:
	for side: float in [-1.0,1.0]:
		_box(_hips,Vector3(0.045,0.13,0.025),leather,Vector3(side*0.15,-0.13,0.015))
		for k: int in 2:
			var dagger := PrismMesh.new()
			dagger.size = Vector3(0.025,0.09,0.015)
			_mesh(_hips,dagger,metal,Vector3(side*(0.14+k*0.025),-0.14,0.05))
			_box(_hips,Vector3(0.014,0.065,0.017),leather,Vector3(side*(0.14+k*0.025),-0.065,0.052))
			var ring := _ring(_hips,0.014,0.003,metal,Vector3(side*(0.14+k*0.025),-0.022,0.052))
			ring.rotation.x = PI/2.0

func _bone(name: String, rest: bool = false) -> Transform3D:
	var bone: int = _indices[name]
	var pose: Transform3D = rig.hero_skeleton.get_bone_global_rest(bone) if rest else rig.hero_skeleton.get_bone_global_pose(bone)
	var world: Transform3D = rig.hero_skeleton.global_transform * pose
	world.basis = world.basis.orthonormalized()
	return world

func torso_frame() -> Transform3D:
	var hips: Vector3 = _bone("Hips").origin
	var neck: Vector3 = _bone("neck").origin
	var up: Vector3 = (neck-hips).normalized()
	var right: Vector3 = (_bone("LeftArm").origin-_bone("RightArm").origin).normalized()
	var forward: Vector3 = right.cross(up).normalized()
	right = up.cross(forward).normalized()
	return Transform3D(Basis(right,up,forward),hips.lerp(neck,0.60))

func advance(delta: float) -> void:
	if fighter == null or get_tree().paused or fighter.frozen_frames > 0 or fighter.hitstop_frames > 0:
		return
	serial += 1
	if _revision != fighter.motion_revision or rig.ragdoll != null:
		_revision = fighter.motion_revision
		spring = Vector2.ZERO
		spring_velocity = Vector2.ZERO
		return
	var frame: Transform3D = torso_frame()
	var acceleration: Vector3 = frame.basis.inverse() * rig.motion_signals.acceleration.limit_length(MAX_ACCEL)
	var target := Vector2(clampf(-acceleration.z/MAX_ACCEL*MAX_BEND,-MAX_BEND,MAX_BEND),clampf(acceleration.x/MAX_ACCEL*MAX_SIDE,-MAX_SIDE,MAX_SIDE))
	var omega: float = 2.0/RESPONSE
	var dt: float = clampf(delta,0.0,0.05)
	var difference: Vector2 = spring-target
	var step: Vector2 = spring_velocity+omega*difference
	var decay: float = exp(-omega*dt)
	spring = (difference+step*dt)*decay+target
	spring_velocity = (spring_velocity-omega*step*dt)*decay
	spring.x = clampf(spring.x,-MAX_BEND,MAX_BEND)
	spring.y = clampf(spring.y,-MAX_SIDE,MAX_SIDE)

func update_pose() -> void:
	if fighter == null or rig.hero_skeleton == null or get_tree().paused or fighter.frozen_frames > 0 or fighter.hitstop_frames > 0:
		return
	visible = fighter.animator.visible or rig.ragdoll != null
	var frame: Transform3D = torso_frame()
	_body.global_transform = frame
	_hips.global_transform = Transform3D(frame.basis,_bone("Hips").origin)
	if _watch != null:
		_watch.global_transform = _bone("LeftHand") * _watch_local
	for tail: Dictionary in _tails:
		var pin: Transform3D = pin_transform(tail)
		var valid: bool = pin.origin.is_finite() and pin.basis.is_finite() and pin.basis.determinant() > 0.99
		tail.anchor.visible = valid
		if not valid:
			if not tail.get("invalid_reported",false):
				tail.invalid_reported = true
				push_warning("Hero garment tab has an invalid attachment frame: " + fighter.data.id)
			continue
		tail.anchor.global_transform = pin
		var nodes: Array = tail.segments
		var remaining_fold: float = MAX_TOTAL_FOLD
		for i: int in nodes.size():
			var weight: float = float(i+1)/6.0
			# The complete strip obeys the original 15 degree absolute cap.
			var rest_fold: float = 3.0
			var binding_fold: float = deg_to_rad(rest_fold) if i == 0 else 0.0
			var bend: float = minf(remaining_fold,maxf(0.0,binding_fold+spring.x*weight))
			remaining_fold -= bend
			nodes[i].rotation = Vector3(-bend,0,spring.y*weight*tail.side)

func _skin_pin(target_local: Vector3) -> Array:
	if garment.original_mesh == null or garment.rest_points.is_empty():
		return []
	if fighter.data.id == "choko":
		return _facet_pin(target_local)
	var target: Vector3 = torso_frame() * target_local
	var arrays: Array = garment.original_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride: int = joints.size()/vertices.size()
	var skin: Skin = rig.hero_mesh.skin
	var nearest: int = -1
	var best: float = INF
	var hips: Vector3 = _bone("Hips",true).origin
	var neck: Vector3 = _bone("neck",true).origin
	var chest_up: Vector3 = (neck-hips).normalized()
	var chest_right: Vector3 = (_bone("LeftArm",true).origin-_bone("RightArm",true).origin).normalized()
	var chest_front: Vector3 = chest_right.cross(chest_up).normalized()
	var torso_length: float = hips.distance_to(neck)
	if torso_length < 0.01:
		return []
	for vertex: int in garment.rest_points.size():
		var point: Vector3 = rig.hero_skeleton.global_transform * garment.rest_points[vertex]
		var relative: Vector3 = point-hips
		var height: float = relative.dot(chest_up)/torso_length
		# Auto-skinning blends Hips and even small leg weights into chest vertices.
		# Select the actual front chest surface in the rest anatomical frame, then
		# retain EVERY original weight for the live attachment. No shader-mask coupling.
		if height < 0.5 or height > 0.88 or absf(relative.dot(chest_right)) > 0.10 or relative.dot(chest_front) < 0.02:
			continue
		var score: float = point.distance_squared_to(target)
		if score < best:
			nearest = vertex
			best = score
	var result: Array = []
	if nearest < 0:
		return result
	for j: int in stride:
		var at: int = nearest*stride+j
		if weights[at] <= 0.000001:
			continue
		var bind: int = joints[at]
		var bone: int = rig.hero_skeleton.find_bone(skin.get_bind_name(bind)) if skin.get_bind_name(bind) != &"" else skin.get_bind_bone(bind)
		result.append([bone,skin.get_bind_pose(bind)*vertices[nearest],skin.get_bind_pose(bind).basis*normals[nearest],weights[at]])
	return result

func _facet_pin(target_local: Vector3) -> Array:
	# An outer-surface ray avoids buried shell vertices. The final frame follows
	# the actual deformed triangle, not an averaged shading normal at a crease.
	var frame: Transform3D = torso_frame()
	var target: Vector3 = frame * target_local
	var from: Vector3 = target+frame.basis.z
	var to: Vector3 = target-frame.basis.z
	var arrays: Array = garment.original_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride: int = joints.size()/vertices.size()
	var skin: Skin = rig.hero_mesh.skin
	var world := PackedVector3Array()
	for rest: Vector3 in garment.rest_points:
		world.append(rig.hero_skeleton.global_transform*rest)
	var chosen: Array[int] = []
	var bary := Vector3.ZERO
	var best: float = INF
	for triangle: int in indices.size()/3:
		var ia: int = indices[triangle*3]
		var ib: int = indices[triangle*3+1]
		var ic: int = indices[triangle*3+2]
		var hit: Variant = Geometry3D.segment_intersects_triangle(from,to,world[ia],world[ib],world[ic])
		if hit == null or from.distance_squared_to(hit) >= best:
			continue
		var ab: Vector3 = world[ib]-world[ia]
		var ac: Vector3 = world[ic]-world[ia]
		var ap: Vector3 = hit-world[ia]
		var den: float = ab.dot(ab)*ac.dot(ac)-ab.dot(ac)*ab.dot(ac)
		if absf(den) < 1e-16:
			continue
		var v: float = (ac.dot(ac)*ap.dot(ab)-ab.dot(ac)*ap.dot(ac))/den
		var w: float = (ab.dot(ab)*ap.dot(ac)-ab.dot(ac)*ap.dot(ab))/den
		bary = Vector3(1.0-v-w,v,w)
		chosen.assign([ia,ib,ic])
		best = from.distance_squared_to(hit)
	var result: Array = []
	for corner: int in chosen.size():
		var vertex: int = chosen[corner]
		for j: int in stride:
			var at: int = vertex*stride+j
			if weights[at] <= 0.000001:
				continue
			var bind: int = joints[at]
			var bone: int = rig.hero_skeleton.find_bone(skin.get_bind_name(bind)) if skin.get_bind_name(bind) != &"" else skin.get_bind_bone(bind)
			result.append([bone,skin.get_bind_pose(bind)*vertices[vertex],skin.get_bind_pose(bind).basis*normals[vertex],weights[at]*bary[corner],corner,weights[at]])
	return result

func pin_transform(tail: Dictionary) -> Transform3D:
	var invalid := Transform3D(Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO),Vector3.ZERO)
	if tail.skin.is_empty():
		return invalid
	var point := Vector3.ZERO
	var normal := Vector3.ZERO
	var corners := PackedVector3Array([Vector3.ZERO,Vector3.ZERO,Vector3.ZERO])
	for influence: Array in tail.skin:
		var pose: Transform3D = rig.hero_skeleton.get_bone_global_pose(influence[0])
		point += (pose*influence[1])*influence[3]
		normal += (pose.basis*influence[2])*influence[3]
		if influence.size() >= 6:
			corners[influence[4]] += (pose*influence[1])*influence[5]
	if tail.skin[0].size() >= 6:
		var facet: Vector3 = (corners[1]-corners[0]).cross(corners[2]-corners[0])
		normal = facet if facet.dot(normal) >= 0.0 else -facet
	point = rig.hero_skeleton.global_transform * point
	normal = rig.hero_skeleton.global_basis*normal
	if not point.is_finite() or not normal.is_finite() or normal.length_squared() < 1e-12:
		return invalid
	normal = normal.normalized()
	var right: Vector3 = torso_frame().basis.y.cross(normal)
	if right.length_squared() < 1e-8:
		right = torso_frame().basis.x.slide(normal)
	if right.length_squared() < 1e-8:
		return invalid
	right = right.normalized()
	var up: Vector3 = normal.cross(right).normalized()
	return Transform3D(Basis(right,up,normal),point+normal*(PIN_STANDOFF_CHOKO if fighter.data.id == "choko" else PIN_STANDOFF_SKEA))
