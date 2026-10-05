extends SceneTree
## Independent actual-input corridor probe: reach a second wall without touchdown.
const DT: float = 1.0 / 60.0
var checks: int = 0
var failures: int = 0
var mutation: String = ""
var input: Node
var actor: Node3D
var solids: Node3D

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("T4_TRICKS: " + label)

func box(point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	solids.add_child(body)
	body.position = point
	return body

func step(press: String = "", release: String = "") -> void:
	await physics_frame
	input._physics_process(DT)
	if not release.is_empty():
		input.v_release(1, release)
	if not press.is_empty():
		input.v_press(1, press)
	actor._physics_process(DT)

func run() -> void:
	await process_frame
	var game: Node = root.get_node("GameState")
	var actor_script: Script = load("res://scripts/fighter/Fighter.gd")
	game.skeletal_rig = false
	game.free_move = true
	game.water = null
	input = root.get_node("InputRouter")
	input.set_physics_process(false)
	input.set_view_basis(1, Vector3.FORWARD)
	solids = Node3D.new()
	root.add_child(solids)
	box(Vector3(0,-0.5,0), Vector3(60,1,60))
	box(Vector3(0,6,0), Vector3(5,12,0.4))
	box(Vector3(0,6,3.2), Vector3(5,12,0.4))
	await physics_frame
	for hero: String in ["choko", "skea"]:
		actor = load("res://scenes/fighter/Fighter.tscn").instantiate()
		actor.set_script(load("res://scripts/world/CityFighter.gd"))
		actor.data = load("res://data/characters/" + hero + ".tres")
		root.add_child(actor)
		actor.set_physics_process(false)
		input.v_clear(1)
		actor.restart_at(Vector3(0,4,0.8))
		input.set_view_basis(1, Vector3.FORWARD)
		actor._set_state(actor_script.State.JUMP)
		actor.velocity = Vector3.ZERO
		input.v_set(1,"down",true)
		await step("jump")
		check(actor.parkour.phase != "wall_kick", hero + " initial held jump cannot launch a wall kick")
		await step("", "jump")
		var start: Vector3 = actor.position
		await step("jump")
		check(actor.parkour.phase == "wall_kick", hero + " release then fresh input launches from actual wall")
		check(actor.position.z > start.z and actor.position.y > start.y, hero + " kick moves away and upward")
		var frozen_position: Vector3 = actor.position
		var frozen_velocity: Vector3 = actor.velocity
		var frozen_snapshot: Dictionary = actor.parkour_snapshot()
		check(actor.freeze(3), hero + " live kick accepts freeze")
		for frame: int in 3:
			await step()
		check(actor.position == frozen_position and actor.velocity == frozen_velocity and actor.parkour_snapshot() == frozen_snapshot, hero + " freeze holds movement and trick progress without replenishing effort")
		var touched_floor: bool = false
		for frame: int in 24:
			await step()
			touched_floor = touched_floor or actor.is_on_floor()
		check(not touched_floor and actor.position.y > 2.0, hero + " whole corridor transfer remains airborne")
		check(actor.position.z > 2.15 and actor.position.z < 3.0, hero + " physical transfer reaches second wall without crossing it")
		check(actor.parkour.phase.is_empty(), hero + " first kick presentation has completed")
		input.v_release(1,"down")
		input.v_set(1,"up",true)
		await step("", "jump")
		if mutation == "budget":
			actor.parkour.kick_spent = false
		var before_second: float = actor.velocity.y
		await step("jump")
		check(actor.parkour.phase != "wall_kick", hero + " opposite wall cannot refill airborne kick budget")
		check(actor.velocity.y <= before_second, hero + " repeated jump adds no upward impulse")
		check(actor.invulnerable_frames == 0, hero + " traversal never grants combat invulnerability")
		actor.set_control(false)
		check(actor.parkour_snapshot().is_empty(), hero + " control loss clears presentation immediately")
		# Separate open-floor drop exercises actual touchdown, passive carry and UI interruption.
		input.v_clear(1)
		actor.restart_at(Vector3(10,0.2,8))
		actor._set_state(actor_script.State.JUMP)
		actor.velocity = Vector3(0,-9,-5)
		input.v_set(1,"up",true)
		input.v_set(1,"crouch",true)
		for frame: int in 3:
			await step()
		check(actor.parkour.phase == "landing_roll", hero + " independent real touchdown starts roll")
		var horizontal: float = Vector2(actor.velocity.x, actor.velocity.z).length()
		for frame: int in 5:
			await step()
			var current: float = Vector2(actor.velocity.x, actor.velocity.z).length()
			check(current <= horizontal + 0.00001, hero + " roll cannot add horizontal speed")
			check(actor.invulnerable_frames == 0 and not actor.dodging, hero + " roll remains combat-vulnerable")
			horizontal = current
		frozen_position = actor.position
		frozen_snapshot = actor.parkour_snapshot()
		check(actor.freeze(2), hero + " live roll accepts freeze")
		await step()
		await step()
		check(actor.position == frozen_position and actor.parkour_snapshot() == frozen_snapshot, hero + " frozen roll never slides or advances")
		input.acquire_ui(solids)
		await step()
		check(actor.parkour_snapshot().is_empty(), hero + " modal owner cancels roll")
		input.release_ui(solids)
		await step()
		check(actor.parkour_snapshot().is_empty(), hero + " closing modal cannot revive cancelled roll")
		actor.queue_free()
		await process_frame
	input.v_clear(1)
	input.clear_view_basis(1)
	input.set_physics_process(true)
	solids.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		root.get_node(singleton).queue_free()
	var drain_until_ms: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < drain_until_ms:
		await process_frame
		OS.delay_msec(1)
	print("T4_TRICKS_COMPLETE checks=%d failures=%d mutation=%s" % [checks, failures, mutation])
	quit(1 if failures else 0)
