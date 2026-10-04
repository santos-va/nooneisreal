extends SceneTree
## Independent acceptance: real ramp/bridge movement, swept rope contact and modal choices.
## Other location changes are explicit fixture teleports, never a manual-play claim.
var city: Node3D
var f: Node3D
var director: Node
var progress: Node
var Places: GDScript
var Layout: GDScript
var Actor: GDScript
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("T4_HOOK %s=%s" % [label,ok])
	if not ok:
		failures += 1
		push_error(label)
func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame
func press(fragment: String) -> void:
	for button: Node in director.dialogue.choices_box.get_children():
		if button is Button and fragment in button.text and not button.disabled:
			button.pressed.emit()
			return
	check(false,"missing button " + fragment)
func open_worker(index: int) -> void:
	director.dialogue.close()
	f.restart_at(Places.shops()[index].visit + Vector3(0,0,0.9))
	f.set_physics_process(false)
	director._refresh_actors()
	await ticks(3)
	check(director.find_nearest() == index,"reachable giver " + str(index))
	director.open_conversation(index)
func walk_to(target: Vector3, label: String) -> void:
	var arrived := false
	for tick in 600:
		await physics_frame
		var axis: Vector3 = target-f.global_position
		axis.y = 0.0
		if axis.length() < 0.2:
			arrived = true
			break
		f._wish = axis.normalized()
		f._set_forward(f._wish)
		f.state = Actor.State.WALK
		f._walk_free(1.0/60.0)
		await process_frame
	f._wish = Vector3.ZERO
	f.velocity = Vector3.ZERO
	f.state = Actor.State.IDLE
	check(arrived, "physical " + label)
	await ticks(3)
func _run() -> void:
	Places = load("res://scripts/world/CityPlaces.gd")
	Layout = load("res://scripts/world/CityLayout.gd")
	Actor = load("res://scripts/fighter/Fighter.gd")
	root.get_node("GameState").skeletal_rig = false
	root.get_node("GameState").p1_character = "choko"
	city = load("res://scenes/world/CityWorld.tscn").instantiate()
	root.add_child(city)
	current_scene = city
	f = city.player
	f.set_physics_process(false)
	director = city.npc_director
	progress = city.progress
	director.active_radius = 80.0
	director.save_enabled = false
	progress.save_enabled = false
	# First two quests are covered by district_life_check and native button/save acceptance.
	# Start their completed checkpoint without reading or writing any player progress.
	progress.heroes.clear()
	progress.hero_id = "choko"
	progress._ensure_hero()
	progress.heroes.choko.accepted = ["introductions", "parcel"]
	progress.heroes.choko.completed = ["introductions", "parcel"]
	progress.heroes.choko.events = {"meet": ["resident_00", "resident_01", "resident_02"], "deliver": ["thread_parcel"]}
	progress.heroes.choko.credits = 6
	check(progress.summary().completed == 2,"two completed quest checkpoint fixture")
	await open_worker(2)
	press("Доручення: Огляд")
	press("Беруся")
	director.dialogue.close()
	f.restart_at(Vector3(18,0,8))
	f.set_physics_process(false)
	await ticks(3)
	await walk_to(Vector3(18,4,-20),"east ramp to roof")
	await walk_to(Vector3(0,4,-20),"bridge objective")
	await walk_to(Vector3(-24,4,-19),"clock tower objective")
	check(progress.quest_status("roof_walk")=="ready","CityWorld real roof events complete objectives")
	await open_worker(2)
	press("Завершити: Огляд")
	press("Доручення: Дві")
	press("Беруся")
	director.dialogue.close()
	for index in 2:
		var anchor: Node3D
		for node: Node in get_nodes_in_group("grapple_anchor"):
			if node.global_position.distance_to(Layout.anchors()[index]) < 0.01:
				anchor = node
		var point: Vector3 = Layout.anchors()[index]
		f.grapple.detach()
		f.restart_at(Vector3(point.x,0,point.z))
		f.set_physics_process(false)
		await ticks(3)
		f.grapple.fire(false,"grapple_parkour",{"target_id":String(anchor.get_path()),"point":point})
		for tick in 90:
			await physics_frame
			f.grapple.drive(1.0/60.0,true)
			await process_frame
			if f.grapple.attached:
				break
		check(f.grapple.attached,"actual swept attachment " + str(index))
		await ticks(3)
	check(progress.quest_status("rope_route")=="ready","distinct real anchor hooks feed quest")
	f.grapple.detach()
	await open_worker(2)
	press("Завершити: Дві")
	await open_worker(1)
	press("Доручення: Знайомі")
	press("Беруся")
	director.dialogue.close()
	for index in range(3,7):
		var resident: Node3D = director.actors[index]
		f.restart_at(resident.global_position + Vector3(0,0,1))
		f.set_physics_process(false)
		await ticks(2)
		check(director.find_nearest()==index,"reachable outdoor resident " + str(index))
		director.open_conversation(index)
		director.dialogue.close()
	await open_worker(1)
	press("Завершити: Знайомі")
	press("Доручення: Свій")
	press("Беруся")
	press("Приміряти")
	press("М'ят")
	director.dialogue.close()
	f.restart_at(Vector3(0,0,20))
	f.set_physics_process(false)
	await ticks(3)
	check(progress.quest_status("own_style")=="ready","palette choice and real market visit feed quest")
	await open_worker(1)
	press("Завершити: Свій")
	check(progress.summary().completed==6,"all six completed through production event/UI hooks")
	print("T4_REMAINING_HOOKS_COMPLETE checks=%d failures=%d credits=%s" % [checks,failures,progress.summary().credits])
	city.queue_free()
	await ticks(90)
	for name: String in ["Sfx","UltMusic","Music"]:
		root.get_node(name).queue_free()
	var until: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	quit(1 if failures else 0)
