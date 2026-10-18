extends SceneTree
## T6 YELLOW (docs/Audit/2026-10-15-T6-Geometry-Fix-Acceptance.md § 5, «манекен»): from the cutting table's rim a hero
## jumped onto the tailor's dress form and stood on its flat top (y 1.96) for 50+ ticks. Its torso collider is now one
## plane falling west from a high edge against the shop wall (CityInteriors._dress_form_torso).
## Subject: the dress form holds no hero, however he comes onto it, and the cutting table's rim beside it keeps its way
## out. Real keys, both heroes unless said:
##   P1 place — T6's ТЗ: the hero put on (−17.8; 1.98; 13.0) is on the floor or the table (≤ 1.1 m) within 30 ticks;
##   P2 drops — the hero dropped from y 2.15 (under the shop's ceiling) every DROP_STEP over a disk of DROP_RADIUS round
##              the form's axis (a start the capsule does not fit is skipped): none rests on the form 30 ticks (Choko:
##              the capsule is the same for both, Fighter.tscn);
##   P3 jumps — from the cutting table 0.40 m inside its −z edge at 5 points across, W and Space toward the form: no run
##              rests on the form 30 ticks, none ends above 1.1 m (T6's ТЗ);
##   P4 rim   — stepping off the table's −z edge at its middle (T6 stuck_probe.gd, table_dressform): A and D lead to the
##              floor (T6 accepted this wedge «A, D → на підлогу в обох»).
## --break=<m> is a negative control, one form each of «a top the hero can stand on»: flat (the old cylinder r 0.37 up to
## 1.96), cone (a top narrowed up to the neck — r 0.37 → 0.25 → 0.10, T6's «звужений догори»), edge (the top falling west
## from the form's own east edge, 0.63 m off the wall). P4's own negatives, one form each of «a way off the rim does not
## lead to the floor» (T4 audit 2026-10-15 part 2, proposal 1): rim_step (a 0.3 m step under the gap between the table
## and the form, along the shop: both ways end on it), rim_west and rim_east (that step on one side of the rim only: A,
## or D, ends on it, the other way stays on the floor), rim_low (the step 0.08 m high, just over the floor's 0.05).
## Sentinel CITY_PERCH_COMPLETE checks=N failures=M mutation=<m> red=<families|none>; failures print "CITY_PERCH:
## [family] ...". A family is the guard's tag, the label's first word lower-cased (P1 → p1 … P4 → p4); the torso's
## presence is p0. Each negative of tools/gates/playable_check.sh names the families it must turn red, so a negative that
## goes red on a neighbouring guard no longer passes (T4 audit 2026-10-15 part 2, class 18).
const BREAKS := ["flat", "cone", "edge", "rim_step", "rim_west", "rim_east", "rim_low"]
## P4 negatives: [x from, x to, top] of the step on the floor under the gap between the cutting table's −z edge (z 14.05)
## and the form's foot (r 0.48 round the axis: z 13.48), from the shop's west wall to its east wall (inner faces x −23.2
## and −16.8, ShopWall at local x ∓3.3, 0.2 thick); the rim's hero stands at x −17.85 (P4), r 0.35.
const RIM_STEPS := {"rim_step": [-23.2, -16.8, 0.3], "rim_west": [-23.2, -18.0, 0.3], "rim_east": [-17.7, -16.8, 0.3],
	"rim_low": [-23.2, -16.8, 0.08]}
const RIM_STEP_Z := Vector2(13.5, 14.05)
const AXIS := Vector3(-17.8, 0, 13.0)        # the dress form: the tailor's door (−20, 0, 12) + local (2.2, 1.0)
const PLACE := Vector3(-17.8, 1.98, 13.0)    # T6 § 5 ТЗ
const HOLD_TICKS: int = 30                   # T6 § 5 ТЗ: «за ≤ 30 тиків опиняється на підлозі або на столі»
const OFF_HEIGHT: float = 1.1                # T6 § 5 ТЗ: «не закінчується вище 1,1 м»
const DROP_STEP: float = 0.15                # a grain, not a threshold
const DROP_RADIUS: float = 0.75              # the torso's 0.37 + the capsule's 0.35, rounded up
const TABLE_EDGE_Z: float = 14.05            # the cutting table's −z edge (local z 2.95 − 0.9)
var mutation := "none"
var checks: int = 0
var failures: int = 0
var red: Dictionary = {}   # family → true for every family with a red check (the sentinel's red=)
var world: Node3D
var space: PhysicsDirectSpaceState3D
var held: Dictionary = {}
var torso: StaticBody3D


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--break="):
			mutation = argument.trim_prefix("--break=")
	_run.call_deferred()


