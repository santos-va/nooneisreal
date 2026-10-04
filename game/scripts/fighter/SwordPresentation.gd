class_name SwordPresentation
extends Node3D
## One original procedural weapon, attached to the rendered hero rather than hidden capsule pivots.
## Reference: Characters/Choko and weapon_choko_main_sword.png. Dimensions are provisional art tuning.
const EMERALD := Color("23864e")
const GOLD := Color("e8bd62")
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
var dust: Array[MeshInstance3D] = []
var weapon_materials: Array[ShaderMaterial] = []
var outlines: Array[Material] = []
var ornaments: Array[MeshInstance3D] = []
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
	var brass := _material(Color("aa8544"))
	var dark := _material(Color("153d2a"))
	blade_material = _material(EMERALD)
	blade = _piece(_blade_mesh(), blade_material, Vector3.ZERO)
	var handle := CylinderMesh.new()
	handle.top_radius = 0.032
	handle.bottom_radius = 0.035
	handle.height = 0.25
	handle.radial_segments = 8
	_piece(handle, dark, Vector3(0, -0.025, 0))
	var guard := BoxMesh.new()
	guard.size = Vector3(0.31, 0.055, 0.055)
	_piece(guard, brass, Vector3(0, 0.13, 0))
	for side: float in [-1.0, 1.0]:
		var quillon := PrismMesh.new()
		quillon.size = Vector3(0.13, 0.10, 0.055)
		var mesh := _piece(quillon, brass, Vector3(side * 0.17, 0.15, 0))
		mesh.rotation.z = side * -0.35
	var pommel := SphereMesh.new()
	pommel.radius = 0.052
	pommel.height = 0.085
	pommel.radial_segments = 8
	pommel.rings = 3
	_piece(pommel, brass, Vector3(0, -0.18, 0))
	var gem := SphereMesh.new()
	gem.radius = 0.055
	gem.height = 0.11
	gem.radial_segments = 6
	gem.rings = 2
	_piece(gem, blade_material, Vector3(0, 0.16, 0.055))
	for side: float in [-1.0, 1.0]:
		var points: Array[Vector3] = [Vector3(side * 0.09, 0.17, 0), Vector3(side * 0.115, 0.34, 0), Vector3(side * 0.052, 0.87, 0), Vector3(0, 1.08, 0)]
		for index in 3:
			var a := points[index]
			var b := points[index + 1]
			var rail := CylinderMesh.new()
			rail.top_radius = 0.005
			rail.bottom_radius = 0.005
			rail.height = a.distance_to(b)
			rail.radial_segments = 5
			var mesh := _piece(rail, brass, (a + b) * 0.5)
			mesh.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
			ornaments.append(mesh)
	# Simple wrap bands remain readable at play distance without a texture dependency.
	for i in 5:
		var band := TorusMesh.new()
		band.inner_radius = 0.028
		band.outer_radius = 0.037
		band.rings = 8
		band.ring_segments = 4
		_piece(band, brass, Vector3(0, -0.13 + i * 0.045, 0))
	_setup_dust()
	stow_weight = 1.0 if not fighter.sword_drawn else 0.0
	update_pose()

func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = DISSOLVE_SHADER
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("rim_strength", 0.18)
	var outline := ShaderMaterial.new()
	outline.shader = RigAnimator.OUTLINE
	outline.set_shader_parameter("width", 0.004)
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

static func _blade_mesh() -> ArrayMesh:
	# Diamond section with a shoulder and long pointed tip. Flat normals expose four painted facets.
	var rings: Array[PackedVector3Array] = []
	for spec: Vector3 in [Vector3(0.17, 0.09, 0.028), Vector3(0.34, 0.115, 0.033), Vector3(0.87, 0.052, 0.018)]:
		rings.append(PackedVector3Array([Vector3(-spec.y, spec.x, 0), Vector3(0, spec.x, spec.z), Vector3(spec.y, spec.x, 0), Vector3(0, spec.x, -spec.z)]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in 2:
		for i in 4:
			var n := (i + 1) % 4
			for vertex: Vector3 in [rings[r][i], rings[r + 1][i], rings[r + 1][n], rings[r][i], rings[r + 1][n], rings[r][n]]:
				surface.add_vertex(vertex)
	for i in 4:
		for vertex: Vector3 in [rings[2][i], Vector3(0, 1.08, 0), rings[2][(i + 1) % 4]]:
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
	# Hand leaf +Y extends from wrist into palm; blade exits its thumb-side grip (-Z).
	var grip := pose.origin + basis * grip_offset(side)
	return Transform3D(basis * grip_calibration(side), grip)

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
		stow_weight = 1.0 - smoothstep(0.2, 0.85, fighter.sword_swap_progress())
	if fighter.state == Fighter.State.ATTACK and fighter.current_move != null:
		var move := fighter.current_move
		if SwordMotion.supports(move.anim) or move.anim_clip.begins_with("Sword_") or move.id == "crouch_light":
			# A fast armed normal must reach the hand by its existing first active frame.
			stow_weight = minf(stow_weight, clampf(1.0 - float(fighter.move_frame) / float(maxi(1, move.startup)), 0.0, 1.0))
	if stow_weight > 0.0:
		var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
		var right := facing.cross(Vector3.UP)
		var up := (Vector3.UP * 0.85 + right * 0.53).normalized()
		var normal := -facing
		var across := up.cross(normal).normalized()
		var carry := Transform3D(Basis(across, up, across.cross(up)), fighter.global_position + Vector3.UP * 0.8 - facing * 0.30 - right * 0.20)
		pose = pose.interpolate_with(carry, smoothstep(0.0, 1.0, stow_weight))
	global_transform = pose
	var ultimate := fighter.state == Fighter.State.ATTACK and fighter.current_move != null and fighter.current_move.effect == "sword_storm"
	_update_morph(ultimate)
	blade_material.set_shader_parameter("albedo", GOLD if _ultimate_gold else EMERALD)

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
	return _left_calibration if side == "left" else Basis(Vector3.RIGHT, -PI * 0.5)

func grip_offset(side: String) -> Vector3:
	return _left_offset if side == "left" else Vector3(0, 0.055, 0)


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
	var shape: Vector3 = [Vector3.ONE, Vector3(0.62, 1.14, 0.75), Vector3(1.42, 0.87, 1.2)][posmod(presented_form, 3)]
	blade.scale = shape
	for ornament: MeshInstance3D in ornaments:
		ornament.visible = presented_form == 0
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
