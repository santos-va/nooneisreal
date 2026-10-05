extends SceneTree
## Real InputRouter -> CityFighter walking over shipped geometry, never waypoint teleports.
var checks: int = 0
var failures: int = 0
var input: Node
var fighter: Node3D
var district: CityDistrict

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_LOWER_GALLERY: " + label)

func tick() -> void:
	await physics_frame
	fighter._physics_process(1.0 / 60.0)

func walk(target: Vector3, label: String, limit: int = 500) -> bool:
	var reached: bool = false
	for frame: int in limit:
		var delta: Vector3 = target - fighter.position
		delta.y = 0
		if delta.length() <= 0.13:
			reached = true
			break
		input.set_view_basis(1, delta.normalized())
		input.v_set(1, "up", true)
		await tick()
	input.v_set(1, "up", false)
	for frame: int in 10:
		await tick()
	check(reached and absf(fighter.position.y-target.y) < 0.16, label + " reached actual floor at " + str(fighter.position))
	return reached

func ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [fighter.get_rid()]
	return district.get_world_3d().direct_space_state.intersect_ray(query)

func run() -> void:
	await process_frame
	var game: Node = root.get_node("GameState")
	game.skeletal_rig = false
	game.free_move = true
	game.water = null
	input = root.get_node("InputRouter")
	district = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(district)
	var gallery: Node3D = district.lower_gallery
	for hero: String in ["choko", "skea"]:
		var base: Node3D = load("res://scenes/fighter/Fighter.tscn").instantiate()
		base.set_script(load("res://scripts/world/CityFighter.gd"))
		fighter = base
		fighter.data = load("res://data/characters/" + hero + ".tres")
		root.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.restart_at(CityLayout.spawn_position())
		input.v_clear(1)
		gallery.set_lamp_aligned(false)
		gallery.set_record_delivered(false)
		for frame: int in 12:
			await tick()
		# Full original approach, then a continuous branch through the actual arch.
		for point: Vector3 in [Vector3.ZERO,Vector3(18,0,10),Vector3(18,0,8),
			Vector3(18,4,-10),Vector3(20,4,-20),Vector3(0,4,-20),Vector3(-16,4,-20),
			Vector3(-16,4,-15.1),Vector3(-13.65,4,-15.1)]:
			if not await walk(point,hero + " continuous archive approach"):
				break
		var lamp_point: Node3D = gallery.lower_points().lamp
		check(ray(fighter.position+Vector3.UP*1.1,lamp_point.global_position).is_empty(),hero+" real close lamp LOS")
		check(not gallery.lamp_aligned(),hero+" traversal never changes story pose")
		check(not gallery.plate_is_lit(),hero+" away detent never authorizes copying")
		var light: SpotLight3D = gallery.lamp_light()
		var plate_body: Node3D = gallery.get_node("RoutePlate")
		var away: Basis = light.global_basis
		var away_hit: Dictionary = ray(light.global_position,light.global_position-light.global_basis.z*light.spot_range)
		check(not away_hit.is_empty() and away_hit.collider != plate_body,hero+" away cone centre hits blank wall")
		var plate_mesh: MeshInstance3D = plate_body.get_node("Visible")
		var plate_material: Material = plate_mesh.material_override
		var light_energy: float = light.light_energy
		gallery.set_lamp_aligned(true)
		await tick()
		check(gallery.lamp_aligned() and light.global_basis != away,hero+" head and actual light rotate")
		var hit: Dictionary = ray(light.global_position,light.global_position-light.global_basis.z*light.spot_range)
		check(not hit.is_empty() and hit.collider == plate_body,hero+" actual beam centre strikes collidable plate")
		check(light.light_cull_mask == 8 and plate_mesh.layers == 8,hero+" real light scoped to archive receivers")
		check(plate_mesh.material_override == plate_material and light.light_energy == light_energy,hero+" orientation uses identical material and energy")
		check(plate_material is StandardMaterial3D,hero+" plate receives genuine attenuated light")
		check(gallery.plate_is_lit(),hero+" actual clear beam authorizes inspection")
		var aligned_basis: Basis = light.basis
		light.rotate_y(PI/2)
		check(not gallery.plate_is_lit(),hero+" rotated light rejected despite cached aligned flag")
		light.basis = aligned_basis
		var mask: int = light.light_cull_mask
		light.light_cull_mask = 0
		check(not gallery.plate_is_lit(),hero+" disconnected receiver layer cannot authorize copy")
		light.light_cull_mask = mask
		var blocker := StaticBody3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.25,1,1)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		blocker.add_child(collision)
		blocker.position = Vector3(-12.3,5.45,-14.2)
		root.add_child(blocker)
		await tick()
		check(not gallery.plate_is_lit(),hero+" real inserted occluder blocks aligned beam")
		blocker.queue_free()
		await tick()
		check(gallery.plate_is_lit(),hero+" removing occluder restores actual beam")
		for point: Vector3 in [Vector3(-12.3,4,-15.1),Vector3(-11.9,4,-14.2)]:
			await walk(point,hero+" walk around physical lamp stand")
		var plate_point: Node3D = gallery.lower_points().plate
		check(ray(fighter.position+Vector3.UP*1.1,plate_point.global_position).is_empty(),hero+" actual close plate LOS")
		check(fighter.is_on_floor(),hero+" plate reachable without jump or grapple")
		check(not ray(Vector3(-10.2,5.2,-14.2),plate_point.global_position).is_empty(),hero+" back wall blocks through-wall inspection")
		gallery.set_record_delivered(true)
		var copy: Node3D = gallery.get_node("DeliveredRouteCopy")
		check(copy.visible and copy.find_children("*","CollisionObject3D",true,false).is_empty(),hero+" delivered copy visible and cannot block workshop")
		gallery.set_lamp_aligned(false)
		check(copy.visible,hero+" turning lamp away cannot erase delivered record")
		gallery.set_record_delivered(false)
		check(not copy.visible,hero+" suppressed successor removes visible record")
		# Leave via the arch and walk to the unchanged old clock checkpoint and west ramp.
		for point: Vector3 in [Vector3(-12.3,4,-15.1),Vector3(-16,4,-15.1),Vector3(-16,4,-20),
			Vector3(-24,4,-19),Vector3(-29,4,-19),Vector3(-29,4,-10),Vector3(-29,0,8),Vector3(-29,0,10)]:
			await walk(point,hero+" preserved return route")
		input.v_clear(1)
		fighter.queue_free()
		await process_frame
	district.queue_free()
	for singleton: String in ["Sfx","UltMusic","Music"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec()+250
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_LOWER_GALLERY_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