## One guard's verdict. A red check adds its family to `red`: the label's tag (its first word lower-cased) or the one
## the call names.
func _check(ok: bool, label: String, family: String = "") -> void:
	checks += 1
	if not ok:
		failures += 1
		var tag: String = family if not family.is_empty() else label.get_slice(" ", 0).to_lower()
		red[tag] = true
		push_error("CITY_PERCH: [%s] %s" % [tag, label])


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


func _release_all() -> void:
	for code: Key in held.keys():
		_key(code, false)


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
	if world.events != null and world.events.has_method("enable_for_test"):
		world.events.enable_for_test(2468)
		world.events.start_chance = 0.0
	await _ticks(40)
	world.onboarding.skip()
	space = world.get_world_3d().direct_space_state
	torso = world.district.get_node("CityInteriors").find_child("DressFormTorso", false, false) as StaticBody3D


func _close_world() -> void:
	_release_all()
	world.queue_free()
	current_scene = null
	await _ticks(3)


func _ring(r: float, y: float, n: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		points.append(Vector3(AXIS.x + cos(a) * r, y, AXIS.z + sin(a) * r))
	return points


func _break_scene() -> void:
	var collision := torso.get_child(0) as CollisionShape3D
	var origin: Vector3 = torso.global_position
	if RIM_STEPS.has(mutation):
		var spec: Array = RIM_STEPS[mutation]
		var step := StaticBody3D.new()
		step.name = "NegativeRimStep"
		step.collision_layer = 1
		step.collision_mask = 0
		var step_shape := CollisionShape3D.new()
		var step_box := BoxShape3D.new()
		step_box.size = Vector3(float(spec[1]) - float(spec[0]), float(spec[2]), RIM_STEP_Z.y - RIM_STEP_Z.x)
		step_shape.shape = step_box
		step.add_child(step_shape)
		world.district.add_child(step)
		step.global_position = Vector3((float(spec[0]) + float(spec[1])) * 0.5, float(spec[2]) * 0.5, (RIM_STEP_Z.x + RIM_STEP_Z.y) * 0.5)
	match mutation:
		"flat":
			var cylinder := CylinderShape3D.new()
			cylinder.radius = 0.37
			cylinder.height = 1.05
			collision.shape = cylinder
		"cone":
			var points := PackedVector3Array()
			for ring: PackedVector3Array in [_ring(0.37, 0.91, 32), _ring(0.25, 1.785, 32), _ring(0.10, 1.96, 32)]:
				for p: Vector3 in ring:
					points.append(p - origin)
			var cone := ConvexPolygonShape3D.new()
			cone.points = points
			collision.shape = cone
		"edge":
			var rise: float = tan(deg_to_rad(52.0))
			var points := PackedVector3Array()
			for p: Vector3 in _ring(0.37, 0.91, 32):
				points.append(p - origin)
				points.append(Vector3(p.x, 1.96 - (AXIS.x + 0.37 - p.x) * rise, p.z) - origin)
			var edge := ConvexPolygonShape3D.new()
			edge.points = points
			collision.shape = edge


func _free(at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	q.shape = cap
	q.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, 0.93, 0))
	q.collision_mask = world.player.collision_mask
	q.exclude = [world.player.get_rid()]
	return space.intersect_shape(q, 1).is_empty()


## On the form: on the floor, with the torso among this tick's contacts from below.
func _on_form() -> bool:
	var p: CharacterBody3D = world.player
	if not p.is_on_floor():
		return false
	for i: int in p.get_slide_collision_count():
		var c := p.get_slide_collision(i)
		if c.get_collider() == torso and c.get_normal().dot(Vector3.UP) > 0.5:
			return true
	return false


## Ticks while counting the longest run on the form.
func _watch(ticks: int, best: int = 0) -> int:
	var streak := 0
	for t: int in ticks:
		await _ticks(1)
		streak = streak + 1 if _on_form() else 0
		best = maxi(best, streak)
	return best


func _face(dir: Vector3) -> void:
	world.player._set_forward(dir)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-dir.x, -dir.z)


func _p1_place(hero: String) -> void:
	var p: CharacterBody3D = world.player
	_release_all()
	p.restart_at(PLACE - Vector3.UP * 0.06)
	var off := -1
	for t: int in 60:
		await _ticks(1)
		if off < 0 and p.is_on_floor() and p.global_position.y <= OFF_HEIGHT:
			off = t + 1
	print("CITY_PERCH_INFO P1 %s off_tick=%d end=%s" % [hero, off, _v(p.global_position)])
	_check(off > 0 and off <= HOLD_TICKS, "P1 %s: put on the form at %s the hero is on the floor or the table within %d ticks (tick %d, end %s)" % [hero, _v(PLACE), HOLD_TICKS, off, _v(p.global_position)])


