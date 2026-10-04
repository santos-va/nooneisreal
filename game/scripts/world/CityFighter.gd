class_name CityFighter
extends Fighter
## Exploration adapter. The duel controller, animations and parkour remain authoritative.
## Only city support/flash bounds and unavailable combat systems differ from Fighter.

@export var support_probe_depth: float = 64.0 # PLACEHOLDER district safety depth.

func _ready() -> void:
	super._ready()
	floor_snap_length = 0.3 # PLACEHOLDER: follows the district ramp without snapping a jump.
	floor_constant_speed = true
	if printer != null:
		printer.process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta: float) -> void:
	# Terrain snap is a walking aid, not an extra tether during a grapple or jump.
	floor_snap_length = 0.3 if state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK] else 0.0
	super._physics_process(delta)
	# Walking off a roof must use airborne controls/gravity, never a grounded jump in midair.
	if not on_ground() and velocity.y < -0.01 and state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK]:
		_set_state(State.JUMP)

func _pressed(action: String) -> bool:
	if action in ["skill1", "skill2", "ultimate", "grapple_enemy"]:
		InputRouter.buffered(player_index, action)
		return false
	return super._pressed(action)

func _start_flash(axis: float, jump_dash: bool = false) -> bool:
	if not super._start_flash(axis, jump_dash):
		return false
	# Fighter's static clamp_arena belongs to duel scenes. Collision still uses move_and_slide.
	_flash_to = _flash_from + _dash_vec * data.flash_distance
	return true

func floor_y() -> float:
	if not is_inside_tree():
		return -support_probe_depth
	# Start at the feet, never above the head: an overhead roof is not floor support.
	var origin := global_position + Vector3.UP * 0.05
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * support_probe_depth, 1)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and Vector3(result.normal).dot(Vector3.UP) > 0.5:
		return float(result.position.y)
	return -support_probe_depth

func _post_move() -> void:
	# Physical world collision supplies floor and walls; the city owns fall recovery.
	_water_grounded = false

func restart_at(point: Vector3) -> void:
	reset_for_round(point.x, 1)
	fatigue = 0.0
	global_position = point + Vector3.UP * 0.06
	_set_forward(Vector3.FORWARD)
	set_control(true)
