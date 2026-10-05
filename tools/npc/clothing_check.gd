extends SceneTree
var checks: int = 0
var failures: int = 0
var Appearance: GDScript
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("NPC_CLOTHING: "+label)
func run() -> void:
	await process_frame
	Appearance = load("res://scripts/npc/NpcAppearance.gd")
	var max_meshes: int = 0
	var max_triangles: int = 0
	var max_parts: int = 0
	var moving_profiles: int = 0
	for seed_value: int in range(36,60):
		var visual: Node3D = Appearance.build({"appearance_seed":seed_value})
		root.add_child(visual)
		var cloth = visual.clothing
		var identity: Dictionary = visual.get_meta("appearance").duplicate(true)
		var meshes: Array[Node] = visual.find_children("*","MeshInstance3D",true,false)
		var triangles: int = 0
		for mesh: MeshInstance3D in meshes: triangles += mesh.mesh.get_faces().size()/3
		max_meshes = maxi(max_meshes,meshes.size())
		max_triangles = maxi(max_triangles,triangles)
		max_parts = maxi(max_parts,cloth.parts.size())
		check(meshes.size() <= 48 and triangles <= 8000,"existing geometry budget")
		var texture_path: String = "res://assets/characters/npc/knit_stripes.svg" if identity.outfit == 1 else "res://assets/characters/npc/workwear_seams.svg"
		var detailed_parts: int = 0
		for mesh: MeshInstance3D in meshes:
			var shoulder: bool = mesh.get_parent() == visual and mesh.position.is_equal_approx(Vector3(-0.205,1.36,0)) or mesh.get_parent() == visual and mesh.position.is_equal_approx(Vector3(0.205,1.36,0))
			if mesh.name == "Torso" or shoulder or mesh.name == "Sleeve":
				var material: ShaderMaterial = mesh.material_override
				check(material.shader == load("res://shaders/toon.gdshader") and material.get_shader_parameter("albedo_tex") == load(texture_path), "existing torso/sleeve craftsmanship texture remains visibly bound")
				detailed_parts += 1
		check(detailed_parts == 5,"texture regression fixture covers torso, both shoulders and sleeves")
		# Real triangle interiors against conservative rendered trouser ellipsoids.
		# This catches a flat resting hem cutting through a steady swinging leg.
		var fabrics: Array[Node] = visual.find_children("*Fabric","MeshInstance3D",true,false)
		var legs: Array[Node] = visual.find_children("Trouser*","MeshInstance3D",true,false)
		for phase: int in 17:
			visual.set_motion(1.5,float(phase)/16.0*TAU/7.0)
			for mesh: MeshInstance3D in fabrics:
				var points: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for face: int in points.size()/3:
					for u: int in 5:
						for v: int in 5-u:
							var sample: Vector3 = points[face*3]*(1.0-float(u+v)/4.0)+points[face*3+1]*float(u)/4.0+points[face*3+2]*float(v)/4.0
							for leg: MeshInstance3D in legs:
								check(leg.to_local(mesh.to_global(sample)).length() >= .5,"tailored panel remains outside steady-walk trouser envelope")
		var moved: float = 0.0
		for frame: int in 240:
			var t: float = frame/60.0
			if frame < 30: visual.position.z -= t/60.0
			elif frame < 90: visual.position.z -= 1.0/60.0
			elif frame < 120: visual.rotation.y += .03
			visual.set_motion(1.0 if frame < 90 else 0.0,t)
			if frame == 95: visual.presentation_event("greet")
			visual.set_work(["grocer","tailor","workshop"][seed_value%3],t)
			var arms: Array = [visual._arms[0].transform,visual._arms[1].transform,visual._head.transform]
			var owner_transform: Transform3D = visual.transform
			visual.step_clothing(1.0/60.0)
			check(owner_transform == visual.transform,"cloth cannot move actor")
			check(arms == [visual._arms[0].transform,visual._arms[1].transform,visual._head.transform],"cloth cannot clobber work/gesture")
			for part: Dictionary in cloth.parts:
				var limit: float = .10 if part.kind == "leather" else .24
				check(part.angle >= 0.0 and part.angle <= limit,"predeclared outward angle bound")
				check(part.node.transform.origin.distance_to(part.rest.origin) <= .001,"pinned hinge <=1mm")
				check(part.node.scale.distance_to(Vector3.ONE) < .0001,"no garment stretching")
				moved = maxf(moved,absf(part.angle))
		if not cloth.parts.is_empty():
			moving_profiles += 1
			check(moved > .002,"actual acceleration/turn produces visible secondary movement")
			for part: Dictionary in cloth.parts:
				check(absf(part.angle) < .001 and absf(part.speed) < .001,"stationary garment settles without perpetual wobble")
		check(identity == visual.get_meta("appearance"),"identity unchanged")
		visual.position += Vector3(5,0,0)
		visual.step_clothing(1.0/60.0)
		for part: Dictionary in cloth.parts: check(part.angle == 0.0 and part.node.transform == part.rest,"teleport resets exactly")
		var before: int = cloth.ticks
		paused = true
		visual.step_clothing(1.0/60.0)
		paused = false
		check(cloth.ticks == before,"pause does not advance cloth clock")
		var other := Node3D.new()
		root.add_child(other)
		other.global_transform = visual.global_transform
		cloth.step(other,1.0/60.0)
		for part: Dictionary in cloth.parts: check(part.angle == 0.0,"same-position rebind clears prior inertia")
		other.free()
		visual.free()
	check(moving_profiles >= 18,"representative outfits carry free clothing/accessory parts")
	# Render reads are pure: two same-seed rigs advance identically at 60Hz while
	# one is sampled between ticks at simulated 30/60/120 rendering cadences.
	var a: Node3D = Appearance.build({"appearance_seed":42})
	var b: Node3D = Appearance.build({"appearance_seed":42})
	root.add_child(a); root.add_child(b)
	var skin_a: MeshInstance3D = a.find_children("Head","MeshInstance3D",true,false)[0]
	check(skin_a.material_override.shader == load("res://shaders/toon.gdshader"),"skin stays on original toon material")
	for frame: int in 120:
		a.position.z -= .02 if frame < 60 else 0.0
		b.position = a.position
		a.step_clothing(1.0/60.0); b.step_clothing(1.0/60.0)
		for reads: int in (2 if frame%2 == 0 else 1):
			for part: Dictionary in b.clothing.parts: var _pose: Transform3D = part.node.global_transform
		for i: int in a.clothing.parts.size():
			var first: Transform3D = a.clothing.parts[i].node.transform
			var second: Transform3D = b.clothing.parts[i].node.transform
			check(first.origin.distance_to(second.origin) <= .001 and first.basis.get_rotation_quaternion().angle_to(second.basis.get_rotation_quaternion()) <= deg_to_rad(.1),"render read frequency leaves same-physics pose unchanged")
	var actor = load("res://scripts/npc/CityNpcActor.gd").new()
	root.add_child(actor)
	actor.setup(3,{"appearance_seed":42})
	actor.set_physics_process(false)
	actor._physics_process(1.0/60.0)
	check(actor.visual.clothing.ticks == 1,"production actor ticks helper once")
	var saved: Dictionary = actor.motion_state()
	actor.restore_motion(saved)
	check(not actor.visual.clothing._valid,"stream restore clears only presentation history")
	check(saved == actor.motion_state(),"cloth restore does not change saved actor motion")
	actor.free(); a.free(); b.free()
	for name: String in ["Sfx","UltMusic","Music"]: root.get_node(name).queue_free()
	await create_timer(.25).timeout
	print("NPC_CLOTHING_COMPLETE checks=%d failures=%d max_meshes=%d max_triangles=%d max_hinges=%d" % [checks,failures,max_meshes,max_triangles,max_parts])
	quit(0 if failures == 0 else 1)
