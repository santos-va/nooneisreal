class_name BoneRagdoll
extends Ragdoll
## Launch 7.1: the ragdoll on the skeleton (docs/Tech/Active-Ragdoll.md, stage 2). Instead of loose capsules, the
## UAL mannequin — the pose source of SkeletalRig — gets a PhysicalBoneSimulator3D with eleven PhysicalBone3D, one per
## capsule-rig part (same masses and radii, lengths from the bones). SkeletalRig.retarget() copies the simulated pose
## onto the hero, so the hero itself falls. Physics stays presentation only (ADR-004): Fighter reads the pelvis exactly
## as it read the capsule pelvis.
##
## Why the mannequin and not the Meshy hero: the hero's Armature is scaled 0.01 (bones in cm), and Jolt joints between
## PhysicalBone3D under that scale blow up (docs/Fix/2026-10-03-launch-7-1-skeleton-ragdoll.md § Проба). The mannequin
## is unit scale.
## Stage-2 "muscles": the 6DOF angular springs of each PhysicalBone3D joint (equilibrium = the pose at spawn), same
## stiffness and damping as the capsule springs; Jolt honours them (measured in the fix log; a script PD torque instead
## ran the limbs into Jolt's angular-velocity cap).

## Capsule-rig part → [mannequin bone, bone the body aims at ("" = along the parent bone)].
const BONES := {
	"pelvis": ["pelvis", "spine_02"], "torso": ["spine_02", "neck_01"], "head": ["Head", ""],
	"upper_arm_l": ["upperarm_l", "lowerarm_l"], "forearm_l": ["lowerarm_l", "hand_l"],
	"upper_arm_r": ["upperarm_r", "lowerarm_r"], "forearm_r": ["lowerarm_r", "hand_r"],
	"thigh_l": ["thigh_l", "calf_l"], "shin_l": ["calf_l", "foot_l"],
	"thigh_r": ["thigh_r", "calf_r"], "shin_r": ["calf_r", "foot_r"],
}
## Frames for the simulator's influence to go 0 → 1 (Active-Ragdoll stage 2: 2–4 frames).
const BLEND_FRAMES := 3

var rig: SkeletalRig = null
var sim: PhysicalBoneSimulator3D = null
var _parent_of: Dictionary = {}    # part → parent part (jointed parts only)
var _frames: int = 0


