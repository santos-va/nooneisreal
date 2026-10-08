class_name CitySubstances
extends Node
## «Хміль» (alcohol) and «Задишка» (a cigarette) — the substance states of plan 2026-10-08-Thirst-Substances-Icons step 2
## (ADR-026 п. 1; T5 docs/GDD/2026-10-08-Substances-And-Nutrition.md § 2–4, § 7; T8 06-UI-UX § «Спрага…» п. 3–4). Data
## profiles on CityHaze's pattern, never new fighter states. Session only, never saved. Every number is a PLACEHOLDER.
##   * A price, never a gain (М1): «Хміль» 120 s — braking × 0.5 and no wall steps; «Задишка» 60 s — the dodge refills
##     × 0.75. Walk, jump, hang, hook, damage, frames: as they are. Nothing on the screen (М4): no FOV, no vignette, no
##     shake — only the HUD line.
##   * One at a time (М6): no state starts while another one (or «Заплутаність») lasts. City only (М5): CityFighter reads
##     it outside a lethal pocket only, and the pocket's entry stays shut while it lasts (CityWorld).
##   * City time like CityHaze (stands in the pause), ramp-in 3 s, fade-out 10 s. Water or any drink lets it fade (10 s);
##     a drink during «Хміль» also cancels the hangover. The natural end of «Хміль» without a drink: the hangover on W
##     (CityThirst.hangover, T5 Р6′: W −15, never into faint; H untouched).
##   * `drugs` Off (ContentSettings): clear() — gone at once, no fade, no hint, no hangover (T8 п. 4).
signal started(id: String)
signal fading(id: String)
signal ended(id: String, natural: bool)
## The hangover hit W (`dropped` hundredths); `crossed` when it took W over a band edge (then the band's own hint speaks,
## otherwise the HUD says DRY MOUTH).
signal hangover(dropped: int, crossed: bool)

const IDS: Array[String] = ["tipsy", "winded"]

@export var ramp_in_seconds: float = 3.0       # as CityHaze (T5 § 3.2)
@export var fade_out_seconds: float = 10.0     # as CityHaze; a drink leaves at most this
@export var tipsy_seconds: float = 120.0       # T5 § 3.2: 120 s / 7200 frames
@export var tipsy_decel_scale: float = 0.5     # T5 § 3.2: ground_decel × 0.5
@export var winded_seconds: float = 60.0       # T5 § 3.2: 60 s / 3600 frames
@export var winded_regen_scale: float = 0.75   # T5 § 3.2: the dodge refill × 0.75

var thirst: CityThirst = null
var haze: CityHaze = null
var state: String = ""            # "" | "tipsy" | "winded"
var _remaining: float = 0.0
var _elapsed: float = 0.0
var _fading_sent: bool = false
var _drank: bool = false           # a drink during «Хміль»: no hangover


func active() -> bool:
	return not state.is_empty() and _remaining > 0.0


func remaining() -> float:
	return _remaining if active() else 0.0


## Any substance state the hero is in, «Заплутаність» included (М6: they never stack).
func any_state() -> bool:
	return active() or (haze != null and haze.haze_active())


func duration(id: String) -> float:
	return tipsy_seconds if id == "tipsy" else winded_seconds


## Starts `id` ("tipsy" | "winded"). False while any state lasts (М6) or for an unknown id.
func begin(id: String) -> bool:
	if not id in IDS or any_state():
		return false
	state = id
	_remaining = duration(id)
	_elapsed = 0.0
	_fading_sent = false
	_drank = false
	started.emit(id)
	return true


## Water or a drink (T5 § 4): whatever is left becomes at most the fade-out; «Хміль» loses its hangover.
func drink() -> bool:
	if not active():
		return false
	if state == "tipsy":
		_drank = true
	if _remaining <= fade_out_seconds:
		return false
	_remaining = fade_out_seconds
	_announce_fading()
	return true


## Gone at once (`drugs` Off, a restart of the walk): no fade, no hint, no hangover.
func clear() -> void:
	if not active():
		state = ""
		return
	var id: String = state
	state = ""
	_remaining = 0.0
	ended.emit(id, false)


## 0 → 1 over the ramp-in, 1 on the plateau, → 0 over the last fade_out_seconds (CityHaze.weight). No pulse.
func weight() -> float:
	if not active():
		return 0.0
	var rise: float = clampf(_elapsed / maxf(ramp_in_seconds, 0.001), 0.0, 1.0)
	var fall: float = clampf(_remaining / maxf(fade_out_seconds, 0.001), 0.0, 1.0)
	return smoothstep(0.0, 1.0, rise) * smoothstep(0.0, 1.0, fall)


func decel_multiplier() -> float:
	return lerpf(1.0, tipsy_decel_scale, weight()) if state == "tipsy" and active() else 1.0


func regen_multiplier() -> float:
	return lerpf(1.0, winded_regen_scale, weight()) if state == "winded" and active() else 1.0


## «Хміль» switches the wall steps off for its whole length (the same hook as «famished», T5 § 3.3).
func wall_run_allowed() -> bool:
	return not (state == "tipsy" and active())


func _physics_process(delta: float) -> void:
	step(delta)


## One tick of city time (fixtures call it to cover 120 s without 7200 engine frames).
func step(delta: float) -> void:
	if not active():
		return
	_elapsed += delta
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= fade_out_seconds:
		_announce_fading()
	if _remaining <= 0.0:
		var id: String = state
		state = ""
		if id == "tipsy" and not _drank and thirst != null:
			var before: int = thirst.band_index()
			var dropped: int = thirst.hangover()
			hangover.emit(dropped, thirst.band_index() > before)
		ended.emit(id, true)


func _announce_fading() -> void:
	if not _fading_sent:
		_fading_sent = true
		fading.emit(state)
