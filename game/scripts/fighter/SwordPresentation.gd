class_name SwordPresentation
extends Node3D
## One original procedural weapon, attached to the rendered hero rather than hidden capsule pivots.
## Reference: Characters/Choko and weapon_choko_main_sword.png. Dimensions are provisional art tuning.
const EMERALD := Color("315d52")
const GOLD := Color("b8aa7b")
const AGED_BRASS := Color("9a8960")
var fighter: Fighter
var rig: SkeletalRig
var blade_material: ShaderMaterial
var blade: MeshInstance3D
var grip_side: String = "right"
var handoff_blend: float = 0.0
var stow_weight: float = 0.0
var _last_tick: int = -1
# PLACEHOLDER art dimensions/counts. Changes affect presentation, never weapon reach.
const DUST_COUNT: int = 40
const DISSOLVE_SHADER = preload("res://shaders/sword_dissolve.gdshader")
const INLAY_PATH: String = "res://assets/characters/equipment/sword_inlay_muted_20261005.png"
var dust: Array[MeshInstance3D] = []
var weapon_materials: Array[ShaderMaterial] = []
var outlines: Array[Material] = []
var ornaments: Array[MeshInstance3D] = []
var _blade_forms: Array[ArrayMesh] = []
var blade_profile_edges: Array[PackedVector3Array] = []
var dissolve_weight: float = 0.0
var presented_form: int = 0
const ULT_MORPH_FRAMES: int = 12 # PLACEHOLDER visual only, independent of move damage timing.
var _ultimate_requested: bool = false
var _ultimate_gold: bool = false
var _ultimate_morph_frame: int = ULT_MORPH_FRAMES
var _morph_tick: int = -1
var _left_calibration := Basis.IDENTITY
var _left_offset := Vector3(0, 0.055, 0)

func setup(owner_fighter: Fighter, owner_rig: SkeletalRig) -> void:
	fighter = owner_fighter
	rig = owner_rig
	top_level = true
	# Retarget uses aligned rests, not raw Meshy rests. Reflect right-hand grip across
	# the body's sagittal plane while reversing only the symmetrical weapon width axis.
	var skeleton := rig.hero_skeleton if rig.hero_skeleton != null else rig.skeleton
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var normal := (skeleton.global_basis.orthonormalized().inverse() * facing.cross(Vector3.UP)).normalized()
	var reflection := Basis(Vector3.RIGHT - 2.0 * normal * normal.x, Vector3.UP - 2.0 * normal * normal.y, Vector3.BACK - 2.0 * normal * normal.z)
	var right_rest := rig.aligned_hand_rest("right")
	var left_rest := rig.aligned_hand_rest("left")
	_left_calibration = (left_rest.inverse() * reflection * right_rest * grip_calibration("right") * Basis.from_scale(Vector3(-1, 1, 1))).orthonormalized()
	_left_offset = left_rest.inverse() * reflection * right_rest * Vector3(0, 0.055, 0)
	var brass := _material(AGED_BRASS, 2, 0.0012)
	var dark := _material(Color("263b35"), 3, 0.0015)
	blade_material = _material(EMERALD, 1, 0.0011)
	# Original procedural detail remains usable when an optional art map is absent.
	if ResourceLoader.exists(INLAY_PATH):
		blade_material.set_shader_parameter("inlay_tex", load(INLAY_PATH))
		blade_material.set_shader_parameter("use_inlay_map", true)
	for form: int in 3:
		_blade_forms.append(_blade_mesh(form))
		blade_profile_edges.append(_profile_edges(_blade_forms[-1]))
	blade = _piece(_blade_forms[0], blade_material, Vector3.ZERO)
	var handle := CylinderMesh.new()
	handle.top_radius = 0.023
	handle.bottom_radius = 0.025
	handle.height = 0.25
	handle.radial_segments = 12
	_piece(handle, dark, Vector3(0, -0.025, 0))
	var guard := BoxMesh.new()
	guard.size = Vector3(0.23, 0.016, 0.026)
	_piece(guard, brass, Vector3(0, 0.13, 0))
	for side: float in [-1.0, 1.0]:
		var quillon := PrismMesh.new()
		quillon.size = Vector3(0.038, 0.042, 0.018)
		var mesh := _piece(quillon, brass, Vector3(side * 0.13, 0.155, 0))
		mesh.rotation.z = side * -0.35
	var pommel := SphereMesh.new()
	pommel.radius = 0.027
	pommel.height = 0.060
	pommel.radial_segments = 8
	pommel.rings = 3
	_piece(pommel, brass, Vector3(0, -0.18, 0))
	var gem := SphereMesh.new()
	gem.radius = 0.023
	gem.height = 0.047
	gem.radial_segments = 6
	gem.rings = 2
	_piece(gem, blade_material, Vector3(0, 0.158, 0.017))
	# Open guard scrolls share one original mesh; no opaque box painted as a hole.
	ornaments.append(_piece(_filigree_mesh(), brass, Vector3.ZERO))
	# Simple wrap bands remain readable at play distance without a texture dependency.
	for i in 5:
		var band := TorusMesh.new()
		band.inner_radius = 0.022
		band.outer_radius = 0.0265
		band.rings = 8
		band.ring_segments = 4
		_piece(band, brass, Vector3(0, -0.13 + i * 0.045, 0))
	_setup_dust()
	stow_weight = 1.0 if not fighter.sword_drawn else 0.0
	update_pose()

