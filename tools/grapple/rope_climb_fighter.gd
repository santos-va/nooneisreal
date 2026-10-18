extends CityFighter
## Negative controls for the city rope's guards on the hero's side (plan 2026-10-15-Rope-Climb-Perch-Release step 5,
## 15а). Never used by the game: CityWorld runs this script only when a fixture sets CityWorld.fighter_script, or a fixture
## puts it on a Fighter scene itself, before the body enters the tree. The mutation is read from the engine meta
## "rope_climb_mutation" (empty: CityFighter byte for byte in behaviour, with the hook's own script).
##   drop_on_flicker — T5 § 8: E lets go as soon as this tick's packet has no target, though one was shown 3 ticks ago
##                     (the 15-tick stickiness gone);
##   stay_on_empty   — T5 § 8: E never lets go: with no target shown for the whole window the hero still hangs;
##   snap            — T6 acceptance 2026-10-15 § 9 п. 2: the pull-up does not turn the hero toward the arm, so the grip's
##                     first tick flips his facing (15а as T6 saw it);
##   short_window    — T5 Е2 (≥ 6): the stickiness 5 ticks instead of 15 (T4 audit 15а Y1);
##   zero_v          — T5 Е1: E's let-go stops the swing (velocity zero) instead of keeping it (T4 audit 15а RED-2 б);
##   leap_along      — T6 acceptance 2026-10-15 § 9 п. 5: 15а's leap — the stick as it is, no stick along the arm;
##   rope_buffer     — T8 acceptance 2026-10-15 ТЗ 5 (N2): the city rope's tick no longer takes the dodge's press (it
##                     fires after the release);
##   perch_flash     — the same, ТЗ 6: the grip on an arm no longer takes the dash's press (Skea's flash fires after
##                     the drop, as before the fix);
##   pad_dash        — the same, ТЗ 4: the slide reads the held dash too (Y + X slides — P3);
##   hang_flash      — T4 re-audit 15а Y-A: the rope's tick takes the dodge's press but no longer the dash's (Skea's flash
##                     fires after the let-go; T4's product mutant `hang_dash_kept`); the grip still takes it;
##   anything in rope_climb_mutants.gd — the hook's script becomes that mutant with the same mutation.
const HOOK_MUTATIONS: Array[String] = ["noreq", "perpetual", "twosided", "boost", "overlong", "stuck", "double", "far", "hung", "transfer_skip", "reel_range", "reel_right", "tail_stays", "instant", "mute_deny"]
var mutation: String = ""


func _ready() -> void:
	mutation = String(Engine.get_meta("rope_climb_mutation", ""))
	if mutation in HOOK_MUTATIONS:
		var node := get_node("GrappleHook")
		node.set_script(load((get_script() as Script).resource_path.get_base_dir().path_join("rope_climb_mutants.gd")))
		node.set("mutation", mutation)
	super._ready()


func _turn_to_perch(facing: Vector3, delta: float) -> void:
	if mutation == "snap":
		return
	super._turn_to_perch(facing, delta)


func _tick_grapple(intent: Dictionary) -> void:
	var hanging: bool = grapple.attached
	super._tick_grapple(intent)
	if mutation == "zero_v" and hanging and not grapple.attached and grapple.phase == GrappleHook.Phase.IDLE:
		velocity = Vector3.ZERO


func _take_rope_presses(on_arm: bool) -> void:
	if mutation == "rope_buffer" and not on_arm:
		InputRouter.buffered(player_index, "dash")
		return
	if mutation == "perch_flash" and on_arm:
		return
	if mutation == "hang_flash" and not on_arm:
		InputRouter.buffered(player_index, "dodge")
		return
	super._take_rope_presses(on_arm)


func _climb_input(intent: Dictionary) -> int:
	var input: int = super._climb_input(intent)
	if mutation == "pad_dash" and input == 0 and InputRouter.rope_climb == "hold" and not intent.jump_held and InputRouter.held(player_index, "dash"):
		return -1
	return input


func perch_leap_direction(flat: Vector3) -> Vector3:
	if mutation == "leap_along":
		return flat.normalized() if flat.length() >= parkour.profile.minimum_kick_away else Vector3(grapple.perch_pose.get("away", -forward))
	return super.perch_leap_direction(flat)


func rope_e_lets_go() -> bool:
	if mutation == "short_window":
		var aim: HarpoonAim = _harpoon_aim()
		if grapple.reusable_rope() != 0:
			return false
		return aim == null or (String(aim.published.get("target_id", "")).is_empty() and aim.ticks_since_target() >= 5)
	if mutation == "stay_on_empty":
		return false
	if mutation == "drop_on_flicker":
		var aim: HarpoonAim = _harpoon_aim()
		return grapple.reusable_rope() == 0 and (aim == null or String(aim.published.get("target_id", "")).is_empty())
	return super.rope_e_lets_go()
