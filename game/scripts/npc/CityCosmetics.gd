class_name CityCosmetics
extends Node3D
## A physical cloth sash follows the hero's torso; original skin/eyes/materials stay intact.
var fighter: Fighter
var progress: CityProgress
var cloth: StandardMaterial3D

func setup(target: Fighter, model: CityProgress) -> void:
	fighter = target
	progress = model
	process_physics_priority = 30
	cloth = StandardMaterial3D.new()
	cloth.roughness = 1.0
	var strap := MeshInstance3D.new()
	strap.name = "ClothSash"
	var strip := BoxMesh.new()
	strip.size = Vector3(0.11, 0.52, 0.035)
	strap.mesh = strip
	strap.position.z = 0.22
	strap.rotation.z = -0.55
	strap.material_override = cloth
	add_child(strap)
	var back_strap := strap.duplicate() as MeshInstance3D
	back_strap.name = "ClothSashBack"
	back_strap.position.z = -0.20
	back_strap.rotation.z = 0.55
	add_child(back_strap)
	var belt := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.19
	ring.outer_radius = 0.23
	ring.rings = 16
	ring.ring_segments = 6
	belt.mesh = ring
	belt.position.y = -0.23
	belt.scale = Vector3(1.0, 1.4, 0.75)
	belt.material_override = cloth
	add_child(belt)
	progress.changed.connect(update_color)
	update_color()

func update_color() -> void:
	visible = progress.summary().palette != "original"
	cloth.albedo_color = progress.current_palette()

func _physics_process(_delta: float) -> void:
	if fighter == null or not visible:
		return
	var hips: Vector3 = fighter.global_position + Vector3.UP * 0.92
	var neck: Vector3 = fighter.global_position + Vector3.UP * 1.48
	if fighter.skeletal != null and fighter.skeletal.hero_skeleton != null:
		var bones: Skeleton3D = fighter.skeletal.hero_skeleton
		var hip_index: int = bones.find_bone("Hips")
		var neck_index: int = bones.find_bone("neck")
		if hip_index >= 0 and neck_index >= 0:
			hips = bones.to_global(bones.get_bone_global_pose(hip_index).origin)
			neck = bones.to_global(bones.get_bone_global_pose(neck_index).origin)
	var up: Vector3 = (neck - hips).normalized()
	var forward: Vector3 = fighter.forward.normalized()
	var right: Vector3 = up.cross(forward).normalized()
	if right.length_squared() < 0.5:
		return
	forward = right.cross(up).normalized()
	global_transform = Transform3D(Basis(right, up, forward), hips.lerp(neck, 0.58))