func _material(color: Color, surface_kind: int = 0, ink_width: float = 0.0015) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = DISSOLVE_SHADER
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("surface_kind", surface_kind)
	material.set_shader_parameter("ornament_color", AGED_BRASS)
	material.set_shader_parameter("rim_strength", 0.10)
	material.set_shader_parameter("shadow_tint", Color("514559"))
	var outline := ShaderMaterial.new()
	outline.shader = RigAnimator.OUTLINE
	outline.set_shader_parameter("width", ink_width)
	material.next_pass = outline
	weapon_materials.append(material)
	outlines.append(outline)
	fighter.animator.materials.append(material)
	return material

func _piece(mesh: Mesh, material: Material, position_local: Vector3) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = material
	piece.position = position_local
	add_child(piece)
	return piece

static func _blade_mesh(form: int = 0) -> ArrayMesh:
	# Designed per-form silhouettes; existing tip lengths are retained in metres.
	var profiles: Array = [
		[Vector3(0.17, 0.035, 0.008), Vector3(0.32, 0.065, 0.010), Vector3(0.72, 0.038, 0.007), Vector3(0.94, 0.022, 0.004)],
		[Vector3(0.17, 0.027, 0.006), Vector3(0.26, 0.038, 0.008), Vector3(0.80, 0.026, 0.005), Vector3(1.07, 0.014, 0.003)],
		[Vector3(0.17, 0.040, 0.008), Vector3(0.29, 0.070, 0.011), Vector3(0.42, 0.046, 0.009), Vector3(0.53, 0.062, 0.008), Vector3(0.75, 0.038, 0.005), Vector3(0.84, 0.022, 0.003)]
	]
	var length: float = [1.08, 1.08 * 1.14, 1.08 * 0.87][posmod(form, 3)]
	var rings: Array[PackedVector3Array] = []
	for spec: Vector3 in profiles[posmod(form, 3)]:
		rings.append(PackedVector3Array([Vector3(-spec.y, spec.x, 0), Vector3(0, spec.x, spec.z), Vector3(spec.y, spec.x, 0), Vector3(0, spec.x, -spec.z)]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r: int in rings.size() - 1:
		for i: int in 4:
			var n: int = (i + 1) % 4
			for vertex: Vector3 in [rings[r][i], rings[r + 1][i], rings[r + 1][n], rings[r][i], rings[r + 1][n], rings[r][n]]:
				_blade_vertex(surface, vertex, length)
	for i: int in 4:
		for vertex: Vector3 in [rings[-1][i], Vector3(0, length, 0), rings[-1][(i + 1) % 4]]:
			_blade_vertex(surface, vertex, length)
	surface.generate_normals()
	return surface.commit()

static func _blade_vertex(surface: SurfaceTool, point: Vector3, length: float) -> void:
	# Real UV consumed by the material's inlay/groove pattern on both blade faces.
	surface.set_uv(Vector2(point.x / 0.14 + 0.5, (point.y - 0.17) / (length - 0.17)))
	surface.add_vertex(point)

static func _filigree_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0, 1.0]:
		var path: Array[Vector3] = [Vector3(side * 0.025, 0.133, 0), Vector3(side * 0.075, 0.143, 0), Vector3(side * 0.123, 0.205, 0), Vector3(side * 0.115, 0.231, 0), Vector3(side * 0.080, 0.211, 0), Vector3(side * 0.045, 0.169, 0), Vector3(side * 0.025, 0.133, 0)]
		for index: int in path.size() - 1:
			var a: Vector3 = path[index]
			var b: Vector3 = path[index + 1]
			var across: Vector3 = (b - a).normalized().cross(Vector3.BACK) * 0.003
			var depth: Vector3 = Vector3.BACK * 0.004
			var first: Array[Vector3] = [a - across - depth, a + across - depth, a + across + depth, a - across + depth]
			var last: Array[Vector3] = [b - across - depth, b + across - depth, b + across + depth, b - across + depth]
			for face: int in 4:
				var next: int = (face + 1) % 4
				for vertex: Vector3 in [first[face], last[face], last[next], first[face], last[next], first[next]]:
					surface.set_uv(Vector2(vertex.x * 8.0, vertex.y * 8.0))
					surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()


func hand_grip(side: String) -> Transform3D:
	var skeleton := rig.hero_skeleton if rig.hero_skeleton != null else rig.skeleton
	var name := ("RightHand" if side == "right" else "LeftHand") if rig.hero_skeleton != null else ("hand_r" if side == "right" else "hand_l")
	var bone := skeleton.find_bone(name)
	if bone < 0:
		return Transform3D(Basis.IDENTITY, fighter.global_position + Vector3.UP)
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	var basis := pose.basis.orthonormalized()
	# Hand leaf +Y extends from wrist into palm; blade exits the calibrated palm side (+Z), opposite the previous reverse grip.
	var grip := pose.origin + basis * grip_offset(side)
	return Transform3D(basis * grip_calibration(side), grip)

## Single actual torso socket, shared by the carried weapon and the drawing hand.
## +weapon Y points toward the tip: tip down, handle accessible above the shoulder.
func back_grip() -> Transform3D:
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var right: Vector3 = facing.cross(Vector3.UP)
	var down: Vector3 = -(Vector3.UP * 0.85 + right * 0.53).normalized()
	var normal: Vector3 = -facing
	var across: Vector3 = down.cross(normal).normalized()
	var origin: Vector3 = fighter.global_position + Vector3.UP * 1.45 - facing * 0.23 + right * 0.07
	var carry := Transform3D(Basis(across, down, across.cross(down)), origin)
	var body: Skeleton3D = rig.hero_skeleton if rig.hero_skeleton != null else rig.skeleton
	var torso: int = body.find_bone("Spine01" if rig.hero_skeleton != null else "spine_02")
	if torso >= 0:
		var rest: Transform3D = body.global_transform * body.get_bone_global_rest(torso)
		var current: Transform3D = body.global_transform * body.get_bone_global_pose(torso)
		var turn: Basis = current.basis.orthonormalized() * rest.basis.orthonormalized().inverse()
		carry = Transform3D(turn * carry.basis, current.origin + turn * (carry.origin - rest.origin))
	return carry

func update_pose() -> void:
	if fighter == null or rig == null:
		return
	if fighter.get_tree().paused or fighter.frozen_frames > 0 or fighter.hitstop_frames > 0:
		return
	grip_side = fighter.attack_sword_hand if fighter.state == Fighter.State.ATTACK else fighter.sword_hand
	var pose := hand_grip(grip_side)
	handoff_blend = 0.0
	if fighter.state == Fighter.State.SWAP and not fighter.sword_swap_drawing:
		handoff_blend = smoothstep(0.40, 0.60, fighter.sword_swap_progress())
		pose = hand_grip(fighter.sword_swap_from).interpolate_with(hand_grip(fighter.sword_swap_to), handoff_blend)
	var tick := Engine.get_physics_frames()
	if tick != _last_tick and not fighter.get_tree().paused and fighter.frozen_frames <= 0 and fighter.hitstop_frames <= 0:
		_last_tick = tick
		var busy := not fighter.sword_drawn or fighter.state == Fighter.State.GRAPPLE or fighter.grapple.recovering()
		stow_weight = move_toward(stow_weight, 1.0 if busy else 0.0, 1.0 / 12.0)
	if fighter.state == Fighter.State.SWAP and fighter.sword_swap_drawing:
		# Draw hand reaches and holds the actual socket before ownership releases.
		stow_weight = 1.0 if fighter.sword_swap_progress() < 0.40 else 0.0
	if fighter.state == Fighter.State.ATTACK and fighter.current_move != null:
		var move := fighter.current_move
		if SwordMotion.supports(move.anim) or move.anim_clip.begins_with("Sword_") or move.id == "crouch_light":
			# A fast armed normal must reach the hand by its existing first active frame.
			stow_weight = minf(stow_weight, clampf(1.0 - float(fighter.move_frame) / float(maxi(1, move.startup)), 0.0, 1.0))
	if stow_weight > 0.0:
		pose = pose.interpolate_with(back_grip(), smoothstep(0.0, 1.0, stow_weight))
	global_transform = pose
	var ultimate := fighter.state == Fighter.State.ATTACK and fighter.current_move != null and fighter.current_move.effect == "sword_storm"
	_update_morph(ultimate)
	blade_material.set_shader_parameter("albedo", GOLD if _ultimate_gold else EMERALD)
	blade_material.set_shader_parameter("gold_variant", 1.0 if _ultimate_gold else 0.0)

func _physics_process(_delta: float) -> void:
	update_pose()

func reset_pose_state() -> void:
	stow_weight = 1.0 if not fighter.sword_drawn else 0.0
	dissolve_weight = 0.0
	_ultimate_requested = false
	_ultimate_gold = false
	_ultimate_morph_frame = ULT_MORPH_FRAMES
	_morph_tick = -1
	handoff_blend = 0.0
	_last_tick = -1
	update_pose()

func grip_calibration(side: String) -> Basis:
	return _left_calibration if side == "left" else Basis(Vector3.RIGHT, PI * 0.5)

func grip_offset(side: String) -> Vector3:
	return _left_offset if side == "left" else Vector3(0, 0.055, 0)


## Cache the real longitudinal facet ridges, not an oversized constant-width box.
## Pairs of points form edge segments. Pair zero is the independent centerline.
func _profile_edges(mesh: ArrayMesh) -> PackedVector3Array:
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var rings: Dictionary = {}
	for point: Vector3 in vertices:
		if not rings.has(point.y):
			rings[point.y] = Vector2.ZERO
		var extent: Vector2 = rings[point.y]
		rings[point.y] = Vector2(maxf(extent.x, absf(point.x)), maxf(extent.y, absf(point.z)))
	var heights: Array = rings.keys()
	heights.sort()
	var edges := PackedVector3Array([Vector3(0, heights[0], 0), Vector3(0, heights[-1], 0)])
	for index: int in heights.size() - 1:
		var a: float = heights[index]
		var b: float = heights[index + 1]
		var ae: Vector2 = rings[a]
		var be: Vector2 = rings[b]
		for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			edges.append(Vector3(direction.x * ae.x, a, direction.y * ae.y))
			edges.append(Vector3(direction.x * be.x, b, direction.y * be.y))
	return edges


func _setup_dust() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = EMERALD.lightened(0.4)
	material.emission_enabled = true
	material.emission = EMERALD
	for index in DUST_COUNT:
		var grain := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.018, 0.032, 0.018)
		grain.mesh = mesh
		grain.material_override = material
		grain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grain.visible = false
		add_child(grain)
		dust.append(grain)


