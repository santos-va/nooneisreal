extends SceneTree
## Plan docs/Plans/2026-10-07-Aim-Free-Rope.md step 2: rope anchor coverage of the district on a 1 m grid.
##   T8   — the measure of the T8 audit (docs/GDD/06-UI-UX.md, 1533 / 3969 before): integer grid −31…31, feet at y 0,
##          hand +1.25 m, at least one anchor within range. No buildings, no line of sight.
##   REAL — every walkable floor (a 0.6 m standing patch with 1.8 m of headroom) of each grid column of the real
##          CityDistrict colliders that is reachable from the spawn (walk, drop, or a jump + ledge grab of ≤ CLIMB m). Covered when one anchor passes the T8 hard filters from
##          that hand: ≤ range, ≥ 1.5 m above the hand, a clear line on layers 1 | COVER (GrappleHook.line_clear).
##   ROOFS — each roof region the hero reaches has ≥ 1 covered point.
##   SUPPORTS — each anchor has a support (CityLayout.anchor_supports): its visible cap within 0.35 m of the point, and
##          its mount point inside static world geometry that is not the new support itself. Nothing hangs in the air.
## Range is read from choko.tres (14 m, unchanged). Thresholds are the plan's literals: T8 ≥ 90 %, every roof, every support.
## Optional: --dump=<path> writes every grid floor as CSV (x,z,floor_y,reachable,covered,anchors) for the journal.
## Sentinel: ANCHOR_COVERAGE_COMPLETE checks=N failures=M anchors=A t8=a/b real=c/d roofs=k/K supports=s/A
const HAND: float = 1.25
const ABOVE: float = 1.5
const CLIMB: float = 4.5 # PLACEHOLDER reach: Choko jump apex 11²/(2·24) = 2.52 m + reach_height 2.05 m (city_parkour)
const CLEARANCE: float = 1.8
const PATCH: float = 0.3 # standing patch half-width, PLACEHOLDER
const T8_SHARE: float = 0.90
const ROOFS := {
	"NorthWestRoof": AABB(Vector3(-30, 3.0, -30), Vector3(20, 3.5, 20)),
	"NorthEastRoof": AABB(Vector3(10, 3.0, -30), Vector3(20, 3.5, 20)),
	"RoofBridge": AABB(Vector3(-10, 3.0, -22), Vector3(20, 3.5, 4)),
}
var checks: int = 0
var failures: int = 0
var space: PhysicsDirectSpaceState3D


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ANCHOR_COVERAGE: " + label)


