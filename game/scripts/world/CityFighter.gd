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
## The hunger scale (plan 2026-10-08-Survival-Hunger step 4; T5 § 3; Santos «Повний перенос»): the band's walk and dodge
## refill — in the city and in a lethal pocket alike — and no wall steps from «famished» on. Fighter and the duel never
## read it.
var hunger: CityHunger = null
## «Хміль» and «Задишка» (plan 2026-10-08-Thirst-Substances-Icons step 2; T5 Substances § 3): braking × 0.5 and no wall
## steps, or the dodge refill × 0.75 — in the city only, never inside a lethal pocket (whose entry they shut anyway).
var substances: CitySubstances = null

@export var support_probe_depth: float = 64.0 # PLACEHOLDER district safety depth.
const ParkourMotor = preload("res://scripts/world/CityParkourMotor.gd")
@export var parkour_profile: Resource = preload("res://data/world/city_parkour.tres")
var parkour: ParkourMotor = ParkourMotor.new()
## The stick's pace during a landing's land_frames tick, −1 outside one (T5 Substances § 12.3 (б); see _walk_physics):
## what Fighter._tick_ground would ask of _walk_physics without the landing — the wish at this body's walk.
var _settle_pace: float = -1.0

## ADR-028 (plan 2026-10-15-Rope-Climb-Perch-Release step 5, 15а): the city rope's grammar — hold jump to climb to the
## anchor and grip its arm, hold dodge to slide down, E with no target lets go, the rope comes back at the grip. Only this
## class sets GrappleHook.climb_enabled (T8 § 7), so Fighter._tick_grapple and the duel stay as they are.
## T8 docs/GDD/2026-10-15-Rope-Climb-Input.md § 2.2: E lets go only once no target has been shown for this many ticks.
const ROPE_STICKY_TICKS := 15
var _rope_token: int = 0
var _rope_since: int = 0
var _climb_armed: bool = false   # jump released since the attach: only a later press climbs (T8 § 2.5)
var _slide_armed: bool = false   # dodge released since the attach
var _climb_toggle: int = 0       # ROPE CLIMB · TOGGLE (T8 § 5): +1 climbing, −1 sliding, 0 neither
var _toggle_revision: int = -1
var _perched: bool = false
var _leap_armed: bool = false    # jump released since the grip began: a held climb never leaps (T8 § 2.5)
## The jump and the dodge as they were held at the end of the last tick: a key not held on the attach tick is a new press.
var _jump_held_before: bool = false
var _dodge_held_before: bool = false

func _ready() -> void:
	super._ready()
	# The district's invisible edge over its boundary walls (CityLayout.BOUNDARY_VEIL_LAYER) holds only the city body.
	collision_mask |= CityLayout.BOUNDARY_VEIL_LAYER
	parkour.profile = parkour_profile
	grapple.responsive_parkour = true
	grapple.climb_enabled = true
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
	_jump_held_before = InputRouter.held(player_index, "jump")
	_dodge_held_before = InputRouter.held(player_index, "dodge")

## The actions the city consumes right now: all four in exploration, only the enemy hook inside a lethal pocket.
func sealed_actions() -> Array[String]:
	return POCKET_SEALED_ACTIONS if lethal_pocket else SEALED_ACTIONS

func _hazy() -> bool:
	return haze != null and not lethal_pocket and haze.haze_active()

func _substance() -> bool:
	return substances != null and not lethal_pocket and substances.active()

## What the city multiplies the dodge refill by right now: the body band and «Сила» (CityHunger), «Задишка».
func dodge_regen_scale() -> float:
	return (hunger.dodge_regen_multiplier() if hunger != null else 1.0) * (substances.regen_multiplier() if _substance() else 1.0)

## What the city multiplies the ground braking by right now: «Заплутаність» or «Хміль» (never both: they do not stack).
func decel_scale() -> float:
	return (haze.decel_multiplier() if _hazy() else 1.0) * (substances.decel_multiplier() if _substance() else 1.0)

