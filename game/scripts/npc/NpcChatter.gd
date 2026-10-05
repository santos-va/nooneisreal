class_name NpcChatter
extends Node3D
## Original nonverbal synthesis. One shared two-voice pool per district, on the existing SFX bus.
const SAMPLE_RATE := 22050
const RANGE := 8.0
const MAX_VOICES := 2
const RESIDENT_COOLDOWN := 2.0
const GLOBAL_COOLDOWN := 0.18
const EVENTS := ["greet", "talk", "agree", "goodbye"]
static var _streams: Dictionary = {}
var _listener: Node3D
var _spatial_listener: AudioListener3D
var _previous_listener: AudioListener3D
var _voices: Array[AudioStreamPlayer3D] = []
var _owners: Array[String] = []
var _last_resident: Dictionary = {}
var _last_global := -100.0
var _clock := 0.0

func configure(listener: Node3D) -> void:
	_listener = listener
	if not _voices.is_empty(): return
	_previous_listener = get_viewport().get_audio_listener_3d()
	_spatial_listener = AudioListener3D.new()
	_spatial_listener.name = "ResidentAudioListener"
	add_child(_spatial_listener)
	_update_listener()
	_spatial_listener.make_current()
	for i in MAX_VOICES:
		var voice := AudioStreamPlayer3D.new()
		voice.name = "ResidentVoice%d" % i
		voice.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		voice.max_distance = RANGE
		voice.unit_size = 1.5
		voice.volume_db = -12.0
		voice.max_polyphony = 1
		add_child(voice)
		_voices.append(voice)
		_owners.append("")

func _process(delta: float) -> void:
	_clock += delta
	_update_listener()
	if _muted(): stop_all()
	for i in _voices.size():
		if _voices[i].playing and (not is_instance_valid(_listener) or (_listener.global_position + Vector3.UP * 1.5).distance_to(_voices[i].global_position) > RANGE):
			_voices[i].stop()
			_owners[i] = ""

func speak(world_position: Vector3, appearance_seed: int, event: String, resident_id: String) -> bool:
	if event not in EVENTS or not is_instance_valid(_listener) or _voices.is_empty() or _muted(): return false
	if _listener.global_position.distance_to(world_position) > RANGE: return false
	if _clock - _last_global < GLOBAL_COOLDOWN or _clock - float(_last_resident.get(resident_id, -100.0)) < RESIDENT_COOLDOWN: return false
	for i in _voices.size():
		if _voices[i].playing: continue
		var voice := _voices[i]
		voice.global_position = world_position + Vector3(0, 1.5, 0)
		voice.stream = stream_for(appearance_seed, event)
		_owners[i] = resident_id
		_last_resident[resident_id] = _clock
		_last_global = _clock
		voice.play()
		return true
	return false

static func stream_for(appearance_seed: int, event: String) -> AudioStreamWAV:
	var timbre := posmod(appearance_seed, 3)
	var contour := EVENTS.find(event)
	if contour < 0: contour = 1
	var key := "%d:%d" % [timbre, contour]
	if _streams.has(key): return _streams[key]
	var duration := 0.42 if contour == 1 else 0.30
	var count := int(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var u := t / duration
		var base: float = [185.0, 285.0, 115.0][timbre]
		var pitch := base * (1.0 + (0.20 if contour == 0 else -0.12)*u + 0.035*sin(t*38))
		phase += TAU * pitch / SAMPLE_RATE
		var syllable := pow(maxf(0.0, sin(PI * fmod(u*2.0, 1.0))), 0.65)
		var edge := minf(1, minf(t/0.015, (duration-t)/0.025))
		var voiced := sin(phase)*0.60 + sin(phase*2.0)*0.23 + sin(phase*(3.0+timbre))*0.12
		var sample := clampf(voiced * syllable * edge * 0.40, -0.95, 0.95)
		pcm.encode_s16(i*2, int(sample*32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	_streams[key] = stream
	return stream

func release_actor(resident_id: String) -> void:
	for i in _voices.size():
		if _owners[i] == resident_id:
			_voices[i].stop()
			_owners[i] = ""

func stop_all() -> void:
	for voice in _voices: voice.stop()
	for i in _owners.size(): _owners[i] = ""

func _exit_tree() -> void:
	stop_all()
	# A later camera/scene may have taken ownership; never steal its listener on exit.
	if is_instance_valid(_spatial_listener) and get_viewport().get_audio_listener_3d() == _spatial_listener:
		_spatial_listener.clear_current()
		if is_instance_valid(_previous_listener) and _previous_listener.is_inside_tree(): _previous_listener.make_current()

func _update_listener() -> void:
	if not is_instance_valid(_spatial_listener) or not is_instance_valid(_listener): return
	_spatial_listener.global_position = _listener.global_position + Vector3.UP * 1.5
	var camera := get_viewport().get_camera_3d()
	if camera != null: _spatial_listener.global_basis = camera.global_basis.orthonormalized()

func _muted() -> bool:
	for bus_name in ["Master", "SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0 and (AudioServer.is_bus_mute(index) or AudioServer.get_bus_volume_db(index) <= -60.0): return true
	return false
