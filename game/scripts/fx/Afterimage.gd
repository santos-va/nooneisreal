class_name Afterimage
extends Node3D
## A frozen, translucent copy of the visible skeletal mesh, or the diagnostic capsule rig.
## Used for Skea's flash-step ghosts, Choko's rewind trail, veil shimmer and Grimoire shadows.
## Burns away in steps (12 fps feel, fx_glow / fx_ink dissolve) so it reads as a drawn frame, not a motion-blur smear.

## Presentation budget for both fighters together; excess ghosts are skipped.
const MAX_ACTIVE := 16

var _mat: ShaderMaterial
var _life: float = 0.3
var _left: float = 0.3
var _alpha: float = 0.5
var _drift: Vector3 = Vector3.ZERO


static func spawn(parent: Node, snapshot: Array, color: Color, life: float = 0.3, alpha: float = 0.5,
		additive: bool = true, scale_mult: float = 1.0, offset: Vector3 = Vector3.ZERO, drift: Vector3 = Vector3.ZERO) -> Afterimage:
	if not Fx.enabled or parent.get_tree().get_nodes_in_group("afterimage").size() >= MAX_ACTIVE:
		return null
	var a := Afterimage.new()
	a.top_level = true
	a.add_to_group("afterimage")
	parent.add_child(a)
	a._build(snapshot, color, life, alpha, additive, scale_mult, offset, drift)
	return a


## Capture values only: mesh and immutable bind Skin are shared, pose/transforms are frozen.
## Legacy callers may still pass RigAnimator.part_snapshot() directly to spawn().
static func snapshot(animator: RigAnimator, rig: SkeletalRig = null) -> Array:
	if not Fx.enabled or animator.get_tree().get_nodes_in_group("afterimage").size() >= MAX_ACTIVE:
		return []
	if not is_instance_valid(rig):
		return animator.part_snapshot()
	var skeleton: Skeleton3D = rig.hero_skeleton if rig.hero_skeleton != null else rig.skeleton
	if skeleton == null:
		return animator.part_snapshot()
	var bones: Array = []
	for i in skeleton.get_bone_count():
		bones.append({"name": skeleton.get_bone_name(i), "parent": skeleton.get_bone_parent(i),
			"rest": skeleton.get_bone_rest(i), "enabled": skeleton.is_bone_enabled(i),
			"position": skeleton.get_bone_pose_position(i), "rotation": skeleton.get_bone_pose_rotation(i),
			"scale": skeleton.get_bone_pose_scale(i)})
	var result: Array = []
	# Visibility on the rig can deliberately blink during dash; select its drawn mesh identity,
	# not is_visible_in_tree(), so the flash-step still leaves a silhouette during that blink.
	for child in skeleton.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var shapes: Array = []
		for i in mesh.get_blend_shape_count():
			shapes.append(mesh.get_blend_shape_value(i))
		result.append({"mesh": mesh.mesh, "skin": mesh.skin,
			"transform": mesh.global_transform, "skeleton_transform": skeleton.global_transform,
			"bones": bones, "rest_only": skeleton.show_rest_only, "blend_shapes": shapes,
			"center": (animator.parts["pelvis"]["mesh"] as MeshInstance3D).global_position})
	return result if not result.is_empty() else animator.part_snapshot()


func _build_skeletal(snapshot: Array, scale_mult: float, offset: Vector3) -> void:
	var first: Dictionary = snapshot[0]
	var center: Vector3 = first.center
	# World-space affine map p -> center + scale * (p - center) + offset.
	# Both mesh and skeleton receive it; imported centimetre armature scales remain intact.
	var placement := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_mult), center * (1.0 - scale_mult) + offset)
	var frozen := Skeleton3D.new()
	frozen.name = "FrozenSkeleton"
	frozen.show_rest_only = first.rest_only
	add_child(frozen)
	frozen.global_transform = placement * (first.skeleton_transform as Transform3D)
	for bone in first.bones:
		frozen.add_bone(bone.name)
	for i in first.bones.size():
		var bone: Dictionary = first.bones[i]
		frozen.set_bone_parent(i, bone.parent)
		frozen.set_bone_rest(i, bone.rest)
		# Copy the source TRS channels exactly, avoiding a global-to-local inversion and
		# decomposition round trip on the centimetre-scale hero armature.
		frozen.set_bone_enabled(i, bone.enabled)
		frozen.set_bone_pose_position(i, bone.position)
		frozen.set_bone_pose_rotation(i, bone.rotation)
		frozen.set_bone_pose_scale(i, bone.scale)
	for entry in snapshot:
		var mesh := Fx.mesh(entry.mesh, _mat)
		frozen.add_child(mesh)
		mesh.global_transform = placement * (entry.transform as Transform3D)
		mesh.skin = entry.skin
		mesh.skeleton = mesh.get_path_to(frozen)
		for i in entry.blend_shapes.size():
			mesh.set_blend_shape_value(i, entry.blend_shapes[i])


func _build(snapshot: Array, color: Color, life: float, alpha: float, additive: bool, scale_mult: float, offset: Vector3, drift: Vector3) -> void:
	_life = maxf(life, 0.05)
	_left = _life
	_alpha = alpha
	_drift = drift
	# additive ghosts get a fresnel rim (a drawn outline of the pose); the ink double stays a flat silhouette
	_mat = FxShader.stroke(color, alpha, additive, 0.0, 1.0 if additive else 0.0)
	if snapshot.is_empty():
		return
	if snapshot[0].has("mesh"):
		_build_skeletal(snapshot, scale_mult, offset)
		return
	var center: Vector3 = (snapshot[0].transform as Transform3D).origin
	for s in snapshot:
		var cm := CapsuleMesh.new()
		cm.radius = s.radius * scale_mult * 1.08
		cm.height = maxf(s.length + s.radius * 2.0, s.radius * 2.0) * scale_mult
		cm.radial_segments = 10
		cm.rings = 2
		var mi := Fx.mesh(cm, _mat)
		add_child(mi)
		var t: Transform3D = s.transform
		var o := center + (t.origin - center) * scale_mult + offset
		mi.transform = Transform3D(t.basis, o)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	var k := Fx.stepped(_left / _life)
	FxShader.fade(_mat, k)
	_mat.set_shader_parameter("alpha", _alpha * (0.5 + 0.5 * k))
	position += _drift * delta
