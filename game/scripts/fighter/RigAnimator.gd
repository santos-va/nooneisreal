class_name RigAnimator
extends Node3D
## Procedural placeholder rig: capsules on joint pivots, posed from the fighter state.
## This is the stand-in until rigged Meshy/VRoid characters land (docs/Art/Pipeline-2D-to-3D.md).
## It also carries the spring-based "flinch" layer that gives hits a wobbly, physical feel.

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")

var parts: Dictionary = {}       # name -> {pivot: Node3D, mesh: MeshInstance3D, length: float, radius: float, mass: float, parent: String}
var materials: Array[ShaderMaterial] = []
var pose: Dictionary = {}        # name -> Vector3 euler (current)
var target_pose: Dictionary = {} # name -> Vector3 euler (target)
var root_offset: Vector3 = Vector3.ZERO
var target_root_offset: Vector3 = Vector3.ZERO
var walk_phase: float = 0.0
var idle_time: float = 0.0
var flash_time: float = 0.0
var spin: float = 0.0
var water_tilt: float = 0.0      # river stage sway (radians, rig-local), visual only
var flinch_zone: String = "mid"  # high | mid | low — which part of the body the last hit snaps

## Attack readability (plan 2026-10-03 step 1.5). Presentation only, frame data untouched.
const ANTICIPATION := 0.35       # wind-up: pose pulled this far *behind* rest early in startup
const OVERSHOOT := 0.22          # extension past the key pose on the first active frame
const STEP_FRAMES := 5           # attacks pose on 12 fps steps (60 / 5), anime limited animation
var _step_frame: int = -1

# second-order spring for flinch (x = backward tilt, y = bob, z = twist)
var flinch_x: Vector3 = Vector3.ZERO
var flinch_v: Vector3 = Vector3.ZERO
const FLINCH_FREQ := 5.5
const FLINCH_DAMP := 0.32

var _data: CharacterData
## The flinch pose feeds Ragdoll.build_from(), and the ragdoll's pelvis becomes the fighter's position
## after a launch — so even this "visual" randomness must be seeded, or replays diverge (0.3-6).
var _rng := RandomNumberGenerator.new()


func setup(data: CharacterData) -> void:
	_rng.seed = hash(data.id) if data != null else 1
	_data = data
	for c in get_children():
		c.queue_free()
	parts.clear()
	materials.clear()
	var skin := _mat(data.skin_color)
	var prim := _mat(data.primary_color)
	var sec := _mat(data.secondary_color)
	var acc := _mat(data.accent_color)
	var hair := _mat(data.hair_color)
	var glove := _mat(Color(0.08, 0.07, 0.09))
	# name, parent, pivot local pos (in parent pivot space; "" = rig root), length, radius, material, mass
	_part("pelvis", "", Vector3(0, 0.95, 0), 0.22, 0.2, sec, 10.0)
	_part("torso", "pelvis", Vector3(0, 0.2, 0), 0.5, 0.21, prim, 12.0)
	_part("head", "torso", Vector3(0, 0.56, 0), 0.26, 0.15, skin, 4.0)
	_part("upper_arm_l", "torso", Vector3(0, 0.46, 0.27), 0.32, 0.07, prim, 2.0)
	_part("forearm_l", "upper_arm_l", Vector3(0, -0.32, 0), 0.3, 0.06, glove, 1.5)
	_part("upper_arm_r", "torso", Vector3(0, 0.46, -0.27), 0.32, 0.07, prim, 2.0)
	_part("forearm_r", "upper_arm_r", Vector3(0, -0.32, 0), 0.3, 0.06, glove, 1.5)
	_part("thigh_l", "pelvis", Vector3(0, -0.05, 0.12), 0.45, 0.1, sec, 5.0)
	_part("shin_l", "thigh_l", Vector3(0, -0.45, 0), 0.45, 0.08, sec, 3.0)
	_part("thigh_r", "pelvis", Vector3(0, -0.05, -0.12), 0.45, 0.1, sec, 5.0)
	_part("shin_r", "thigh_r", Vector3(0, -0.45, 0), 0.45, 0.08, sec, 3.0)
	# hair cap
	var hair_mesh := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.17
	sph.height = 0.24
	hair_mesh.mesh = sph
	hair_mesh.material_override = hair
	hair_mesh.position = Vector3(-0.02, 0.1, 0)
	(parts["head"]["pivot"] as Node3D).add_child(hair_mesh)
	# weapon
	if data.weapon_kind == "sword":
		var blade := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.95, 0.12)
		blade.mesh = box
		blade.material_override = acc
		blade.position = Vector3(0.02, -0.55, 0)
		(parts["forearm_r"]["pivot"] as Node3D).add_child(blade)
	elif data.weapon_kind == "fans":
		for side in ["forearm_l", "forearm_r"]:
			var fan := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.22
			cyl.bottom_radius = 0.02
			cyl.height = 0.03
			fan.mesh = cyl
			fan.material_override = acc
			fan.position = Vector3(0.0, -0.4, 0)
			fan.rotation = Vector3(0, 0, PI / 2)
			(parts[side]["pivot"] as Node3D).add_child(fan)
	elif data.weapon_kind == "kunai":
		# three kunai in a knuckle grip on the right fist (card panel 2)
		var steel := _mat(Color(0.2, 0.19, 0.24))
		for k in 3:
			var kn := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.07, 0.24, 0.03)
			kn.mesh = pm
			kn.material_override = steel
			kn.position = Vector3(0.05, -0.36, -0.06 + 0.06 * k)
			kn.rotation = Vector3(0, 0, PI * 0.5)
			(parts["forearm_r"]["pivot"] as Node3D).add_child(kn)
		# backpack with the glowing ∞8 sigil
		var pack := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.16, 0.36, 0.3)
		pack.mesh = pb
		pack.material_override = _mat(Color(0.2, 0.14, 0.24))
		pack.position = Vector3(-0.25, 0.28, 0)
		(parts["torso"]["pivot"] as Node3D).add_child(pack)
		var sig := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.04
		tm.outer_radius = 0.065
		sig.mesh = tm
		var gm := StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.albedo_color = data.accent_color
		sig.material_override = gm
		sig.position = Vector3(-0.34, 0.3, 0)
		sig.rotation = Vector3(0, 0, PI * 0.5)
		(parts["torso"]["pivot"] as Node3D).add_child(sig)
	for n in parts.keys():
		pose[n] = Vector3.ZERO
		target_pose[n] = Vector3.ZERO
	_apply_pose()