func _ray(from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.hit_from_inside = false
	query.exclude = exclude
	return space.intersect_ray(query)


## Walkable floors of one column, top to bottom: an upward-facing hit with CLEARANCE free above it.
func _floors(x: float, z: float) -> Array[float]:
	var result: Array[float] = []
	var top := 40.0
	for guard: int in 24:
		var hit := _ray(Vector3(x, top, z), Vector3(x, -1.0, z), 1)
		if hit.is_empty():
			break
		var y: float = hit.position.y
		if Vector3(hit.normal).y > 0.7 and _standing_patch(x, y, z):
			if result.is_empty() or absf(result[-1] - y) > 0.2:
				result.append(y)
		top = y - 0.02
	return result


## A floor the hero can stand on: the same height within 0.1 m at ±PATCH around the point (not a trim, rail or post top)
## and CLEARANCE free above each of those five points.
func _standing_patch(x: float, y: float, z: float) -> bool:
	for offset: Vector2 in [Vector2.ZERO, Vector2(PATCH, 0), Vector2(-PATCH, 0), Vector2(0, PATCH), Vector2(0, -PATCH)]:
		var px := x + offset.x
		var pz := z + offset.y
		var below := _ray(Vector3(px, y + 0.1, pz), Vector3(px, y - 0.1, pz), 1)
		if below.is_empty() or not _ray(Vector3(px, y + 0.05, pz), Vector3(px, y + CLEARANCE, pz), 1).is_empty():
			return false
	return true


## Indices of the anchors that pass the T8 hard filters from this hand (empty = not covered).
func _covering(hand: Vector3, anchors: Array[Vector3], reach: float) -> PackedInt32Array:
	var result := PackedInt32Array()
	for index: int in anchors.size():
		var point: Vector3 = anchors[index]
		if point.y - hand.y >= ABOVE and hand.distance_to(point) <= reach and _ray(hand, point, 1 | ArenaLayout.COVER_LAYER).is_empty():
			result.append(index)
	return result


func _run() -> void:
	await process_frame
	var dump := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--dump="):
			dump = argument.trim_prefix("--dump=")
	var reach: float = (load("res://data/characters/choko.tres") as CharacterData).grapple_range
	var district: Node3D = load("res://scripts/world/CityDistrict.gd").new()
	root.add_child(district)
	for tick: int in 3:
		await physics_frame
	space = district.get_world_3d().direct_space_state
	var anchors: Array[Vector3] = []
	for node: Node in get_nodes_in_group("grapple_anchor"):
		anchors.append((node as Node3D).global_position)
	_check(anchors.size() == CityLayout.anchors().size(), "every CityLayout anchor is a live grapple_anchor (%d / %d)" % [anchors.size(), CityLayout.anchors().size()])
	# T8 measure.
	var t8_total := 0
	var t8_covered := 0
	for x: int in range(-31, 32):
		for z: int in range(-31, 32):
			t8_total += 1
			var hand := Vector3(x, HAND, z)
			for point: Vector3 in anchors:
				if hand.distance_to(point) <= reach:
					t8_covered += 1
					break
	# Real floors and reachability from the spawn.
	var floors: Dictionary = {} # Vector2i -> Array[float]
	for x: int in range(-31, 32):
		for z: int in range(-31, 32):
			floors[Vector2i(x, z)] = _floors(float(x), float(z))
	var spawn := CityLayout.spawn_position()
	var start := Vector3i(int(spawn.x), int(spawn.z), 0)
	var reachable: Dictionary = {start: true}
	var queue: Array[Vector3i] = [start]
	while not queue.is_empty():
		var at: Vector3i = queue.pop_front()
		var from_y: float = floors[Vector2i(at.x, at.y)][at.z]
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var column := Vector2i(at.x + step.x, at.y + step.y)
			if not floors.has(column):
				continue
			var list: Array = floors[column]
			for index: int in list.size():
				var to_y: float = list[index]
				var node := Vector3i(column.x, column.y, index)
				if reachable.has(node) or to_y - from_y > CLIMB:
					continue
				# Over the top at the higher floor + 1 m, with the vertical way clear in both columns (no slab between a
				# floor and the crossing height: the ground inside a solid block is never entered from its roof).
				var height := maxf(from_y, to_y) + 1.0
				if not _ray(Vector3(at.x, height, at.y), Vector3(column.x, height, column.y), 1).is_empty():
					continue
				if not _ray(Vector3(at.x, from_y + 0.05, at.y), Vector3(at.x, height, at.y), 1).is_empty():
					continue
				if not _ray(Vector3(column.x, height, column.y), Vector3(column.x, to_y + 0.05, column.y), 1).is_empty():
					continue
				reachable[node] = true
				queue.append(node)
	var real_total := 0
	var real_covered := 0
	# Uncovered reachable floors by place: inside the walk-in shops (no rope indoors), the 1 m strips between the
	# buildings and the boundary walls (|x| or |z| = 31), and the rest of the outdoor district.
	var shop_bounds: Array[AABB] = []
	for shop: Dictionary in CityPlaces.shops():
		shop_bounds.append(shop.bounds)
	var gaps := {"indoor": 0, "strip": 0, "outdoor": 0}
	var indoor_total := 0
	var strip_total := 0
	var roof_points: Dictionary = {}
	var roof_covered: Dictionary = {}
	for roof: String in ROOFS:
		roof_points[roof] = 0
		roof_covered[roof] = 0
	var rows: PackedStringArray = ["x,z,floor_y,reachable,covered,anchors"]
	for column: Vector2i in floors:
		var list: Array = floors[column]
		for index: int in list.size():
			var y: float = list[index]
			var hand := Vector3(column.x, y + HAND, column.y)
			var is_reachable := reachable.has(Vector3i(column.x, column.y, index))
			var covering := _covering(hand, anchors, reach)
			var covered := not covering.is_empty()
			if dump != "":
				rows.append("%d,%d,%.2f,%d,%d,%s" % [column.x, column.y, y, int(is_reachable), int(covered), ";".join(Array(covering).map(func(i: int) -> String: return str(i)))])
			if not is_reachable:
				continue
			real_total += 1
			real_covered += int(covered)
			var place := "outdoor"
			for bounds: AABB in shop_bounds:
				if bounds.grow(0.01).has_point(Vector3(column.x, y + 0.05, column.y)):
					place = "indoor"
			if place == "outdoor" and (absi(column.x) == 31 or absi(column.y) == 31):
				place = "strip"
			indoor_total += int(place == "indoor")
			strip_total += int(place == "strip")
			if not covered:
				gaps[place] += 1
			for roof: String in ROOFS:
				if (ROOFS[roof] as AABB).has_point(Vector3(column.x, y, column.y)):
					roof_points[roof] += 1
					roof_covered[roof] += int(covered)
	var roofs_ok := 0
	for roof: String in ROOFS:
		var ok: bool = int(roof_points[roof]) > 0 and int(roof_covered[roof]) >= 1
		roofs_ok += int(ok)
		print("ANCHOR_COVERAGE roof %s covered=%d/%d" % [roof, roof_covered[roof], roof_points[roof]])
		_check(ok, "roof %s has a covered point (%d / %d)" % [roof, roof_covered[roof], roof_points[roof]])
	# Supports.
	var supports: Array[Dictionary] = CityLayout.anchor_supports()
	var supports_ok := 0
	var own_supports: Array[RID] = []
	for node: Node in district.get_children():
		if node is StaticBody3D and String(node.name).begins_with("AnchorPost"):
			own_supports.append((node as StaticBody3D).get_rid())
	for index: int in supports.size():
		var spec: Dictionary = supports[index]
		var point: Vector3 = spec.point
		var cap := district.get_node_or_null("AnchorCeramic%d" % index) as Node3D
		var cap_ok := cap != null and cap.global_position.distance_to(point) <= 0.35
		var probe := PhysicsShapeQueryParameters3D.new()
		var ball := SphereShape3D.new()
		ball.radius = 0.12
		probe.shape = ball
		probe.transform = Transform3D(Basis.IDENTITY, spec.mount)
		probe.collision_mask = 1
		probe.exclude = own_supports
		var mount_ok := not space.intersect_shape(probe, 1).is_empty()
		supports_ok += int(cap_ok and mount_ok)
		_check(cap_ok, "anchor %d %s has its visible cap at the point" % [index, point])
		_check(mount_ok, "anchor %d %s (%s) is mounted on world geometry at %s" % [index, point, spec.kind, spec.mount])
	# Every anchor counts for the rope quest (CityProgress validates "anchor_<index>" events); nothing past the last one.
	var progress: GDScript = load("res://scripts/npc/CityProgress.gd")
	var last := "anchor_%d" % (anchors.size() - 1)
	_check(progress._event_id_valid("rope", "anchor_0") and progress._event_id_valid("rope", last), "the rope quest accepts anchor_0 … %s" % last)
	_check(not progress._event_id_valid("rope", "anchor_%d" % anchors.size()) and not progress._event_id_valid("rope", "anchor_01") and not progress._event_id_valid("rope", "anchor_-1"), "the rope quest rejects a missing index and a second spelling")
	if dump != "":
		var file := FileAccess.open(dump, FileAccess.WRITE)
		file.store_string("\n".join(rows) + "\n")
		file.close()
	var t8_share := float(t8_covered) / float(maxi(1, t8_total))
	_check(t8_share >= T8_SHARE, "T8 measure %d / %d = %.1f %% >= %.0f %%" % [t8_covered, t8_total, t8_share * 100.0, T8_SHARE * 100.0])
	print("ANCHOR_COVERAGE t8=%d/%d (%.1f %%) real=%d/%d (%.1f %%) range=%.1f" % [t8_covered, t8_total, t8_share * 100.0,
		real_covered, real_total, 100.0 * float(real_covered) / float(maxi(1, real_total)), reach])
	var open_total := real_total - indoor_total - strip_total
	var open_covered := open_total - int(gaps.outdoor)
	print("ANCHOR_COVERAGE real_open=%d/%d (%.1f %%) without the shops and the boundary strips; uncovered: indoor=%d/%d strip=%d/%d open=%d" % [
		open_covered, open_total, 100.0 * float(open_covered) / float(maxi(1, open_total)), gaps.indoor, indoor_total, gaps.strip, strip_total, gaps.outdoor])
	district.queue_free()
	await process_frame
	print("ANCHOR_COVERAGE_COMPLETE checks=%d failures=%d anchors=%d t8=%d/%d real=%d/%d roofs=%d/%d supports=%d/%d" % [
		checks, failures, anchors.size(), t8_covered, t8_total, real_covered, real_total, roofs_ok, ROOFS.size(), supports_ok, supports.size()])
	quit(1 if failures else 0)
