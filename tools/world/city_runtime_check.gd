extends SceneTree
## Production city traversal, both heroes, real physics and inherited input routing.
var checks: int = 0
var failures: int = 0
var ir: Node
var gs: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_RUNTIME: " + label)

func ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame
		await process_frame

func hold(action: String, count: int) -> void:
	ir.v_press(1, action)
	await ticks(count)
	ir.v_release(1, action)
	await ticks(2)

func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	ir = root.get_node("InputRouter")
	gs.skeletal_rig = false
	for hero: String in ["choko", "skea"]:
		gs.p1_character = hero
		gs.free_move = false
		gs.duel = load("res://scripts/core/DuelFrame.gd").new()
		gs.duel.behind = true
		var prior_duel = gs.duel
		var prior_water = load("res://scripts/core/WaveField.gd").new()
		gs.water = prior_water
		ir.apply_profile("shared", false)
		var city: Node3D = load("res://scenes/world/CityWorld.tscn").instantiate()
		root.add_child(city)
		current_scene = city
		await ticks(15)
		var player = city.player
		check(player.opponent == null and get_nodes_in_group("fighters").size() == 1, hero + " has no dummy foe")
		check(gs.free_move and gs.water == null and ir.profile == "solo", hero + " isolates exploration context")
		check(player.position.z > 22.0 and player.on_ground(), hero + " grounded spawn outside duel radius")
		var before: Vector3 = player.position
		await hold("up", 30)
		check(player.position.z < before.z - 1.0, hero + " W travels camera-forward outside duel radius")
		check(city.onboarding.progress > 1.0, hero + " tutorial observes actual travel")
		city.camera_rig.aim.apply_look(Vector2(-PI / 2.0, 0.0))
		await ticks(3)
		before = player.position
		await hold("up", 20)
		check(player.position.x < before.x - 0.7, hero + " rotated view changes held forward coherently")
		city.restart_exploration()
		await ticks(8)
		ir.v_press(1, "jump")
		await ticks(18)
		check(player.position.y > 0.5 and not player.on_ground(), hero + " real airborne jump")
		ir.v_release(1, "jump")
		await ticks(80)
		check(player.on_ground() and absf(player.position.y) < 0.1, hero + " lands on street collision")
		ir.v_press(1, "right")
		await ticks(2)
		before = player.position
		await hold("dash", 25)
		ir.v_release(1, "right")
		check(player.position.x > before.x + 1.0 and player.position.z > 22.0, hero + " dash remains outside duel radius")
		# Traverse the real district ramp rather than teleporting through an expected height.
		player.restart_at(Vector3(18, 0, 8))
		city.camera_rig.reset_view()
		await ticks(8)
		await hold("up", 230)
		check(player.position.y > 3.9 and player.position.z < -10.0 and player.on_ground(), hero + " walks up real ramp onto roof")
		check(absf(player.floor_y() - 4.0) < 0.1, hero + " roof support is four metres above street")
		await hold("down", 240)
		check(player.position.y < 0.1 and player.position.z > 7.0 and player.on_ground(), hero + " walks down ramp to street")
		player.restart_at(Vector3(20, 4, -20))
		city.camera_rig.reset_view()
		await ticks(8)
		await hold("left", int(42.0 / player.data.walk_speed * 60.0))
		check(player.position.x < -21.0 and player.position.y > 3.9 and player.on_ground(), hero + " crosses real bridge to west roof")
		player.restart_at(Vector3(-29, 4, -14))
		await ticks(8)
		await hold("down", int(24.0 / player.data.walk_speed * 60.0))
		check(player.position.z > 8.0 and player.position.y < 0.1, hero + " west return ramp closes the upper loop")
		player.restart_at(Vector3(0, 0, -20))
		await ticks(12)
		check(player.on_ground() and absf(player.floor_y()) < 0.1 and player.position.y < 0.1, hero + " overhead bridge never becomes floor")
		player.restart_at(Vector3(24, 4, -10.5))
		await ticks(8)
		await hold("down", 20)
		check(player.state == player.State.JUMP and player.position.y < 3.9 and not player.on_ground(), hero + " walking off ledge enters falling state")
		await ticks(75)
		check(player.on_ground() and player.position.y < 0.1, hero + " ledge drop lands on street")
		# An independent obstacle must stop both ordinary walking and Skea's swept flash.
		city.restart_exploration()
		var obstacle := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(8, 5, 0.5)
		collision.shape = box
		obstacle.add_child(collision)
		city.add_child(obstacle)
		obstacle.position = Vector3(0, 2.5, 20)
		await ticks(3)
		ir.v_press(1, "up")
		await hold("dash", 35)
		await ticks(30)
		ir.v_release(1, "up")
		check(player.position.z > 20.5, hero + " world wall blocks walk and dash")
		obstacle.position = Vector3(0, 2.5, player.position.z + 2.0)
		await ticks(12)
		check(city.camera_rig.arm.get_hit_length() < city.camera_rig.follow_distance - 0.5, hero + " camera arm shortens before wall")
		obstacle.queue_free()
		await ticks(2)
		player.restart_at(Vector3(0, 0, 8))
		player._set_forward(Vector3.RIGHT)
		city.camera_rig.reset_view()
		await ticks(8)
		ir.v_press(1, "grapple_parkour")
		await ticks(65)
		check(player.grapple.attached, hero + " parkour contact attaches actual street anchor")
		var length: float = player.grapple.rope_length
		before = player.position
		await hold("jump", 22)
		print("CITY_REEL hero=%s length=%f -> %f position=%s -> %s attached=%s phase=%s velocity=%s" % [hero, length, player.grapple.rope_length, before, player.position, player.grapple.attached, player.grapple.phase, player.velocity])
		check(player.grapple.rope_length < length - 0.3 and player.position.x > before.x + 0.3, hero + " shallow-angle Space reels toward anchor")
		ir.v_release(1, "grapple_parkour")
		await ticks(4)
		check(city.ropes.records.size() == 1, hero + " released rope persists during exploration")
		# A steep rope has upward lift; a shallow grounded rope first pulls toward its support.
		city.restart_exploration()
		player.restart_at(Vector3(5, 0, 8))
		player._set_forward(Vector3.RIGHT)
		await ticks(8)
		ir.v_press(1, "grapple_parkour")
		await ticks(65)
		check(player.grapple.attached, hero + " closer street approach attaches a steep rope")
		length = player.grapple.rope_length
		before = player.position
		await hold("jump", 22)
		check(player.grapple.rope_length < length - 0.3 and player.position.y > before.y + 0.1, hero + " Space lifts from a steep rope without walking input")
		ir.v_release(1, "grapple_parkour")
		await ticks(4)
		city.restart_exploration()
		await ticks(10)
		check(city.ropes.records.is_empty() and player.grapple.charges == player.data.grapple_charges, hero + " restart clears rope inventory")
		check(city.onboarding.current_id() == "move", hero + " restart resets tutorial")
		player.meter = player.MAX_METER
		await hold("skill1", 3)
		await hold("skill2", 3)
		await hold("ultimate", 3)
		await hold("grapple_enemy", 3)
		check(player.current_move == null and player.cooldowns.skill1 == 0.0 and player.cooldowns.skill2 == 0.0 and player.meter == player.MAX_METER and not player.grapple.busy(), hero + " unavailable city skills are not executed or charged")
		player.position = Vector3(0, -15, 0)
		await ticks(10)
		check(player.position.z > 22.0 and player.position.y >= -0.1, hero + " fall recovery returns to safe spawn")
		ir.v_clear(1)
		city.queue_free()
		await ticks(3)
		check(not gs.free_move and ir.profile == "shared" and gs.water == prior_water and gs.duel == prior_duel and gs.duel.behind, hero + " leaving city restores prior arena context")
		check(not paused and not ir.ui_suppressed() and ir.view_basis(1) == Vector3.ZERO, hero + " leaving city clears UI and camera input")
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_RUNTIME_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
