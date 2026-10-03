extends Node
## Boot: route to the menu, or run the headless smoke test when launched with `-- --smoke`.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	apply_saved_mode(args, GameState, InputRouter.SETTINGS_PATH)
	apply_launch_args(args, GameState)
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
## Applies the launch flags to `state` (the GameState autoload at boot; the smoke passes a fresh copy, so the
## wiring itself is checked, not only the parse — T4 audit Launch 4-0 item 7).
static func apply_launch_args(args: PackedStringArray, state: Node) -> void:
	var mode := free_move_arg(args)
	if mode != -1:
		state.set_free_move(mode == 1)
	if "--capsules" in args:
		state.skeletal_rig = false
	if "--skeletal-rig" in args:
		state.skeletal_rig = true


## The menu's MODE choice from `cfg_path` ([gameplay] free_move) onto `state`, unless this is the smoke or a launch
## flag picks the mode for this run (T4 audit Launch 5/6, proposal 4: pure, so the smoke checks it on a temp file).
static func apply_saved_mode(args: PackedStringArray, state: Node, cfg_path: String) -> void:
	if "--smoke" in args or free_move_arg(args) != -1:
		return
	var saved: bool = state.saved_free_move(state.free_move, cfg_path)
	if saved != state.free_move:
		state.set_free_move(saved)


static func free_move_arg(args: PackedStringArray) -> int:
	if "--plane" in args:
		return 0
	if "--free-move" in args:
		return 1
	return -1
