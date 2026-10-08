class_name CityHunger
extends Node
## The city's hunger scale (plan 2026-10-08-Survival-Hunger step 4; T5 numbers docs/GDD/2026-10-08-Hunger-Numbers.md,
## T8 HUD 06-UI-UX § «Шкала голоду в HUD міста», T7 food PROPOSAL-Food-Of-Cronshift § 3; ADR-025 п. 4).
## H runs 100 → 0, kept in hundredths (0…10000) per hero in CityProgress (an optional field; old saves read as 100).
##   * It goes down only with city play time: −1 hundredth every `decay_frames` frames (2.0 a minute). Never in the pause,
##     a conversation, a modal (InputRouter.ui_suppressed), the lethal pocket or the collapse. A scripted run (headless or
##     --script) keeps H = 100 and nothing ticks until a fixture calls enable_for_test().
##   * Bands: sated > 50 ≥ hungry > 25 ≥ famished > 10 ≥ faint > 0. Per band: the dodge stamina refills × 1 / 0.75 /
##     0.6 / 0.5, walking × 1 / 1 / 0.85 / 0.75, wall steps (vertical and side) yes / yes / no / no; city hp +1 % every
##     6 s / +1 % every 12 s / stands / −1 % every 5 s, never below the 40 % floor and never raised to it by the drain.
##     The body only — input, frames, damage and hitboxes never change (02 § Втома, ADR-016).
##   * H = 0: the body drops (the existing KO presentation, no blood), the screen goes dark, the hero wakes at the last
##     safe point (CityJourney via CityWorld.recover_to_spawn) with H = 30, hp ≥ 40 % and −min(tokens, 3).
##   * «Заплутаність» starting: H = max(min(H − 20, 45), min(H, 11)); a renewal never lowers it again.
##   * Santos «Повний перенос» (ADR-025 п. 4): the lethal pocket takes the city hp (never below the floor), the dodge
##     refill and the walk of the band; H stands in the fight; RETRY gives back the hp the hero came in with; after the
##     pocket the city hp is the one from before it. The duel, VERSUS and training never see any of this.
## Thirst (plan 2026-10-08-Thirst-Substances-Icons step 1; T5 Thirst-Numbers): W (CityThirst) runs on this same clock
## (step_frame steps it), and the body takes the worse of the two bands — B = max(band(H), band(W)), never the product —
## for the dodge refill, the walk, the wall steps and the one hp tick. H = 0 or W = 0 is one collapse: H = max(H, 30),
## W = max(W, 30), −min(tokens, 3) once (T5 § 5). The pocket takes B; RETRY the same entry.
## Healthy food (plan step 2; ADR-026 п. 2; T5 Substances § 5.2; T7 Л1 at «Шавлія»): «Вітаміни» 10 min — the city hp
## heals twice as often (sated 180, hungry 360 frames; the faint drain unchanged); «Сила» 15 min — the dodge refill × 1.2
## (with the band) and the hang +1 s in the city. Both on the hunger clock (they stand in the pause, a conversation and the
## pocket), a second dish of a class gives the full timer back (never × 1.44), both may run together, session only.
## «Сила» carries into the pocket (Santos «Повний перенос»): × 1.2 there, its timer standing; hp never grows.
## A drink (tea, uzvar, water) lets «Хміль» and «Задишка» fade and cancels the hangover (CitySubstances.drink).
## Food (T5 § 5, names T7, all PLACEHOLDER): «Відвар шавлії» 1 token +25 and W +30 (in the state: the state fades out in 10 s),
## «Житній буханець» 2 tokens +60, «Окраєць у борг» 0 tokens +30 only with no token and H ≤ 25, at most once per 15 min of
## hunger time. H never goes above 100. Every number here is a PLACEHOLDER (T5).
signal band_changed(band: String, previous: String)
signal collapsed(tokens_lost: int)
signal ate(food_id: String, gained: int)
## A food effect ran out on the hunger clock: "strength" | "vitamins".
signal effect_ended(effect: String)

const FULL := 10000
const BANDS: Array[String] = ["sated", "hungry", "famished", "faint"]

