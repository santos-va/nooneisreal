extends SceneTree
## Pure presentation contract; root runs serially with other Godot checks.
var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	await process_frame
	var script: Script = load("res://scripts/arena/CameraImpact.gd")
	var impact = script.new()
	_expect(impact.step(1.0) == Vector2.ZERO, "idle is exactly zero")
	seed(9861)
	var expected: int = randi()
	seed(9861)
	impact.trigger(0.7)
	for i in 100:
		impact.step(0.001)
	_expect(randi() == expected, "impact never consumes gameplay RNG")
	for amount: float in [0.06, 0.1, 0.3, 0.6, 0.7, 100.0]:
		impact.reset()
		impact.trigger(amount)
		var inside: bool = true
		for i in 240:
			var offset: Vector2 = impact.step(0.001)
			inside = inside and offset.is_finite() and absf(offset.x) <= 0.100001 and absf(offset.y) <= 0.060001
		_expect(inside, "envelope bounded for strength %s" % amount)
		_expect(impact.step(0.001) == Vector2.ZERO, "finite expiry for strength %s" % amount)
	var reference: Vector2 = Vector2.ZERO
	for fps: int in [30, 60, 120, 144]:
		impact.reset()
		impact.trigger(0.7)
		# Exactly 1/6 second, an integer frame count for every target cadence.
		var sample: Vector2 = Vector2.ZERO
		for i in fps / 6:
			sample = impact.step(1.0 / fps)
		if fps == 30:
			reference = sample
		_expect(sample.distance_to(reference) < 0.000001, "same envelope at same elapsed time %s Hz" % fps)
	impact.reset()
	impact.trigger(0.7)
	var paused: Vector2 = impact.step(0.04)
	_expect(impact.step(0.0) == paused, "zero elapsed time freezes envelope")
	_expect(impact.step(0.01, 0.0) == Vector2.ZERO, "scale zero removes movement")
	var rapid_inside: bool = true
	for i in 1000:
		impact.trigger(0.7)
		var offset: Vector2 = impact.step(0.001)
		rapid_inside = rapid_inside and absf(offset.x) <= 0.100001 and absf(offset.y) <= 0.060001
	_expect(rapid_inside, "rapid stacked events remain bounded")
	_expect(impact.step(0.25) == Vector2.ZERO, "burst expires after final event")
	impact.trigger(-1.0)
	impact.trigger(NAN)
	_expect(impact.step(0.01) == Vector2.ZERO, "invalid and negative strengths do not move camera")
	impact.trigger(0.06)
	var light: float = impact.step(0.01).length()
	impact.reset()
	impact.trigger(0.7)
	_expect(impact.step(0.01).length() > light * 10.0, "strong hit clearly exceeds blocked contact")
	impact.reset()
	_expect(impact.step(0.0) == Vector2.ZERO, "reset clears residual offset")
	print("impact-check: %s (%d checks, %d failures)" % ["OK" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("impact-check: " + label)
