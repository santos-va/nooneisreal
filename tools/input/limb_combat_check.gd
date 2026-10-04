extends SceneTree
## Donor invariance and real Fighter dispatch / bounded cancellation contracts.
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LIMB_COMBAT: " + label)
func clear_inputs(ir: Node) -> void:
	ir.v_clear(1)
	for action: String in ir.ACTIONS:
		ir.buffered(1, action)

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var ir = root.get_node("InputRouter")
	var helper: GDScript = load("res://scripts/fighter/LimbMoves.gd")
	var actor: GDScript = load("res://scripts/fighter/Fighter.gd")
	gs.free_move = true
	gs.skeletal_rig = false
	# Production water grounding avoids an absent static floor in this isolated fixture.
	gs.water = load("res://scripts/core/WaveField.gd").new()
	gs.water.amplitudes = Vector3.ZERO
	var excluded: Array[String] = ["id", "display_name", "anim", "anim_chain", "anim_clip", "anim_clip_rec", "anim_clip_chain", "anim_clip_chain_rec", "contact_time", "contact_time_chain"]
	for hero: String in ["choko", "skea"]:
		var data = load("res://data/characters/%s.tres" % hero)
		for action: String in helper.ACTIONS:
			for stance: int in 3:
				for step: int in 3:
					var donor = data.air_light if stance == 2 else (data.crouch_light if stance == 1 else (data.heavy if action.ends_with("leg") else data.light))
					var move = helper.resolve(data, action, step, "left_hand", stance == 1, stance == 2)
					check(move != donor and move.anim.begins_with("limb_" + action + "_"), hero + " owns independent pose " + action)
					for property: Dictionary in donor.get_property_list():
						var name: String = property.name
						if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and name not in excluded:
							check(move.get(name) == donor.get(name), "donor contract " + hero + "/" + action + "/" + name)
		var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.data = data
		root.add_child(f)
		f.set_physics_process(false)
		f.control_locked = false
		f.player_index = 1
		for action: String in helper.ACTIONS:
			clear_inputs(ir)
			f.state = actor.State.IDLE
			f.crouching = false
			ir.v_press(1, action)
			check(f._try_limb_attack(false), "ground dispatch " + action)
			check(f.current_move.anim.begins_with(("sword_" if hero == "choko" and action == "right_hand" else "limb_") + action), "correct requested limb " + action)
			check(f.chain_index == 0, "fresh normal resets combo")
			clear_inputs(ir)
			ir.v_press(1, "right_hand")
			f._normal_connected = false
			check(not f._try_cancel(f.current_move), "whiff/block cannot chain " + action)
			clear_inputs(ir)
			ir.v_press(1, "right_hand")
			f._normal_connected = true
			var chained: bool = f._try_cancel(f.current_move)
			check(chained, "confirmed hands and legs can chain " + action)
			if chained:
				check(f.chain_index == 1, "second normal index")
				clear_inputs(ir)
				ir.v_press(1, "left_hand")
				f._normal_connected = true
				check(f._try_cancel(f.current_move) and f.chain_index == 2, "third normal permitted")
				clear_inputs(ir)
				ir.v_press(1, "right_hand")
				f._normal_connected = true
				check(not f._try_cancel(f.current_move), "fourth normal rejected")
			f._set_state(actor.State.HITSTUN)
			check(f._limb_action == "" and f.chain_index == 0 and not f._normal_connected, "interruption clears sequence")
		# Low legs also participate in the bounded confirmed three-hit sequence.
		clear_inputs(ir)
		f.state = actor.State.IDLE
		f.crouching = true
		ir.v_press(1, "left_leg")
		f._try_limb_attack(false)
		f._normal_connected = true
		clear_inputs(ir)
		ir.v_press(1, "left_hand")
		check(f._try_cancel(f.current_move) and f.chain_index == 1, "low leg confirmed continuation")
		clear_inputs(ir)
		var victim = load("res://scenes/fighter/Fighter.tscn").instantiate()
		victim.data = data
		victim.player_index = 2
		root.add_child(victim)
		victim.set_physics_process(false)
		f.opponent = victim
		victim.opponent = f
		f.position = Vector3.ZERO
		victim.position = Vector3(1.2, 0, 0)
		f.crouching = false
		var normal = helper.resolve(data, "left_hand", 0, "", false, false)
		for outcome: String in ["hit", "block", "invulnerable", "whiff"]:
			victim.hp = data.max_hp
			victim.state = actor.State.BLOCK if outcome == "block" else actor.State.IDLE
			victim.invulnerable_frames = 10 if outcome == "invulnerable" else 0
			victim.forward = Vector3.LEFT
			victim.position = Vector3(8, 0, 0) if outcome == "whiff" else Vector3(1.2, 0, 0)
			await physics_frame
			await process_frame
			f._start_move(normal)
			f._check_hit(normal)
			check(f._normal_connected == (outcome == "hit"), "real hit confirmation excludes " + outcome)
		victim.queue_free()
		f.queue_free()
		await process_frame
	await process_frame
	gs.water = null
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("LIMB_COMBAT_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