func _mat(color: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color)
	var o := ShaderMaterial.new()
	o.shader = OUTLINE
	o.set_shader_parameter("width", 0.022)
	m.next_pass = o
	materials.append(m)
	return m


func _part(pname: String, parent: String, pos: Vector3, length: float, radius: float, mat: ShaderMaterial, mass: float) -> void:
	var pivot := Node3D.new()
	pivot.name = pname
	pivot.position = pos
	if parent == "":
		add_child(pivot)
	else:
		(parts[parent]["pivot"] as Node3D).add_child(pivot)
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = maxf(length + radius * 2.0, radius * 2.0)
	mi.mesh = cap
	mi.material_override = mat
	# torso/pelvis/head capsules are centred on the pivot; limbs hang downward from the pivot
	if pname in ["pelvis", "torso", "head"]:
		mi.position = Vector3(0, length * 0.5, 0)
	else:
		mi.position = Vector3(0, -length * 0.5, 0)
	pivot.add_child(mi)
	parts[pname] = {"pivot": pivot, "mesh": mi, "length": length, "radius": radius, "mass": mass, "parent": parent}


## World-space description of every part — used to spawn a ragdoll in the exact current pose.
func part_snapshot() -> Array:
	var out: Array = []
	for n in parts.keys():
		var p: Dictionary = parts[n]
		var mi: MeshInstance3D = p["mesh"]
		var pv: Node3D = p["pivot"]
		var mat := (mi.material_override as ShaderMaterial)
		out.append({
			"name": n, "parent": p["parent"], "transform": mi.global_transform, "pivot": pv.global_position,
			"length": p["length"], "radius": p["radius"], "mass": p["mass"],
			"color": mat.get_shader_parameter("albedo") if mat else Color.WHITE,
		})
	return out


func set_frozen_tint(v: float) -> void:
	for m in materials:
		m.set_shader_parameter("desat", v)


func flash() -> void:
	flash_time = 0.09


