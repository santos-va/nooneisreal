extends Node
## Autoload: the ultimate's music (docs/Plans/2026-10-03-Skea-Ult-Bass.md, step 3). It only LISTENS to
## the simulation: the effect that owns the ult calls play / set_paused / finish on its own sim frames,
## and nothing here is ever read back by the fight — the end of an ult is a simulation event, never the
## position of the sound. A missing file is silence, not a crash, and changes nothing in the fight.
## Bus "Music" next to "SFX", per docs/GDD/07-Audio.md (the track is already levelled by T6, max −13 dB).

const BASE := "res://assets/audio/music/"
const BUS := "Music"
const FADE_FRAMES := 24          # 0.4 s at 60 Hz: the tail fades under the stinger, no click (plan § Розвилки 4)
const SILENT_DB := -60.0

## Tests point this at a missing folder to run the same fight without the track (smoke 3b, item 3).
var base: String = BASE
var _player: AudioStreamPlayer
var _fade_left: int = 0           # physics frames, not seconds: the KO slow-mo (time_scale 0.4) must not stretch it
var _cache: Dictionary = {}
## What the simulation asked for, whether or not a file exists (the smoke reads these, the fight never does).
var active: bool = false         # between play() and finish()
var paused: bool = false
var track: String = ""
var play_frame: int = -1         # physics frame of the last play()
var fade_frame: int = -1         # physics frame of the last finish()
var stinger: String = ""


func _ready() -> void:
	_ensure_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = BUS
	add_child(_player)


## Starts `music_name` from `from_sec` seconds into the file (the ult's frame 0 is the file's 0 s).
func play(music_name: String, from_sec: float) -> void:
	_fade_left = 0
	active = true
	paused = false
	track = music_name
	stinger = ""
	play_frame = Engine.get_physics_frames()
	fade_frame = -1
	_player.stop()
	_player.stream_paused = false
	_player.volume_db = 0.0
	_player.stream = _stream(music_name)
	if _player.stream != null:
		_player.play(from_sec)


## Time stop: the music stands while the effect's frame counter stands.
func set_paused(on: bool) -> void:
	if not active or on == paused:
		return
	paused = on
	_player.stream_paused = on


## The ult ended on this sim frame: stinger over the cut, the tail fades over FADE_FRAMES physics frames and stops.
func finish(stinger_sfx: String) -> void:
	if not active:
		return
	active = false
	paused = false
	stinger = stinger_sfx
	fade_frame = Engine.get_physics_frames()
	_player.stream_paused = false
	if stinger_sfx != "":
		Sfx.play(stinger_sfx, 0.0, 0.0)
	_fade_left = FADE_FRAMES if _player.playing else 0


func _physics_process(_delta: float) -> void:
	if _fade_left <= 0:
		return
	_fade_left -= 1
	_player.volume_db = lerpf(SILENT_DB, 0.0, float(_fade_left) / float(FADE_FRAMES))
	if _fade_left == 0:
		_player.stop()


## True while sound is actually coming out (file found, not stopped, not paused).
func audible() -> bool:
	return _player.playing and not _player.stream_paused


func has_stream(music_name: String) -> bool:
	return _stream(music_name) != null


func _stream(music_name: String) -> AudioStream:
	var path := base + music_name + ".ogg"
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	_cache[path] = s
	return s


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, BUS)
	AudioServer.set_bus_send(idx, "Master")