func _p2_drops() -> void:
	var p: CharacterBody3D = world.player
	var tried := 0
	var held_on: Array[String] = []
	var n: int = int(DROP_RADIUS / DROP_STEP)
	for ix: int in range(-n, n + 1):
		for iz: int in range(-n, n + 1):
			var at := Vector3(AXIS.x + ix * DROP_STEP, 2.15, AXIS.z + iz * DROP_STEP)
			if Vector2(ix, iz).length() * DROP_STEP > DROP_RADIUS + 0.001 or not _free(at):
				continue
			tried += 1
			_release_all()
			p.restart_at(at - Vector3.UP * 0.06)
			await _ticks(20)
			if await _watch(HOLD_TICKS + 5) > HOLD_TICKS:
				held_on.append("(%+.2f,%+.2f)y%.2f" % [ix * DROP_STEP, iz * DROP_STEP, p.global_position.y])
	print("CITY_PERCH_INFO P2 tried=%d held=%d %s" % [tried, held_on.size(), held_on])
	_check(tried > 0 and held_on.is_empty(), "P2 dropped over the form at every %.2f m within %.2f m of its axis the hero never rests on it %d ticks (%d drops, held: %s)" % [DROP_STEP, DROP_RADIUS, HOLD_TICKS, tried, held_on])


func _p3_jumps(hero: String) -> void:
	var p: CharacterBody3D = world.player
	for dx: float in [-0.5, -0.25, 0.0, 0.25, 0.5]:
		var start := Vector3(AXIS.x + dx, 1.03, TABLE_EDGE_Z + 0.40)
		_release_all()
		world.ropes.clear_match()
		p.restart_at(start)
		_face(Vector3(0, 0, -1))
		await _ticks(10)
		_key(KEY_W, true)
		await _ticks(2)
		_key(KEY_SPACE, true)
		await _ticks(2)
		_key(KEY_SPACE, false)
		var best: int = await _watch(36)
		_release_all()
		best = await _watch(HOLD_TICKS + 20, best)
		var end: Vector3 = p.global_position
		print("CITY_PERCH_INFO P3 %s dx=%+.2f on_form_ticks=%d end=%s" % [hero, dx, best, _v(end)])
		_check(best <= HOLD_TICKS and end.y <= OFF_HEIGHT, "P3 %s dx=%+.2f: a jump from the cutting table's edge toward the form neither rests on it %d ticks nor ends above %.1f m (%d ticks on it, end %s)" % [hero, dx, HOLD_TICKS, OFF_HEIGHT, best, _v(end)])


func _p4_rim(hero: String) -> void:
	var p: CharacterBody3D = world.player
	var outs: Array[String] = []
	for way: Array in [["A", KEY_A], ["D", KEY_D]]:
		_release_all()
		world.ropes.clear_match()
		p.restart_at(Vector3(-17.85, 1.03, TABLE_EDGE_Z + 0.40))
		_face(Vector3(0, 0, -1))
		await _ticks(15)
		_key(KEY_W, true)
		await _ticks(40)
		_release_all()
		await _ticks(30)
		var before: Vector3 = p.global_position
		_key(way[1], true)
		await _ticks(90)
		_release_all()
		await _ticks(40)
		var after: Vector3 = p.global_position
		outs.append("%s:%.2f>%.2f@%.2f,%.2f" % [way[0], before.y, after.y, after.x, after.z])
		_check(after.y <= 0.05, "P4 %s: off the cutting table's −z edge, %s leads to the floor (from y %.2f to %s)" % [hero, way[0], before.y, _v(after)])
	print("CITY_PERCH_INFO P4 %s %s" % [hero, outs])


func _run() -> void:
	await process_frame
	if mutation != "none" and not mutation in BREAKS:
		push_error("CITY_PERCH: unknown --break=" + mutation)
		quit(2)
		return
	root.get_node("GameState").set_free_move(true)
	for hero: String in ["choko", "skea"]:
		await _open_world(hero)
		_check(torso != null, "%s the dress form's torso collider is there" % hero, "p0")
		if torso == null:
			await _close_world()
			continue
		_break_scene()
		await _ticks(2)
		await _p1_place(hero)
		if hero == "choko":
			await _p2_drops()
		await _p3_jumps(hero)
		await _p4_rim(hero)
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
	print("CITY_PERCH_COMPLETE checks=%d failures=%d mutation=%s red=%s" % [checks, failures, mutation,
		",".join(PackedStringArray(families)) if not families.is_empty() else "none"])
	quit(1 if failures else 0)
