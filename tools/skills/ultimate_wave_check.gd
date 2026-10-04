extends SceneTree
## Range/lifetime integration, including negative controls: rear/side/height/throw/expired ult.
var checks: int = 0
var failures: int = 0
var f
var enemy
var actor: Script
var wave: Script
var book: Script
var storm: Script
var fx: Script

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ULTIMATE_WAVE: " + label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.free_move = true
	gs.skeletal_rig = false
	gs.water = null
	actor = load("res://scripts/fighter/Fighter.gd")
	wave = load("res://scripts/skills/SkeaWave.gd")
	book = load("res://scripts/skills/GrimoireFx.gd")
	storm = load("res://scripts/skills/SwordStormFx.gd")
	fx = load("res://scripts/fx/Fx.gd")
	var scene := Node3D.new()
	root.add_child(scene)
	current_scene = scene
	var effects := Node3D.new()
	effects.name = "FX"
	scene.add_child(effects)
	f = load("res://scenes/fighter/Fighter.tscn").instantiate()
	f.data = load("res://data/characters/skea.tres")
	enemy = load("res://scenes/fighter/Fighter.tscn").instantiate()
	enemy.data = load("res://data/characters/choko.tres")
	enemy.player_index = 2
	scene.add_child(f)
	scene.add_child(enemy)
	f.set_physics_process(false)
	enemy.set_physics_process(false)
	f.opponent = enemy
	enemy.opponent = f
	f.reset_for_round(0.0, 1)
	enemy.reset_for_round(8.0, -1)
	f.state = actor.State.IDLE
	enemy.state = actor.State.IDLE
	f.ult_fx = book.spawn(f, f.data.ultimate_veil)
	f.ult_fx.set_physics_process(false)
	var limbs: Script = load("res://scripts/fighter/LimbMoves.gd")
	for action: String in limbs.ACTIONS:
		for stance: int in 3:
			var m = limbs.resolve(f.data, action, 0, "", stance == 1, stance == 2)
			var box: Dictionary = wave.hitbox_for(f, m)
			check(is_equal_approx(box.size.x - m.hitbox_size.x, 1.0), action + " +1m at stance%d" % stance)
			check(is_equal_approx(box.offset.x - box.size.x * 0.5, m.hitbox_offset.x - m.hitbox_size.x * 0.5), "rear edge unchanged")
			check(box.offset.y == m.hitbox_offset.y and box.size.y == m.hitbox_size.y and box.size.z == m.hitbox_size.z, "height and side unchanged")
			var visual = wave.spawn(f, m)
			check(visual != null and is_equal_approx(visual.global_position.y, f.position.y + m.hitbox_offset.y), "wave starts at limb hit height")
			visual.queue_free()
	var normal = f.data.light
	var off_box: Dictionary = wave.hitbox_for(f, normal)
	fx.enabled = false
	check(wave.hitbox_for(f, normal) == off_box and wave.spawn(f, normal) == null, "FX off changes no collision")
	fx.enabled = true
	for excluded in [f.data.skill1, f.data.ultimate, f.data.throw_move]:
		if excluded != null:
			check(wave.hitbox_for(f, excluded).size == excluded.hitbox_size, "skills/ult/throws never extended")
	# Real shape queries: front metre hits once, rear/lateral/vertical positions do not.
	for direction: Vector3 in [Vector3.RIGHT, Vector3.FORWARD]:
		f.forward = direction
		var side := direction.cross(Vector3.UP)
		for offset: Vector3 in [direction * 2.2, direction * 3.3, -direction * 1.5, direction * 2.2 + side * 2.0, direction * 2.2 + Vector3.UP * 4.0]:
			enemy.reset_for_round(8.0, -1)
			enemy.state = actor.State.IDLE
			enemy.position = offset
			f.position = Vector3.ZERO
			f.state = actor.State.IDLE
			f._start_move(normal)
			# Start-up auto-targets a new human attack. This probe begins at the committed
			# active frame, after a victim has moved outside that captured direction.
			f._set_forward(direction)
			f.move_frame = normal.startup
			f.airborne_attack = false
			await physics_frame
			await process_frame
			var hp_before: float = enemy.hp
			f._tick_attack(0.0)
			var hp_after: float = enemy.hp
			var wanted: bool = offset == direction * 2.2
			check((hp_after < hp_before) == wanted, "authoritative range direction%s at%s" % [direction, offset])
			for i in normal.active - 1:
				f._tick_attack(0.0)
			check(enemy.hp == hp_after, "one contact for entire active window")
	f.ult_fx.end_ult()
	check(wave.hitbox_for(f, normal).size == normal.hitbox_size, "ended ult immediately loses extension")
	# Reset while frozen must clear both the simulation and visual tails synchronously.
	f.state = actor.State.IDLE
	enemy.state = actor.State.IDLE
	f.ult_fx = book.spawn(f, f.data.ultimate_veil)
	var grimoire = f.ult_fx
	var crest = wave.spawn(f, normal)
	f.frozen_frames = 120
	f.reset_for_round(0.0, 1)
	check(f.ult_fx == null and grimoire.is_queued_for_deletion() and crest.is_queued_for_deletion(), "frozen round reset retires book and wave")
	for owner_ko: bool in [true, false]:
		f.state = actor.State.IDLE
		enemy.state = actor.State.IDLE
		var crystal = storm.spawn(enemy)
		enemy.frozen_frames = 120
		if owner_ko:
			enemy.state = actor.State.KO
		else:
			f.state = actor.State.KO
		crystal._physics_process(0.0)
		check(crystal.is_queued_for_deletion() and crystal.hit_log.is_empty(), "KO clears frozen crystal before any damage")
	f.state = actor.State.IDLE
	enemy.state = actor.State.IDLE
	var reset_crystal = storm.spawn(enemy)
	enemy.reset_for_round(3.0, -1)
	check(reset_crystal.is_queued_for_deletion(), "round reset retires crystal immediately")
	scene.queue_free()
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("ULTIMATE_WAVE_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