## Impulse into the flinch spring. dir.x = direction the hit travels (world), strength ~ damage.
## zone picks the reaction: high = head snaps back, mid = folds over the gut, low = knees buckle.
func flinch(dir: Vector3, strength: float, facing: int, zone: String = "mid") -> void:
	flinch_zone = zone
	# local: positive x = forward for the rig; a hit travelling along +facing pushes the torso backward
	var local_back := -dir.x * float(facing)   # >0 when pushed away from where we face
	flinch_v.x += clampf(strength / 40.0, 0.4, 2.2) * (1.0 if local_back > 0.0 else -1.0) * 6.0
	flinch_v.y -= clampf(strength / 60.0, 0.2, 1.5) * 2.0
	flinch_v.z += _rng.randf_range(-1.0, 1.0) * 1.5   # own seeded RNG: this pose seeds the ragdoll (0.3-6)


func tick(delta: float, f: Fighter, frozen: bool) -> void:
	if frozen:
		_integrate_flinch(delta * 0.35)
		_apply_pose()
		_update_flash(delta)
		return
	idle_time += delta
	rotation.y = f.yaw() if GameState.free_move else (0.0 if f.facing == 1 else PI)
	_compute_target(f, delta)
	_water_sway(f)
	if f.state == Fighter.State.ATTACK and f.current_move != null:
		# hold each drawing, then snap to the next on a 12 fps step or on a phase boundary
		if _is_step(f):
			for n in parts.keys():
				pose[n] = target_pose[n]
			root_offset = target_root_offset
	else:
		_step_frame = -1
		var k := 1.0 - pow(0.0001, delta)  # fast exponential smoothing (≈ 10-14 frames to settle)
		for n in parts.keys():
			pose[n] = (pose[n] as Vector3).lerp(target_pose[n], k)
		root_offset = root_offset.lerp(target_root_offset, k)
	_integrate_flinch(delta)
	_apply_pose()
	_update_flash(delta)


## Stage-River: the pelvis follows the wave slope, amplified for unsteady fighters
## (tilt = atan(slope along forward) × (1.6 − water_balance)). Presentation only — hitboxes don't move.
func _water_sway(f: Fighter) -> void:
	var w := GameState.water
	var target := 0.0
	if w != null and f.on_ground() and f.state != Fighter.State.KNOCKDOWN and f.state != Fighter.State.KO:
		# slope along where the fighter faces: plane → ±X (facing), free movement → forward in XZ
		var fwd := Vector2(f.forward.x, f.forward.z) if GameState.free_move else Vector2(float(f.facing), 0.0)
		target = atan(w.gradient(f.global_position.x, f.global_position.z).dot(fwd)) * (1.6 - f.data.water_balance)
		if w.swell_started_now():
			flinch_v.x += (1.6 - f.data.water_balance) * 3.0 * (1.0 if target >= 0.0 else -1.0)
	water_tilt = lerpf(water_tilt, target, 0.25)


func _update_flash(delta: float) -> void:
	if flash_time > 0.0:
		flash_time -= delta
		var v := 1.0 if flash_time > 0.0 else 0.0
		for m in materials:
			m.set_shader_parameter("hit_flash", v)


func _integrate_flinch(delta: float) -> void:
	var w := TAU * FLINCH_FREQ
	var kk := w * w
	var c := 2.0 * FLINCH_DAMP * w
	var a := -kk * flinch_x - c * flinch_v
	flinch_v += a * delta
	flinch_x += flinch_v * delta


func _pose_set(n: String, e: Vector3) -> void:
	target_pose[n] = e


