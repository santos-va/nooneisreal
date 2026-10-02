class_name Ragdoll
extends Node3D
## Physics ragdoll built at runtime from a RigAnimator snapshot (same pose, same colours).
## Stage-2 "active ragdoll": joints carry angular springs ("muscle tone") that pull limbs back
## toward the rest pose while the fighter is alive; on KO the muscles are off and the body goes limp.
## Physics is presentation only — it never decides hits. Docs: docs/Tech/Active-Ragdoll.md

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")

const JOINT_LIMITS := {
	"torso": Vector3(0.35, 0.45, 0.4), "head": Vector3(0.6, 0.8, 0.5),
	"upper_arm_l": Vector3(1.5, 1.2, 1.5), "upper_arm_r": Vector3(1.5, 1.2, 1.5),
	"forearm_l": Vector3(0.15, 0.15, 2.2), "forearm_r": Vector3(0.15, 0.15, 2.2),
	"thigh_l": Vector3(1.3, 0.5, 1.3), "thigh_r": Vector3(1.3, 0.5, 1.3),
	"shin_l": Vector3(0.1, 0.1, 2.0), "shin_r": Vector3(0.1, 0.1, 2.0),
}
const MUSCLE_STIFFNESS := 55.0
const MUSCLE_DAMPING := 6.0

var bodies: Dictionary = {}
var joints: Array[Generic6DOFJoint3D] = []
var muscles: bool = true
var _age: float = 0.0
var _settle_frames: int = 0


func build_from(snapshot: Array, impulse: Vector3, with_muscles: bool) -> void:
	muscles = with_muscles
	for s in snapshot:
		var rb := RigidBody3D.new()
		rb.name = s.name
		rb.collision_layer = 16
		rb.collision_mask = 1
		rb.mass = s.mass
		rb.linear_damp = 0.25
		rb.angular_damp = 2.5
		rb.continuous_cd = true
		rb.axis_lock_linear_z = true
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = s.radius
		cap.height = maxf(s.length + s.radius * 2.0, s.radius * 2.0)
		cs.shape = cap
		rb.add_child(cs)
		var mi := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = s.radius
		cm.height = cap.height
		mi.mesh = cm
		mi.material_override = _mat(s.color)
		rb.add_child(mi)
		add_child(rb)
		rb.global_transform = s.transform
		bodies[s.name] = rb
	for s in snapshot:
		if s.parent == "" or not bodies.has(s.parent):
			continue
		var j := Generic6DOFJoint3D.new()
		add_child(j)
		var parent_rb: RigidBody3D = bodies[s.parent]
		j.global_transform = Transform3D(parent_rb.global_transform.basis, s.pivot)
		j.node_a = parent_rb.get_path()
		j.node_b = (bodies[s.name] as RigidBody3D).get_path()
		j.exclude_nodes_from_collision = true
		_setup_joint(j, JOINT_LIMITS.get(s.name, Vector3(0.5, 0.5, 0.5)))
		joints.append(j)
	if bodies.has("torso"):
		(bodies["torso"] as RigidBody3D).apply_central_impulse(impulse * (bodies["torso"] as RigidBody3D).mass)
		(bodies["torso"] as RigidBody3D).apply_torque_impulse(Vector3(0, 0, -signf(impulse.x) * 4.0))
	if bodies.has("pelvis"):
		(bodies["pelvis"] as RigidBody3D).apply_central_impulse(impulse * (bodies["pelvis"] as RigidBody3D).mass * 0.8)
	if bodies.has("head"):
		(bodies["head"] as RigidBody3D).apply_central_impulse(impulse * (bodies["head"] as RigidBody3D).mass * 0.5)


func _setup_joint(j: Generic6DOFJoint3D, lim: Vector3) -> void:
	# lock linear motion on all axes
	j.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	j.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	j.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	j.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	j.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	j.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	j.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	j.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	j.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	# angular limits
	j.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	j.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	j.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	j.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -lim.x)
	j.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, lim.x)
	j.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -lim.y)
	j.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, lim.y)
	j.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -lim.z)
	j.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, lim.z)
	# muscles: angular springs toward the rest pose
	_set_muscles(j, muscles)


func _set_muscles(j: Generic6DOFJoint3D, on: bool) -> void:
	j.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, on)
	j.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, on)
	j.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, on)
	for axis in 3:
		var stiff := MUSCLE_STIFFNESS if on else 0.0
		var damp := MUSCLE_DAMPING if on else 0.0
		match axis:
			0:
				j.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, stiff)
				j.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, damp)
				j.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0.0)
			1:
				j.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, stiff)
				j.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, damp)
				j.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0.0)
			2:
				j.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, stiff)
				j.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, damp)
				j.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_EQUILIBRIUM_POINT, 0.0)


func go_limp() -> void:
	muscles = false
	for j in joints:
		_set_muscles(j, false)


func _mat(color: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color)
	var o := ShaderMaterial.new()
	o.shader = OUTLINE
	o.set_shader_parameter("width", 0.022)
	m.next_pass = o
	return m


func _physics_process(delta: float) -> void:
	_age += delta
	var vmax := 0.0
	for b in bodies.values():
		vmax = maxf(vmax, (b as RigidBody3D).linear_velocity.length())
	if vmax < 0.7:
		_settle_frames += 1
	else:
		_settle_frames = 0
	# muscles fade after the initial flight so a live fighter "collapses" before getting up
	if muscles and _age > 0.9:
		go_limp()


func pelvis_position() -> Vector3:
	if bodies.has("pelvis"):
		return (bodies["pelvis"] as RigidBody3D).global_position
	return global_position


func settled() -> bool:
	return _age > 0.8 and _settle_frames >= 18
