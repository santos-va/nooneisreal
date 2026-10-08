class_name CityFighter
extends Fighter
## Exploration adapter. The duel controller, animations and parkour remain authoritative.
## Only city support/flash bounds and unavailable combat systems differ from Fighter.

## Arena-dependent actions stay sealed in the city (ADR-023). A fresh press is consumed, never acted
## on, and reported once so the HUD can say why nothing happened. No new input action is involved.
signal sealed_action(action: String)
const SEALED_ACTIONS: Array[String] = ["skill1", "skill2", "ultimate", "grapple_enemy"]
## ADR-024 п. 6: for the length of a lethal pocket fight skill1, skill2 and the ultimate open; the enemy hook and
## the Printer stay off. Set only by CityLethalFight, together with the pocket's circle (arena_center/radius).
const POCKET_SEALED_ACTIONS: Array[String] = ["grapple_enemy"]
var lethal_pocket: bool = false
## «Заплутаність» (plan 2026-10-08-City-Events-Stage-1, step 4; T5 § 4.2): slower walking and braking and half the
## attack tracking while the city state lasts. Never inside a lethal pocket; Fighter and the duel never read it.
var haze: CityHaze = null

@export var support_probe_depth: float = 64.0 # PLACEHOLDER district safety depth.
const ParkourMotor = preload("res://scripts/world/CityParkourMotor.gd")
@export var parkour_profile: Resource = preload("res://data/world/city_parkour.tres")
var parkour: ParkourMotor = ParkourMotor.new()

func _ready() -> void:
	super._ready()
	parkour.profile = parkour_profile
	grapple.responsive_parkour = true
	floor_snap_length = 0.3 # PLACEHOLDER: follows the district ramp without snapping a jump.
	floor_constant_speed = true
	if printer != null:
		printer.process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta: float) -> void:
	parkour.prepare(self)
	# Terrain snap is a walking aid, not an extra tether during a grapple or jump.
	floor_snap_length = 0.3 if state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK] else 0.0
	super._physics_process(delta)
	# Walking off a roof must use airborne controls/gravity, never a grounded jump in midair.
	if not on_ground() and velocity.y < -0.01 and state in [State.IDLE, State.WALK, State.CROUCH, State.BLOCK]:
		_set_state(State.JUMP)
	# One sweep per tick covers every state (ground, air, ledge, rope); duel polling never sees them.
	for action: String in sealed_actions():
		if InputRouter.buffered(player_index, action) and not control_locked:
			sealed_action.emit(action)

## The actions the city consumes right now: all four in exploration, only the enemy hook inside a lethal pocket.
func sealed_actions() -> Array[String]:
	return POCKET_SEALED_ACTIONS if lethal_pocket else SEALED_ACTIONS

func _hazy() -> bool:
	return haze != null and not lethal_pocket and haze.haze_active()

func speed_mult() -> float:
	return super.speed_mult() * (haze.walk_multiplier() if _hazy() else 1.0)

## Fighter._walk_physics with the braking rate scaled by the state (T5: «ноги не слухаються»).
func _walk_physics(delta: float, vx: float, vz: float = 0.0) -> void:
	if not _hazy():
		super._walk_physics(delta, vx, vz)
		return
	var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
	var want := Vector2(vx, vz if _free() else 0.0)
	var rate := data.ground_accel if want.length() > cur.length() - 0.001 else data.ground_decel * haze.decel_multiplier()
	var h := cur.move_toward(want, rate * delta)
	_ground_physics(delta, h.x, h.y)

func _start_move(m: MoveData, slot: String = "") -> void:
	super._start_move(m, slot)
	if _hazy():
		_track_left *= haze.tracking_multiplier()

## В1, Choko's sword «Лякає» (ADR-025 п. 6): the event draws the sword from the back the way weapon_swap does, without
## a key press; an already drawn sword stays as it is. False for Skea or when the body cannot draw now.
func draw_sword_for_event() -> bool:
	if data.id != "choko" or data.weapon_kind != "sword":
		return false
	if sword_drawn:
		return true
	if state not in [State.IDLE, State.WALK] or not on_ground() or grapple.busy():
		return false
	sword_swap_from = sword_hand
	sword_swap_drawing = true
	sword_swap_to = sword_hand
	sword_swap_frame = 0
	crouching = false
	_set_state(State.SWAP)
	_discard_swap_blocked_inputs()
	return true

func _tick_air(delta: float, intent: Dictionary) -> void:
	if not parkour.tick(self, delta, intent):
		var previous_velocity: Vector3 = velocity
		super._tick_air(delta, intent)
		parkour.after_air(self, delta, intent, previous_velocity)

func _tick_ground(delta: float, intent: Dictionary) -> void:
	if not parkour.tick_ground(self, delta, intent):
		super._tick_ground(delta, intent)

func set_control(enabled: bool) -> void:
	super.set_control(enabled)
	if not enabled and parkour != null:
		parkour.reset(self, false)

func _set_state(next: State) -> void:
	if next != State.JUMP and parkour != null:
		parkour.reset(self, false)
	super._set_state(next)

func reset_for_round(x: float, face: int) -> void:
	super.reset_for_round(x, face)
	parkour.reset(self)

func parkour_snapshot() -> Dictionary:
	return get_meta("parkour_presentation", {}).duplicate()

func _pressed(action: String) -> bool:
	if action in sealed_actions():
		return false # Consumed and reported by the end-of-tick sweep in _physics_process.
	return super._pressed(action)

## The city never pulls a fighter on a rope (ADR-023, ADR-024 п. 6): even a crouched generic grapple stays a
## parkour shot, so an enemy inside a pocket cannot be hooked by another route.
func _try_grapple(_prefer_enemy: bool) -> bool:
	return super._try_grapple(false)

func _start_flash(axis: float, jump_dash: bool = false) -> bool:
	if not super._start_flash(axis, jump_dash):
		return false
	# Fighter's duel circle does not apply to the open city; a lethal pocket holds the flash inside its own circle.
	# Collision still uses move_and_slide.
	_flash_to = _flash_from + _dash_vec * data.flash_distance
	if lethal_pocket:
		_flash_to = bound(_flash_to)
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
	# Physical world collision supplies floor and walls; the city owns fall recovery. Inside a lethal pocket the
	# pocket's soft wall holds the hero like the duel circle (the enemy pushes both bodies apart, Fighter._push_radial).
	_water_grounded = false
	if lethal_pocket and _free():
		_soft_wall()

func restart_at(point: Vector3) -> void:
	reset_for_round(point.x, 1)
	fatigue = 0.0
	global_position = point + Vector3.UP * 0.06
	_set_forward(Vector3.FORWARD)
	set_control(true)
