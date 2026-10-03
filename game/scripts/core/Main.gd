extends Node
## Boot: route to the menu, or run the headless smoke test when launched with `-- --smoke`.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--free-move" in args:
		GameState.set_free_move(true)
	if "--smoke" in args:
		var t := SmokeTest.new()
		get_tree().root.add_child.call_deferred(t)
		return
	for a in args:
		if a.begins_with("--screenshot"):
			var s := ScreenshotRunner.new()
			get_tree().root.add_child.call_deferred(s)
			return
	GameState.to_menu.call_deferred()
