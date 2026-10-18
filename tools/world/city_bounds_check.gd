extends SceneTree
## Plan docs/Plans/2026-10-14-T6-Acceptance-Crane-Albedo-AB.md, «Рішення T1 після приймань T6» (2026-10-15), choice «а»:
## the district's invisible edge (CityLayout.boundary_veils, CityDistrict._boundary_veils) on the real CityWorld.
## Subject: for every boundary of the district and every height a hero reaches, the hero stays inside the district, and
## the edge is a collider only the hero's body meets — nothing drawn, no camera, no rope, no parkour surface.
##   B1 build   — one veil per boundary wall («<wall>Veil»): a StaticBody3D on BOUNDARY_VEIL_LAYER alone, mask 0, one
##                live box, the wall's plan to 1 mm, from the wall's top up to at least the highest solid of the district
##                + Skea's jump (+2.80, T6 docs/Audit/2026-10-15-T6-Geometry-Fix-Acceptance.md § 3.2) + the hero capsule
##                (1.8, Fighter.tscn); nothing visual under it; no other collider on its layer;
##   B2 sweep   — every SWEEP_STEP along each boundary and every SWEEP_RISE of height from the floor to the veil's top less
##                the capsule: a hero capsule (r 0.35, h 1.8) cast outward with the city hero's mask from SWEEP_INSIDE inside
##                the line stops before its axis reaches the line (a start the capsule does not fit is counted, not judged);
##   B3 unseen  — from 0.5 m inside to 1.5 m outside each boundary at y 6 and 12, rays with the follow camera's mask (the live
##                CityCamera arm), the rope's masks (GrappleHook: cover | world | hurtbox, cover | world) and the world mask 1
##                meet no veil; the city hero's mask holds the veil;
##   B4 parkour — CityParkourMotor finds no wall at the veil: _wall(hero, outward) from 0.4 m inside at feet y 5, 7, 9 at
##                three points of each boundary is empty (no wall run, side run, kick or grip on thin air);
##   B5 escape  — both heroes, real W and Space (T6's escape_probe.gd rule: Space once the hero is `jump_after` m along its
##                heading, on the floor; W held 170 ticks): T6's west runs from the terrace (y 4) and the service gallery
##                (y 6.3), the north terrace west of the clock tower over its parapet, the east terrace, and spots by each
##                boundary the hero is placed on (the tall house's mansard, the crane's cab, the SE wing's mansard, the SW
##                block's roof): never past |x| or |z| 32, never recovered to the spawn.
## --break=<m> is a negative control, one form each of «the edge does not hold or is not invisible to the rest»: gap (the
## north veil gone), low (every veil's top at 8 m), world (the veils on the world layer too, which the camera, the rope and
## the motor see), mesh (a veil drawn), hero (the city hero's mask without the veil). Sentinel CITY_BOUNDS_COMPLETE
## checks=N failures=M mutation=<m> red=<families|none>; failures print "CITY_BOUNDS: [family] ...". A family is the
## guard's tag, the label's first word lower-cased (B1 → b1 … B5 → b5). Each negative of tools/gates/playable_check.sh
## names the families it must turn red, so a negative that goes red on a neighbouring guard no longer passes (T4 audit
## 2026-10-15 part 2, class 18).
const BREAKS := ["gap", "low", "world", "mesh", "hero"]
const FIGHTER_R: float = 0.35          # Fighter.tscn BodyShape
const FIGHTER_H: float = 1.8
const SKEA_JUMP: float = 2.80          # T6 § 3.2: «стрибок із гребеня піднімає ступні до … 9,00 (Skea)» from 6.20
const SWEEP_STEP: float = 2.0          # a grain, not a threshold
const SWEEP_RISE: float = 0.5
const SWEEP_INSIDE: float = 0.5
const SAME: float = 0.001
const GRAPPLE_COVER: int = 8           # ArenaLayout.COVER_LAYER
# [label, start, heading, jump_after] — T6's escape_probe.gd RUNS_COMMON (west) and the T2 all-boundary set
# (docs/Fix/2026-10-15-Stall-Wedge-Boundary-Fix.md § 4); «_t»: a spot the hero is placed on, not a route.
const RUNS: Array = [
	["W_terrace_z20", Vector3(-26.0, 4.0, -20.0), Vector3(-1, 0, 0), 3.3],
	["W_gallery_run_end", Vector3(-22.0, 6.31, -17.3), Vector3(-1, 0, 0), 4.3],
	["W_lintel", Vector3(-27.4, 6.54, -13.95), Vector3(-1, 0, 0), 0.0],
	["N_terrace_x29", Vector3(-29.0, 4.0, -26.0), Vector3(0, 0, -1), 1.5],
	["N_tallhouse_mansard_t", Vector3(20.0, 17.55, -28.0), Vector3(0, 0, -1), 0.6],
	["E_terrace_z22", Vector3(26.0, 4.0, -22.0), Vector3(1, 0, 0), 3.3],
	["E_crane_cab_t", Vector3(28.0, 10.4, -14.9), Vector3(1, 0, 0), 0.0],
	["S_sewing_mansard_t", Vector3(26.0, 13.55, 27.0), Vector3(0, 0, 1), 2.0],
	["S_swblock_roof_t", Vector3(-20.0, 11.55, 27.0), Vector3(0, 0, 1), 2.0],
]
var mutation := "none"
var checks: int = 0
var failures: int = 0
var red: Dictionary = {}   # family → true for every family with a red check (the sentinel's red=)
var world: Node3D
var space: PhysicsDirectSpaceState3D
var held: Dictionary = {}


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


