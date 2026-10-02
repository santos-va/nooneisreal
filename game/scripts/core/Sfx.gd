extends Node
## Autoload: tiny SFX player with a voice pool. Streams live in res://assets/audio/sfx/<name>.wav.
## The current files are synthesised placeholders (see docs/GDD/07-Audio.md); a missing file is a
## silent no-op so the game never crashes on absent audio.

const POOL := 12
const BASE := "res://assets/audio/sfx/"

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _next: int = 0


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func play(sfx_name: String, volume_db: float = 0.0, pitch_jitter: float = 0.08) -> void:
	var stream := _stream(sfx_name)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func _stream(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var path := BASE + sfx_name + ".wav"
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	_cache[sfx_name] = s
	return s
