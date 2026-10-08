class_name CityThirst
extends Node
## The city's thirst scale W (plan 2026-10-08-Thirst-Substances-Icons step 1; T5 docs/GDD/2026-10-08-Thirst-Numbers.md
## § 2–7, T8 06-UI-UX § «Спрага, стани речовин і іконки предметів», ADR-026 п. 3). W runs 100 → 0 in hundredths per
## hero in CityProgress (an optional field; old saves read as 100). Every number here is a PLACEHOLDER (T5).
##   * One clock with H: CityHunger.step_frame steps W too, so W stands exactly where H stands (the pause, a conversation
##     or modal, the lethal pocket, the collapse, a scripted run). −1 hundredth every `decay_frames` frames (3.0 a minute).
##   * Bands as H's: quenched > 50 ≥ thirsty > 25 ≥ parched > 10 ≥ faint > 0. W has no effects of its own: the body takes
##     the worse of the two bands (CityHunger.body_band_index, T5 § 3.2 «гірший із двох», never the product), so the
##     dodge refill, the walk, the wall steps and the one hp tick all come from that band.
##   * No water source in the world (CityDistrict.water_pump), no thirst: W stays 100 and the clock never moves W
##     (T5 § 4: otherwise a hero with no token could quench it only with a paid drink).
##   * W = 0 is CityHunger's one collapse; on waking W = max(W, 30) (T5 § 5).
##   * Water from the pump: free, W → 100, H unchanged; it lets «Хміль» and «Задишка» fade and cancels the hangover
##   (CitySubstances); «Заплутаність» stays (only the sage tea clears it).
signal band_changed(band: String, previous: String)
signal drank(source: String, gained: int)

const FULL := 10000
const BANDS: Array[String] = ["quenched", "thirsty", "parched", "faint"]

@export var decay_frames: int = 12      # T5 § 2: 3600 / 12 = 300 hundredths = 3.0 a minute
@export var thirsty_at: int = 5000      # T5 § 2: ≤ 50
@export var parched_at: int = 2500      # ≤ 25
@export var faint_at: int = 1000        # ≤ 10
@export var wake_w: int = 3000          # T5 § 5: W = max(W, 30) after the collapse
@export var hangover_drop: int = 1500   # T5 § 7 (Р6′): W − 15 at the natural end of «Хміль» …
@export var hangover_floor: int = 1100  # … never into faint: max(W − 15, min(W, 11))

var world: Node
var progress: CityProgress
## The water source (CityDistrict.water_pump). Null: thirst never runs.
var source: CityWaterPump
## CityHunger.running at setup (false in a scripted run) and a water source in the world.
var running: bool = false
var centi: int = FULL
## «Хміль», «Задишка» and the hangover (CitySubstances, block 2 of the plan); null until the world binds it.
var substances: Node = null
var _decay_left: int = 12
var _band: int = 0


func setup(owner_world: Node, clock_running: bool) -> void:
	world = owner_world
	progress = world.get("progress")
	var district: Node = world.get("district")
	source = district.get("water_pump") as CityWaterPump if district != null else null
	running = clock_running and has_source()
	centi = progress.thirst_centi() if running and progress != null else FULL
	_band = band_index()
	_decay_left = decay_frames


func has_source() -> bool:
	return source != null and is_instance_valid(source)


## Fixtures: W from `level` hundredths with the clock running — only where a water source exists (the gate holds).
func enable_for_test(level: int) -> void:
	running = has_source()
	set_centi(level if running else FULL)
	_decay_left = decay_frames


## One frame of the shared clock (CityHunger.step_frame calls it, so simulate() covers W too).
func step_frame() -> void:
	if not running:
		return
	_decay_left -= 1
	if _decay_left <= 0:
		_decay_left = decay_frames
		if centi > 0:
			set_centi(centi - 1)


# --- reading ------------------------------------------------------------------------------------------------------
func value() -> float:
	return float(centi) / 100.0


## The whole percent the HUD shows: rounded up, so a word and its number never disagree (50.01 → 51, quenched).
func percent() -> int:
	return ceili(float(centi) / 100.0)


func band_index() -> int:
	if centi <= faint_at:
		return 3
	if centi <= parched_at:
		return 2
	if centi <= thirsty_at:
		return 1
	return 0


func band() -> String:
	return BANDS[band_index()]


## The band the body takes from W: 0 while the scale does not run (no source, a scripted run).
func body_band_index() -> int:
	return band_index() if running else 0


func dry() -> bool:
	return running and centi <= 0


# --- writing ------------------------------------------------------------------------------------------------------
func set_centi(level: int) -> void:
	centi = clampi(level, 0, FULL)
	var now: int = band_index()
	if now != _band:
		var previous: String = BANDS[_band]
		_band = now
		band_changed.emit(BANDS[now], previous)
		persist()


func persist() -> void:
	if running and progress != null:
		progress.set_thirst(centi)


## A drink that adds `amount` hundredths (the tea +30, T5 § 4). Never above 100; nothing while the scale is off.
func gain(amount: int) -> int:
	if not running or amount <= 0:
		return 0
	var before: int = centi
	set_centi(mini(FULL, centi + amount))
	persist()
	return centi - before


## The collapse woke the hero: W = max(W, 30) (T5 § 5: a scale near zero is lifted, a full one is left alone).
func wake() -> void:
	if not running:
		return
	set_centi(maxi(centi, wake_w))
	_decay_left = decay_frames
	persist()


## The natural end of «Хміль» without a drink (T5 § 7, Р6′): W = max(W − 15, min(W, 11)); H is not touched.
func hangover() -> int:
	if not running:
		return 0
	var before: int = centi
	set_centi(maxi(centi - hangover_drop, mini(centi, hangover_floor)))
	persist()
	return before - centi


# --- the pump -----------------------------------------------------------------------------------------------------
## A grounded, free hero within hand reach of the spout with a clear line to it (as CityWorld.can_inspect_story).
func can_drink(player: CityFighter) -> bool:
	if not has_source() or player == null or get_tree().paused or InputRouter.ui_suppressed() or player.control_locked \
			or player.frozen_frames > 0 or player.hitstop_frames > 0 or not player.on_ground() or player.grapple.busy() \
			or player.lethal_pocket:
		return false
	if player.state not in [Fighter.State.IDLE, Fighter.State.WALK, Fighter.State.CROUCH, Fighter.State.BLOCK]:
		return false
	var spout: Vector3 = source.spout_point()
	var origin: Vector3 = player.global_position + Vector3.UP * 1.1
	var offset: Vector3 = spout - origin
	if not offset.is_finite() or absf(offset.y) > CityWaterPump.REACH_VERTICAL or Vector2(offset.x, offset.z).length() > CityWaterPump.REACH:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, spout, 1, [player.get_rid()])
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == source.body


## Free water (T5 § 4): W → 100, H and tokens unchanged; «Хміль» and «Задишка» fade (10 s) and the hangover is off.
## Returns the hundredths of W gained.
func drink_water(source_id: String = "pump") -> int:
	var before: int = centi
	if running:
		set_centi(FULL)
		persist()
	if substances != null:
		substances.call("drink")
	drank.emit(source_id, centi - before)
	return centi - before


func _exit_tree() -> void:
	persist()