@export var decay_frames: int = 18                          # T5 § 2: 3600 / 18 = 200 hundredths = 2.0 a minute
@export var hungry_at: int = 5000                           # T5 § 2: ≤ 50
@export var famished_at: int = 2500                         # ≤ 25
@export var faint_at: int = 1000                            # ≤ 10
@export var regen_multipliers: Array[float] = [1.0, 0.75, 0.6, 0.5]   # T5 § 3: dodge stamina refill
@export var walk_multipliers: Array[float] = [1.0, 1.0, 0.85, 0.75]   # T5 § 3: walking
@export var hp_tick_frames: Array[int] = [360, 720, 0, 300] # T5 § 4: +1 % / +1 % / stands / −1 %
@export var hp_tick_ratio: float = 0.01
@export var hp_floor_ratio: float = 0.4                     # T5 § 4: the floor, 40 %
@export var collapse_h: int = 3000                          # T5 § 4: H = 30 after the collapse
@export var collapse_tokens: int = 3                        # T5 § 4: −min(tokens, 3)
@export var haze_drop: int = 2000                           # T5 § 6: H − 20 …
@export var haze_cap: int = 4500                            # … at most 45 …
@export var haze_floor: int = 1100                          # … never into faint: min(H, 11)
@export var crust_cooldown_frames: int = 54000              # T5 § 5: once per 15 min of hunger time
@export var crust_max_h: int = 2500                         # T5 § 5: only at H ≤ 25
@export var persist_frames: int = 3600                      # the save between band changes: once a minute of hunger time
@export var collapse_fall_frames: int = 90                  # the body drops; the dark comes over its second half
@export var collapse_wake_frames: int = 30                  # the dark lifts at the safe point
@export var foods: Array[Dictionary] = [
	{"id": "tea", "title": "Відвар шавлії", "gain": 2500, "price": 1, "clears_haze": true, "water": 3000, "drink": true},
	{"id": "loaf", "title": "Житній буханець", "gain": 6000, "price": 2, "icon": "rye_loaf"},
	{"id": "crust", "title": "Окраєць у борг", "gain": 3000, "price": 0, "credit": true, "icon": "rye_crust"},
	# T5 § 5.2 classes, T7 Л1 names: vitamin 1 token +15; protein snack 1 token +15; protein dish 2 tokens +40.
	# `icon`: T6's accepted cell (docs/Art/2026-10-08-Substances-And-Food-Items.md § Підсумок хвилі 2); none for the tea
	# (its cell failed criterion 2) and the cheese pastry (a copy of the pie) — they stand as text (T8 п. 5).
	{"id": "pickled_apples", "title": "Мочені яблука", "gain": 1500, "price": 1, "effect": "vitamins", "icon": "pickled_apples"},
	{"id": "uzvar", "title": "Узвар", "gain": 1500, "price": 1, "water": 3000, "drink": true, "effect": "vitamins", "icon": "uzvar"},
	{"id": "eggs", "title": "Два яйця в мундирі", "gain": 1500, "price": 1, "effect": "strength", "icon": "eggs"},
	{"id": "cheese_pastry", "title": "Пиріжок із сиром", "gain": 4000, "price": 2, "effect": "strength"},
]
@export var strength_full_frames: int = 54000               # T5 § 5.2: «Сила» 15 min of hunger time
@export var strength_regen_scale: float = 1.2               # T5 § 5.2: the dodge refill × 1.2
@export var strength_hang_bonus: float = 1.0                # T5 § 5.2: hang_seconds 3.0 → 4.0, city only
@export var vitamins_full_frames: int = 36000               # T5 § 5.2: «Вітаміни» 10 min of hunger time
@export var vitamins_period_scale: float = 0.5              # T5 § 5.2: +1 % every 180 / 360 frames instead of 360 / 720

var world: Node
var player: CityFighter
var progress: CityProgress
var lethal: CityLethalFight
var haze: CityHaze
## The thirst scale on this clock (CityWorld binds it after setup); null: H alone, as before.
var thirst: CityThirst = null
## «Хміль» and «Задишка» (CityWorld binds them): a drink lets them fade.
var substances: CitySubstances = null
var strength_left: int = 0               # frames of hunger time left of «Сила»
var vitamins_left: int = 0               # frames of hunger time left of «Вітаміни»
var running: bool = true
var centi: int = FULL
var city_hp: float = 0.0
var crust_wait: int = 0                 # frames of hunger time until Mira gives a crust again
var collapse_phase: String = ""         # "" | "fall" | "wake"
var collapse_frames: int = 0
var last_tokens_lost: int = 0
var last_collapse_cause: String = ""   # "hunger" | "thirst" | "both" — the words of the HUD's collapse hint
var collapsed_recently: bool = false    # Mira's first word after the collapse (T7 М6); session only
var _decay_left: int = 18
var _hp_band: int = -1
var _hp_frames: int = 0
var _persist_left: int = 3600
var _band: int = 0


