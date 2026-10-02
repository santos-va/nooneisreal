class_name ScreenshotRunner
extends Node
## Renders a CPU-vs-CPU fight and saves PNG frames (needs a GPU or Mesa/llvmpipe + Xvfb).
## Run: godot --path game --rendering-driver opengl3 -- --screenshot=/abs/dir

var _dir: String = "user://"
var _f: int = 0
var _shots: Array[int] = [140, 230, 330, 420]
var _arena: Node3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot="):
			_dir = a.trim_prefix("--screenshot=")
	GameState.p2_is_cpu = true
	GameState.p1_character = "choko"
	GameState.p2_character = "skea"
	GameState.stage_index = 0
	get_tree().change_scene_to_file.call_deferred("res://scenes/arena/Arena.tscn")


func _physics_process(_d: float) -> void:
	_f += 1
	if _arena == null:
		var cs := get_tree().current_scene
		if cs and cs.name == "Arena":
			_arena = cs
			# P1 also CPU-driven for a lively frame
			var p1: Fighter = _arena.p1
			if p1 and p1._brain == null:
				var b := CpuBrain.new()
				b.fighter = p1
				p1.add_child(b)
				p1._brain = b
		return
	if _f in _shots:
		var img := get_viewport().get_texture().get_image()
		var path := _dir.path_join("shot_%03d.png" % _f)
		var err := img.save_png(path)
		print("[shot] %s -> %s" % [path, error_string(err)])
	if _f > _shots[-1] + 5:
		get_tree().quit(0)
