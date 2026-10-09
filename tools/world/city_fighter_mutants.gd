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
var mutation: String = ""


func _in_state() -> bool:
	return _hazy() or _substance()


func _walk_physics(delta: float, vx: float, vz: float = 0.0) -> void:
	if mutation == "carry" and _in_state():
		var cur := Vector2(velocity.x, velocity.z if _free() else 0.0)
		var want := Vector2(vx, vz if _free() else 0.0)
		var rate := data.ground_accel if want.length() > cur.length() - 0.001 else data.ground_decel * decel_scale()
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
