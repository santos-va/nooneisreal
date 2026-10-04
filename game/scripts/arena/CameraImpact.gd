class_name CameraImpact
extends Resource
## Presentation-only hit envelope. T5 PLACEHOLDER tuning: GDD02 Camera impact.
## One instance per camera; no simulation RNG, time scale, lens or yaw writes.

@export_range(0.0, 0.2) var horizontal_limit: float = 0.10
@export_range(0.0, 0.2) var vertical_limit: float = 0.06
@export_range(0.01, 0.5) var duration: float = 0.24
@export_range(0.5, 4.0) var cycles: float = 1.5

var _elapsed: float = 0.0
var _strength: float = 0.0


func trigger(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0:
		return
	# A weaker contact cannot restart a heavier kick. Equal/heavier events replace,
	# never sum amplitudes, so a rapid combo stays inside the same readable bounds.
	var incoming: float = clampf(amount / 0.7, 0.0, 1.0)
	var remaining: float = _strength * pow(maxf(0.0, 1.0 - _elapsed / duration), 2.0)
	if incoming < remaining:
		return
	_strength = incoming
	_elapsed = 0.0


func step(delta: float, scale: float = 1.0) -> Vector2:
	if _strength == 0.0:
		return Vector2.ZERO
	if is_finite(delta):
		_elapsed += maxf(delta, 0.0)
	if _elapsed >= duration:
		reset()
		return Vector2.ZERO
	var t: float = _elapsed / duration
	var gain: float = clampf(scale, 0.0, 1.0) if is_finite(scale) else 0.0
	var envelope: float = _strength * pow(1.0 - t, 2.0) * gain
	var phase: float = TAU * cycles * t
	return Vector2(horizontal_limit * cos(phase), vertical_limit * sin(phase)) * envelope


func reset() -> void:
	_strength = 0.0
	_elapsed = 0.0
