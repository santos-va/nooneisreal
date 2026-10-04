extends SceneTree
## $GODOT_BIN --headless --path game -s $PWD/tools/fx/afterimage_check.gd
## Visible mesh identity, bind resources, every frozen bone, world placement and bounded lifetime.
var Ghost: GDScript
var Effects: GDScript
var checks: int = 0
var failures: int = 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	await process_frame
	Ghost = load("res://scripts/fx/Afterimage.gd")
	Effects = load("res://scripts/fx/Fx.gd")
	root.get_node("GameState").skeletal_rig = true
	root.get_node("GameState").free_move = true
	var fx_parent := Node3D.new()
	root.add_child(fx_parent)
	fx_parent.transform = Transform3D(Basis(Vector3.UP, 0.72).scaled(Vector3(1.3, 0.8, 1.6)), Vector3(7, 2, -5))
	for id: String in ["skea", "choko"]:
		var fighter = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
		fighter.data = load("res://data/characters/%s.tres" % id)
		root.add_child(fighter)
		fighter.set_physics_process(false)
		fighter.skeletal.set_physics_process(false)
		fighter.global_transform = Transform3D(Basis(Vector3.UP, -0.65).scaled(Vector3(1.2, 0.9, 1.1)), Vector3(-3, 1, 4))
		fighter.skeletal.player.play(fighter.skeletal.clip_name(fighter.data.dash_clip))
		fighter.skeletal.player.seek(0.13, true)
		fighter.skeletal.retarget()
		var source: MeshInstance3D = fighter.skeletal.hero_mesh
		var source_skeleton: Skeleton3D = fighter.skeletal.hero_skeleton
		for size: float in [1.0, 1.3, 1.36]:
			var snap: Array = Ghost.snapshot(fighter.animator, fighter.skeletal)
			var shift := Vector3(1.5, 0.2, -0.05)
			var ghost = Ghost.spawn(fx_parent, snap, Color(0.7, 0.2, 1.0), 0.3, 0.5, size != 1.3, size, shift)
			ghost.set_process(false)
			var meshes: Array = ghost.find_children("*", "MeshInstance3D", true, false)
			check(meshes.size() == 1, id + " one visible hero mesh")
			var mesh: MeshInstance3D = meshes[0]
			var frozen: Skeleton3D = mesh.get_node(mesh.skeleton)
			check(mesh.mesh == source.mesh and mesh.skin == source.skin, id + " shared mesh and immutable skin")
			check(frozen != source_skeleton, id + " independent skeleton")
			check(mesh.material_override != source.material_override and mesh.material_override.next_pass == null, "independent single-pass ghost material")
			check(ghost.find_children("*", "AnimationPlayer", true, false).is_empty(), "no ghost animation player")
			check(mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "no ghost shadow")
			var center: Vector3 = snap[0].center
			var placement := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), center * (1.0 - size) + shift)
			check(mesh.global_transform.is_equal_approx(placement * source.global_transform), id + " mesh world transform")
			check(frozen.global_transform.is_equal_approx(placement * source_skeleton.global_transform), id + " skeleton world transform including imported scale")
			for i in source_skeleton.get_bone_count():
				check(frozen.get_bone_global_pose(i).is_equal_approx(source_skeleton.get_bone_global_pose(i)), id + " frozen bone %d" % i)
			# Evaluate bind transforms on the imported mesh's actual vertex samples; no mesh copy in runtime.
			_compare_vertices(source, source_skeleton, frozen, placement, id)
			var held_pose: Transform3D = frozen.get_bone_global_pose(0)
			var held_world: Transform3D = mesh.global_transform
			source_skeleton.set_bone_pose_position(0, source_skeleton.get_bone_pose_position(0) + Vector3(5, 1, 2))
			fighter.position += Vector3(2, 0, 1)
			check(frozen.get_bone_global_pose(0).is_equal_approx(held_pose), "pose independent after hero moves")
			check(mesh.global_transform.is_equal_approx(held_world), "world transform independent after hero moves")
			ghost._process(0.4)
			check(ghost.is_queued_for_deletion(), "ghost expires")
			ghost.free()
		var capsules: Array = Ghost.snapshot(fighter.animator, null)
		var fallback = Ghost.spawn(fx_parent, capsules, Color.WHITE)
		check(fallback.find_children("*", "Skeleton3D", true, false).is_empty(), "capsule fallback has no skeleton")
		check(fallback.get_child_count() == capsules.size(), "legacy capsule snapshot remains supported")
		fallback.free()
		Effects.enabled = false
		check(Ghost.snapshot(fighter.animator, fighter.skeletal).is_empty(), "disabled does not capture")
		check(Ghost.spawn(fx_parent, capsules, Color.WHITE) == null, "disabled does not spawn")
		Effects.enabled = true
		for i in Ghost.MAX_ACTIVE + 4:
			Ghost.spawn(fx_parent, capsules, Color.WHITE)
		check(get_nodes_in_group("afterimage").size() == Ghost.MAX_ACTIVE, "global active bound")
		check(Ghost.snapshot(fighter.animator, fighter.skeletal).is_empty(), "budget rejects capture before allocations")
		for node in get_nodes_in_group("afterimage"):
			node.free()
		var surviving = Ghost.spawn(fx_parent, Ghost.snapshot(fighter.animator, fighter.skeletal), Color.WHITE)
		var retained_mesh: Mesh = source.mesh
		fighter.free()
		check((surviving.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh == retained_mesh, "resources survive source destruction")
		surviving.free()
	fx_parent.free()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			await _capture(arg.trim_prefix("--capture-dir="))
	print("afterimage: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _compare_vertices(source: MeshInstance3D, original: Skeleton3D, frozen: Skeleton3D, placement: Transform3D, label: String) -> void:
	var skin: Skin = source.skin
	check(skin != null, label + " imported skin exists")
	if skin == null:
		return
	for surface in source.mesh.get_surface_count():
		var arrays: Array = source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := indices.size() / vertices.size()
		for vertex in range(0, vertices.size(), maxi(1, vertices.size() / 31)):
			var expected := Vector3.ZERO
			var actual := Vector3.ZERO
			for influence in stride:
				var offset: int = vertex * stride + influence
				var bind: int = indices[offset]
				var bone := original.find_bone(skin.get_bind_name(bind)) if skin.get_bind_name(bind) != &"" else skin.get_bind_bone(bind)
				var sample: Vector3 = skin.get_bind_pose(bind) * vertices[vertex]
				expected += original.get_bone_global_pose(bone) * sample * weights[offset]
				actual += frozen.get_bone_global_pose(bone) * sample * weights[offset]
			check((placement * (original.global_transform * expected)).is_equal_approx(frozen.global_transform * actual), label + " posed vertex world position")


## Optional native captures: actual materials side by side, then exact same placement.
## No simulation runs while waiting for RenderingServer; ghosts hold their spawn drawing.
func _capture(directory: String) -> void:
	check(DirAccess.make_dir_recursive_absolute(directory) == OK, "capture directory")
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.06, 0.07, 0.09)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.4
	camera.position = Vector3(0, 1.2, 8)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.make_current()
	var overlay := CanvasLayer.new()
	stage.add_child(overlay)
	var label := Label.new()
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 22)
	overlay.add_child(label)
	var fighter_script: GDScript = load("res://scripts/fighter/Fighter.gd")
	for id: String in ["skea", "choko"]:
		var fighter = (load("res://scenes/fighter/Fighter.tscn") as PackedScene).instantiate()
		fighter.data = load("res://data/characters/%s.tres" % id)
		stage.add_child(fighter)
		for node in fighter.find_children("*", "", true, false):
			node.set_process(false)
			node.set_physics_process(false)
		fighter.set_process(false)
		fighter.set_physics_process(false)
		fighter.position = Vector3(-1.1, 0, 0)
		fighter.state = fighter_script.State.DASH
		fighter.velocity = Vector3.RIGHT
		fighter.forward = Vector3.RIGHT
		fighter.facing = 1
		fighter.animator.tick(1.0 / 60.0, fighter, false)
		fighter.skeletal.rotation.y = fighter.animator.rotation.y
		fighter.skeletal.player.play(fighter.skeletal.clip_name(fighter.data.dash_clip))
		fighter.skeletal.player.seek(0.13, true)
		fighter.skeletal.retarget()
		await process_frame
		await RenderingServer.frame_post_draw
		var ghost = Ghost.spawn(stage, Ghost.snapshot(fighter.animator, fighter.skeletal), fighter.data.vfx_primary, 0.3, 0.6, true, 1.0, Vector3(2.2, 0, 0))
		ghost.set_process(false)
		label.text = id.to_upper() + " / visible hero (left), frozen hero ghost (right) / same scale"
		await _capture_frame(directory.path_join(id + "-pair.png"))
		fighter.position.x = 0
		ghost.position.x = -1.1
		label.text = id.to_upper() + " / exact placement overlay / real hero + frozen ghost"
		await _capture_frame(directory.path_join(id + "-overlay.png"))
		ghost.hide()
		label.text = id.to_upper() + " / exact placement / hero only"
		await _capture_frame(directory.path_join(id + "-hero.png"))
		ghost.show()
		fighter.hide()
		label.text = id.to_upper() + " / exact placement / ghost only"
		await _capture_frame(directory.path_join(id + "-ghost.png"))
		ghost.free()
		fighter.free()
	stage.free()
	print("AFTERIMAGE_CAPTURE_COMPLETE images=8 dir=", directory)

func _capture_frame(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + path.get_file())