func build_on(r: SkeletalRig, snapshot: Array, impulse: Vector3, with_muscles: bool) -> void:
	rig = r
	muscles = with_muscles
	var sk := rig.skeleton
	sim = PhysicalBoneSimulator3D.new()
	sim.name = "Ragdoll"
	sim.influence = 0.0
	sk.add_child(sim)
	var frame := rig.global_transform.basis.orthonormalized()   # x forward, y up, z lateral — the capsule rig's frame
	var by_name: Dictionary = {}
	for s in snapshot:
		by_name[s.name] = s
	for part in BONES.keys():
		if not by_name.has(part):
			continue
		var s: Dictionary = by_name[part]
		var bi := sk.find_bone(BONES[part][0])
		if bi < 0:
			continue
		var bg := sk.get_bone_global_pose(bi)
		var dir: Vector3
		if BONES[part][1] != "":
			dir = sk.get_bone_global_pose(sk.find_bone(BONES[part][1])).origin - bg.origin
		else:
			dir = (bg.origin - sk.get_bone_global_pose(sk.get_bone_parent(bi)).origin).normalized() * float(s.length)
		var local := bg.basis.inverse() * dir
		var pb := PhysicalBone3D.new()
		pb.name = part
		pb.bone_name = BONES[part][0]
		pb.body_offset = Transform3D(_aim_y(local.normalized()), local * 0.5)
		pb.mass = s.mass
		pb.linear_damp = 0.25
		pb.angular_damp = 2.5
		pb.collision_layer = 16
		pb.collision_mask = 1
		pb.axis_lock_linear_z = true
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = s.radius
		cap.height = maxf(local.length() + s.radius * 2.0, s.radius * 2.0)
		cs.shape = cap
		pb.add_child(cs)
		if s.parent != "" and by_name.has(s.parent):
			_parent_of[part] = s.parent
		sim.add_child(pb)
		bodies[part] = pb
	sim.physical_bones_start_simulation()
	# joint frames from the bodies as start_simulation() placed them — the pose at spawn is the springs' equilibrium
	for part in bodies.keys():
		var pb: PhysicalBone3D = bodies[part]
		PhysicsServer3D.body_set_enable_continuous_collision_detection(pb.get_rid(), true)
		if not _parent_of.has(part):
			continue
		# joint on the bone's pivot, axes in the rig frame — JOINT_LIMITS mean what they meant on the capsules
		pb.joint_offset = Transform3D(pb.global_transform.basis.orthonormalized().inverse() * frame, pb.body_offset.affine_inverse() * Vector3.ZERO)
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
		var lim: Vector3 = JOINT_LIMITS.get(part, Vector3(0.5, 0.5, 0.5))
		for ax in 3:
			var a: String = ["x", "y", "z"][ax]
			pb.set("joint_constraints/%s/angular_limit_enabled" % a, true)
			pb.set("joint_constraints/%s/angular_limit_upper" % a, rad_to_deg(lim[ax]))
			pb.set("joint_constraints/%s/angular_limit_lower" % a, -rad_to_deg(lim[ax]))
		_springs(pb, muscles)
	for part in [["torso", 1.0], ["pelvis", 0.8], ["head", 0.5]]:
		if bodies.has(part[0]):
			var b: PhysicalBone3D = bodies[part[0]]
			b.apply_central_impulse(impulse * b.mass * float(part[1]))
	if bodies.has("torso"):
		PhysicsServer3D.body_apply_torque_impulse((bodies["torso"] as PhysicalBone3D).get_rid(), Vector3(0, 0, -signf(impulse.x) * 4.0))
	rig.ragdoll = self


## Basis whose +Y points along d (unit).
static func _aim_y(d: Vector3) -> Basis:
	if d.dot(Vector3.UP) < -0.9999:
		return Basis(Vector3.RIGHT, PI)
	return Basis(Quaternion(Vector3.UP, d))


func go_limp() -> void:
	muscles = false
	for part in _parent_of.keys():
		_springs(bodies[part], false)


func _springs(pb: PhysicalBone3D, on: bool) -> void:
	for a in ["x", "y", "z"]:
		pb.set("joint_constraints/%s/angular_spring_enabled" % a, on)
		pb.set("joint_constraints/%s/angular_spring_stiffness" % a, MUSCLE_STIFFNESS if on else 0.0)
		pb.set("joint_constraints/%s/angular_spring_damping" % a, MUSCLE_DAMPING if on else 0.0)
		pb.set("joint_constraints/%s/angular_equilibrium_point" % a, 0.0)


func _physics_process(delta: float) -> void:
	if sim == null:
		return
	_frames += 1
	sim.influence = minf(1.0, float(_frames) / float(BLEND_FRAMES))
	_age += delta
	var vmax := 0.0
	for b in bodies.values():
		vmax = maxf(vmax, (b as PhysicalBone3D).linear_velocity.length())
	if vmax < 0.7:
		_settle_frames += 1
	else:
		_settle_frames = 0
	if muscles and _age > 0.9:
		go_limp()
	if GameState.water != null:
		_float(delta)



func pelvis_position() -> Vector3:
	if bodies.has("pelvis"):
		return (bodies["pelvis"] as PhysicalBone3D).global_position
	return global_position


## Ends the simulation now (not at queue_free), so the get-up frame already draws the animation.
func release() -> void:
	if sim != null and is_instance_valid(sim):
		sim.physical_bones_stop_simulation()
		sim.active = false
		sim.queue_free()
	sim = null
	if rig != null and is_instance_valid(rig) and rig.ragdoll == self:
		rig.ragdoll = null


func _exit_tree() -> void:
	release()