func _compute_target(f: Fighter, delta: float) -> void:
	for n in parts.keys():
		target_pose[n] = Vector3.ZERO
	target_root_offset = Vector3.ZERO
	spin = lerpf(spin, 0.0, 0.2)
	var breathe := sin(idle_time * 2.2) * 0.03
	match f.state:
		Fighter.State.IDLE, Fighter.State.INTRO:
			_guard(breathe)
		Fighter.State.WALK:
			var along := f.velocity.dot(f.forward) if GameState.free_move else f.velocity.x * f.facing
			walk_phase += delta * 9.0 * signf(along if along != 0.0 else 1.0)
			_guard(breathe)
			var s := sin(walk_phase)
			_pose_set("thigh_l", Vector3(0, 0, 0.55 * s))
			_pose_set("thigh_r", Vector3(0, 0, -0.55 * s))
			_pose_set("shin_l", Vector3(0, 0, -0.5 * maxf(0.0, -s)))
			_pose_set("shin_r", Vector3(0, 0, -0.5 * maxf(0.0, s)))
			_pose_set("torso", Vector3(0, 0, 0.08))
		Fighter.State.CROUCH:
			_crouch()
			_guard(0.0)
		Fighter.State.JUMP:
			_pose_set("thigh_l", Vector3(0, 0, 0.7))
			_pose_set("thigh_r", Vector3(0, 0, 0.4))
			_pose_set("shin_l", Vector3(0, 0, -1.1))
			_pose_set("shin_r", Vector3(0, 0, -0.8))
			_pose_set("upper_arm_l", Vector3(0, 0, 2.3))
			_pose_set("upper_arm_r", Vector3(0, 0, 1.0))
			_pose_set("forearm_r", Vector3(0, 0, 0.8))
		Fighter.State.DASH when f.flashing:
			_pose_set("torso", Vector3(0, 0, 0.75))
			_pose_set("head", Vector3(0, 0, -0.45))
			_pose_set("upper_arm_l", Vector3(0, 0, -1.3))
			_pose_set("upper_arm_r", Vector3(0, 0, -1.4))
			_pose_set("thigh_l", Vector3(0, 0, 1.1))
			_pose_set("thigh_r", Vector3(0, 0, -0.9))
			_pose_set("shin_r", Vector3(0, 0, -1.2))
			target_root_offset = Vector3(0, -0.15, 0)
		Fighter.State.DASH:
			_pose_set("torso", Vector3(0, 0, 0.45))
			_pose_set("head", Vector3(0, 0, -0.25))
			_pose_set("thigh_l", Vector3(0, 0, 0.9))
			_pose_set("thigh_r", Vector3(0, 0, -0.6))
			_pose_set("shin_r", Vector3(0, 0, -0.9))
			_pose_set("upper_arm_l", Vector3(0, 0, -0.7))
			_pose_set("upper_arm_r", Vector3(0, 0, -0.9))
		Fighter.State.BLOCK, Fighter.State.BLOCKSTUN:
			_pose_set("torso", Vector3(0, 0, -0.12))
			_pose_set("upper_arm_l", Vector3(0, 0, 1.25))
			_pose_set("upper_arm_r", Vector3(0, 0, 1.35))
			_pose_set("forearm_l", Vector3(0, 0, 1.9))
			_pose_set("forearm_r", Vector3(0, 0, 1.8))
			_pose_set("thigh_l", Vector3(0, 0, 0.25))
			_pose_set("thigh_r", Vector3(0, 0, -0.2))
			_pose_set("shin_r", Vector3(0, 0, -0.4))
			if f.crouching:
				_crouch()
		Fighter.State.HITSTUN:
			_pose_set("torso", Vector3(0, 0, -0.35))
			_pose_set("head", Vector3(0, 0, -0.3))
			_pose_set("upper_arm_l", Vector3(0, 0, -0.5))
			_pose_set("upper_arm_r", Vector3(0, 0, -0.6))
			_pose_set("thigh_l", Vector3(0, 0, -0.2))
			_pose_set("thigh_r", Vector3(0, 0, 0.3))
		Fighter.State.ATTACK:
			_attack_pose(f)
		Fighter.State.GRAPPLE:
			var to_anchor: Vector3 = f.grapple.anchor_point - f.global_position
			var ang := atan2(to_anchor.y, absf(to_anchor.x)) if to_anchor.length() > 0.01 else 1.2
			_pose_set("upper_arm_r", Vector3(0, 0, PI * 0.5 + ang))
			_pose_set("forearm_r", Vector3(0, 0, 0.1))
			_pose_set("upper_arm_l", Vector3(0, 0, 0.9))
			_pose_set("thigh_l", Vector3(0, 0, 0.9))
			_pose_set("thigh_r", Vector3(0, 0, 0.6))
			_pose_set("shin_l", Vector3(0, 0, -1.3))
			_pose_set("shin_r", Vector3(0, 0, -1.0))
			_pose_set("torso", Vector3(0, 0, 0.2))
		Fighter.State.WALL_SPLAT:
			# flattened against the wall: back arched into it, arms thrown wide, head snapped back
			_pose_set("torso", Vector3(0, 0, -0.45))
			_pose_set("head", Vector3(0, 0, -0.5))
			_pose_set("upper_arm_l", Vector3(0, 0, -1.9))
			_pose_set("upper_arm_r", Vector3(0, 0, -1.7))
			_pose_set("forearm_l", Vector3(0, 0, 0.3))
			_pose_set("forearm_r", Vector3(0, 0, 0.4))
			_pose_set("thigh_l", Vector3(0, 0, 0.2))
			_pose_set("thigh_r", Vector3(0, 0, -0.25))
			_pose_set("shin_l", Vector3(0, 0, -0.5))
			target_root_offset = Vector3(-0.15, -0.1, 0)
		Fighter.State.KNOCKDOWN, Fighter.State.KO:
			_pose_set("pelvis", Vector3(0, 0, -PI / 2.0))
			target_root_offset = Vector3(0, -0.75, 0)
		Fighter.State.GETUP:
			var t := clampf(float(f.frame_in_state) / float(f.getup_frames()), 0.0, 1.0)
			_pose_set("pelvis", Vector3(0, 0, -PI / 2.0 * (1.0 - t)))
			_crouch_t(1.0 - t)
			target_root_offset = Vector3(0, -0.75 * (1.0 - t), 0)
			_guard(0.0)
		_:
			_guard(breathe)


