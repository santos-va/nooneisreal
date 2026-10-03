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
	{"id": "river", "label": "River", "name": "Kronshift — River (dusk, on the water)", "texture": "res://assets/backgrounds/bg_kronshift_river.jpg", "sun": Color(1.0, 0.72, 0.5), "ambient": Color(0.32, 0.3, 0.4), "sky_top": Color(0.3, 0.3, 0.42), "sky_bottom": Color(0.9, 0.55, 0.35),
		# 1500x848 photo-wide painting: shrink + lift so the clock towers are in frame; the embankment
		# (76 % down the image) sits at y≈0.5 where the 3D water meets it. Sides mirror until outpaint.
		"backdrop": {"size": Vector2(50.9, 20.0), "pos": Vector3(0.0, 7.62, -18.0), "mirror_x": 2.4, "img_top": 0.4},
		"water": "res://data/stages/river_water.tres"},
	{"id": "market_street", "name": "Kronshift — Market Street", "texture": "res://assets/backgrounds/bg_kronshift_market_street.webp", "sun": Color(1.0, 0.78, 0.55), "ambient": Color(0.38, 0.34, 0.42), "sky_top": Color(0.16, 0.22, 0.32), "sky_bottom": Color(0.78, 0.42, 0.26)},
	{"id": "back_alley", "name": "Kronshift — Back Alley (night)", "texture": "res://assets/backgrounds/bg_kronshift_back_alley.webp", "sun": Color(0.55, 0.72, 0.95), "ambient": Color(0.12, 0.17, 0.26), "sky_top": Color(0.04, 0.06, 0.12), "sky_bottom": Color(0.12, 0.3, 0.36)},
	{"id": "main_street", "name": "Kronshift — Main Street (dusk)", "texture": "res://assets/backgrounds/bg_kronshift_main_street.webp", "sun": Color(1.0, 0.7, 0.45), "ambient": Color(0.3, 0.27, 0.36), "sky_top": Color(0.2, 0.2, 0.34), "sky_bottom": Color(0.9, 0.5, 0.3)},
	{"id": "city_reference", "name": "Kronshift — City (reference)", "texture": "res://assets/backgrounds/bg_kronshift_city_reference.webp", "sun": Color(1.0, 0.8, 0.6), "ambient": Color(0.3, 0.3, 0.38), "sky_top": Color(0.18, 0.24, 0.34), "sky_bottom": Color(0.7, 0.4, 0.28)},
	# sprint A2 (docs/Plans/2026-10-03-Sprint-Arenas-VFX.md; canon docs/World/Cronshift.md § Нові арени). PLACEHOLDER art:
	# the old-style cards stand in until band C (T6·A) delivers the Sketch-Cel arenas; colours too (T6 retunes them).
	{"id": "bazaar", "label": "Bazaar", "name": "Bazaar", "layout": "bazaar", "texture": "res://assets/backgrounds/bg_kronshift_market_street.webp", "sun": Color(1.0, 0.86, 0.66), "ambient": Color(0.42, 0.38, 0.44), "sky_top": Color(0.3, 0.42, 0.56), "sky_bottom": Color(0.86, 0.6, 0.4),
		"night": {"texture": "res://assets/backgrounds/bg_kronshift_back_alley.webp", "sun": Color(0.55, 0.72, 0.95), "ambient": Color(0.12, 0.17, 0.26), "sky_top": Color(0.04, 0.06, 0.12), "sky_bottom": Color(0.12, 0.3, 0.36), "tint": Color(0.85, 0.88, 1.0)}},
	{"id": "fountain", "label": "Fountain Square", "name": "Fountain Square", "layout": "fountain", "texture": "res://assets/backgrounds/bg_kronshift_main_street.webp", "sun": Color(1.0, 0.84, 0.62), "ambient": Color(0.4, 0.37, 0.44), "sky_top": Color(0.28, 0.4, 0.56), "sky_bottom": Color(0.9, 0.62, 0.42),
		"night": {"sun": Color(0.5, 0.62, 0.9), "ambient": Color(0.13, 0.15, 0.25), "sky_top": Color(0.03, 0.05, 0.11), "sky_bottom": Color(0.1, 0.16, 0.3), "tint": Color(0.4, 0.46, 0.68), "neon": "CRONSHIFT"}},
]
## The arenas in rotation (menu STAGE row, settings), in order; the rest of STAGES stays for the smoke and old saves.
const ROTATION := ["river", "bazaar", "fountain"]
## Night for the river (the day card is the dusk painting). PLACEHOLDER until band C.
const RIVER_NIGHT := {"sun": Color(0.52, 0.66, 0.95), "ambient": Color(0.12, 0.15, 0.26), "sky_top": Color(0.04, 0.06, 0.13), "sky_bottom": Color(0.14, 0.24, 0.38), "tint": Color(0.4, 0.46, 0.68)}

