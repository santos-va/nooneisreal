extends SceneTree
## Bounded render-only cable under motion, misses, wet drag, invalid input and reset.
var failures: int = 0
var checks: int = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ROPE_VISUAL: " + label)
func _initialize() -> void:
	await process_frame
	var Script: GDScript = load("res://scripts/grapple/RopeVisual.gd")
	var rope = Script.new()
	root.add_child(rope)
	var gs: Node = root.get_node("GameState")
	var fx: GDScript = load("res://scripts/fx/Fx.gd")
	var fx_prior: bool = fx.enabled
	fx.enabled = false
	for wet: bool in [false, true]:
		var field = load("res://scripts/core/WaveField.gd").new() if wet else null
		gs.water = field
		var start := Vector3(0.0, 3.0, 0.0)
		var end := Vector3(8.0, 2.0, 0.0)
		rope.reset_rope(start, end)
		for frame: int in 240:
			start = Vector3(sin(frame * 0.025) * 0.8, 3.0, 0.0)
			end = Vector3(8.0 - minf(float(frame) * 0.02, 3.0), maxf(2.0 - float(frame) * 0.03, -0.6 if wet else 0.02), 0.0)
			var before_frame: int = field.frame if wet else 0
			rope.update_rope(start, end, 10.0, 1.0 / 60.0, field, true)
			check(rope.points.size() == Script.SEGMENTS + 1, "fixed allocation")
			check(rope.points[0].is_equal_approx(start) and rope.points[Script.SEGMENTS].is_equal_approx(end), "authoritative endpoints pinned")
			if wet:
				check(field.frame == before_frame, "visual never advances authoritative water")
			for i: int in rope.points.size():
				check(rope.points[i].is_finite(), "finite cable")
				var baseline: Vector3 = start.lerp(end, float(i) / float(Script.SEGMENTS))
				check(rope.points[i].distance_to(baseline) <= 10.001, "bounded envelope")
				if i > 0 and i < Script.SEGMENTS:
					var floor_y: float = field.height(rope.points[i].x, rope.points[i].z) - 1.5 if wet else Script.RADIUS
					check(rope.points[i].y >= floor_y - 0.0001, "ground or river-bottom collision")
		check(rope._mesh.get_surface_count() == 1, "bounded cable drawing")
		check(rope._mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() <= Script.SEGMENTS * Script.SIDES * 6, "bounded rendered vertices")
		print("ROPE_VISUAL_TRACE wet=", wet, " entries=", rope.water_entries, " points=", rope.points.size())
		if wet:
			check(rope.water_entries > 0, "miss enters water")
	# Independent failure classes: static gravity bow, moving-end lag and stale
	# velocity after slack is caught. A loaded cable must satisfy all three.
	for mode: String in ["static", "moving", "catch"]:
		var start := Vector3(0, 8, 0)
		var end := Vector3(1, 2, 0)
		rope.reset_rope(start, end)
		if mode == "catch":
			for frame: int in 90:
				rope.update_rope(start, end, 10.0, 1.0 / 60.0, null, true)
		for frame: int in 120:
			if mode == "moving":
				end = Vector3(sin(frame * 0.1) * 2.0, 2.0, cos(frame * 0.1))
			rope.update_rope(start, end, start.distance_to(end), 1.0 / 60.0)
			var arc: float = 0.0
			for i: int in Script.SEGMENTS + 1:
				check(rope.points[i].distance_to(start.lerp(end, float(i) / Script.SEGMENTS)) < 0.0001, mode + " loaded span has no transverse bow")
				check(rope.previous[i].is_equal_approx(rope.points[i]), mode + " load clears residual waves")
				if i > 0:
					arc += rope.points[i - 1].distance_to(rope.points[i])
			check(absf(arc - start.distance_to(end)) < 0.0001, mode + " loaded cable cannot stretch")
	var snapshot: PackedVector3Array = rope.points.duplicate()
	rope.update_rope(Vector3.ZERO, Vector3.ONE, 2.0, 0.0)
	check(rope.points == snapshot, "zero delta holds complete drawing")
	rope.update_rope(Vector3(NAN, 0.0, 0.0), Vector3.ZERO, 2.0, 0.016)
	check(rope.points == snapshot, "nonfinite endpoint rejected")
	rope.update_rope(Vector3.ZERO, Vector3.ONE, INF, 0.016)
	check(rope.points == snapshot, "nonfinite length rejected")
	rope.update_rope(Vector3.ZERO, Vector3.ONE, 2.0, NAN)
	check(rope.points == snapshot, "nonfinite time rejected")
	rope.update_rope(Vector3.ZERO, Vector3(100.0, 0.0, 0.0), 100.0, 0.016)
	check(not rope.visible and rope.points == snapshot, "out-of-contract span hidden without endpoint rewrite")
	rope.reset_rope(Vector3.ZERO, Vector3.ZERO)
	rope.update_rope(Vector3.ZERO, Vector3.ZERO, 0.0, 0.0)
	check(rope.points[0] == Vector3.ZERO and rope.points[Script.SEGMENTS] == Vector3.ZERO, "collapsed rope finite")
	check(rope._mesh.get_surface_count() == 0, "collapsed reset clears stale geometry")
	gs.water = null
	fx.enabled = fx_prior
	rope.free()
	print("ROPE_VISUAL_CHECK_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