## «Сила»'s extra hang (CityParkourMotor.hang_limit): city only.
func hang_bonus_seconds() -> float:
	return hunger.hang_bonus_seconds() if hunger != null and not lethal_pocket else 0.0

## The grip on a rope anchor's arm lasts as long as the grip on a ledge: 3.0 s + «Сила» (T5 З1, Л6).
func perch_limit() -> float:
	return parkour.hang_limit(self)

## ADR-028: the city's grapple tick. The duel's Fighter._tick_grapple is the same but for the rope's own rows here.
func _tick_grapple(intent: Dictionary) -> void:
	var hook: GrappleHook = grapple
	var delta: float = get_physics_process_delta_time()
	_track_rope()
	if hook.phase == GrappleHook.Phase.PERCH:
		_tick_perch(intent, delta)
		return
	if _pressed("grapple_detach") or _pressed("block"):
		hook.detach()
		_set_state(State.JUMP if not on_ground() else State.IDLE)
		return
	var on_rope: bool = hook.attached and hook.phase in [GrappleHook.Phase.HANG, GrappleHook.Phase.CLIMB_TOP]
	if hook.phase == GrappleHook.Phase.CLIMB_TOP and not hook.perch_pose.is_empty():
		_turn_to_perch(Vector3(hook.perch_pose.facing), delta)
	if on_rope:
		hook.climb_input = _climb_input(intent) if hook.phase == GrappleHook.Phase.HANG else 0
		# Ф2а: no dodge off the city rope, the held dodge slides.
		_take_rope_presses(false)
	else:
		hook.climb_input = 0
		if _pressed("dodge") and _start_dodge(intent.axis):
			return
	if hook.attached and hook.phase == GrappleHook.Phase.HANG and _pressed("grapple_parkour"):
		if rope_e_lets_go():
			hook.let_go() # T5 Е1: the swing's velocity as it is
			_set_state(State.JUMP if not on_ground() else State.IDLE)
			return
		if hook.retarget():
			stats.grapples += 1
	if hook.phase == GrappleHook.Phase.ROPE_REACH and on_ground() and _pressed("jump"):
		velocity.y = data.jump_velocity
		_water_grounded = false
	hook.drive(delta, intent.grapple_held or hook.action == "grapple_parkour", intent.jump_held)
	if not hook.busy() or hook.recovering():
		_set_state(State.JUMP if not on_ground() else State.IDLE)

## The presses the rope takes on its tick so that none fires after the release (T8 § 2.1): on the rope the dodge (the
## held dodge slides) and the signature dash (T8 § 3); on an anchor's arm the dash only — the dodge dodges off it (T8
## § 1), the dash means nothing there and used to fire after the drop (Skea's flash, T8 acceptance 2026-10-15 ТЗ 6).
func _take_rope_presses(on_arm: bool) -> void:
	if not on_arm:
		InputRouter.buffered(player_index, "dodge")
	InputRouter.buffered(player_index, "dash")

## The pull-up turns the hero toward the arm he is about to grip (_tick_perch then keeps him facing it) at the drawn body's
## turn rate: the grip's tick used to flip him 100–180° at once (T6 acceptance 2026-10-15 § 9 п. 2). Presentation of the
## facing only — the pull-up's path and the capsule do not depend on it.
func _turn_to_perch(facing: Vector3, delta: float) -> void:
	var now := Vector3(forward.x, 0.0, forward.z)
	var want := Vector3(facing.x, 0.0, facing.z)
	if now.length() < 0.001 or want.length() < 0.001:
		return
	var angle: float = now.normalized().signed_angle_to(want.normalized(), Vector3.UP)
	var limit: float = deg_to_rad(HeroBodyMotion.BODY_TURN_RATE) * delta
	_set_forward(now.normalized().rotated(Vector3.UP, clampf(angle, -limit, limit)))

