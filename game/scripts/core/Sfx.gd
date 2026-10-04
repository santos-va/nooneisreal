extends Node
## Autoload: SFX player with a voice pool. Streams live in res://assets/audio/sfx/:
##   <name>.ogg|.wav           variant 1
##   <name>_2.ogg|.wav, _3 ... more variants → cached AudioStreamRandomizer container (private RNG; no immediate repeats)
## Everything plays on the "SFX" bus: compressor (attack 1 ms, 4:1) → limiter −1 dB, per
## docs/GDD/07-Audio.md. A missing file is a silent no-op so the game never crashes on absent audio.

const POOL := 12
const BASE := "res://assets/audio/sfx/"
const EXTS := ["ogg", "wav"]
const MAX_VARIANTS := 8
const BUS := "SFX"
## Presentation-only PLACEHOLDER spacing in physics ticks; independent for both fighter slots.
const WATER_GAP := {"step": 10, "land": 8, "dash": 12, "skid": 12}
const WATER_VOLUME_DB := {"step": -12.0, "land": -5.0, "dash": -8.0, "skid": -12.0}

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _next: int = 0
var _water_last: Dictionary = {}
var _variant_last: Dictionary = {}
var _audio_rng := RandomNumberGenerator.new()
## sfx name → physics frame of its last play() (smoke: hit sound on the hit frame, launch 4 § C1).
var last_frame: Dictionary = {}


func _ready() -> void:
	_ensure_bus()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		add_child(p)
		_players.append(p)


func play(sfx_name: String, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	last_frame[sfx_name] = Engine.get_physics_frames()
	var stream := _stream(sfx_name)
	if stream == null or _players.is_empty():
		return
	_play_stream(_select_variant(sfx_name, stream), volume_db, 1.0 + _audio_rng.randf_range(-pitch_jitter, pitch_jitter))


## No placeholder impact is substituted for absent water recordings. The caller owns the surface test.
## Returns whether a voice was started; never use this presentation result to drive combat.
func play_surface_water(event: String, actor_slot: int = 0) -> bool:
	if not WATER_GAP.has(event) or actor_slot < 0 or actor_slot > 1 or _players.is_empty():
		return false
	var frame := Engine.get_physics_frames()
	var key := "%d:%s" % [actor_slot, event]
	if _water_last.has(key) and frame - int(_water_last[key]) < int(WATER_GAP[event]):
		return false
	var sfx_name := "water_" + event
	var stream := _stream(sfx_name)
	if stream == null:
		return false
	_water_last[key] = frame
	last_frame[sfx_name] = frame
	_play_stream(_select_variant(sfx_name, stream), float(WATER_VOLUME_DB[event]), 1.0 + _audio_rng.randf_range(-0.04, 0.04))
	return true


func _select_variant(sfx_name: String, stream: AudioStream) -> AudioStream:
	# Keep the cached variant container for inspection, but never let it consume shared RNG.
	if stream is AudioStreamRandomizer:
		var variants := stream as AudioStreamRandomizer
		var count := variants.streams_count
		var previous: int = int(_variant_last.get(sfx_name, -1))
		var index := _audio_rng.randi_range(0, count - 2 if previous >= 0 else count - 1)
		if previous >= 0 and index >= previous:
			index += 1
		_variant_last[sfx_name] = index
		return variants.get_stream(index)
	return stream


func _play_stream(stream: AudioStream, volume_db: float, pitch: float) -> void:
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stop()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func _exit_tree() -> void:
	# Release active playback before dropping cached randomizers and their source streams.
	for p in _players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_players.clear()
	_cache.clear()
	_water_last.clear()
	_variant_last.clear()
	last_frame.clear()
	_next = 0


## Number of variants found for a name (0 = missing). Used by the smoke test.
func variant_count(sfx_name: String) -> int:
	var s := _stream(sfx_name)
	if s == null:
		return 0
	if s is AudioStreamRandomizer:
		return (s as AudioStreamRandomizer).streams_count
	return 1


func _stream(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var found: Array[AudioStream] = []
	for v in range(1, MAX_VARIANTS + 1):
		var stem := sfx_name if v == 1 else "%s_%d" % [sfx_name, v]
		var s := _load_first(stem)
		if s == null:
			break
		found.append(s)
	var out: AudioStream = null
	if found.size() == 1:
		out = found[0]
	elif found.size() > 1:
		var r := AudioStreamRandomizer.new()
		r.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
		r.random_pitch = 1.0      # pitch jitter is applied per voice in play()
		r.random_volume_offset_db = 0.0
		for s in found:
			r.add_stream(-1, s)
		out = r
	_cache[sfx_name] = out
	return out


func _load_first(stem: String) -> AudioStream:
	for ext in EXTS:
		var path: String = BASE + stem + "." + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, BUS)
	AudioServer.set_bus_send(idx, "Master")
	var comp := AudioEffectCompressor.new()
	comp.threshold = -12.0
	comp.ratio = 4.0
	comp.attack_us = 1000.0
	comp.release_ms = 80.0
	AudioServer.add_bus_effect(idx, comp)
	var lim := AudioEffectLimiter.new()
	lim.ceiling_db = -1.0
	lim.threshold_db = -3.0
	AudioServer.add_bus_effect(idx, lim)
