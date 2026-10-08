class_name CityHaze
extends Node
## The «Заплутаність» state of stage 1 (plan 2026-10-08-City-Events-Stage-1, step 4; T5 brief § 4.2, § 4.4; T7 brief
## § 5.2; T8 06-UI-UX § «Заплутаність» поруч зі шкалою). A session-only state, never saved:
##   * a static vignette (CityHazeVignette, under the HUD) and a narrower city FOV — no pulse, no sway; the FOV part
##     follows COMFORT's CAMERA SHAKE (0 → no FOV change), the vignette is the same for everybody;
##   * slower walking and braking and half the attack tracking for CityFighter in the city — never inside a lethal
##     pocket (the director's events never start there and the pocket refuses a hazy hero), never in Fighter or a duel;
##   * every second sentence of a resident's reply fades to «…» two seconds after it is shown — choice labels, prices,
##     quest and story lines, the journal and the HUD never fade, and nothing is lost from the saved data.
## It ends with time or with food at «Шавлія» (then it fades over `fade_out_seconds`). No hunger flag: the future FOOD
## bar (plan 2026-10-08-Survival-Hunger) reads haze_active() / haze_remaining() itself (T1 → T2, 2026-10-08).
## Every number is a PLACEHOLDER (T5 § 4.2).
signal started
signal fading
signal ended

@export var duration_seconds: float = 90.0     # T_haze — T5 § 4.2: 90 s
@export var max_seconds: float = 90.0          # T_haze_max — T7 § 5.2: a second drag never goes beyond this
@export var ramp_in_seconds: float = 3.0       # T5: «наростання 3 с»
@export var fade_out_seconds: float = 10.0     # T5: «згасання 10 с»; food leaves at most this much (T5 § 4.3)
@export var walk_scale: float = 0.85           # T5: хода × 0,85
@export var decel_scale: float = 0.6           # T5: ground_decel × 0,6
@export var tracking_scale: float = 0.5        # T5: tracking_deg × 0,5 on startup
@export var fov_narrow_degrees: float = 10.0   # T5: fov 65 → 55
@export var forget_delay_seconds: float = 2.0  # T5 § 4.4: the sentence dims 2 s after it is shown
const FORGOTTEN := "…"

var camera: Camera3D
var base_fov: float = 65.0
var comfort: Node
var _remaining: float = 0.0
var _elapsed: float = 0.0
var _fading_sent: bool = false


func setup(city_camera: Camera3D) -> void:
	camera = city_camera
	if camera != null:
		base_fov = camera.fov
	comfort = get_node_or_null("/root/ComfortSettings")


func haze_active() -> bool:
	return _remaining > 0.0


func haze_remaining() -> float:
	return _remaining


## Starts the state (or renews it up to max_seconds). True when the hero is now in it.
func begin() -> bool:
	if not haze_active():
		_elapsed = 0.0
		_remaining = minf(duration_seconds, max_seconds)
		_fading_sent = false
		started.emit()
	else:
		_remaining = minf(maxf(_remaining, duration_seconds), max_seconds)
		_fading_sent = _remaining <= fade_out_seconds
	return haze_active()


## Food at «Шавлія»: whatever is left becomes at most the fade-out. True when it shortened the state.
func eat() -> bool:
	if not haze_active() or _remaining <= fade_out_seconds:
		return false
	_remaining = fade_out_seconds
	_announce_fading()
	return true


## Gone at once (content Off, a restart of the walk). No fade.
func clear() -> void:
	if not haze_active():
		return
	_remaining = 0.0
	_apply_fov()
	ended.emit()


## 0 → 1 over the ramp-in, 1 on the plateau, → 0 over the last fade_out_seconds. Constant on the plateau: no pulse.
func weight() -> float:
	if not haze_active():
		return 0.0
	var rise: float = clampf(_elapsed / maxf(ramp_in_seconds, 0.001), 0.0, 1.0)
	var fall: float = clampf(_remaining / maxf(fade_out_seconds, 0.001), 0.0, 1.0)
	return smoothstep(0.0, 1.0, rise) * smoothstep(0.0, 1.0, fall)


func walk_multiplier() -> float:
	return lerpf(1.0, walk_scale, weight())


func decel_multiplier() -> float:
	return lerpf(1.0, decel_scale, weight())


func tracking_multiplier() -> float:
	return lerpf(1.0, tracking_scale, weight())


## The FOV part of the narrow view follows CAMERA SHAKE: 0 → none; the default 0.5 and above → the full T5 narrowing.
func fov_offset() -> float:
	var shake: float = float(comfort.call("get_value", "shake")) if comfort != null else 0.5
	return fov_narrow_degrees * weight() * clampf(shake / 0.5, 0.0, 1.0)


## Half of the sentences of a resident's line fade to «…»: sentence k fades when (k + salt) is odd, so the choice is
## fixed by the resident and the turn (no randf) and exactly ⌊n/2⌋ or ⌈n/2⌉ of n sentences go.
static func fade_line(text: String, salt: int) -> String:
	var sentences: PackedStringArray = split_sentences(text)
	for k: int in sentences.size():
		if posmod(k + salt, 2) == 1:
			sentences[k] = FORGOTTEN
	return " ".join(sentences)


static func split_sentences(text: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var current: String = ""
	var length: int = text.length()
	for i: int in length:
		var character: String = text[i]
		current += character
		var ends: bool = character in ".!?…"
		var next: String = text[i + 1] if i + 1 < length else " "
		if ends and (next == " " or next == "\n") and not next in ".!?…":
			result.append(current.strip_edges())
			current = ""
	if not current.strip_edges().is_empty():
		result.append(current.strip_edges())
	return result


func _physics_process(delta: float) -> void:
	if not haze_active():
		return
	_elapsed += delta
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= fade_out_seconds:
		_announce_fading()
	_apply_fov()
	if _remaining <= 0.0:
		ended.emit()


func _announce_fading() -> void:
	if not _fading_sent:
		_fading_sent = true
		fading.emit()


func _apply_fov() -> void:
	if camera != null and is_instance_valid(camera):
		camera.fov = base_fov - fov_offset()