func setup(owner_world: Node) -> void:
	world = owner_world
	player = world.get("player")
	progress = world.get("progress")
	lethal = world.get("lethal")
	haze = world.get("haze")
	city_hp = player.data.max_hp
	var graphics: Node = get_node_or_null("/root/GraphicsSettings")
	running = not (graphics != null and bool(graphics.call("scripted_run")))
	centi = progress.hunger_centi() if running and progress != null else FULL
	crust_wait = progress.crust_wait() if running and progress != null else 0
	_band = band_index()
	_reset_counters()
	if haze != null:
		haze.started.connect(_on_haze_started)
	if lethal != null:
		lethal.closed.connect(func(_reason: String) -> void: restore_city_hp())


## Fixtures: H from `level` hundredths, the clock and the effects running (saves stay as the fixture set them).
func enable_for_test(level: int) -> void:
	running = true
	collapse_phase = ""
	collapse_frames = 0
	city_hp = player.hp
	set_centi(level)
	_reset_counters()


func _reset_counters() -> void:
	_decay_left = decay_frames
	_hp_band = body_band_index()
	_hp_frames = 0
	_persist_left = persist_frames


# --- reading ------------------------------------------------------------------------------------------------------
func value() -> float:
	return float(centi) / 100.0


## The whole percent the HUD shows: rounded up, so a word and its number never disagree (50.01 → 51, sated).
func percent() -> int:
	return ceili(float(centi) / 100.0)


func band_index() -> int:
	if centi <= faint_at:
		return 3
	if centi <= famished_at:
		return 2
	if centi <= hungry_at:
		return 1
	return 0


func band() -> String:
	return BANDS[band_index()]


## The band the body takes: the worse of H's and W's (T5 Thirst-Numbers § 3.2). W counts only while thirst runs.
func body_band_index() -> int:
	return maxi(band_index(), thirst.body_band_index() if thirst != null else 0)


## The band's refill × «Сила» (T5 § 5.3: it multiplies with the band, in the city and in the pocket alike).
func dodge_regen_multiplier() -> float:
	return regen_multipliers[body_band_index()] * (strength_regen_scale if strength_left > 0 else 1.0)


## «Сила»'s extra hang in the city (CityParkourMotor.hang_limit; the shared profile is never mutated).
func hang_bonus_seconds() -> float:
	return strength_hang_bonus if strength_left > 0 else 0.0


func walk_multiplier() -> float:
	return walk_multipliers[body_band_index()]


func wall_run_allowed() -> bool:
	return body_band_index() < 2


func hp_floor() -> float:
	return player.data.max_hp * hp_floor_ratio


## The hunger clock runs only in city exploration: never paused, in a conversation or modal, in the pocket, collapsing.
func ticking() -> bool:
	return running and collapse_phase.is_empty() and not get_tree().paused and not InputRouter.ui_suppressed() \
		and not (lethal != null and lethal.active)


# --- the clock ----------------------------------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	if not running or player == null:
		return
	if not collapse_phase.is_empty():
		_tick_collapse()
		return
	if lethal != null and lethal.active:
		return
	if not is_equal_approx(player.hp, city_hp):
		player.set_round_hp(city_hp)   # a restart_at (fall, teleport) refilled hp: the city's value stands
	if ticking():
		step_frame()


## One frame of hunger time. simulate() repeats exactly this (fixtures cover 25 minutes without 90 000 engine frames).
func step_frame() -> void:
	_decay_left -= 1
	if _decay_left <= 0:
		_decay_left = decay_frames
		if centi > 0:
			set_centi(centi - 1)
	if thirst != null:
		thirst.step_frame()
	if strength_left > 0:
		strength_left -= 1
		if strength_left == 0:
			effect_ended.emit("strength")
	if vitamins_left > 0:
		vitamins_left -= 1
		if vitamins_left == 0:
			effect_ended.emit("vitamins")
	if crust_wait > 0:
		crust_wait -= 1
	_tick_hp()
	_persist_left -= 1
	if _persist_left <= 0:
		_persist_left = persist_frames
		persist()
	if (centi <= 0 or (thirst != null and thirst.dry())) and collapse_phase.is_empty():
		_begin_collapse()


func simulate(frames: int) -> void:
	for frame: int in frames:
		if not collapse_phase.is_empty():
			return
		step_frame()