func _guard(breathe: float) -> void:
	_pose_set("torso", Vector3(0, 0, 0.06 + breathe))
	_pose_set("head", Vector3(0, 0, -0.05))
	_pose_set("upper_arm_l", Vector3(0, 0, 0.75))
	_pose_set("forearm_l", Vector3(0, 0, 1.35))
	_pose_set("upper_arm_r", Vector3(0, 0, 0.95))
	_pose_set("forearm_r", Vector3(0, 0, 1.15))
	_pose_set("thigh_l", Vector3(0, 0, 0.18))
	_pose_set("thigh_r", Vector3(0, 0, -0.15))
	_pose_set("shin_r", Vector3(0, 0, -0.3))


func _crouch() -> void:
	_crouch_t(1.0)


func _crouch_t(t: float) -> void:
	target_root_offset = Vector3(0, -0.42 * t, 0)
	_pose_set("thigh_l", Vector3(0, 0, 1.25 * t))
	_pose_set("thigh_r", Vector3(0, 0, 1.05 * t))
	_pose_set("shin_l", Vector3(0, 0, -1.9 * t))
	_pose_set("shin_r", Vector3(0, 0, -1.9 * t))
	_pose_set("torso", Vector3(0, 0, 0.35 * t))


## Attack poses are parametrised by the move's phase: 0..1 across startup, 1..2 across active, 2..3 recovery.
func _attack_pose(f: Fighter) -> void:
	var m := f.current_move
	if m == null:
		_guard(0.0)
		return
	var fr := f.move_frame
	var phase: float
	if fr < m.startup:
		phase = float(fr) / maxf(1.0, float(m.startup))
	elif fr < m.startup + m.active:
		phase = 1.0 + float(fr - m.startup) / maxf(1.0, float(m.active))
	else:
		phase = 2.0 + float(fr - m.startup - m.active) / maxf(1.0, float(m.recovery))
	var ext := attack_ext(phase)
	_guard(0.0)
	var anim := m.anim
	if f.chain_index % 2 == 1 and m.anim_chain != "":
		anim = m.anim_chain
	match anim:
		"light":
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 1.6, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.15, 0.05, ext)))
			_pose_set("torso", Vector3(0, lerpf(0.0, -0.35, ext), 0.12 * ext))
			_pose_set("thigh_l", Vector3(0, 0, 0.35 * ext))
		"light2":
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(0.75, 1.6, ext)))
			_pose_set("forearm_l", Vector3(0, 0, lerpf(1.35, 0.05, ext)))
			_pose_set("torso", Vector3(0, lerpf(0.0, 0.35, ext), 0.12 * ext))
		"heavy":
			_pose_set("thigh_r", Vector3(0, 0, lerpf(-0.15, 1.55, ext)))
			_pose_set("shin_r", Vector3(0, 0, lerpf(-0.3, -0.05, ext)))
			_pose_set("torso", Vector3(0, 0, lerpf(0.06, -0.3, ext)))
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(0.75, -0.6, ext)))
			_pose_set("thigh_l", Vector3(0, 0, -0.1 * ext))
		"slash":
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(2.6, 0.9, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(0.5, 0.0, ext)))
			_pose_set("torso", Vector3(0, lerpf(0.4, -0.5, ext), 0.25 * ext))
			_pose_set("thigh_l", Vector3(0, 0, 0.5 * ext))
		"crouch_light":
			_crouch()
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 1.7, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.15, 0.05, ext)))
		"air_light":
			_pose_set("thigh_r", Vector3(0, 0, lerpf(0.4, 1.6, ext)))
			_pose_set("shin_r", Vector3(0, 0, lerpf(-0.8, -0.1, ext)))
			_pose_set("thigh_l", Vector3(0, 0, 0.9))
			_pose_set("shin_l", Vector3(0, 0, -1.4))
			_pose_set("torso", Vector3(0, 0, -0.25 * ext))
		"cast":
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(0.75, 1.55, ext)))
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 1.55, ext)))
			_pose_set("forearm_l", Vector3(0, 0, lerpf(1.35, 0.1, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.15, 0.1, ext)))
			_pose_set("torso", Vector3(0, 0, lerpf(0.06, 0.28, ext)))
		"spin":
			spin = ext * TAU * 0.5
			_pose_set("upper_arm_l", Vector3(0, 0, 1.5))
			_pose_set("upper_arm_r", Vector3(0, 0, 1.5))
			_pose_set("forearm_l", Vector3(0, 0, 0.0))
			_pose_set("forearm_r", Vector3(0, 0, 0.0))
		"slam":
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(2.8, 1.2, ext)))
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(2.8, 1.2, ext)))
			_pose_set("forearm_l", Vector3(0, 0, 0.2))
			_pose_set("forearm_r", Vector3(0, 0, 0.2))
			_pose_set("torso", Vector3(0, 0, lerpf(-0.4, 0.6, ext)))
			_pose_set("thigh_l", Vector3(0, 0, 0.6 * ext))
			_pose_set("thigh_r", Vector3(0, 0, 0.6 * ext))
			_pose_set("shin_l", Vector3(0, 0, -0.8 * ext))
			_pose_set("shin_r", Vector3(0, 0, -0.8 * ext))
			target_root_offset = Vector3(0, -0.25 * ext, 0)
		"elbow":
			_pose_set("upper_arm_r", Vector3(0, lerpf(0.0, -0.6, ext), lerpf(0.95, 1.9, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.15, 2.4, ext)))
			_pose_set("torso", Vector3(0, lerpf(0.0, -0.5, ext), 0.15 * ext))
			_pose_set("thigh_l", Vector3(0, 0, 0.3 * ext))
		"roundhouse":
			spin = ext * 0.7
			_pose_set("thigh_r", Vector3(0, 0, lerpf(-0.15, 1.7, ext)))
			_pose_set("shin_r", Vector3(0, 0, lerpf(-0.3, -0.05, ext)))
			_pose_set("torso", Vector3(0, 0, lerpf(0.06, -0.4, ext)))
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(0.75, 2.0, ext)))
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, -0.8, ext)))
		"low_kick":
			_crouch_t(0.3)
			_pose_set("thigh_r", Vector3(0, 0, lerpf(-0.15, 0.85, ext)))
			_pose_set("shin_r", Vector3(0, 0, lerpf(-0.3, -0.05, ext)))
			_pose_set("torso", Vector3(0, 0, lerpf(0.2, -0.2, ext)))
		"flying_knee":
			_pose_set("thigh_r", Vector3(0, 0, lerpf(0.4, 1.9, ext)))
			_pose_set("shin_r", Vector3(0, 0, lerpf(-0.8, -2.2, ext)))
			_pose_set("thigh_l", Vector3(0, 0, -0.3))
			_pose_set("upper_arm_l", Vector3(0, 0, 2.2 * ext))
			_pose_set("upper_arm_r", Vector3(0, 0, 2.0 * ext))
			_pose_set("forearm_l", Vector3(0, 0, 1.2))
			_pose_set("forearm_r", Vector3(0, 0, 1.2))
			_pose_set("torso", Vector3(0, 0, 0.25 * ext))
		"toss":
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.9, 3.0, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.2, 0.2, ext)))
			_pose_set("torso", Vector3(0, 0, lerpf(0.06, -0.2, ext)))
			_pose_set("head", Vector3(0, 0, -0.35 * ext))
		"veil":
			_crouch_t(0.6 * ext)
			_pose_set("upper_arm_l", Vector3(0, 0, 1.8))
			_pose_set("upper_arm_r", Vector3(0, 0, -0.4))
			spin = ext * PI
		"book":
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(0.75, 1.35, ext)))
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 1.35, ext)))
			_pose_set("forearm_l", Vector3(0, 0, 0.9))
			_pose_set("forearm_r", Vector3(0, 0, 0.9))
			_pose_set("torso", Vector3(0, 0, -0.15 * ext))
			_pose_set("head", Vector3(0, 0, -0.35 * ext))
			_pose_set("thigh_l", Vector3(0, 0, 0.3 * ext))
			_pose_set("shin_l", Vector3(0, 0, -0.6 * ext))
			target_root_offset = Vector3(0, 0.35 * ext, 0)
		"watch":
			_pose_set("upper_arm_l", Vector3(0, 0, lerpf(0.75, 1.55, ext)))
			_pose_set("forearm_l", Vector3(0, 0, lerpf(1.35, 1.7, ext)))
			_pose_set("head", Vector3(0, 0, -0.2 * ext))
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 0.3, ext)))
		"sword_up":
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 3.0, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.15, 0.0, ext)))
			_pose_set("upper_arm_l", Vector3(0, 0, -0.4 * ext))
			_pose_set("torso", Vector3(0, 0, -0.25 * ext))
			_pose_set("head", Vector3(0, 0, -0.3 * ext))
		"throw":
			_pose_set("upper_arm_l", Vector3(0, 0, 1.5))
			_pose_set("upper_arm_r", Vector3(0, 0, 1.5))
			_pose_set("forearm_l", Vector3(0, 0, lerpf(1.2, 0.1, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.2, 0.1, ext)))
			_pose_set("torso", Vector3(0, 0, lerpf(0.06, -0.4, ext)))
		_:
			_pose_set("upper_arm_r", Vector3(0, 0, lerpf(0.95, 1.6, ext)))
			_pose_set("forearm_r", Vector3(0, 0, lerpf(1.15, 0.05, ext)))


