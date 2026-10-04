extends SceneTree
## Authoritative hand transfer, real input, interruption boundaries and donor invariance.
var checks: int = 0
var failures: int = 0
var ir: Node
var actor: GDScript
var f
var enemy

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SWORD_STATE: " + label)

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func pad(code: int, down: bool, device: int = 0) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func clear_inputs() -> void:
	for player: int in [1, 2]:
		ir.v_clear(player)
		for action: String in ir.ACTIONS:
			ir.buffered(player, action)

func fresh() -> void:
	clear_inputs()
	f.reset_for_round(-3.0, 1)
	f.set_control(true)
	f.set_physics_process(false)
	f.position = Vector3.ZERO
	enemy.reset_for_round(3.0, -1)
	enemy.set_control(true)
	enemy.set_physics_process(false)
	f.is_cpu = false

func begin() -> void:
	ir.v_press(1, "weapon_swap")
	f._physics_process(1.0 / 60.0)
	ir.v_release(1, "weapon_swap")
	check(f.state == actor.State.SWAP and f.sword_swap_frame == 0, "request starts dedicated transfer counter")

func ticks(count: int) -> void:
	for i in count:
		f._physics_process(1.0 / 60.0)

func _run() -> void:
	await process_frame
	ir = root.get_node("InputRouter")
	actor = load("res://scripts/fighter/Fighter.gd")
	var gs = root.get_node("GameState")
	gs.free_move = true
	gs.skeletal_rig = false
	gs.water = load("res://scripts/core/WaveField.gd").new()
	gs.water.amplitudes = Vector3.ZERO
	ir.apply_profile("solo", false)
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.data = load("res://data/characters/choko.tres")
	enemy = load("res://scenes/fighter/Fighter.tscn").instantiate()
	enemy.data = load("res://data/characters/skea.tres")
	enemy.player_index = 2
	root.add_child(f)
	root.add_child(enemy)
	f.set_physics_process(false)
	enemy.set_physics_process(false)
	f.opponent = enemy
	enemy.opponent = f
	fresh()
	var capacity: int = f.grapple.charges
	begin()
	ticks(11)
	check(f.sword_hand == "right" and f.sword_swap_frame == 11, "old hand owns sword before contact")
	ticks(1)
	check(f.sword_hand == "left" and f.sword_swap_frame == 12, "contact commits exactly once at12")
	ticks(11)
	check(f.sword_hand == "left" and f.state == actor.State.SWAP, "new owner persists through recovery")
	for action: String in ["left_hand", "right_hand", "skill1", "skill2", "ultimate", "grapple_enemy", "grapple_parkour", "weapon_swap"]:
		ir.v_press(1, action)
	ticks(1)
	check(f.state == actor.State.IDLE and f.sword_hand == "left", "transfer ends at24")
	for action: String in ["left_hand", "right_hand", "skill1", "skill2", "ultimate", "grapple_enemy", "grapple_parkour", "weapon_swap"]:
		check(not ir.buffered(1, action), "blocked final-frame input consumed: " + action)
	check(f.grapple.charges == capacity and f.grapple.registry.owned(1) == 0, "transfer leaves hook inventory untouched")
	# Actual damage callbacks before and after contact preserve committed authority.
	for frame: int in [11, 12]:
		fresh()
		begin()
		ticks(frame)
		f.receive_hit(enemy, enemy.data.light)
		check(f.state == actor.State.HITSTUN and f.sword_hand == ("right" if frame == 11 else "left"), "hit interruption preserves owner at%d" % frame)
	# Allowed actions interrupt first; no hidden new combo or handoff event.
	for frame: int in [11, 12]:
		for action: String in ["dash", "left_leg", "right_leg"]:
			fresh()
			begin()
			ticks(frame)
			ir.v_press(1, action)
			ticks(1)
			check(f.sword_hand == ("right" if frame == 11 else "left"), action + " uses committed owner")
			check(f.state == (actor.State.DASH if action == "dash" else actor.State.ATTACK), action + " acts after interrupt")
			if action != "dash":
				check(f.current_move.anim.begins_with("limb_" + action) and f.chain_index == 0, "leg remains leg and fresh combo")
	fresh()
	begin()
	ticks(6)
	f.hitstop_frames = 3
	ticks(3)
	check(f.sword_swap_frame == 6 and f.sword_hand == "right", "hitstop freezes transfer counter")
	f.frozen_frames = 3
	ticks(3)
	check(f.sword_swap_frame == 6 and f.sword_hand == "right", "time stop freezes transfer counter")
	f.set_physics_process(true)
	paused = true
	for i in 4:
		await process_frame
	check(f.sword_swap_frame == 6, "scene pause freezes transfer")
	f.set_physics_process(false)
	paused = false
	fresh()
	check(f.sword_hand == "right" and f.sword_swap_frame == 0, "round reset restores right owner")
	# Invalid states and busy hands consume requests rather than triggering later.
	for state: int in [actor.State.CROUCH, actor.State.BLOCK, actor.State.JUMP, actor.State.ATTACK, actor.State.GRAPPLE, actor.State.HITSTUN]:
		fresh()
		f.state = state
		ir.v_press(1, "weapon_swap")
		check(not f._try_sword_swap() and not ir.buffered(1, "weapon_swap"), "invalid state rejects and consumes %d" % state)
	fresh()
	f._start_move(f.data.light)
	f.move_frame = f.data.light.total_frames() - 1
	ir.v_press(1, "weapon_swap")
	ticks(2)
	check(f.state != actor.State.SWAP and not ir.buffered(1, "weapon_swap"), "busy-frame V cannot trigger after attack ends")
	for phase: int in [1, 2, 3, 4, 5]:
		fresh()
		f.grapple.phase = phase
		ir.v_press(1, "weapon_swap")
		check(not f._try_sword_swap() and not ir.buffered(1, "weapon_swap"), "busy hook rejects transfer %d" % phase)
	fresh()
	ir.v_press(2, "weapon_swap")
	check(not enemy._try_sword_swap() and enemy.sword_hand == "right", "Skea has no sword swap")
	# Actual keyboard and R3 use the canonical action, including UI release fences.
	key(KEY_V, true)
	ticks(1)
	check(f.state == actor.State.SWAP, "physical SOLO V starts transfer")
	key(KEY_V, false)
	fresh()
	pad(JOY_BUTTON_RIGHT_STICK, true)
	ticks(1)
	check(f.state == actor.State.SWAP, "physical R3 starts transfer")
	pad(JOY_BUTTON_RIGHT_STICK, false)
	var owner := Node.new()
	root.add_child(owner)
	fresh()
	key(KEY_V, true)
	ir.acquire_ui(owner)
	ir.release_ui(owner)
	ticks(1)
	check(f.state != actor.State.SWAP, "held V through UI cannot transfer")
	key(KEY_V, false)
	key(KEY_V, true)
	ticks(1)
	check(f.state == actor.State.SWAP, "fresh V after UI recovers")
	key(KEY_V, false)
	fresh()
	pad(JOY_BUTTON_RIGHT_STICK, true)
	ir.acquire_ui(owner)
	ir.release_ui(owner)
	ticks(1)
	check(f.state != actor.State.SWAP, "held R3 through UI cannot transfer")
	pad(JOY_BUTTON_RIGHT_STICK, false)
	pad(JOY_BUTTON_RIGHT_STICK, true)
	ticks(1)
	check(f.state == actor.State.SWAP, "fresh R3 after UI recovers")
	pad(JOY_BUTTON_RIGHT_STICK, false)
	owner.free()
	ir.apply_profile("shared", false)
	key(KEY_H, true)
	check(ir.buffered(1, "weapon_swap") and not ir.buffered(2, "weapon_swap"), "shared H belongs to P1")
	key(KEY_H, false)
	key(KEY_P, true)
	check(ir.buffered(2, "weapon_swap") and not ir.buffered(1, "weapon_swap"), "shared P belongs to P2")
	key(KEY_P, false)
	ir.apply_profile("solo", false)
	# A held key spans real physics ticks: no automatic second transfer after completion.
	fresh()
	f.set_physics_process(true)
	key(KEY_V, true)
	for i in 36:
		await physics_frame
		await process_frame
	f.set_physics_process(false)
	check(f.sword_hand == "left" and f.state != actor.State.SWAP, "held V does not repeat transfer")
	key(KEY_V, false)
	# Donor authority is invariant; active-side selection changes only pose metadata.
	var helper: GDScript = load("res://scripts/fighter/LimbMoves.gd")
	var excluded := ["id", "display_name", "anim", "anim_chain", "anim_clip", "anim_clip_rec", "anim_clip_chain", "anim_clip_chain_rec", "contact_time", "contact_time_chain"]
	for hand: String in ["left", "right"]:
		for stance: int in 3:
			for index: int in 3:
				var move = helper.resolve(f.data, hand + "_hand", index, "", stance == 1, stance == 2, hand)
				var donor = f.data.air_light if stance == 2 else (f.data.crouch_light if stance == 1 else f.data.light)
				check(move.anim.begins_with("sword_" + hand + "_hand_"), "armed normal selects sword family")
				for property: Dictionary in donor.get_property_list():
					if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name not in excluded:
						check(move.get(property.name) == donor.get(property.name), "sword preserves donor " + property.name)
		fresh()
		f.sword_hand = hand
		ir.v_press(1, hand + "_hand")
		f._try_limb_attack(false)
		check(f.attack_sword_hand == hand and f.current_move.anim.begins_with("sword_"), "attack snapshots committed armed hand")
		var captured: String = f.current_move.anim
		f.sword_hand = "left" if hand == "right" else "right"
		check(f.current_move.anim == captured and f.attack_sword_hand == hand, "attack snapshot does not follow later hand mutation")
		f.state = actor.State.IDLE
		f._start_move(f.data.light)
		check(f.attack_sword_hand == f.sword_hand, "legacy attack snapshots hand")
		f.state = actor.State.IDLE
		f._limb_action = "left_leg"
		f._start_move(f.data.ultimate)
		check(f._limb_action == "", "legacy sword ultimate clears prior leg identifier")
		check(f.attack_sword_hand == f.sword_hand, "ultimate snapshots hand")
	f.queue_free()
	enemy.queue_free()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	gs.water = null
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("SWORD_STATE_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
