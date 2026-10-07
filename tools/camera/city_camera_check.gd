extends SceneTree
## Real district solids, close framing, camera-local materials and lifecycle counterexamples.
var checks: int = 0
var failures: int = 0
var city: Node3D
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_CAMERA: " + label)
func ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame
func opacity(material: ShaderMaterial) -> float:
	var value: Variant = material.get_shader_parameter("camera_visibility")
	return 1.0 if value == null else float(value)
func ink(material: ShaderMaterial) -> float:
	var value: Variant = material.get_shader_parameter("camera_outline_visibility")
	return 1.0 if value == null else float(value)
func clear_lens() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.05
	query.shape = shape
	query.transform.origin = city.camera_rig.camera.global_position
	query.collision_mask = 1
	query.exclude = [city.player.get_rid()]
	return city.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	await process_frame
	var state: Node = root.get_node("GameState")
	state.skeletal_rig = true
	for hero: String in ["choko", "skea"]:
		state.p1_character = hero
		city = load("res://scenes/world/CityWorld.tscn").instantiate()
		root.add_child(city)
		current_scene = city
		city.player.set_physics_process(false)
		var rig = city.camera_rig
		for x: float in [-26.6, -20.0, -13.4]:
			for z: float in [10.0, 12.5, 15.4, 18.8]:
				city.player.position = Vector3(x, 0, z)
				rig.reset_view()
				await ticks(36)
				check(clear_lens(), hero + " camera stays outside shop solids")
				check(rig.arm.position.y >= 0.0 and rig.arm.position.y <= rig.close_lift + 0.001, "bounded vertical framing")
				check(root.get_node("InputRouter").view_basis(1).distance_to(Vector3.FORWARD) < 0.001, "framing never rotates horizontal input")
				if z > 18.0:
					check(rig.arm.get_hit_length() < 0.4 and rig.arm.position.y > 0.5, "existing collision is retained and close view lifts")
					# Policy of docs/Plans/2026-10-07-Tight-Support-Camera.md step 3: the lens-distance factor
					# still drops, but the fill stops at its floor and the ink line stays, so the hero never vanishes.
					check(rig.proximity.visibility < 0.15 and is_equal_approx(rig.proximity.fill_visibility, rig.proximity.fill_floor) and is_equal_approx(rig.proximity.outline_visibility, 1.0), "lens at head/torso thins the fill to its floor and keeps the ink line")
		# Continuous near-wall entry and retreat: no opacity jump or stuck recovery.
		city.player.position = Vector3(-26.6, 0, 17)
		rig.reset_view()
		await ticks(20)
		var old_visibility: float = rig.proximity.visibility
		for frame: int in 80:
			city.player.position.z = 17.0 + 1.8 * (float(frame) / 39.0 if frame < 40 else float(79 - frame) / 39.0)
			await ticks(1)
			check(clear_lens(), "continuous camera path has no solid penetration")
			check(absf(rig.proximity.visibility - old_visibility) < 0.3, "bounded proximity transition")
			old_visibility = rig.proximity.visibility
		await ticks(30)
		check(rig.proximity.visibility > 0.99, "retreat restores full body")
		# A different active view must immediately restore the camera-owned layer.
		city.player.position = Vector3(-26.6, 0, 18.8)
		rig.reset_view()
		await ticks(36)
		var body: ShaderMaterial = city.player.skeletal.hero_mesh.material_override
		check(is_equal_approx(opacity(body), rig.proximity.fill_floor), "hero fill follows proximity down to its floor")
		check(body.next_pass is ShaderMaterial and body.next_pass in rig.proximity._outlines and is_equal_approx(ink(body.next_pass), 1.0), "hero ink outline joins the policy and is never dithered")
		check(city.player.visible and city.player.skeletal.visible, "actor and rig visibility authority untouched")
		var other := Camera3D.new()
		city.add_child(other)
		other.make_current()
		await ticks(2)
		check(is_equal_approx(opacity(body), 1.0), "inactive camera restores material")
		rig.camera.make_current()
		other.queue_free()
		await ticks(36)
		# Late materials and their own non-default values survive teardown exactly.
		var late := ShaderMaterial.new()
		late.shader = load("res://shaders/toon.gdshader")
		late.set_shader_parameter("camera_visibility", 0.8)
		city.player.animator.materials.append(late)
		await ticks(2)
		check(is_equal_approx(opacity(late), 0.8 * rig.proximity.fill_floor), "late weapon material joins policy with its own original scaled to the floor")
		var cloth = city.cosmetics
		var original: Color = cloth.cloth.albedo_color
		await ticks(2)
		check(not rig.proximity._clothing.is_empty(), "late city cloth is included")
		rig.proximity.restore()
		check(is_equal_approx(opacity(late), 0.8), "late material exact original restored")
		check(is_equal_approx(opacity(body), 1.0), "body exact original restored")
		for mesh: Node in cloth.get_children():
			check(mesh.material_override == cloth.cloth, "original cloth resource restored")
		check(cloth.cloth.albedo_color == original, "cosmetic palette was never mutated")
		rig.proximity.setup(city.player)
		city.player.position = Vector3(0,4,-20)
		rig.reset_view()
		await ticks(30)
		check(clear_lens() and rig.proximity.visibility > 0.99, "roof reset leaves no stale proximity")
		city.queue_free()
		await ticks(2)
		check(is_equal_approx(opacity(body), 1.0), "leaving city restores material resource")
	print("CITY_CAMERA_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
