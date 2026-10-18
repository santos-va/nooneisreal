extends SceneTree
## Current contact, live loaded spans, visibility and finite inventory boundaries.
## The T4 transfer refusals below are the duel's and stay. The city (ADR-028 п. 5, T5 docs/GDD/2026-10-15-Rope-Climb-
## Numbers.md § 8): a rope shown 0.701 m off the hand (APPROACH ROPE, a target on screen) — E keeps the hang, its length
## and the stock; the same rope out of view for the 15-tick window — E lets go (city_rope_approach).
var checks: int = 0
var failures: int = 0
var f: Node3D
var other: Node3D
var registry: Node3D
var token: int
var Hook: GDScript

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ROPE_CONTACT: " + label)

func _initialize() -> void:
	run.call_deferred()

func packet() -> Dictionary:
	return {"target_id": String(registry.records[token].marker.get_path()), "candidate_kind": "rope", "rope_token": token}

func blocker(at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.12, 0.4, 0.4)
	shape.shape = box
	body.add_child(shape)
	body.position = at
	root.add_child(body)
	return body

func run() -> void:
	await process_frame
	Hook = load("res://scripts/grapple/GrappleHook.gd")
	var state: Node = root.get_node("GameState")
	state.free_move = true
	state.skeletal_rig = false
	state.water = null
	for player: int in [1, 2]:
		var actor: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
		actor.data = load("res://data/characters/choko.tres" if player == 1 else "res://data/characters/skea.tres")
		actor.player_index = player
		root.add_child(actor)
		actor.set_physics_process(false)
		actor.control_locked = false
		if player == 1:
			f = actor
		else:
			other = actor
	registry = f.grapple.registry
	registry.set_physics_process(false)
	token = registry.issue(1)
	registry.deploy(token, 1, Vector3(0, 8, 0), Vector3.ZERO, 8.0)
	var stock: int = f.grapple.charges
	for distance: float in [0.0, 0.699, 0.700, 0.701, 2.0, 3.0]:
		for velocity: float in [-60.0, 0.0, 60.0]:
			f.position = Vector3(distance, 2, 0)
			f.velocity = Vector3(velocity, 0, 0)
			var contact: Dictionary = f.grapple.rope_grab_candidate()
			check(not contact.is_empty() == (distance <= 0.7), "current boundary %.3f velocity %.0f" % [distance, velocity])
			check(f.grapple.charges == stock and registry.records.size() == 1, "query is inventory-pure")
	f.position = Vector3(3, 2, 0)
	for action: String in ["grapple", "grapple_parkour"]:
		check(f.grapple.fire(false, action, packet()) == Hook.Target.NONE and not f.grapple.busy(), "far rope refuses gameplay " + action)
		check(f.grapple.charges == stock and f.grapple.token == 0, "far refusal cannot issue or rewind a new token")
	check(f.grapple.presentation_grip().is_empty(), "far cue never extends animation hands")
	# A stale packet may not silently become an unrelated new throw.
	var stale := packet()
	stale.target_id = "/root/MissingRope"
	stale.rope_token = 9001
	check(f.grapple.fire(false, "grapple_parkour", stale) == Hook.Target.NONE and not f.grapple.busy(), "stale rope cue cannot fall through")
	# Preparation and confirmation revalidate current distance; release cancels it.
	f.position = Vector3(0.699, 2, 0)
	f.grapple.aim_intent = packet()
	check(f.grapple._prepare_rope_catch(), "near prepare is allowed")
	f.position.x = 0.701
	f.grapple.drive(1.0 / 60.0, true)
	check(not f.grapple.busy() and not f.grapple.attached, "leaving reach before confirm cancels")
	f.position.x = 0.699
	check(f.grapple._prepare_rope_catch(), "near prepare can rearm")
	f.grapple.drive(1.0 / 60.0, false)
	check(not f.grapple.busy(), "release cancels preparation")
	f.grapple.fire(false, "grapple_parkour", packet())
	check(f.grapple.attached and f.grapple.charges == stock and f.grapple._deployed_token == token, "rearm attaches once without a new device")
	check(f.grapple.presentation_grip().point.is_equal_approx(f.position + Hook.HAND), "animation grip uses current physical hand")
	f.grapple.detach()
	# Grip and support rays protect different physical paths.
	f.position = Vector3(0.6, 2, 0)
	var wall := blocker(Vector3(0.3, 3.25, 0))
	await physics_frame
	check(f.grapple.line_clear(f.position + Hook.HAND, Vector3(0,8,0)), "grip blocker leaves support ray clear")
	check(f.grapple.rope_grab_candidate().is_empty(), "grip blocker prevents through-wall contact")
	wall.position.y = 5.625
	await physics_frame
	check(f.grapple.line_clear(f.position + Hook.HAND, Vector3(0,3.25,0)), "support blocker leaves grip ray clear")
	check(f.grapple.rope_grab_candidate().is_empty(), "support blocker prevents immediate invalid tether")
	wall.queue_free()
	await physics_frame
	# Loaded rope ends at the other user's live hand, not its old vertical tail.
	other.position = Vector3(0, 2, 0)
	var foreign_stock: int = other.grapple.charges
	other.grapple.fire(false, "grapple_parkour", packet())
	check(other.grapple.attached and other.grapple.charges == foreign_stock, "foreign user reuses original owner token")
	other.position.x = 4.0
	f.position = Vector3(2, 4.375, 0.2)
	var moving: Dictionary = f.grapple.rope_grab_candidate()
	check(not moving.is_empty() and moving.point.is_equal_approx(Vector3(2,5.625,0)), "contact follows actual slanted loaded span")
	f.position = Vector3(0, 2, 0)
	check(f.grapple.rope_grab_candidate().is_empty(), "hidden old vertical span is not a ghost catch target")
	f.position = Vector3(2, 4.375, 0.2)
	other.position.x = -4.0
	check(f.grapple.rope_grab_candidate().is_empty(), "moving user invalidates previous contact immediately")
	other.grapple.detach()
	f.position = Vector3(0.6, 2, 0)
	check(not f.grapple.rope_grab_candidate().is_empty(), "released rope restores hanging authoritative span")
	while f.grapple.charges > 0:
		registry.issue(1)
	f.grapple.fire(false, "grapple_parkour", packet())
	check(f.grapple.attached and f.grapple.charges == 0, "zero stock still permits valid reuse")
	check(f.grapple.charges + registry.owned(1) == f.grapple.max_charges, "reuse conserves owner inventory")
	var old := packet()
	registry.clear_match()
	check(f.grapple.fire(false, "grapple_parkour", old) == Hook.Target.NONE and not f.grapple.busy(), "deleted token cannot rearm or spend")
	check(f.grapple.charges == f.grapple.max_charges and other.grapple.charges == other.grapple.max_charges, "match reset restores finite capacities")
	# Independent T4 transfer refusal checks from a real attached source.
	var source_token: int = registry.issue(1)
	var target_token: int = registry.issue(1)
	registry.deploy(source_token, 1, Vector3(0,8,0), Vector3.ZERO, 8.0)
	registry.deploy(target_token, 1, Vector3(4,8,0), Vector3.ZERO, 8.0)
	f.position = Vector3(0.1,2,0)
	f.velocity = Vector3(2,3,4)
	f.grapple.fire(false,"grapple_parkour",{"candidate_kind":"rope","rope_token":source_token,"target_id":str(registry.records[source_token].marker.get_path())})
	var source_length: float = f.grapple.rope_length
	var source_stock: int = f.grapple.charges
	var intent: Dictionary = {"candidate_kind":"rope","rope_token":target_token,"target_id":str(registry.records[target_token].marker.get_path())}
	check(f.grapple.attached and f.grapple._deployed_token==source_token,"T4 source actually attached")
	check(not f.grapple.retarget(intent),"T4 far transfer refused")
	check(f.grapple.attached and f.grapple._deployed_token==source_token and f.grapple.rope_length==source_length,"T4 far transfer preserves support and length")
	check(f.grapple.charges==source_stock and f.velocity==Vector3(2,3,4),"T4 far transfer preserves stock and velocity")
	var missing: Dictionary=intent.duplicate(true)
	missing.target_id="/root/DeletedSupport"
	check(not f.grapple.retarget(missing) and f.grapple._deployed_token==source_token,"T4 stale transfer preserves current hang")
	f.position=Vector3(3.299,2,0)
	check(not f.grapple.retarget(intent) and f.grapple._deployed_token==source_token,"T4 .701 transfer remains old support")
	f.position=Vector3(3.301,2,0)
	check(f.grapple.retarget(intent) and f.grapple._deployed_token==target_token,"T4 .699 transfer reaches new support")
	check(f.grapple.charges==source_stock and registry.records[source_token].deployed,"T4 transfer keeps old device and stock")
	f.grapple.detach()
	other.grapple._attach_existing(target_token)
	other.position=Vector3(4,2,0)
	f.position=Vector3(4.699,2,0)
	check(not f.grapple.rope_grab_candidate(target_token).is_empty(),"T4 current loaded endpoint .699")
	f.position=Vector3(4.701,2,0)
	f.velocity=Vector3(-100,0,0)
	check(f.grapple.rope_grab_candidate(target_token).is_empty(),"T4 endpoint velocity never grants futurecontact")
	other.grapple.detach()
	var untouched: Dictionary=registry.records.duplicate(true)
	f.position=Vector3(4.701,2,0)
	for action in ["grapple","grapple_parkour"]:
		for repeat in 10:
			check(f.grapple.fire(false,action,intent)==Hook.Target.NONE and not f.grapple.busy(),"T4 repeatedfarinput staysidle")
	check(f.grapple.charges==source_stock and registry.records.size()==untouched.size(),"T4 repeatedfarinput inventorystable")
	city_rope_approach()
	# The city's let-go plays its release sound: let the audio servers drop their decoders before the tree exits.
	for singleton: String in ["Sfx", "UltMusic"]:
		var node := root.get_node_or_null(singleton)
		if node != null:
			node.queue_free()
	var until := Time.get_ticks_msec() + 300
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("ROPE_CONTACT_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func city_rope_approach() -> void:
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo", false)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	var helper: Node = load("res://scripts/core/HarpoonAim.gd").new()
	root.add_child(helper)
	helper.setup(camera, true)
	var city: Node3D = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
	city.set_script(load("res://scripts/world/CityFighter.gd"))
	city.data = load("res://data/characters/choko.tres")
	root.add_child(city)
	city.set_physics_process(false)
	var hook: Node = city.grapple
	for shown: bool in [true, false]:
		registry.clear_match()
		var source: int = registry.issue(1)
		var target: int = registry.issue(1)
		registry.deploy(source, 1, Vector3(0, 8, 0), Vector3.ZERO, 8.0)
		registry.deploy(target, 1, Vector3(4, 8, 0), Vector3.ZERO, 8.0)
		city.position = Vector3(0.1, 2, 0)
		city.velocity = Vector3.ZERO
		city.state = (load("res://scripts/fighter/Fighter.gd") as GDScript).State.GRAPPLE
		city.control_locked = false
		hook.fire(false, "grapple_parkour", {"candidate_kind": "rope", "rope_token": source, "target_id": str(registry.records[source].marker.get_path())})
		city.position = Vector3(3.299, 2, 0) # the hand 0.701 m off the target rope, as the T4 refusal above
		var tag := "city APPROACH ROPE .701 %s: " % ("shown" if shown else "out of view 20 ticks")
		check(hook.attached and hook._deployed_token == source, tag + "the source rope holds")
		var now: int = input.frame()
		var packet := {"tick": now - 1, "player": 1, "enemy_mode": false, "origin": city.position + Hook.HAND, "point": Vector3(4, 3.25, 0),
			"target_id": str(registry.records[target].marker.get_path()) if shown else "", "candidate_kind": "rope" if shown else "",
			"rope_token": target if shown else 0, "reachable": false, "assist": true, "reason": "" if shown else "none"}
		helper.published = packet
		helper._published_before = packet
		helper.last_target_tick = now - 1 if shown else now - 20
		var length: float = hook.rope_length
		var stock: int = hook.charges
		input.v_press(1, "grapple_parkour")
		city._tick_grapple(city._read_intent())
		input.v_release(1, "grapple_parkour")
		if shown:
			check(hook.attached and hook._deployed_token == source and absf(hook.rope_length - length) <= 0.000001 and hook.charges == stock, tag + "E keeps the hang, its length and the stock (attached %s, token %d)" % [hook.attached, hook._deployed_token])
		else:
			check(not hook.attached and hook.charges == stock and registry.records[source].deployed, tag + "E lets go, the rope stays, the stock %d (attached %s)" % [stock, hook.attached])
		hook.detach()
	registry.clear_match()
	city.set_process(false)
