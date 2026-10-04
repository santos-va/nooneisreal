extends SceneTree
## Run from repository root: godot --headless --path game -s "$PWD/tools/fx/water_splash_check.gd"
## Lazy script loading lets autoload names register before compiling gameplay dependencies.
var fails: int = 0

func check(ok: bool, label: String) -> void:
	print("splash: %s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		fails += 1

func _initialize() -> void:
	await process_frame
	var wave_script: Script = load("res://scripts/core/WaveField.gd")
	var burst_script: Script = load("res://scripts/fx/WaterBurst3D.gd")
	var fighter_script: Script = load("res://scripts/fighter/Fighter.gd")
	var director_script: Script = load("res://scripts/fx/FxDirector.gd")
	var fx_script: Script = load("res://scripts/fx/Fx.gd")
	var gs: Node = root.get_node("GameState")
	var stage := Node3D.new()
	root.add_child(stage)
	current_scene = stage
	var field = wave_script.new()
	field.use_z = true
	field.reset()
	gs.water = field
	seed(741)
	var expected := randf()
	seed(741)
	var a = burst_script.play(stage, Vector3(2.0, 90.0, 3.0), Vector3(4.0, 0.0, 1.0), burst_script.Kind.HEAVY, 25)
	check(a != null, "creates real geometry")
	if a == null:
		quit(1)
		return
	check(is_equal_approx(a.global_position.y, field.height(2.0, 3.0)), "origin samples actual surface, ignores input y")
	check(a._drops.instance_count == burst_script.MAX_DROPS and a._lines.get_surface_count() == 1, "bounded mesh geometry")
	check(randf() == expected, "global gameplay RNG unchanged")
	var b = burst_script.play(stage, Vector3(2.0, 0.0, 3.0), Vector3(4.0, 0.0, 1.0), burst_script.Kind.HEAVY, 25)
	check(a._velocities == b._velocities, "local seeded trajectories repeat")
	var owner = fighter_script.new()
	b._owner = weakref(owner)
	owner.frozen_frames = 12
	b._process(0.1)
	check(b.age == 0.0, "time stop freezes geometry lifetime")
	owner.frozen_frames = 0
	owner.hitstop_frames = 4
	b._process(0.1)
	check(b.age == 0.0, "hitstop freezes geometry lifetime")
	owner.hitstop_frames = 0
	b._process(0.1)
	check(is_equal_approx(b.age, 0.1), "geometry resumes after freeze")
	owner.free()
	field.tick()
	a._process(0.12)
	var contact = a._surface(0.9, 0.6) + a.global_position
	check(absf(contact.y - field.height(contact.x, contact.z) - 0.025) < 0.0001, "ring follows changing wave surface")
	check(director_script.water_landing_kind(-2.0) == burst_script.Kind.LIGHT and director_script.water_landing_kind(-5.0) == burst_script.Kind.MEDIUM and director_script.water_landing_kind(-10.0) == burst_script.Kind.HEAVY, "impact speed classification")
	for i in 40:
		burst_script.play(stage, Vector3.ZERO, Vector3.ZERO, burst_script.Kind.STEP, i)
	check(get_nodes_in_group(burst_script.GROUP).size() == burst_script.MAX_ACTIVE, "flood cannot exceed global burst cap")
	fx_script.enabled = false
	check(burst_script.play(stage, Vector3.ZERO, Vector3.ZERO, 0, 1) == null, "disabled FX cannot spawn")
	a._process(0.0)
	check(a.is_queued_for_deletion(), "disabled live geometry clears")
	fx_script.enabled = true
	for node in get_nodes_in_group(burst_script.GROUP):
		node._process(5.0)
	await process_frame
	check(get_nodes_in_group(burst_script.GROUP).is_empty(), "expired bursts clean up")
	gs.water = null
	check(burst_script.play(stage, Vector3.ZERO, Vector3.ZERO, 0, 1) == null, "dry stages cannot spawn water")
	print("SPLASH CHECK: %d failures" % fails)
	quit(0 if fails == 0 else 1)