## T8 § 2.2, T5 Е1–Е2: E does what the screen shows. A rope in the hand's reach or a shown target — the transfer (denied
## when it no longer holds); E lets go only when no target has been shown for ROPE_STICKY_TICKS. Read-only (the HUD's
## «E: let go» asks the same).
func rope_e_lets_go() -> bool:
	if grapple.reusable_rope() != 0:
		return false
	var aim: HarpoonAim = _harpoon_aim()
	if aim == null:
		return true
	if not String(aim.published.get("target_id", "")).is_empty():
		return false
	return aim.ticks_since_target() >= ROPE_STICKY_TICKS

func _harpoon_aim() -> HarpoonAim:
	if not is_inside_tree():
		return null
	var camera := get_viewport().get_camera_3d()
	return camera.get_meta("harpoon_aim") as HarpoonAim if camera != null and camera.has_meta("harpoon_aim") else null

## A new hang (a shot, a transfer or a catch) re-arms the climb and gives back the air dodge (T5 § 2: one per rope, as on
## the ground); the grip on an arm re-arms the leap.
func _track_rope() -> void:
	var hook: GrappleHook = grapple
	var token: int = hook._deployed_token if hook.attached and hook.phase == GrappleHook.Phase.HANG else 0
	if token != 0 and token != _rope_token:
		# The attach happened on the last tick: a key not held then is a press after it (T8 § 2.5).
		_rope_token = token
		_rope_since = InputRouter.frame() - 1
		_climb_armed = not _jump_held_before
		_slide_armed = not _dodge_held_before
		_climb_toggle = 0
		_dodge_air_used = false
	elif token == 0 and hook.phase != GrappleHook.Phase.CLIMB_TOP:
		_rope_token = 0
	if hook.phase == GrappleHook.Phase.PERCH and not _perched:
		_perched = true
		_leap_armed = false
		_climb_toggle = 0
	elif hook.phase != GrappleHook.Phase.PERCH:
		_perched = false

## +1 climb, −1 slide, 0 neither (both held is neither, T5 § 2). HOLD: the held key after a press made after the attach;
## TOGGLE (T8 § 5): a press starts, the same press stops, the other key switches; a menu or the pause stops it.
func _climb_input(intent: Dictionary) -> int:
	var revision: int = InputRouter.press_history_revision(player_index)
	if revision != _toggle_revision:
		_toggle_revision = revision
		_climb_toggle = 0
	var jump_held: bool = intent.jump_held
	var dodge_held: bool = InputRouter.held(player_index, "dodge")
	if not jump_held:
		_climb_armed = true
	if not dodge_held:
		_slide_armed = true
	if InputRouter.rope_climb == "toggle":
		if _fresh_press("jump"):
			_climb_toggle = 0 if _climb_toggle > 0 else 1
		if _fresh_press("dodge"):
			_climb_toggle = 0 if _climb_toggle < 0 else -1
		return _climb_toggle
	var up: bool = jump_held and _climb_armed
	var down: bool = dodge_held and _slide_armed
	if up == down:
		return 0
	return 1 if up else -1

## A buffered press of `action` made on or after the attach: taken (consumed) either way.
func _fresh_press(action: String) -> bool:
	var age: int = InputRouter.buffered_age(player_index, action)
	if age < 0 or age > InputRouter.BUFFER_FRAMES:
		return false
	var fresh: bool = InputRouter.frame() - age >= _rope_since
	InputRouter.buffered(player_index, action)
	return fresh