func _tick_hp() -> void:
	var b: int = body_band_index()   # one tick for both scales (T5 § 3.2): never a second one for W
	if b != _hp_band:
		_hp_band = b
		_hp_frames = 0
	var period: int = hp_tick_frames[b]
	if period <= 0:
		return
	if vitamins_left > 0 and b < 3:
		period = maxi(1, roundi(float(period) * vitamins_period_scale))   # heals faster; the faint drain is untouched
	_hp_frames += 1
	if _hp_frames < period:
		return
	_hp_frames = 0
	var maximum: float = player.data.max_hp
	var step: float = maximum * hp_tick_ratio
	var before: float = city_hp
	if b == 3:
		if city_hp > hp_floor():
			city_hp = maxf(hp_floor(), city_hp - step)   # never below the floor; below it nothing drains
	elif city_hp < maximum:
		city_hp = minf(maximum, city_hp + step)
	if city_hp != before and (lethal == null or not lethal.active):
		player.set_round_hp(city_hp)


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
		progress.set_hunger(centi, crust_wait, thirst.centi if thirst != null and thirst.running else -1)


## Back from a restart (a fall from the map, the collapse, the pocket): the city hp is the one before it.
func restore_city_hp() -> void:
	if running and player != null and collapse_phase.is_empty():
		player.set_round_hp(city_hp)


# --- «Заплутаність» ------------------------------------------------------------------------------------------------
func _on_haze_started() -> void:
	if running:
		set_centi(maxi(mini(centi - haze_drop, haze_cap), mini(centi, haze_floor)))


# --- the lethal pocket (Santos «Повний перенос») ------------------------------------------------------------------
## The hp the hero enters the pocket with (and gets back on RETRY); -1 when hunger does not run (scripted, untouched).
func pocket_entry_hp() -> float:
	return maxf(city_hp, hp_floor()) if running else -1.0


const HUNGER_WORDS: Array[String] = ["", "HUNGRY", "FAMISHED", "FAINT"]
const THIRST_WORDS: Array[String] = ["", "THIRSTY", "PARCHED", "FAINT"]
const BODY_EFFECTS: Array[String] = ["", "slower stamina", "slower stamina and walk", "slower stamina and walk"]


## The words the pocket's HUD adds to the hero's line (T8 06-UI-UX § «Спрага…» п. 2, PLACEHOLDER): the worse scale's
## word and the effect of B; equal bands → both words without the effect (`FAMISHED · PARCHED`, the 644 px half of the
## band); both FAINT → one word. Empty when both are fine or nothing runs.
func pocket_status() -> String:
	if not running:
		return ""
	var food: int = band_index()
	var water: int = thirst.body_band_index() if thirst != null else 0
	if food == 0 and water == 0:
		return ""
	if food > water:
		return HUNGER_WORDS[food] + " · " + BODY_EFFECTS[food]
	if water > food:
		return THIRST_WORDS[water] + " · " + BODY_EFFECTS[water]
	if food == 3:
		return "FAINT · " + BODY_EFFECTS[3]
	return HUNGER_WORDS[food] + " · " + THIRST_WORDS[water]


## pocket_status() plus ` · STRENGTH` when «Сила» comes in with the hero (T8 п. 2); what CityLethalFight shows.
func pocket_words() -> String:
	var words: String = pocket_status()
	if running and strength_left > 0:
		words += (" · " if not words.is_empty() else "") + "STRENGTH"
	return words


# --- food at «Шавлія» ----------------------------------------------------------------------------------------------
func food(id: String) -> Dictionary:
	for entry: Dictionary in foods:
		if String(entry.id) == id:
			return entry
	return {}


## W the entry adds (0 for solid food); counted only while the world has a water source (T5 Thirst § 4).
func water_gain(entry: Dictionary) -> int:
	return int(entry.get("water", 0)) if thirst != null and thirst.has_source() else 0


## True when nothing the entry does would change anything (T8 п. 5): every scale it raises is at 100 and it shortens no
## state the hero is in. Then the counter says «ти ситий».
func _sated_for(entry: Dictionary) -> bool:
	if centi < FULL and int(entry.gain) > 0:
		return false
	if water_gain(entry) > 0 and thirst.centi < CityThirst.FULL:
		return false
	if bool(entry.get("clears_haze", false)) and haze != null and haze.haze_active() and haze.haze_remaining() > haze.fade_out_seconds:
		return false
	if bool(entry.get("drink", false)) and substances != null and substances.active() and substances.remaining() > substances.fade_out_seconds:
		return false
	return true


