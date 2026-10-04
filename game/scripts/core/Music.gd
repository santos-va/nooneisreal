extends Node
## Background soundtrack only; never supplies simulation state or consumes gameplay RNG.
## Quiet tuning values are PLACEHOLDER until Santos auditions the actual three masters.
const MANIFEST := "res://data/audio/soundtracks.cfg"
const BASE_DB := -8.0
const DUCK_DB := -28.0
var context: String = ""
var current_slot: String = ""
var _tracks: Dictionary = {}
var _player: AudioStreamPlayer
var _battle_index: int = -1
var _gain_db: float = -60.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Music" # UltMusic creates the shared bus before this autoload.
	_player.volume_db = _gain_db
	add_child(_player)
	_player.finished.connect(_on_finished)
	reload_manifest()

func reload_manifest(path: String = MANIFEST) -> void:
	_tracks.clear()
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for slot: String in ["menu", "battle_1", "battle_2"]:
		var source: String = str(config.get_value("tracks", slot, ""))
		if not source.is_empty() and ResourceLoader.exists(source):
			_tracks[slot] = source

func play_menu() -> void:
	if context == "menu":
		return
	context = "menu"
	_start_slot("menu")

func play_battle() -> void:
	if context == "battle":
		return
	context = "battle"
	_next_battle()

func stop_music() -> void:
	context = ""
	current_slot = ""
	_player.stop()
	_player.stream = null
	_gain_db = -60.0

func _start_slot(slot: String) -> void:
	_player.stop()
	current_slot = slot
	_gain_db = -60.0
	_player.volume_db = _gain_db
	_player.stream = load(_tracks[slot]) as AudioStream if _tracks.has(slot) else null
	if _player.stream != null:
		_player.play()

func _next_battle() -> void:
	for attempt: int in 2:
		_battle_index = (_battle_index + 1) % 2
		var slot := "battle_%d" % (_battle_index + 1)
		if _tracks.has(slot):
			_start_slot(slot)
			return
	_start_slot("battle_1")

func _on_finished() -> void:
	if context == "battle":
		_next_battle()
	elif context == "menu":
		_start_slot("menu")

func target_gain_db() -> float:
	# Duck across time stop and the ultimate's audible fade tail, not just active frames.
	var ultimate: Node = get_node_or_null("/root/UltMusic")
	return DUCK_DB if ultimate != null and (ultimate.active or ultimate.audible()) else BASE_DB

func _process(delta: float) -> void:
	_gain_db = move_toward(_gain_db, target_gain_db(), delta * 80.0)
	_player.volume_db = _gain_db