## The grip on a rope anchor's arm (ADR-028 п. 3; T5 § 3; T8 § 1): Z, F / L or X drops, dodge dodges off it as off a
## ledge, E fires at the next anchor (no target shown — drops), a new jump press leaps with the stick (away from the
## support without it).
func _tick_perch(intent: Dictionary, delta: float) -> void:
	var hook: GrappleHook = grapple
	_take_rope_presses(true)
	if not intent.jump_held:
		_leap_armed = true
	if not hook.perch_pose.is_empty():
		_set_forward(Vector3(hook.perch_pose.facing))
	if _pressed("grapple_detach") or _pressed("block") or intent.crouch:
		hook.let_go()
		_set_state(State.JUMP)
		return
	if _pressed("dodge") and _start_dodge(intent.axis):
		return
	if _pressed("grapple_parkour"):
		if rope_e_lets_go():
			hook.let_go()
			_set_state(State.JUMP)
			return
		if hook.perch_shot() != GrappleHook.Target.NONE:
			stats.grapples += 1
			hook.drive(delta, true, false)
			if not hook.busy() or hook.recovering():
				_set_state(State.JUMP if not on_ground() else State.IDLE)
			return
	if _leap_armed and _pressed("jump"):
		var profile: CityParkourProfile = parkour.profile
		var direction: Vector3 = perch_leap_direction(Vector3(_wish.x, 0.0, _wish.z))
		hook.leap_from_perch(direction * profile.wall_kick_out_speed + Vector3.UP * profile.wall_kick_up_speed)
		_set_state(State.JUMP)
		_set_forward(direction)
		parkour.begin_leap(self, direction)
		return
	hook.drive(delta, true, false)
	if not hook.busy():
		_set_state(State.JUMP if not on_ground() else State.IDLE)

func speed_mult() -> float:
	return super.speed_mult() * (haze.walk_multiplier() if _hazy() else 1.0) * (hunger.walk_multiplier() if hunger != null else 1.0)

## Fighter._tick_dodge_stamina with the refill scaled by the hunger band (T5 § 3); the pause after a dodge, the cost and
## the invulnerability stay exactly as they are.
func _tick_dodge_stamina(delta: float) -> void:
	if hunger == null and not _substance():
		super._tick_dodge_stamina(delta)
		return
	if control_locked or state == State.KO or dodging:
		return
	if _dodge_regen_wait > 0.0:
		_dodge_regen_wait = maxf(0.0, _dodge_regen_wait - delta)
		return
	var previous: float = dodge_stamina
	dodge_stamina = minf(dodge_stamina_max(), dodge_stamina + dodge_profile().stamina_regen * dodge_regen_scale() * delta)
	if dodge_stamina != previous:
		dodge_stamina_changed.emit(dodge_stamina, dodge_stamina_max())

## CityParkourMotor asks before a vertical or side wall run (T5 § 3: none from «famished» on, none in «Хміль»).
func wall_run_allowed() -> bool:
	return (hunger == null or hunger.wall_run_allowed()) and (not _substance() or substances.wall_run_allowed())

## H = 0 (CityHunger): the body drops with the existing KO presentation — no damage, no blood, no knocked_out signal.
## restart_at at the safe point clears it.
func collapse_from_hunger() -> void:
	if grapple.busy():
		grapple.detach()
	set_control(false)
	velocity = Vector3(0.0, minf(velocity.y, 0.0), 0.0)
	if GameState.use_ragdoll:
		_spawn_ragdoll(Vector3.ZERO, false)
	_set_state(State.KO)

## This body's walking pace without a city state: walk_speed × Fighter.speed_mult() (fatigue, the duel's own factors)
## × the hunger band's walk — never the haze's walk × 0.85 (T5 docs/GDD/2026-10-09-Rope-Pull-And-Jump-Arc-Numbers.md
## Х1, § 3.2: a hungry body is compared with a hungry body). The edge of variant A in _walk_physics.
func sober_pace() -> float:
	return data.walk_speed * super.speed_mult() * (hunger.walk_multiplier() if hunger != null else 1.0)