var p1_character: String = "choko"
var p2_character: String = "skea"
var stage_index: int = 0
## Sprint A2: time of day (menu TIME row, `-- --night`). The night values live in the stage's "night" entry.
var night: bool = false
var p2_is_cpu: bool = true
var training_mode: bool = false
var rounds_to_win: int = 2
var round_seconds: int = 99
var show_hitboxes: bool = false
var use_ragdoll: bool = true
var last_result: Dictionary = {}
## The live water surface when the current stage is on water (set by Arena), else null.
## Fighters read their floor from it; see scripts/core/WaveField.gd.
var water: WaveField = null
## Prototype 0.3 free 3D movement with lock-on (docs/Plans/2026-10-03-Prototype-0.3-Free-Movement.md).
## true = free movement (default since Santos's word 2026-10-03, T4 audit 0.3-7). false = the 0.2 fight on
## the X plane, unchanged. Switch with set_free_move() (it also re-binds the keyboard), or launch with
## `-- --plane` / `-- --free-move`.
var free_move: bool = true
## Launch 4/5: the heroes (Meshy M-0/M-1, retargeted from the UAL mannequin) draw the fighter instead of the capsules
## (SkeletalRig.gd); the capsule rig keeps running underneath. On by default since Santos's «так» (2026-10-03, via T1);
## `-- --capsules` draws the old capsules, `-- --skeletal-rig` forces the heroes.
var skeletal_rig: bool = true
## The duel's screen frame for free movement (scripts/core/DuelFrame.gd); fighters sync it each frame.
var duel: DuelFrame = DuelFrame.new()


func set_free_move(on: bool) -> void:
	free_move = on
	duel.reset()
	InputRouter.apply_profile(InputRouter.profile, false)


## Menu MODE row (docs/GDD/06-UI-UX.md § Кнопка «РЕЖИМ 2.5D / 3D»): switch and remember the player's choice in
## user://settings.cfg → [gameplay] free_move. load() first, so [input] survives.
func save_free_move(on: bool) -> void:
	set_free_move(on)
	var cfg := ConfigFile.new()
	cfg.load(InputRouter.SETTINGS_PATH)
	cfg.set_value("gameplay", "free_move", on)
	cfg.save(InputRouter.SETTINGS_PATH)


## The saved MODE choice, or the default (free movement) when nothing is saved. Main applies it at boot before
## the launch flags, which win for that run only; the smoke never reads it.
static func saved_free_move(default_on: bool, path: String = InputRouter.SETTINGS_PATH) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return default_on
	return bool(cfg.get_value("gameplay", "free_move", default_on))


## ADR-015: free movement against the CPU (FIGHT, TRAINING) puts the camera behind P1; VERSUS keeps the shared
## side-on camera.
func camera_behind() -> bool:
	return free_move and p2_is_cpu


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
	var st: Dictionary = (STAGES[clampi(stage_index, 0, STAGES.size() - 1)] as Dictionary).duplicate()
	if night:
		var n: Dictionary = st.get("night", RIVER_NIGHT if st.id == "river" else {})
		st.merge(n, true)
	st.erase("night")
	st["time_of_day"] = "night" if night else "day"
	return st


func stage_id() -> String:
	return String(STAGES[clampi(stage_index, 0, STAGES.size() - 1)].id)


## Index of a stage id in STAGES, or -1.
static func stage_index_of(id: String) -> int:
	for i in STAGES.size():
		if STAGES[i].id == id:
			return i
	return -1


## A rotation arena by id; an unknown or non-rotation id falls back to the first rotation arena (06-UI-UX § Збереження).
func set_stage(id: String) -> void:
	if not id in ROTATION or stage_index_of(id) < 0:
		id = ROTATION[0]
	stage_index = stage_index_of(id)
	config_changed.emit()


## Menu STAGE row: steps through the rotation only (river → bazaar → fountain); from a non-rotation stage it lands on
## the first rotation arena.
func cycle_stage(dir: int = 1) -> void:
	var i := ROTATION.find(stage_id())
	set_stage(ROTATION[0] if i < 0 else ROTATION[wrapi(i + dir, 0, ROTATION.size())])


## Menu STAGE/TIME choice → user://settings.cfg [gameplay] stage, time_of_day (id, not index).
func save_stage_time(path: String = InputRouter.SETTINGS_PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("gameplay", "stage", stage_id())
	cfg.set_value("gameplay", "time_of_day", "night" if night else "day")
	cfg.save(path)


## The saved STAGE/TIME (or the defaults: river, day) onto this state.
func load_stage_time(path: String = InputRouter.SETTINGS_PATH) -> void:
	var cfg := ConfigFile.new()
	var id := ROTATION[0] as String
	var tod := "day"
	if cfg.load(path) == OK:
		id = str(cfg.get_value("gameplay", "stage", id))
		tod = str(cfg.get_value("gameplay", "time_of_day", tod))
	set_stage(id)
	night = tod == "night"


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
