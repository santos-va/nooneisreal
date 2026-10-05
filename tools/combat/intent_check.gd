extends SceneTree
## Real InputRouter -> Fighter ticks/contact/hitstop, including lifecycle boundaries.
const DT: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0
var a: Node3D
var b: Node3D
var input: Node
var game: Node
var Actor: Script
var world: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBAT_INTENT: " + label)

func solid(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	body.position = center
	return body

func tick() -> void:
	await physics_frame
	# Preserve the real router-before-fighters order, with exactly one tick per participant.
	input._physics_process(DT)
	a._physics_process(DT)
	b._physics_process(DT)

func tap(player: int, action: String) -> void:
	input.v_press(player, action)
	input.v_release(player, action)

func fresh(hero: String, outcome: String = "hit") -> void:
	for player: int in [1,2]:
		input.v_clear(player)
		input.clear_player_presses(player)
	a.data = game.load_character(hero)
	b.data = game.load_character("choko")
	a.reset_for_round(-0.6,1)
	b.reset_for_round(0.6,-1)
	a.set_control(true)
	b.set_control(true)
	if outcome == "whiff":
		b.position.x = 8.0
	if outcome == "block":
		input.v_set(2,"block",true)
	for index: int in 4:
		await tick()
	if outcome == "invulnerable":
		b.invulnerable_frames = 90

func begin(hero: String, action: String, outcome: String = "hit") -> void:
	await fresh(hero, outcome)
	tap(1,action)
	await tick()
	check(a.state == Actor.State.ATTACK and a._limb_action == action, hero + " real input starts " + action)

func connect_attack(hero: String, action: String) -> void:
	await begin(hero,action)
	for index: int in 40:
		if a._normal_connected:
			break
		await tick()
	check(a._normal_connected and a.hitstop_frames > 0, hero + " actual hitbox creates hitstop " + action)

func await_chain(index: int) -> bool:
	for frame: int in 70:
		if a.chain_index == index and a.state == Actor.State.ATTACK:
			return true
		await tick()
	return false

func capture_pending() -> void:
	tap(1,"right_hand")
	await tick()
	check(a.combat_intent.action == "right_hand", "contact tap retained")

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	game = root.get_node("GameState")
	input = root.get_node("InputRouter")
	input.set_physics_process(false)
	game.free_move = true
	game.skeletal_rig = false
	game.water = null
	load("res://scripts/fx/Fx.gd").enabled = false
	world = Node3D.new()
	root.add_child(world)
	solid(Vector3(0,-0.5,0),Vector3(40,1,40))
	for player: int in [1,2]:
		var fighter: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
		fighter.player_index = player
		root.add_child(fighter)
		fighter.set_physics_process(false)
		if player == 1:
			a = fighter
		else:
			b = fighter
	a.opponent = b
	b.opponent = a
	for hero: String in ["choko","skea"]:
		for limb: String in ["left_hand","left_leg"]:
			await connect_attack(hero,limb)
			var frozen_move_frame: int = a.move_frame
			await capture_pending()
			var original_age: int = a.combat_intent.age
			while a.hitstop_frames > 0:
				await tick()
				check(a.combat_intent.age == original_age and a.move_frame == frozen_move_frame, hero + " own hitstop preserves original input age/move")
			check(a.chain_index == 0, "hitstop never starts an early cancel")
			check(await await_chain(1), hero + " contact tap survives to legal continuation " + limb)
			check(a._limb_action == "right_hand" and a.combat_intent.action.is_empty(), "one requested continuation consumed")
			for frame: int in 55:
				await tick()
			check(a.chain_index == 0 and a.state != Actor.State.ATTACK, "one tap never creates an automatic extra attack")
		# Original raw age six is preserved, not refreshed by entering hitstop.
		await begin(hero,"left_leg")
		var startup: int = a.current_move.startup
		while a.move_frame < startup - 4:
			await tick()
		tap(1,"right_hand")
		while not a._normal_connected and a.state == Actor.State.ATTACK:
			await tick()
		await tick()
		check(a.combat_intent.age == input.BUFFER_FRAMES and a.combat_intent.action == "right_hand", "six-tick old raw edge retains its age")
		while a.hitstop_frames > 0:
			await tick()
		await tick()
		check(a.combat_intent.action.is_empty() and a.chain_index == 0, "age six expires at first unfrozen tick")
		# Block, whiff and i-frames do not protect a contact-time queue.
		for outcome: String in ["block","whiff","invulnerable"]:
			await begin(hero,"left_hand",outcome)
			while a.state == Actor.State.ATTACK and a.move_frame <= a.current_move.startup:
				await tick()
			tap(1,"right_hand")
			await tick()
			check(not a._normal_connected and a.combat_intent.action.is_empty(), outcome + " cannot retain protected continuation")
			# A separate fresh tap at the very end of recovery remains a neutral buffered attack.
			while a.state == Actor.State.ATTACK and a.move_frame < a.move_end_frame(a.current_move) - 1:
				await tick()
			tap(1,"right_leg")
			for frame: int in 3:
				await tick()
			check(a.state == Actor.State.ATTACK and a._limb_action == "right_leg" and a.chain_index == 0, outcome + " keeps ordinary late-recovery buffer")
	# Most recent distinct press wins; timestamp ties keep ACTIONS order.
	await connect_attack("choko","left_leg")
	await capture_pending()
	tap(1,"right_leg")
	await tick()
	check(a.combat_intent.action == "right_leg", "fresh press replaces single pending slot")
	tap(1,"right_leg")
	tap(1,"left_hand")
	await tick()
	check(a.combat_intent.action == "left_hand", "equal timestamps use stable limb priority")
	check(not input.buffered(1,"right_leg"), "unselected simultaneous edge cannot replay")
	check(await await_chain(1), "replacement still starts exactly one continuation")
	check(a._limb_action == "left_hand", "replacement executes selected limb")
	await connect_attack("choko","left_leg")
	input.v_press(1,"right_hand")
	await tick()
	check(await await_chain(1), "held key starts its one fresh continuation")
	for frame: int in 55:
		await tick()
	check(input.held(1,"right_hand") and a.state != Actor.State.ATTACK, "held limb cannot auto-repeat after continuation")
	# A real wall keeps the opponent within reach while proving the full bounded string.
	var stop: StaticBody3D = solid(Vector3(1.2,2,0),Vector3(0.2,4,4))
	await connect_attack("choko","left_hand")
	for target: int in [1,2]:
		tap(1,"right_hand" if target == 1 else "left_hand")
		check(await await_chain(target), "actual confirmed string reaches index %d" % target)
		for frame: int in 40:
			if a._normal_connected:
				break
			await tick()
		check(a._normal_connected, "actual next strike reconnects")
	tap(1,"right_hand")
	await tick()
	check(a.combat_intent.action.is_empty(), "third hit cannot open a fourth-hit slot")
	for frame: int in 50:
		await tick()
	check(a.state != Actor.State.ATTACK and a.chain_index == 0, "three-hit string terminates")
	stop.queue_free()
	await tick()
	# Menu can enter and leave entirely while the fighter has no tick.
	await connect_attack("choko","left_leg")
	await capture_pending()
	var menu := Node.new()
	root.add_child(menu)
	input.acquire_ui(menu)
	input.release_ui(menu)
	menu.queue_free()
	await tick()
	check(a.combat_intent.action.is_empty(), "UI history epoch clears pending without an intervening fighter tick")
	# A released pad edge must not be recaptured after device disconnect.
	await connect_attack("choko","left_leg")
	var pad := InputEventJoypadButton.new()
	pad.device = 0
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	pad.pressed = true
	input._input(pad)
	pad.pressed = false
	input._input(pad)
	input._pad_connection_changed(0,false)
	await tick()
	check(a.combat_intent.action.is_empty() and not input.buffered(1,"right_hand"), "released pad edge discarded on disconnect")
	for boundary: String in ["freeze","control","hit","reset","rewind"]:
		await connect_attack("choko","left_leg")
		if boundary == "rewind":
			a.place_record()
		await capture_pending()
		tap(2,"left_leg")
		input.v_set(1,"right",true)
		input.v_set(1,"block",true)
		if boundary == "freeze":
			a.freeze(4)
		elif boundary == "control":
			a.set_control(false)
		elif boundary == "hit":
			a.receive_hit(b,b.data.light)
		elif boundary == "reset":
			tap(1,"left_leg")
			a.reset_for_round(-0.6,1)
			a.set_control(true)
		elif boundary == "rewind":
			tap(1,"left_leg")
			a.rewind()
		check(a.combat_intent.action.is_empty(), boundary + " clears protected pending")
		check(input.buffered(2,"left_leg"), boundary + " preserves other player's queued press")
		if boundary in ["reset","rewind"]:
			check(not input.buffered(1,"left_leg"), boundary + " clears own queued raw attack")
			check(input.held(1,"right") and input.held(1,"block") and not input.buffered(1,"block"), boundary + " preserves held movement/guard without new edges")
		await tick()
		check(a.combat_intent.action.is_empty(), boundary + " does not recapture old input")
	# Higher-tier cancellation wins over the pending limb and discards it.
	await connect_attack("choko","left_leg")
	await capture_pending()
	while a.hitstop_frames > 0:
		await tick()
	tap(1,"skill1")
	for frame: int in 6:
		await tick()
	check(a.current_slot == "skill1" and a._limb_action.is_empty() and a.combat_intent.action.is_empty(), "skill cancel retains priority without carrying the pending limb")
	# End-of-hitstun guard responds on the exact first legal grounded tick.
	for guarding: bool in [false,true]:
		await fresh("choko")
		a.receive_hit(b,b.data.light)
		input.v_set(1,"block",guarding)
		while a.hitstop_frames > 0 or a.stun_frames > 1:
			await tick()
		check(a.state == Actor.State.HITSTUN, "guard never shortens hitstun")
		await tick()
		check(a.state == (Actor.State.BLOCK if guarding else Actor.State.IDLE), "guard restored exactly at grounded stun end")
		if guarding:
			var hp_before: float = a.hp
			a.receive_hit(b,b.data.light)
			check(a.state == Actor.State.BLOCKSTUN and a.hp == hp_before, "first legal guard blocks actual frontal hit")
			b.position = a.position - a.forward * 1.2
			a.receive_hit(b,b.data.light)
			check(a.hp < hp_before, "held guard never blocks a back hit")
	await fresh("choko")
	a.position.y = 8.0
	a._set_state(Actor.State.JUMP)
	await tick()
	a.freeze(1)
	a.receive_hit(b,b.data.light)
	input.v_set(1,"block",true)
	for frame: int in 50:
		await tick()
		if a.frozen_frames == 0 and a.state != Actor.State.HITSTUN:
			break
	check(a.state == Actor.State.JUMP and not a.on_ground(), "airborne stun recovery never creates a grounded guard")
	# Physical just_pressed from before reset must not repopulate raw history.
	await fresh("choko")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F12
	var old_events: Array[InputEvent] = InputMap.action_get_events("p1_left_hand")
	InputMap.action_erase_events("p1_left_hand")
	InputMap.action_add_event("p1_left_hand",event)
	event.pressed = true
	Input.parse_input_event(event)
	# Deliver the queued OS event before the reset boundary; a later event is a fresh press.
	Input.flush_buffered_events()
	check(Input.is_action_pressed("p1_left_hand"), "physical fixture actually holds the key before reset")
	a.reset_for_round(-0.6,1)
	a.set_control(true)
	await tick()
	check(a.state != Actor.State.ATTACK and not input.buffered(1,"left_hand"), "reset fences stale physical just_pressed")
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	InputMap.action_erase_events("p1_left_hand")
	for old: InputEvent in old_events:
		InputMap.action_add_event("p1_left_hand",old)
	for player: int in [1,2]:
		input.v_clear(player)
	a.queue_free()
	b.queue_free()
	world.queue_free()
	for singleton: String in ["Sfx","UltMusic","Music"]:
		root.get_node(singleton).queue_free()
	var until_ms: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < until_ms:
		await process_frame
		OS.delay_msec(1)
	print("COMBAT_INTENT_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