func _update_morph(ultimate: bool) -> void:
	if ultimate != _ultimate_requested:
		_ultimate_requested = ultimate
		_ultimate_morph_frame = 0
		_morph_tick = Engine.get_physics_frames()
	elif Engine.get_physics_frames() != _morph_tick:
		_morph_tick = Engine.get_physics_frames()
		_ultimate_morph_frame = mini(ULT_MORPH_FRAMES, _ultimate_morph_frame + 1)
	var ult_progress: float = float(_ultimate_morph_frame) / float(ULT_MORPH_FRAMES)
	if ult_progress >= 0.5:
		_ultimate_gold = _ultimate_requested
	var swapping: bool = fighter.state == Fighter.State.SWAP and not fighter.sword_swap_drawing
	var progress: float = fighter.sword_swap_progress() if swapping else 0.0
	# Full dissolution covers the gameplay contact frame, before the new form appears.
	dissolve_weight = smoothstep(0.1, 0.42, progress) * (1.0 - smoothstep(0.58, 0.9, progress)) if swapping else 0.0
	if _ultimate_morph_frame < ULT_MORPH_FRAMES:
		var ult_dissolve: float = smoothstep(0.0, 0.4, ult_progress) * (1.0 - smoothstep(0.6, 1.0, ult_progress))
		dissolve_weight = maxf(dissolve_weight, ult_dissolve)
		if not swapping:
			progress = ult_progress
	presented_form = fighter.attack_sword_form if fighter.state == Fighter.State.ATTACK else fighter.sword_form
	blade.mesh = _blade_forms[posmod(presented_form, 3)]
	blade.scale = Vector3.ONE
	blade_material.set_shader_parameter("blade_form", posmod(presented_form, 3))
	for ornament: MeshInstance3D in ornaments:
		ornament.visible = true
	for index in weapon_materials.size():
		weapon_materials[index].set_shader_parameter("dissolve", dissolve_weight)
		# The generic ink pass does not know the dissolve mask.
		weapon_materials[index].next_pass = null if dissolve_weight > 0.0 else outlines[index]
	for index in dust.size():
		var grain: MeshInstance3D = dust[index]
		grain.visible = dissolve_weight > 0.0
		if not grain.visible:
			continue
		var seed_angle: float = float(index) * 2.399963
		var spread: float = dissolve_weight * (0.12 + float(index % 7) * 0.022)
		var height: float = lerpf(-0.12, 1.08, float(index) / float(DUST_COUNT - 1))
		grain.position = Vector3(cos(seed_angle + progress * TAU) * spread, height + sin(seed_angle) * spread, sin(seed_angle + progress * TAU) * spread)
		grain.rotation = Vector3(seed_angle, seed_angle + progress * TAU, progress * PI)
		grain.scale = Vector3.ONE * dissolve_weight
