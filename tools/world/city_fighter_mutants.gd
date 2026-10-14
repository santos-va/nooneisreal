extends CityFighter
## Negative controls for tools/world/city_substances_check.gd (plan 2026-10-09-Rope-Pull-Jump-Arc-Substance-Momentum
## step 3; T4 audit 2026-10-08-Thirst-Substances-Icons-Review п. 1, mutations U1–U3). Never used by the game: CityWorld
## runs this script only when a fixture sets CityWorld.fighter_script before the world enters the tree.
## Each mutation is one product change that gives a body in a city state («Заплутаність», «Хміль», «Задишка») something
## a sober body does not have; without a mutation the class is CityFighter, byte for byte in behaviour.
##   carry  — CityFighter._walk_physics frozen as it was before the fix (e6c2206): the state's braking scale at every
##            speed, so what is left of a dash rolls on beyond walking pace;
##   accel  — U1: ground_accel × 1.5 while in a state;
##   hang   — U2: hang_bonus_seconds + 1 s while in a state;
##   dodges — U3: dodge_stamina_max() × 1.25 while in a state.
## The state-blind route (city_substances_check.gd --part=route, B13; plan 2026-10-14 step 6; T4 audit 2026-10-09 п. 3,
## U5/U6), each a gain of the route's own moves while in a state:
##   jump    — U5: the take-off speed × 1.08 (a jump from the ground);
##   float   — the jump's gravity 15 % lighter in the air (the same take-off, a longer flight);
##   pull    — U6: the rope pulls 1.25 × faster (GrappleHook.parkour_pull_speed);
##   target  — the rope's target length 1 m shorter on each hang (the body pulled higher);
##   vault   — the vault 20 % shorter (CityParkourProfile.vault_seconds, on this body's own copy of the profile);
##   wallrun — the wall run 25 % faster along and up (wall_along_speed, wall_up_speed, on the same copy).
## T5 docs/GDD/2026-10-08-Substances-And-Nutrition.md § 12.3 (б) rolled back (T4 audit 2026-10-14 п. 6):
##   settle  — CityFighter._walk_physics as it was before (variant A only): in a landing's land_frames ticks the state's
##             braking scale applies even with the stick holding walking pace (strict `> sober_pace()`, no stick).
const JUMP_GAIN: float = 1.08
const FLOAT_LIFT: float = 0.15
const PULL_GAIN: float = 1.25
const TARGET_LIFT: float = 1.0
const VAULT_SCALE: float = 0.8
const WALL_GAIN: float = 1.25
var mutation: String = ""
var _base_pull: float = -1.0
var _target_hang: bool = false
var _base_profile: Resource


func _in_state() -> bool:
	return _hazy() or _substance()


func _set_state(next: State) -> void:
	if mutation == "jump" and next == State.JUMP and _in_state() and is_equal_approx(velocity.y, data.jump_velocity):
		velocity.y *= JUMP_GAIN
	super._set_state(next)


func _physics_process(delta: float) -> void:
	if mutation == "float" and state == State.JUMP and _in_state() and not on_ground():
		velocity.y += GRAVITY * (data.fall_gravity_mult if velocity.y < 0.0 else 1.0) * FLOAT_LIFT * delta
	if mutation == "pull":
		if _base_pull < 0.0:
			_base_pull = grapple.parkour_pull_speed
		grapple.parkour_pull_speed = _base_pull * (PULL_GAIN if _in_state() else 1.0)
	if mutation == "target":
		if grapple.attached and grapple.phase == GrappleHook.Phase.HANG and _in_state() and not _target_hang:
			_target_hang = true
			grapple._hang_start_length = maxf(2.0, grapple._hang_start_length - TARGET_LIFT)
		elif not grapple.attached:
			_target_hang = false
	if mutation in ["vault", "wallrun"]:
		if _base_profile == null:
			_base_profile = parkour.profile
			parkour.profile = _base_profile.duplicate()
		var on: bool = _in_state()
		parkour.profile.vault_seconds = _base_profile.vault_seconds * (VAULT_SCALE if on and mutation == "vault" else 1.0)
		parkour.profile.wall_along_speed = _base_profile.wall_along_speed * (WALL_GAIN if on and mutation == "wallrun" else 1.0)
		parkour.profile.wall_up_speed = _base_profile.wall_up_speed * (WALL_GAIN if on and mutation == "wallrun" else 1.0)
	super._physics_process(delta)


func _walk_physics(delta: float, vx: float, vz: float = 0.0) -> void:
	if mutation == "carry" and _in_state():
		var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
		var want := Vector2(vx, vz if _free() else 0.0)
		var rate := data.ground_accel if want.length() > cur.length() - 0.001 else data.ground_decel * decel_scale()
		var h := cur.move_toward(want, rate * delta)
		_ground_physics(delta, h.x, h.y)
		return
	if mutation == "settle" and _in_state():
		var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
		var want := Vector2(vx, vz if _free() else 0.0)
		var rate := data.ground_accel
		if want.length() <= cur.length() - 0.001:
			rate = data.ground_decel if cur.length() > sober_pace() else data.ground_decel * decel_scale()
		var h := cur.move_toward(want, rate * delta)
		_ground_physics(delta, h.x, h.y)
		return
	if mutation == "accel" and _in_state():
		var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
		var want := Vector2(vx, vz if _free() else 0.0)
		if want.length() > cur.length() - 0.001:
			var h := cur.move_toward(want, data.ground_accel * 1.5 * delta)
			_ground_physics(delta, h.x, h.y)
			return
	super._walk_physics(delta, vx, vz)


func hang_bonus_seconds() -> float:
	return super.hang_bonus_seconds() + (1.0 if mutation == "hang" and _in_state() else 0.0)


func dodge_stamina_max() -> float:
	return super.dodge_stamina_max() * (1.25 if mutation == "dodges" and _in_state() else 1.0)
