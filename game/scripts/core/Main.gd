extends Node
## Boot: route to the menu, or run the headless smoke test when launched with `-- --smoke`.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := free_move_arg(args)
	if mode != -1:
		GameState.set_free_move(mode == 1)
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


## Movement mode the launch arguments ask for: 0 = `--plane` (the 0.2 side-on fight; wins over
## `--free-move`), 1 = `--free-move`, -1 = neither (keep GameState's default). Pure, so the smoke can
## check it (T4 audit Launch 2, proposal 3).
static func free_move_arg(args: PackedStringArray) -> int:
	if "--plane" in args:
		return 0
	if "--free-move" in args:
		return 1
	return -1
