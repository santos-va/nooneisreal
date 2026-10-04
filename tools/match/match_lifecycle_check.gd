extends SceneTree
## Real arena lifecycle: match-owned ropes, best-of-three, rematch UI and dash readout.
var failures: int = 0
var checks: int = 0
var mutation: String = ""
var arena: Node
var flow: Node
var ropes: Node
var hud: Node
var router: Node
var state: Node
var match_starts: int = 0


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


func _run() -> void:
	await process_frame
	state = root.get_node("GameState")
	router = root.get_node("InputRouter")
	_check(state.rounds_to_win == 2, "default is first to two")
	state.training_mode = false
	state.skeletal_rig = false
	arena = load("res://scenes/arena/Arena.tscn").instantiate()
	root.add_child(arena)
	flow = arena.get_node("MatchFlow")
	ropes = arena.get_node("MatchRopes")
	hud = arena.get_node("HUD")
	flow.set_physics_process(false)
	arena.get("p1").set_physics_process(false)
	arena.get("p2").set_physics_process(false)
	flow.match_started.connect(func(): match_starts += 1)
	await process_frame
	_check(flow.round_no == 1 and flow.wins == {1: 0, 2: 0}, "fresh match starts round one at zero")
	var token: int = ropes.issue(1)
	_check(ropes.deploy(token, 1, Vector3(3, 8, 3), Vector3(3, 0, 3), 6.0), "deploy a match-owned rope")
	var remaining: int = arena.get("p1").grapple.charges
	_win_round(1)
	if mutation == "round":
		ropes.clear_match()
	_check(flow.round_no == 2 and flow.phase == 0, "one win advances to second intro")
	_check(ropes.records.has(token) and arena.get("p1").grapple.charges == remaining, "second round preserves rope and finite inventory")
	_win_round(1)
	_check(flow.phase == 3 and flow.round_no == 2, "two straight wins end match after two rounds")
	_check(bool(hud.get("_result").visible) and router.ui_suppressed(), "result owns UI input")
	_check("2 — 0" in hud.get("_result_label").text, "result includes final score")
	_check(state.last_result.get("wins_p1", -1) == 2 and state.last_result.get("wins_p2", -1) == 0, "result snapshot saves score")
	var again: Button = hud.get("_result").get_child(0).get_child(1)
	_check(again.has_focus(), "rematch is focused for keyboard and controller")
	arena.get("p1").fatigue = 0.5
	if mutation == "rematch":
		flow.match_started.disconnect(ropes.clear_match)
	again.pressed.emit()
	_check(flow.round_no == 1 and flow.wins == {1: 0, 2: 0}, "actual rematch button resets round and score")
	_check(ropes.records.is_empty(), "actual rematch clears deployed ropes")
	_check(arena.get("p1").grapple.charges == arena.get("p1").grapple.max_charges, "actual rematch restores rope inventory")
	_check(is_zero_approx(arena.get("p1").fatigue) and state.last_result.is_empty(), "rematch clears fatigue and previous result")
	_check(not bool(hud.get("_result").visible) and not router.ui_suppressed(), "rematch closes result and releases input")
	if mutation == "score":
		hud.call("_on_round_won", 1, 2, 0)
	for player in [1, 2]:
		for pip: ColorRect in hud.get("_pips")[player]:
			_check(not pip.visible, "rematch clears every round pip")
	_check(match_starts == 1, "one new-match event for rematch, none for round transitions")
	# A split match must keep the same registry until the decisive third round finishes.
	token = ropes.issue(2)
	ropes.deploy(token, 2, Vector3(-3, 8, 3), Vector3(-3, 0, 3), 6.0)
	_win_round(1)
	_win_round(2)
	_check(flow.round_no == 3 and flow.phase == 0 and ropes.records.has(token), "split wins preserve ropes into decisive third round")
	_win_round(2)
	_check(flow.phase == 3 and flow.round_no == 3 and flow.wins == {1: 1, 2: 2}, "third-round winner ends best-of-three")
	_check(match_starts == 1, "third round never clears match-owned state")
	var p1: Node = arena.get("p1")
	var p2: Node = arena.get("p2")
	_check(p1.data.dash_charges == 5 and p2.data.dash_charges == 3, "HUD receives five Choko and three Skea charges")
	p1.dash_recharge_total = 8.0
	hud.call("_on_dash", 1, 2, 6.0, 5)
	_check(hud.get("_dash_text")[1].text == "DASH 2/5 · 6.0s", "dash readout names remaining charges and recovery seconds")
	var empty_pip: ColorRect = hud.get("_dash")[1][2]
	_check(is_equal_approx(empty_pip.anchor_top, 0.75), "spent dash fill uses actual growing recovery duration")
	p1.dodge_stamina_changed.emit(5.0, 100.0)
	_check(is_equal_approx(hud.get("_stamina")[1].value, 0.05), "stamina signal reaches dedicated thin bar")
	_check("REST" in hud.get("_vitals")[1].text, "insufficient dodge stamina uses words")
	p1.hp_changed.emit(10.0, 100.0)
	_check("CRITICAL" in hud.get("_vitals")[1].text, "critical health uses words without hiding stamina")
	_check(hud.get("_dash_text")[1].text == "DASH 2/5 · 6.0s", "dodge stamina does not overwrite signature dash stock")
	p1.dodge_stamina_changed.emit(100.0, 100.0)
	_check(not "REST" in hud.get("_vitals")[1].text, "stamina recovery clears rest cue")
	flow.rematch()
	hud.toggle_pause()
	flow.rematch()
	_check(paused and router.ui_suppressed(), "programmatic rematch cannot release a separate pause owner")
	hud.toggle_pause()
	_check(not paused and not router.ui_suppressed(), "pause owner still releases normally")
	_win_round(1)
	_win_round(1)
	arena.queue_free()
	await process_frame
	_check(not router.ui_suppressed(), "leaving result releases UI ownership")
	for singleton in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	# Audio worker teardown needs real elapsed time even in an uncapped headless run.
	var until: int = Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("MATCH_LIFECYCLE %s (%d checks, %d failures; mutation=%s)" % ["PASS" if failures == 0 else "FAIL", checks, failures, mutation])
	quit(0 if failures == 0 else 1)


func _win_round(player: int) -> void:
	# Exercise the same KO and ROUND_END branches as gameplay without waiting for presentation.
	flow.set("phase", 1)
	flow.call("_on_ko", arena.get("p2") if player == 1 else arena.get("p1"))
	flow.set("_phase_frames", 139)
	flow.call("_physics_process", 0.0)
	Engine.time_scale = 1.0


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("MATCH_LIFECYCLE: " + message)
