class_name StaffPresentation
extends Node3D
## The Lamplighter's pole (CharacterData.weapon_kind "staff"), procedural and free of credits: a dark wooden shaft with
## a leather grip, three brass ferrules, an iron foot cap and an open brass hook with a snuffer cone at the top
## (docs/Art/Prompts/Prompt-Library.md § 19 {POLE_LAMPLIGHTER}; § 19d — cylinder and hook, T2). Presentation only:
## hitboxes come from MoveData and never from this mesh. Out of a swing the pole stands upright at the hand; during a
## swing, a fall or a KO it follows the right hand (same palm calibration as SwordPresentation).
## Every dimension is PLACEHOLDER art tuning for T6 Аполлон.
const LENGTH := 2.27            # ≈ 4/3 of the 1.70 m body: the hook always rises well above the head
const GRIP_FROM_BOTTOM := LENGTH / 3.0
const SHAFT_RADIUS := 0.022
const HOOK_RADIUS := 0.13
const UPRIGHT_TILT := deg_to_rad(8.0)   # the hook leans this much forward when the pole is carried
const SWING_IN_TICKS := 6.0
const SWING_OUT_TICKS := 8.0
const WOOD := Color("3a2c22")
const LEATHER := Color("2a1f1a")
const BRASS := Color("9e8752")
const IRON := Color("3b353c")
var fighter: Fighter
var rig: SkeletalRig
var swing_weight: float = 0.0
var pieces: Array[MeshInstance3D] = []
var _last_tick: int = -1


func setup(owner_fighter: Fighter, owner_rig: SkeletalRig) -> void:
	fighter = owner_fighter
	rig = owner_rig
	top_level = true
	var wood := _material(WOOD)
	var leather := _material(LEATHER)
	var brass := _material(BRASS)
	var iron := _material(IRON)
	var bottom := -GRIP_FROM_BOTTOM
	var top := LENGTH - GRIP_FROM_BOTTOM
	_segment(Vector3(0, bottom, 0), Vector3(0, top, 0), SHAFT_RADIUS, wood)
	_segment(Vector3(0, -0.16, 0), Vector3(0, 0.16, 0), SHAFT_RADIUS + 0.004, leather)
	for y: float in [-0.30, 0.45, 1.20]:
		_segment(Vector3(0, y - 0.018, 0), Vector3(0, y + 0.018, 0), SHAFT_RADIUS + 0.005, brass)
	_segment(Vector3(0, bottom, 0), Vector3(0, bottom + 0.05, 0), SHAFT_RADIUS + 0.004, iron)
	# Open hook in the pole's YZ plane, curling forward (+Z) and down past the top: a crook, not a ring.
	var center := Vector3(0, top, HOOK_RADIUS)
	var previous := Vector3(0, top, 0)
	for degrees: float in [45.0, 90.0, 135.0, 180.0, 225.0]:
		var t := deg_to_rad(degrees)
		var point := center + Vector3(0, sin(t), -cos(t)) * HOOK_RADIUS
		_segment(previous, point, 0.014, brass)
		previous = point
	var cone := CylinderMesh.new()
	cone.top_radius = 0.01
	cone.bottom_radius = 0.045
	cone.height = 0.08
	cone.radial_segments = 10
	var snuffer := _piece(cone, brass)
	snuffer.position = Vector3(0, top - 0.04, -0.06)
	update_pose()


func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = RigAnimator.TOON
	material.set_shader_parameter("albedo", color)
	var outline := ShaderMaterial.new()
	outline.shader = RigAnimator.OUTLINE
	outline.set_shader_parameter("width", 0.004)
	material.next_pass = outline
	fighter.animator.materials.append(material)   # the hit flash and the time-stop tint reach the pole too
	return material


func _piece(mesh: Mesh, material: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = material
	add_child(piece)
	pieces.append(piece)
	return piece


## A cylinder from a to b (local), radius r.
func _segment(a: Vector3, b: Vector3, r: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 10
	mesh.rings = 1
	var piece := _piece(mesh, material)
	var up := (b - a).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	piece.transform = Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5)
	return piece


## The right hand's palm-calibrated frame, like SwordPresentation.hand_grip("right"); the capsule fallback has none.
func hand_grip() -> Transform3D:
	var skeleton := rig.hero_skeleton if rig.hero_skeleton != null else rig.skeleton
	var bone := skeleton.find_bone("RightHand" if rig.hero_skeleton != null else "hand_r")
	if bone < 0:
		return Transform3D(Basis.IDENTITY, fighter.global_position + Vector3.UP)
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	var basis := pose.basis.orthonormalized()
	return Transform3D(basis * Basis(Vector3.RIGHT, PI * 0.5), pose.origin + basis * Vector3(0, 0.055, 0))


## Carried: shaft up with the hook leaning forward, the hook opening toward the fighter's gaze.
func upright_basis() -> Basis:
	var facing: Vector3 = fighter.forward if GameState.free_move else Vector3(float(fighter.facing), 0, 0)
	var y := (Vector3.UP * cos(UPRIGHT_TILT) + facing * sin(UPRIGHT_TILT)).normalized()
	var z := (facing - y * facing.dot(y)).normalized()
	return Basis(y.cross(z), y, z)


func swinging() -> bool:
	return fighter.state in [Fighter.State.ATTACK, Fighter.State.LAUNCHED, Fighter.State.KO, Fighter.State.KNOCKDOWN, Fighter.State.WALL_SPLAT]


func update_pose() -> void:
	if fighter == null or rig == null or not is_inside_tree():
		return
	var tick := Engine.get_physics_frames()
	if tick != _last_tick and not get_tree().paused and fighter.frozen_frames <= 0 and fighter.hitstop_frames <= 0:
		_last_tick = tick
		if fighter.state in [Fighter.State.LAUNCHED, Fighter.State.KO]:
			swing_weight = 1.0   # a falling body never carries the pole upright
		else:
			swing_weight = move_toward(swing_weight, 1.0 if swinging() else 0.0, 1.0 / (SWING_IN_TICKS if swinging() else SWING_OUT_TICKS))
	var grip := hand_grip()
	var basis := upright_basis().slerp(grip.basis.orthonormalized(), smoothstep(0.0, 1.0, swing_weight))
	global_transform = Transform3D(basis, grip.origin)


func _physics_process(_delta: float) -> void:
	update_pose()