## One guard's verdict. A red check adds its family, the label's tag (its first word lower-cased), to `red`.
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		var tag: String = label.get_slice(" ", 0).to_lower()
		red[tag] = true
		push_error("CITY_BOUNDS: [%s] %s" % [tag, label])


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _key(code: Key, down: bool) -> void:
	if bool(held.get(code, false)) == down:
		return
	held[code] = down
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()


static func _v(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]


func _open_world(hero: String) -> void:
	root.get_node("GameState").p1_character = hero
	root.get_node("InputRouter").apply_profile("solo", false)
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	world.story_save_enabled = false
	world.journey_save_enabled = false
	world.lower_story_save_enabled = false
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	await _ticks(40)
	world.onboarding.skip()
	space = world.get_world_3d().direct_space_state


func _close_world() -> void:
	_key(KEY_W, false)
	_key(KEY_SPACE, false)
	world.queue_free()
	current_scene = null
	await _ticks(3)


func _veil(id: String) -> StaticBody3D:
	return world.district.get_node_or_null(id) as StaticBody3D


func _break_scene() -> void:
	match mutation:
		"gap":
			_veil("NorthBoundaryVeil").free()
		"low":
			for spec: Dictionary in CityLayout.boundary_veils():
				var body := _veil(spec.id)
				var box := (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
				var bottom: float = body.position.y - box.size.y * 0.5
				box.size.y = 8.0 - bottom
				body.position.y = bottom + box.size.y * 0.5
		"world":
			for spec: Dictionary in CityLayout.boundary_veils():
				_veil(spec.id).collision_layer |= 1
		"mesh":
			var body := _veil("WestBoundaryVeil")
			var mesh := MeshInstance3D.new()
			var cube := BoxMesh.new()
			cube.size = ((body.get_child(0) as CollisionShape3D).shape as BoxShape3D).size
			mesh.mesh = cube
			body.add_child(mesh)
		"hero":
			world.player.collision_mask &= ~CityLayout.BOUNDARY_VEIL_LAYER


func _box_of(body: CollisionObject3D) -> AABB:
	var box := AABB()
	for child: Node in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null or shape.disabled:
			continue
		var wb: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
		box = wb if box.size == Vector3.ZERO else box.merge(wb)
	return box


## B1: the four veils as built, against the walls they stand on and the district's highest solid.
func _b1_build() -> void:
	var walls: Dictionary = {}
	for block: Dictionary in CityLayout.blocks():
		if String(block.id).ends_with("Boundary"):
			walls[block.id] = block
	var highest: float = -INF
	var highest_name := ""
	var on_layer: Array[String] = []
	for node: Node in world.district.find_children("*", "CollisionObject3D", true, false):
		var body := node as CollisionObject3D
		if (body.collision_layer & CityLayout.BOUNDARY_VEIL_LAYER) != 0:
			on_layer.append(String(body.name))
			continue
		if (body.collision_layer & 1) == 0 or String(body.name).ends_with("Boundary"):
			continue
		var box := _box_of(body)
		if box.size != Vector3.ZERO and box.end.y > highest:
			highest = box.end.y
			highest_name = String(world.district.get_path_to(body))
	var need: float = highest + SKEA_JUMP + FIGHTER_H
	print("CITY_BOUNDS_INFO highest solid %s top=%.2f need_veil_top=%.2f veil_top=%.2f on_layer=%s" % [highest_name, highest, need, CityLayout.BOUNDARY_VEIL_TOP, on_layer])
	_check(walls.size() == 4, "B1 the district has four boundary walls (%d)" % walls.size())
	var veils: int = 0
	for id: String in walls:
		var wall: Dictionary = walls[id]
		var body := _veil(id + "Veil")
		if body == null:
			_check(false, "B1 %s has its veil %sVeil" % [id, id])
			continue
		veils += 1
		var shapes: Array[CollisionShape3D] = []
		var visual: Array[String] = []
		for child: Node in body.find_children("*", "", true, false):
			if child is CollisionShape3D and (child as CollisionShape3D).shape != null and not (child as CollisionShape3D).disabled:
				shapes.append(child as CollisionShape3D)
			elif child is VisualInstance3D:
				visual.append(String(child.name))
		var box := _box_of(body)
		var wall_c: Vector3 = wall.center
		var wall_s: Vector3 = wall.size
		var wall_top: float = wall_c.y + wall_s.y * 0.5
		_check(body.collision_layer == CityLayout.BOUNDARY_VEIL_LAYER and body.collision_mask == 0, "B1 %sVeil is on the veil layer alone, mask 0 (layer %d, mask %d)" % [id, body.collision_layer, body.collision_mask])
		_check(shapes.size() == 1 and shapes[0].shape is BoxShape3D, "B1 %sVeil has one live box (%d shapes)" % [id, shapes.size()])
		_check(visual.is_empty(), "B1 %sVeil draws nothing (%s)" % [id, visual])
		_check(absf(box.get_center().x - wall_c.x) <= SAME and absf(box.get_center().z - wall_c.z) <= SAME and absf(box.size.x - wall_s.x) <= SAME and absf(box.size.z - wall_s.z) <= SAME, "B1 %sVeil covers the wall's plan (%s, wall centre %s size %s)" % [id, box, _v(wall_c), _v(wall_s)])
		_check(absf(box.position.y - wall_top) <= SAME, "B1 %sVeil starts on the wall's top %.2f (%.3f)" % [id, wall_top, box.position.y])
		_check(box.end.y >= need, "B1 %sVeil reaches %.2f ≥ the highest solid %.2f + Skea's jump %.2f + the capsule %.2f (%.2f)" % [id, box.end.y, highest, SKEA_JUMP, FIGHTER_H, need])
	_check(veils == 4 and on_layer.size() == 4, "B1 four veils and no other collider on the veil layer (%d veils, on layer: %s)" % [veils, on_layer])


func _boundaries() -> Array[Dictionary]:
	# line: the boundary's inner face; out: the outward normal; along: the axis it runs on.
	return [
		{"name": "West", "out": Vector3(-1, 0, 0), "line": -32.0},
		{"name": "East", "out": Vector3(1, 0, 0), "line": 32.0},
		{"name": "North", "out": Vector3(0, 0, -1), "line": -32.0},
		{"name": "South", "out": Vector3(0, 0, 1), "line": 32.0},
	]


func _point(b: Dictionary, along: float, inside: float, y: float) -> Vector3:
	var out: Vector3 = b.out
	var p: Vector3 = out * (absf(float(b.line)) - inside) + Vector3(absf(out.z), 0, absf(out.x)) * along
	p.y = y
	return p


func _capsule_query(mask: int) -> PhysicsShapeQueryParameters3D:
	var capsule := CapsuleShape3D.new()
	capsule.radius = FIGHTER_R
	capsule.height = FIGHTER_H
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule
	q.collision_mask = mask
	q.exclude = [world.player.get_rid()]
	return q


## B2: the capsule cast outward at every step of every boundary and every height stops before the line.
func _b2_sweep() -> void:
	var mask: int = world.player.collision_mask
	var top: float = CityLayout.BOUNDARY_VEIL_TOP - FIGHTER_H
	for b: Dictionary in _boundaries():
		var cast: int = 0
		var skipped: int = 0
		var through: Array[String] = []
		var along: float = -32.0 + 1.0
		while along <= 32.0 - 1.0 + SAME:
			var y: float = 0.0
			while y <= top + SAME:
				var start: Vector3 = _point(b, along, SWEEP_INSIDE, y)
				var q := _capsule_query(mask)
				q.transform = Transform3D(Basis.IDENTITY, start + Vector3.UP * FIGHTER_H * 0.5)
				if not space.intersect_shape(q, 1).is_empty():
					skipped += 1
				else:
					cast += 1
					q.motion = Vector3(b.out) * 2.0
					var fraction: PackedFloat32Array = space.cast_motion(q)
					if fraction[0] * 2.0 >= SWEEP_INSIDE - SAME and through.size() < 6:
						through.append("%.0f@y%.1f" % [along, y])
					elif fraction[0] * 2.0 >= SWEEP_INSIDE - SAME:
						through.append("...")
				y += SWEEP_RISE
			along += SWEEP_STEP
		print("CITY_BOUNDS_INFO B2 %s cast=%d skipped=%d through=%s" % [b.name, cast, skipped, through])
		_check(cast > 0 and through.is_empty(), "B2 %s: a hero capsule cast outward at every %.1f m and %.1f m of height up to %.1f stops before the line (%d casts, %d through: %s)" % [b.name, SWEEP_STEP, SWEEP_RISE, top, cast, through.size(), through])


## B3: the camera's, the rope's and the world's rays pass the veils; the city hero's mask holds them.
func _b3_unseen() -> void:
	var camera_mask: int = world.camera_rig.arm.collision_mask
	var masks := {"camera": camera_mask, "rope_shot": GRAPPLE_COVER | 1 | 4, "rope_line": GRAPPLE_COVER | 1, "world": 1}
	for b: Dictionary in _boundaries():
		var hits: Array[String] = []
		for along: float in [-20.0, 0.0, 20.0]:
			for y: float in [6.0, 12.0]:
				for key: String in masks:
					var q := PhysicsRayQueryParameters3D.create(_point(b, along, 0.5, y), _point(b, along, -1.5, y), int(masks[key]))
					q.exclude = [world.player.get_rid()]
					var hit: Dictionary = space.intersect_ray(q)
					if not hit.is_empty() and String((hit.collider as Node).name).ends_with("Veil"):
						hits.append("%s@%.0f,y%.0f" % [key, along, y])
		_check(hits.is_empty(), "B3 %s: the camera, the rope and the world rays meet no veil (%s)" % [b.name, hits])
	_check((world.player.collision_mask & CityLayout.BOUNDARY_VEIL_LAYER) != 0, "B3 the city hero's mask holds the veil (mask %d)" % world.player.collision_mask)


## B4: the parkour motor finds no wall at the veil.
func _b4_parkour() -> void:
	var p: CharacterBody3D = world.player
	for b: Dictionary in _boundaries():
		var walls: Array[String] = []
		for along: float in [-20.0, 0.0, 20.0]:
			for y: float in [5.0, 7.0, 9.0]:
				p.global_position = _point(b, along, 0.4 + FIGHTER_R, y)
				var hit: Dictionary = p.parkour._wall(p, Vector3(b.out))
				if not hit.is_empty():
					walls.append("%.0f@y%.0f:%s" % [along, y, (hit.collider as Node).name])
		_check(walls.is_empty(), "B4 %s: the parkour motor takes no veil for a wall (%s)" % [b.name, walls])
	p.restart_at(CityLayout.spawn_position())


## B5: real keys from the routes and the placed spots: never past the boundary, never recovered.
func _b5_escape(hero: String) -> void:
	var p: CharacterBody3D = world.player
	for run: Array in RUNS:
		var start: Vector3 = run[1]
		var heading: Vector3 = run[2]
		var jump_after: float = run[3]
		_key(KEY_W, false)
		_key(KEY_SPACE, false)
		world.ropes.clear_match()
		p.restart_at(start)
		p._set_forward(heading)
		world.camera_rig.reset_view()
		world.camera_rig.aim.yaw_offset = atan2(-heading.x, -heading.z)
		await _ticks(20)
		var settle: Vector3 = p.global_position
		_key(KEY_W, true)
		var jumped := -1
		var out_ticks := 0
		var recovered := false
		var max_y := -INF
		var last: Vector3 = p.global_position
		for t: int in 170:
			if jumped < 0 and (p.global_position - settle).dot(heading) >= jump_after and p.is_on_floor():
				jumped = t
				_key(KEY_SPACE, true)
			await _ticks(1)
			if jumped >= 0 and t == jumped + 2:
				_key(KEY_SPACE, false)
			var pos: Vector3 = p.global_position
			if pos.distance_to(last) > 6.0:
				recovered = true
			last = pos
			max_y = maxf(max_y, pos.y)
			if absf(pos.x) > 32.0 or absf(pos.z) > 32.0:
				out_ticks += 1
		_key(KEY_W, false)
		_key(KEY_SPACE, false)
		await _ticks(20)
		print("CITY_BOUNDS_INFO B5 %s %s settle=%s jumped=%d max_y=%.2f out_ticks=%d recovered=%s end=%s" % [hero, run[0], _v(settle), jumped, max_y, out_ticks, recovered, _v(p.global_position)])
		_check(jumped >= 0, "B5 %s %s: the run takes off (Space at %.1f m)" % [hero, run[0], jump_after])
		_check(out_ticks == 0 and not recovered, "B5 %s %s: the hero stays inside the district (%d ticks past the line, recovered=%s, max y %.2f)" % [hero, run[0], out_ticks, recovered, max_y])


func _run() -> void:
	await process_frame
	if mutation != "none" and not mutation in BREAKS:
		push_error("CITY_BOUNDS: unknown --break=" + mutation)
		quit(2)
		return
	root.get_node("GameState").set_free_move(true)
	for hero: String in ["choko", "skea"]:
		await _open_world(hero)
		_break_scene()
		await _ticks(2)
		if hero == "choko":
			_b1_build()
			_b2_sweep()
			_b3_unseen()
			_b4_parkour()
			await _ticks(2)
		await _b5_escape(hero)
		await _close_world()
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	var deadline: int = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < deadline:
		await process_frame
		OS.delay_msec(1)
	var families: Array = red.keys()
	families.sort()
	print("CITY_BOUNDS_COMPLETE checks=%d failures=%d mutation=%s red=%s" % [checks, failures, mutation,
		",".join(PackedStringArray(families)) if not families.is_empty() else "none"])
	quit(1 if failures else 0)