## What the counter shows for `id`: enabled, the reason when not (words PLACEHOLDER T7/T8), the gain and the result.
func food_state(id: String) -> Dictionary:
	var entry: Dictionary = food(id)
	if entry.is_empty():
		return {"enabled": false, "reason": "", "gain": 0, "after": centi, "price": 0, "water": 0, "water_after": 0}
	var price: int = int(entry.price)
	var tokens: int = progress.credits() if progress != null else 0
	var reason: String = ""
	var water: int = water_gain(entry)
	var water_now: int = thirst.centi if water > 0 else 0
	if _sated_for(entry):
		reason = "ти ситий"
	elif bool(entry.get("credit", false)):
		if tokens > 0:
			reason = "лише коли жетонів немає"
		elif centi > crust_max_h:
			reason = "коли FOOD ≤ %d%%" % ceili(float(crust_max_h) / 100.0)
		elif crust_wait > 0:
			reason = "Міра пригостить пізніше"
	elif tokens < price:
		reason = "бракує %d жет." % (price - tokens)
	var effect: String = String(entry.get("effect", ""))
	return {"enabled": reason.is_empty(), "reason": reason, "gain": int(entry.gain), "after": mini(FULL, centi + int(entry.gain)), "price": price,
		"water": water, "water_after": mini(CityThirst.FULL, water_now + water), "effect": effect,
		"effect_frames": strength_full_frames if effect == "strength" else (vitamins_full_frames if effect == "vitamins" else 0)}


## Buys and eats at once (no inventory). Returns {"ok", "gained", "cleared"}: cleared = the state now fades out.
func feed(id: String) -> Dictionary:
	var state: Dictionary = food_state(id)
	if not bool(state.enabled):
		return {"ok": false, "gained": 0, "cleared": false}
	var entry: Dictionary = food(id)
	if int(entry.price) > 0 and (progress == null or not progress.buy_food(int(entry.price))):
		return {"ok": false, "gained": 0, "cleared": false}
	var before: int = centi
	set_centi(centi + int(entry.gain))
	if bool(entry.get("credit", false)):
		crust_wait = crust_cooldown_frames
	var cleared: bool = bool(entry.get("clears_haze", false)) and haze != null and haze.eat()
	if water_gain(entry) > 0:
		thirst.gain(water_gain(entry))
	if bool(entry.get("drink", false)) and substances != null:
		substances.drink()
	match String(entry.get("effect", "")):
		"strength":
			strength_left = strength_full_frames   # the full timer again, never stacked
		"vitamins":
			vitamins_left = vitamins_full_frames
	persist()
	ate.emit(id, centi - before)
	return {"ok": true, "gained": centi - before, "cleared": cleared}


# --- the collapse at H = 0 -----------------------------------------------------------------------------------------
func _begin_collapse() -> void:
	collapse_phase = "fall"
	collapse_frames = 0
	var dry: bool = thirst != null and thirst.dry()
	last_collapse_cause = "both" if centi <= 0 and dry else ("thirst" if dry else "hunger")
	if world != null and world.get("events") != null:
		world.events.abort_active("thirst" if last_collapse_cause == "thirst" else "hunger")
	player.collapse_from_hunger()


func _tick_collapse() -> void:
	collapse_frames += 1
	if collapse_phase == "fall" and collapse_frames >= collapse_fall_frames:
		_wake()
	elif collapse_phase == "wake" and collapse_frames >= collapse_wake_frames:
		collapse_phase = ""
		collapse_frames = 0


func _wake() -> void:
	collapse_phase = "wake"
	collapse_frames = 0
	city_hp = maxf(city_hp, hp_floor())
	world.recover_to_spawn()
	player.set_round_hp(city_hp)
	last_tokens_lost = progress.spend_credits(mini(progress.credits(), collapse_tokens)) if progress != null else 0
	collapsed_recently = true
	set_centi(maxi(centi, collapse_h))   # T5 Thirst § 5: max, not «= 30» — a fall from thirst keeps the food
	if thirst != null:
		thirst.wake()
	_reset_counters()
	persist()
	collapsed.emit(last_tokens_lost)


## 0 → 1 over the second half of the fall, 1 → 0 while waking: the HUD's dark veil.
func veil() -> float:
	match collapse_phase:
		"fall":
			var half: float = float(collapse_fall_frames) * 0.5
			return clampf((float(collapse_frames) - half) / maxf(half, 1.0), 0.0, 1.0)
		"wake":
			return clampf(1.0 - float(collapse_frames) / maxf(float(collapse_wake_frames), 1.0), 0.0, 1.0)
	return 0.0


func _exit_tree() -> void:
	persist()