## Extension curve across a move: 0 = rest, 1 = key strike pose.
##   startup 0..1: wind-up behind rest (−ANTICIPATION at 45 %), then a fast snap to 1
##   active  1..2: overshoot to 1 + OVERSHOOT on the first active frame, settling to 1
##   recovery 2..3: back to rest
static func attack_ext(phase: float) -> float:
	if phase < 1.0:
		if phase < 0.45:
			return -ANTICIPATION * sin(PI * 0.5 * phase / 0.45)
		var t := (phase - 0.45) / 0.55
		return lerpf(-ANTICIPATION, 1.0, t * t)
	if phase < 2.0:
		var a := phase - 1.0
		return 1.0 + OVERSHOOT * (1.0 - a) * (1.0 - a)
	return 1.0 - clampf(phase - 2.0, 0.0, 1.0)


## True on the frames the attack pose may change: every STEP_FRAMES, plus the first startup,
## first active and first recovery frame so the key drawings are never skipped.
func _is_step(f: Fighter) -> bool:
	var m := f.current_move
	var fr := f.move_frame
	var key := fr == 0 or fr == m.startup or fr == m.startup + m.active or _step_frame < 0
	if key or fr - _step_frame >= STEP_FRAMES or fr < _step_frame:
		_step_frame = fr
		return true
	return false


func _apply_pose() -> void:
	for n in parts.keys():
		var pv: Node3D = parts[n]["pivot"]
		var e: Vector3 = pose[n]
		var fl := absf(flinch_x.x)
		if n == "torso":
			match flinch_zone:
				"high":
					e.z += flinch_x.x * 0.25
				"low":
					e.z += flinch_x.x * 0.15 + fl * 0.2
				_:
					e.z += fl * 0.55          # doubled over
			e.y += flinch_x.z * 0.2
		elif n == "head":
			e.z += flinch_x.x * (1.1 if flinch_zone == "high" else 0.45)
		elif (n == "thigh_l" or n == "thigh_r") and flinch_zone == "low":
			e.z += fl * 0.45
		elif (n == "shin_l" or n == "shin_r") and flinch_zone == "low":
			e.z -= fl * 0.8
		elif n == "pelvis":
			e.y += spin
			e.z += water_tilt
		pv.rotation = e
	var root: Node3D = parts["pelvis"]["pivot"]
	var buckle := absf(flinch_x.x) * 0.07 if flinch_zone == "low" else 0.0
	root.position = Vector3(0, 0.95, 0) + root_offset + Vector3(0, flinch_x.y * 0.08 - buckle, 0)
