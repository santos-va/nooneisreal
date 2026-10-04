class_name CityCamera
extends Node3D
## One-player city camera: explicit orbit, stable physics input basis and world collision.
signal looked(radians: float)

@export var follow_distance: float = 6.0 # PLACEHOLDER city framing; device review pending.
@export var focus_height: float = 1.4
@export var aim_shoulder_offset: float = 1.0 # PLACEHOLDER metres, clear torso when aiming up.
var _shoulder_shape: SphereShape3D
@export var base_pitch: float = -0.24
var player: CityFighter
var arm: SpringArm3D
var camera: Camera3D
var aim: HarpoonAim
var _yaw: float = 0.0
var _pitch: float = 0.0
var _cue: MeshInstance3D

func _ready() -> void:
	process_physics_priority = -50 # InputRouter first, camera packet next, fighter last.
	arm = SpringArm3D.new()
	arm.name = "SpringArm3D"
	arm.collision_mask = 1
	arm.margin = 0.2
	arm.spring_length = follow_distance
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	arm.shape = shape
	_shoulder_shape = SphereShape3D.new()
	_shoulder_shape.radius = 0.25
	add_child(arm)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 65.0
	camera.near = 0.1
	camera.far = 240.0
	arm.add_child(camera)
	aim = HarpoonAim.new()
	aim.return_speed = 0.0 # City orbit stays where the player leaves it.
	add_child(aim)
	aim.setup(camera, true)
	_cue = MeshInstance3D.new()
	var cue_mesh := SphereMesh.new()
	cue_mesh.radius = 0.15
	cue_mesh.height = 0.3
	_cue.mesh = cue_mesh
	var cue_material := StandardMaterial3D.new()
	cue_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cue_material.albedo_color = Color(0.2, 1.0, 0.75)
	_cue.material_override = cue_material
	_cue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cue.top_level = true
	_cue.visible = false
	add_child(_cue)

func setup(fighter: CityFighter) -> void:
	player = fighter
	arm.add_excluded_object(player.get_rid())
	camera.make_current()
	reset_view()

func reset_view() -> void:
	aim.reset()
	_yaw = 0.0
	_pitch = 0.0
	rotation = Vector3.ZERO
	arm.rotation.x = base_pitch
	arm.position = Vector3.ZERO
	global_position = player.global_position + Vector3.UP * focus_height
	_publish_basis()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	aim.step(delta)
	var previous := _yaw
	var previous_pitch := _pitch
	_yaw = aim.yaw_offset
	_pitch = aim.pitch_offset
	rotation.y = _yaw
	arm.rotation.x = base_pitch + aim.pitch_offset
	global_position = global_position.lerp(player.global_position + Vector3.UP * focus_height, 1.0 - exp(-15.0 * delta))
	_update_shoulder(delta)
	_publish_basis()
	var turn := Vector2(angle_difference(previous, _yaw), _pitch - previous_pitch).length()
	if turn > 0.00001:
		looked.emit(turn)
	var packet := aim.capture(player, false, false)
	_cue.visible = not String(packet.target_id).is_empty() and not InputRouter.ui_suppressed()
	if _cue.visible:
		_cue.global_position = packet.point

func _update_shoulder(delta: float) -> void:
	# Shift the arm pivot, not its camera child: the existing spring-arm sweep
	# still covers the complete back-to-front path after the lateral sweep.
	var wanted := aim_shoulder_offset * smoothstep(0.1, 0.6, aim.pitch_offset)
	var offset := lerpf(arm.position.x, wanted, 1.0 - exp(-12.0 * delta))
	var motion := global_basis.x * offset
	if motion.length_squared() > 0.000001:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _shoulder_shape
		query.transform = Transform3D(Basis.IDENTITY, global_position)
		query.motion = motion
		query.collision_mask = arm.collision_mask
		query.exclude = [player.get_rid()]
		var fractions := get_world_3d().direct_space_state.cast_motion(query)
		if not fractions.is_empty():
			offset *= fractions[0]
	arm.position.x = offset

func _publish_basis() -> void:
	InputRouter.set_view_basis(player.player_index, Vector3(-sin(_yaw), 0.0, -cos(_yaw)))

func _exit_tree() -> void:
	InputRouter.clear_view_basis(1)
