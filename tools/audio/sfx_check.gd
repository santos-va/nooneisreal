extends SceneTree
## Run after import: godot --headless --path game -s "$PWD/tools/audio/sfx_check.gd"
## No audio-device assertion: verifies routing, streams, lifecycle and gameplay RNG isolation.

var failures: int = 0
var checks: int = 0
var sfx: Node


func _initialize() -> void:
	await process_frame
	sfx = load("res://scripts/core/Sfx.gd").new()
	root.add_child(sfx)
	_expect(sfx._players.size() == 12, "voice pool initialized")
	for warm in [false, true]:
		for name in ["hit_light", "water_step", "no_such_sfx_regression"]:
			_rng_probe(name, warm)
	_variants()
	await _water()
	_lifecycle()
	# AudioServer retires stopped playback on its mixer thread, after Node teardown.
	# Use wall time: --fixed-fps makes SceneTree timers advance faster than the mixer.
	# Keep pumping deferred destruction; yield CPU so the mixer can process its stop queue.
	var drain_until_ms: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("sfx-check: %s (%d checks, %d failures)" % ["OK" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)


func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("sfx-check: " + label)


func _rng_probe(name: String, warm: bool) -> void:
	sfx._cache.clear()
	sfx._variant_last.clear()
	if warm:
		sfx.variant_count(name)
	seed(4242)
	var expected_first: int = randi()
	var expected_second: int = randi()
	seed(4242)
	var actual_first: int = randi()
	sfx.play(name)
	var actual_second: int = randi()
	_expect(actual_first == expected_first and actual_second == expected_second,
		"global RNG unchanged: %s warm=%s" % [name, warm])


func _variants() -> void:
	var count: int = sfx.variant_count("hit_light")
	_expect(count >= 2, "real hit_light variants available")
	var previous: AudioStream = null
	var seen: Dictionary = {}
	var no_repeats: bool = true
	var sources_only: bool = true
	for i in 32:
		var slot: int = sfx._next
		sfx.play("hit_light")
		var player: AudioStreamPlayer = sfx._players[slot]
		no_repeats = no_repeats and player.stream != null and player.stream != previous
		sources_only = sources_only and not player.stream is AudioStreamRandomizer
		previous = player.stream
		seen[player.stream] = true
	_expect(no_repeats, "32 variants without adjacent repeats")
	_expect(sources_only, "players receive source streams, not randomizer playback")
	_expect(seen.size() >= 2, "variant selection changes source")
	var before: int = sfx._next
	sfx.play("no_such_sfx_regression")
	_expect(sfx._next == before, "missing stream does not steal a voice")
	previous = null
	seen.clear()


func _water() -> void:
	sfx._water_last.clear()
	seed(4242)
	var expected: int = randi()
	seed(4242)
	var before: int = sfx._next
	_expect(not sfx.play_surface_water("missing", 0), "unknown water event rejected")
	_expect(not sfx.play_surface_water("step", -1), "negative actor slot rejected")
	_expect(not sfx.play_surface_water("step", 2), "third actor slot rejected")
	_expect(randi() == expected and sfx._next == before and sfx._water_last.is_empty(),
		"invalid water requests preserve RNG, voices and throttle")
	for event in ["step", "land", "dash", "skid"]:
		var name: String = "water_" + event
		_expect(sfx.variant_count(name) >= 2, "two real water variants: " + event)
		seed(4242)
		expected = randi()
		seed(4242)
		_expect(sfx.play_surface_water(event, 0), "first water event accepted: " + event)
		_expect(not sfx.play_surface_water(event, 0), "same-slot duplicate suppressed: " + event)
		_expect(sfx.play_surface_water(event, 1), "other slot independent: " + event)
		_expect(randi() == expected, "water RNG isolated: " + event)
	_expect(sfx._water_last.size() == 8, "throttle bounded to four events by two slots")
	for i in 13:
		await physics_frame
	_expect(sfx.play_surface_water("step", 0), "water step resumes after spacing")
	# Missing-stream branch remains tested even after the real water assets ship.
	var saved: AudioStream = sfx._cache["water_land"]
	sfx._cache["water_land"] = null
	sfx._water_last.erase("0:land")
	before = sfx._next
	_expect(not sfx.play_surface_water("land", 0) and sfx._next == before,
		"missing water stream is silent and does not steal a voice")
	sfx._cache["water_land"] = saved
	saved = null


func _lifecycle() -> void:
	sfx.play("hit_heavy")
	var voices: Array = sfx._players.duplicate()
	root.remove_child(sfx)
	var released: bool = true
	for voice: AudioStreamPlayer in voices:
		released = released and not voice.playing and voice.stream == null
	_expect(released, "tree exit stops voices and detaches streams")
	_expect(sfx._players.is_empty() and sfx._cache.is_empty() and sfx._water_last.is_empty()
		and sfx._variant_last.is_empty() and sfx.last_frame.is_empty(), "tree exit clears retained state")
	_expect(not sfx.play_surface_water("step", 0), "post-exit water request safe")
	voices.clear()
	sfx.free()
	sfx = null
