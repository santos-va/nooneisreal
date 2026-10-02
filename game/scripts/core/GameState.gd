extends Node
## Autoload: match configuration + scene routing. Single source of truth for "which fight is set up".
## Docs: docs/Tech/Architecture.md

signal config_changed

const CHARACTER_PATHS := {
	"choko": "res://data/characters/choko.tres",
	"skea": "res://data/characters/skea.tres",
}

## Stage registry. Textures are optional: when the file is missing (assets not fetched yet),
## the arena falls back to a procedural Kronshift gradient backdrop. See docs/Art/Backgrounds.md.
const STAGES := [
	{"id": "market_street", "name": "Kronshift — Market Street", "texture": "res://assets/backgrounds/bg_kronshift_market_street.webp", "sun": Color(1.0, 0.78, 0.55), "ambient": Color(0.38, 0.34, 0.42), "sky_top": Color(0.16, 0.22, 0.32), "sky_bottom": Color(0.78, 0.42, 0.26)},
	{"id": "back_alley", "name": "Kronshift — Back Alley (night)", "texture": "res://assets/backgrounds/bg_kronshift_back_alley.webp", "sun": Color(0.55, 0.72, 0.95), "ambient": Color(0.12, 0.17, 0.26), "sky_top": Color(0.04, 0.06, 0.12), "sky_bottom": Color(0.12, 0.3, 0.36)},
	{"id": "main_street", "name": "Kronshift — Main Street (dusk)", "texture": "res://assets/backgrounds/bg_kronshift_main_street.webp", "sun": Color(1.0, 0.7, 0.45), "ambient": Color(0.3, 0.27, 0.36), "sky_top": Color(0.2, 0.2, 0.34), "sky_bottom": Color(0.9, 0.5, 0.3)},
	{"id": "city_reference", "name": "Kronshift — City (reference)", "texture": "res://assets/backgrounds/bg_kronshift_city_reference.webp", "sun": Color(1.0, 0.8, 0.6), "ambient": Color(0.3, 0.3, 0.38), "sky_top": Color(0.18, 0.24, 0.34), "sky_bottom": Color(0.7, 0.4, 0.28)},
]

var p1_character: String = "choko"
var p2_character: String = "skea"
var stage_index: int = 0
var p2_is_cpu: bool = true
var training_mode: bool = false
var rounds_to_win: int = 2
var round_seconds: int = 99
var show_hitboxes: bool = false
var use_ragdoll: bool = true
var last_result: Dictionary = {}


func load_character(id: String) -> CharacterData:
	var path: String = CHARACTER_PATHS.get(id, CHARACTER_PATHS["choko"])
	var res: Resource = load(path)
	if res == null:
		push_error("GameState: character resource missing: %s" % path)
		return null
	return res as CharacterData


func character_ids() -> Array:
	return CHARACTER_PATHS.keys()


func stage() -> Dictionary:
	return STAGES[clampi(stage_index, 0, STAGES.size() - 1)]


func cycle_stage(dir: int = 1) -> void:
	stage_index = wrapi(stage_index + dir, 0, STAGES.size())
	config_changed.emit()


func cycle_character(player: int, dir: int = 1) -> void:
	var ids: Array = character_ids()
	var cur: String = p1_character if player == 1 else p2_character
	var idx: int = wrapi(ids.find(cur) + dir, 0, ids.size())
	if player == 1:
		p1_character = ids[idx]
	else:
		p2_character = ids[idx]
	config_changed.emit()


func start_match() -> void:
	get_tree().change_scene_to_file("res://scenes/arena/Arena.tscn")


func to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