## Fighter._walk_physics with the braking rate scaled by the state (T5: «ноги не слухаються») — below walking pace only.
## Above sober_pace() (what is left of a dash or a landing) the full ground_decel brakes, exactly as without the state,
## so neither «Хміль» nor «Заплутаність» carries momentum beyond a sober body (T4 audit 2026-10-08 RED п. 1; plan
## 2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum step 3, variant A).
## And the state's scale brakes only when the player asks the body to slow down — the stick's own pace below the body's
## speed (T5 docs/GDD/2026-10-08-Substances-And-Nutrition.md § 12.3 (б); T4 audit 2026-10-14 п. 6). In a landing's
## land_frames ticks Fighter brakes toward zero whatever the stick says; with the stick still holding at least the
## body's speed that braking is the full ground_decel, as sober. Let go, and the state's slower stop stays.
func _walk_physics(delta: float, vx: float, vz: float = 0.0) -> void:
	if not _hazy() and not _substance():
		super._walk_physics(delta, vx, vz)
		return
	var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
	var want := Vector2(vx, vz if _free() else 0.0)
	var rate := data.ground_accel
	if want.length() <= cur.length() - 0.001:
		var asked: float = maxf(want.length(), _settle_pace)
		var player_slows: bool = asked <= cur.length() - 0.001
		rate = data.ground_decel if cur.length() > sober_pace() or not player_slows else data.ground_decel * decel_scale()
	var h := cur.move_toward(want, rate * delta)
	_ground_physics(delta, h.x, h.y)


## The ground speed the stick asks for right now: Fighter._walk_free's travel (free move) or its WALK branch (the plane).
func _stick_pace(intent: Dictionary) -> float:
	if _free():
		return _wish.length() * data.walk_speed * speed_mult() * water_walk_mult() if _wish.length() > 0.1 else 0.0
	if absf(intent.axis) <= 0.1:
		return 0.0
	var forward_walk: bool = signf(intent.axis) == float(facing)
	return absf(intent.axis) * (data.walk_speed if forward_walk else data.back_walk_speed) * speed_mult() * water_walk_mult()

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
		# T5 Substances § 12.3 (б): a landing's settle ticks tell _walk_physics what the stick asks for.
		_settle_pace = _stick_pace(intent) if land_lag > 0 and (_hazy() or _substance()) else -1.0
		super._tick_ground(delta, intent)
		_settle_pace = -1.0

func set_control(enabled: bool) -> void:
	super.set_control(enabled)
	if not enabled and parkour != null:
		parkour.reset(self, false)

func _set_state(next: State) -> void:
	if next != State.JUMP and parkour != null:
		parkour.reset(self, false)
	if next != State.GRAPPLE:
		_rope_token = 0 # the next hang, even on the same rope, is a new attach (T8 § 2.5)
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

## T1 on T6's acceptance 2026-10-15 § 9 п. 5: the leap off an anchor's arm never carries the body through the arm or its
## ceramic cap (they have no collider; along the arm the torso passed them for 5–7 ticks). No stick: square to the arm, away
## from it — the side the hero hangs on (−facing). A stick: projected so that it leaves the arm — its part across the arm,
## away from it, at least PERCH_LEAP_ACROSS (a stick along the arm or toward it keeps its part along the arm as given and
## gets that much away; toward the arm the torso crossed the arm for 1–3 ticks). Horizontal and unit; the speeds stay T5's (З3).
## PLACEHOLDER (the rule is T5's / T8's to set, the measure T6's).
const PERCH_LEAP_ACROSS: float = 0.5
func perch_leap_direction(flat: Vector3) -> Vector3:
	var hook: GrappleHook = grapple
	var away := -Vector3(hook.perch_pose.get("facing", forward))
	away = Vector3(away.x, 0.0, away.z).normalized()
	if flat.length() < parkour.profile.minimum_kick_away:
		return away
	var wanted := flat.normalized()
	var across := wanted.dot(away)
	if across >= PERCH_LEAP_ACROSS:
		return wanted
	# The part along the arm as the stick gave it, the part across raised to PERCH_LEAP_ACROSS away from the arm.
	return (wanted - away * across + away * PERCH_LEAP_ACROSS).normalized()

## The HUD's «Release …, then press it to leap» (T8 § 4): a jump released since the grip began.
func perch_leap_armed() -> bool:
	return _leap_armed
