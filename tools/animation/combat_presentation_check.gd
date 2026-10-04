extends SceneTree
## Presentation lifecycle and motion regressions; does not alter combat authority.
var checks: int = 0
var failures: int = 0
var actor: GDScript
var limbs: GDScript
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("COMBAT_PRESENTATION: " + label)
func pose(f: Node3D) -> void:
	f.animator.tick(1.0 / 60.0, f, false)
	f.skeletal._physics_process(1.0 / 60.0)
	f.skeletal._on_mannequin_updated()
func run() -> void:
	await process_frame
	actor = load("res://scripts/fighter/Fighter.gd")
	limbs = load("res://scripts/fighter/LimbMoves.gd")
	root.get_node("GameState").skeletal_rig = true
	var scene := load("res://scenes/fighter/Fighter.tscn") as PackedScene
	var f: Node3D = scene.instantiate()
	f.data = load("res://data/characters/choko.tres")
	root.add_child(f)
	f.set_physics_process(false)
	f.skeletal.set_physics_process(false)
	f.skeletal.sword.set_physics_process(false)
	f.state = actor.State.IDLE
	pose(f)
	var sword: Node3D = f.skeletal.sword
	check(sword.stow_weight == 1.0, "new match stores blade behind back")
	check(not sword.global_position.is_equal_approx(sword.hand_grip("right").origin), "sheathed blade is not floating in hand")
	f.state = actor.State.SWAP
	f.sword_swap_drawing = true
	f.sword_swap_to = "right"
	var last: float = 1.0
	for frame in range(25):
		f.sword_swap_frame = frame
		pose(f)
		check(sword.stow_weight <= last, "draw travels back to hand monotonically")
		last = sword.stow_weight
	check(last == 0.0, "draw reaches hand")
	f.sword_drawn = true
	f.sword_swap_drawing = false
	f.sword_swap_from = "right"
	f.sword_swap_to = "left"
	f.sword_swap_frame = 12
	f.sword_hand = "left"
	f.sword_form = 1
	pose(f)
	check(sword.dissolve_weight > 0.99, "contact replaces mesh with dust")
	check(sword.dust[0].visible, "dust renders during morph")
	var frozen: Transform3D = sword.global_transform
	var dust_point: Vector3 = sword.dust[0].position
	f.hitstop_frames = 3
	f.sword_swap_frame = 20
	sword.update_pose()
	check(sword.global_transform == frozen and sword.dust[0].position == dust_point, "hitstop freezes dust and attachment")
	f.hitstop_frames = 0
	f.state = actor.State.IDLE
	pose(f)
	check(sword.dissolve_weight == 0.0 and not sword.dust[0].visible, "interrupt finishes with one assembled sword")
	var forms: Array[Vector3] = []
	for form in 3:
		f.sword_form = form
		sword.update_pose()
		forms.append(sword.blade.scale)
	check(forms[0] != forms[1] and forms[1] != forms[2] and forms[0] != forms[2], "three different blade silhouettes")
	f.free()
	f = scene.instantiate()
	f.data = load("res://data/characters/skea.tres")
	root.add_child(f)
	f.set_physics_process(false)
	f.skeletal.set_physics_process(false)
	f.state = actor.State.ATTACK
	f.current_move = limbs.resolve(f.data, "left_leg", 2, "right_leg", false, false)
	var last_spin: float = 0.0
	for frame in f.current_move.startup + f.current_move.active + f.current_move.recovery:
		f.move_frame = frame
		pose(f)
		check(f.animator.spin >= last_spin - 0.0001, "spinning kick never reverses during recovery")
		last_spin = f.animator.spin
	check(last_spin > TAU - 0.01, "spinning kick completes one turn")
	f.current_move = f.data.ultimate
	f.move_frame = f.current_move.startup
	pose(f)
	check(f.skeletal.uses_procedural_motion(), "ultimate retarget receives levitation")
	check(f.animator.target_root_offset.y > 0.35, "levitation raises only presentation")
	check(f.animator.target_pose["thigh_l"].x < 0.0 and f.animator.target_pose["thigh_r"].x > 0.0, "crossed legs have opposite lateral folds")
	f.state = actor.State.IDLE
	pose(f)
	check(f.animator.target_root_offset == Vector3.ZERO, "finished ult restores grounded target")
	f.free()
	print("COMBAT_PRESENTATION_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
