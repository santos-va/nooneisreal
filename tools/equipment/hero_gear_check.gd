extends SceneTree
## Actual hero clothing buffers, physics-rate attachments, lifecycle and camera isolation.
var checks: int = 0
var failures: int = 0
const DT: float = 1.0/60.0
var f: Node3D
var Actor: Script

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_GEAR: " + label)

func authority() -> Array:
	return [f.global_transform,f.velocity,f.state,f.hp,f.meter,f.grapple.token,f.grapple.rope_length,f.grapple.charges,f._rng.state]

func bones() -> Array:
	var poses: Array = []
	var sk: Skeleton3D = f.skeletal.hero_skeleton
	for bone: int in sk.get_bone_count():
		poses.append(sk.get_bone_pose(bone))
	return poses

func buffer_check() -> void:
	var gear = f.skeletal.gear
	check(gear._tails.size() == 2 and gear.unsupported_tabs == 0,"both current heroes have two supported nonempty cloth tabs")
	var original: Mesh = gear.garment.original_mesh
	var current: Mesh = f.skeletal.hero_mesh.mesh
	check(gear.garment.selected_vertices > 500 and gear.garment.protected_vertices > 500, "both garment and protected anatomy are present")
	for surface: int in original.get_surface_count():
		var a: Array = original.surface_get_arrays(surface)
		var b: Array = current.surface_get_arrays(surface)
		for channel: int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS,Mesh.ARRAY_INDEX]:
			check(a[channel] == b[channel], "original geometry/UV/skin buffer identical channel %d" % channel)
		# Repacking the imported compressed normals/tangents has bounded precision;
		# positions, UVs, weights and indices above remain byte exact.
		var normal_error: float = 0.0
		var tangent_error: float = 0.0
		for i: int in a[Mesh.ARRAY_NORMAL].size():
			normal_error = maxf(normal_error,a[Mesh.ARRAY_NORMAL][i].distance_to(b[Mesh.ARRAY_NORMAL][i]))
		for i: int in a[Mesh.ARRAY_TANGENT].size():
			tangent_error = maxf(tangent_error,absf(a[Mesh.ARRAY_TANGENT][i]-b[Mesh.ARRAY_TANGENT][i]))
		check(normal_error < 0.0002 and tangent_error < 0.0002,"compressed normal/tangent quantization below 0.0002")
		var old_colors: PackedColorArray = a[Mesh.ARRAY_COLOR] if a[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var colors: PackedColorArray = b[Mesh.ARRAY_COLOR]
		var colors_ok: bool = true
		for i: int in colors.size():
			var old: Color = old_colors[i] if not old_colors.is_empty() else Color.WHITE
			colors_ok = colors_ok and is_equal_approx(colors[i].a,old.a)
			colors_ok = colors_ok and colors[i].r in [0.0,1.0] and colors[i].g in [0.0,1.0] and colors[i].b in [0.0,1.0]
		check(colors_ok,"declared R face/G cloth/B highlight masks are binary; original A preserved")
		var joints: PackedInt32Array = b[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = b[Mesh.ARRAY_WEIGHTS]
		var stride: int = joints.size()/colors.size()
		var protected: int = 0
		var wrong: int = 0
		var protected_anatomy := PackedByteArray()
		protected_anatomy.resize(colors.size())
		var highlight_protected := PackedByteArray()
		highlight_protected.resize(colors.size())
		var face_weight_ok: bool = true
		var neckline_ok: bool = true
		var neckline_count: int = 0
		var hip: Vector3 = f.skeletal.hero_skeleton.get_bone_global_rest(f.skeletal.hero_skeleton.find_bone("Hips")).origin
		var scale_m: float = f.skeletal.hero_skeleton.global_transform.basis.get_scale().x
		for vertex: int in colors.size():
			var head_weight: float = 0.0
			var relative: Vector3 = (gear.garment.rest_points[vertex]-hip)*scale_m
			for j: int in stride:
				var at: int = vertex*stride+j
				if weights[at] <= 0.000001:
					continue
				var skin: Skin = f.skeletal.hero_mesh.skin
				var bone: int = f.skeletal.hero_skeleton.find_bone(skin.get_bind_name(joints[at])) if skin.get_bind_name(joints[at]) != &"" else skin.get_bind_bone(joints[at])
				var name: String = f.skeletal.hero_skeleton.get_bone_name(bone)
				if name in ["Head","head_end","headfront"]:
					head_weight += weights[at]
				if name.contains("Head") or name.contains("neck") or name.contains("Hand") or name.contains("Foot") or name.contains("Toe"):
					protected += 1
					protected_anatomy[vertex] = 1
					wrong += 1 if colors[vertex].g > 0 else 0
					# Skea sleeve cloth has small hand weights before the wrist.
					# Physical hand skin is beyond the independently measured 500 mm guard.
					if not name.contains("Hand") or f.data.id != "skea" or absf(relative.x) >= 0.50:
						highlight_protected[vertex] = 1
						wrong += 1 if colors[vertex].b > 0 else 0
			face_weight_ok = face_weight_ok and (colors[vertex].r == 0.0 or head_weight >= 0.90)
			if f.data.id == "skea" and relative.y >= 0.28 and absf(relative.x) <= 0.16:
				neckline_count += 1
				highlight_protected[vertex] = 1
				neckline_ok = neckline_ok and colors[vertex].b == 0.0
		check(protected > 100 and wrong == 0,"protected head/neck/physical hands/feet receive no highlight; cloth keeps strict bone domain")
		check(face_weight_ok and gear.garment.face_vertices > 0,"face mask has real samples exclusively bound to head")
		check(f.data.id != "skea" or (neckline_count > 100 and neckline_ok),"actual shoulder-weighted bare neckline remains outside highlight mask")
		check(gear.garment.delighted_vertices > 100 if f.data.id == "skea" else gear.garment.delighted_vertices == 0,"Skea has positive highlight domain while Choko atlas is not recolored")
		var old_surface: Dictionary = RenderingServer.mesh_get_surface(original.get_rid(),surface)
		var new_surface: Dictionary = RenderingServer.mesh_get_surface(current.get_rid(),surface)
		check(old_surface.get("lods",[]).size() == 3,"fixture has real imported decimation LODs")
		check(old_surface.get("lods",[]) == new_surface.get("lods",[]),"all original LOD indices and distances preserved")
		var index_sets: Array = [a[Mesh.ARRAY_INDEX]]
		index_sets.append_array(gear.garment._surface_lods(original,surface,a[Mesh.ARRAY_INDEX].size()).values())
		var triangle_safe: bool = true
		var protected_triangles: int = 0
		for triangles: PackedInt32Array in index_sets:
			for tri: int in triangles.size()/3:
				var corners: Array[int] = [triangles[tri*3],triangles[tri*3+1],triangles[tri*3+2]]
				if protected_anatomy[corners[0]] != 0 or protected_anatomy[corners[1]] != 0 or protected_anatomy[corners[2]] != 0:
					protected_triangles += 1
					for corner: int in corners:
						triangle_safe = triangle_safe and colors[corner].g == 0.0
				if highlight_protected[corners[0]] != 0 or highlight_protected[corners[1]] != 0 or highlight_protected[corners[2]] != 0:
					for corner: int in corners:
						triangle_safe = triangle_safe and colors[corner].b == 0.0
		check(protected_triangles > 100 and triangle_safe,"every protected anatomy triangle at base and all imported LODs has zero cloth/highlight interpolation")
	var mat: ShaderMaterial = f.skeletal.hero_mesh.material_override
	check(mat.get_shader_parameter("albedo_tex") != null,"original atlas remains bound")
	print("HERO_GARMENT_METRICS ",f.data.id," selected=",gear.garment.selected_vertices," total=",gear.garment.total_vertices)

func pose_check() -> void:
	var gear = f.skeletal.gear
	var before: Array = authority()
	var pose: Array = bones()
	var serial: int = gear.serial
	var spring: Vector2 = gear.spring
	for repeat: int in 3:
		gear.update_pose()
	check(before == authority() and pose == bones(),"attachments never change fighter or bone authority")
	check(serial == gear.serial and spring == gear.spring,"render callbacks never advance cloth")
	check(absf(gear.spring.x) <= deg_to_rad(12.0)+0.000001 and absf(gear.spring.y) <= deg_to_rad(8.0)+0.000001,"secondary angles bounded")
	for tail: Dictionary in gear._tails:
		check(not tail.skin.is_empty(),"pin is actual skinned garment surface")
		var anchor: Transform3D = gear.pin_transform(tail)
		check(anchor.origin.distance_to(tail.anchor.global_position) <= 0.001,"actual skinned pin stays within 1mm")
		var segments: Array = tail.segments
		var total_fold: float = 0.0
		for segment: Node3D in segments:
			total_fold += absf(segment.rotation.x)
		check(total_fold <= deg_to_rad(15.0)+0.000001,"actual cumulative three-link fold remains within15degrees")
		for i: int in segments.size():
			check(segments[i].global_basis.determinant() > 0.999,"cloth segment never mirrors/scales")
			if i > 0:
				check(absf(segments[i].global_position.distance_to(segments[i-1].global_position)-tail.length/3.0) < 0.0001,"link stretch below0.1mm")
			var end: Vector3 = segments[i].to_global(Vector3(0,-tail.length/3.0,0))
			check((end-anchor.origin).dot(anchor.basis.z) >= -0.001,"free edges stay outside tangent support plane")

func assert_skin(actor: Node3D, oracle: RefCounted, label: String) -> void:
	check(oracle.sample(actor,label) == 0,"actual full-body skin triangles never cross cloth: " + label)
	check(oracle.invalid_shapes == 0,"skin oracle requires six finite nondegenerate cloth boxes and nonempty pins")
	check(oracle.pin_margin > 0.0005 and oracle.pin_margin < 0.004,"actual pins have positive surface clearance without floating beyond4mm")

func crouch_contact_check() -> void:
	# Exact independent reproductions: jog/block facet contacts, settled waist-fold
	# penetration, and crossed arms during high/low/transfer rope animation.
	var fixture := Node3D.new()
	root.add_child(fixture)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100,1,100)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position.y = -0.5
	fixture.add_child(floor_body)
	var input: Node = root.get_node("InputRouter")
	input.apply_profile("solo",false)
	input.set_view_basis(1,Vector3.FORWARD)
	var oracle = load(get_script().resource_path.get_base_dir().path_join("skinned_cloth_oracle.gd")).new()
	for hero: String in ["choko","skea"]:
		var actor = load("res://scenes/fighter/Fighter.tscn").instantiate()
		actor.data = load("res://data/characters/"+hero+".tres")
		fixture.add_child(actor)
		actor.set_physics_process(false)
		actor.skeletal.set_physics_process(false)
		actor.control_locked = false
		actor.state = Actor.State.IDLE
		actor.forward = Vector3.RIGHT
		for frame: int in (441 if hero == "choko" else 381):
			await physics_frame
			input.v_set(1,"right",frame>=60 and frame<200)
			input.v_set(1,"up",frame>=200 and frame<260)
			input.v_set(1,"crouch",frame>=330 and frame<390)
			input.v_set(1,"block",frame>=420 and frame<450)
			actor._physics_process(DT)
			actor.skeletal._physics_process(DT)
			actor.skeletal._on_mannequin_updated()
			if (hero == "choko" and frame in [90,440]) or (hero == "skea" and frame == 380):
				if hero == "skea":
					check(actor.state == Actor.State.CROUCH and actor.frame_in_state >= 49,"worst-case fixture reaches settled actual crouch")
				assert_skin(actor,oracle,hero+"/"+str(frame))
		input.v_clear(1)
		actor.free()
	var Hook: Script = load("res://scripts/grapple/GrappleHook.gd")
	var anchor := Node3D.new()
	fixture.add_child(anchor)
	anchor.add_to_group("grapple_anchor")
	var other := Node3D.new()
	fixture.add_child(other)
	other.add_to_group("grapple_anchor")
	for scenario: String in ["high","low","transfer"]:
		var actor = load("res://scenes/fighter/Fighter.tscn").instantiate()
		actor.data = load("res://data/characters/skea.tres")
		fixture.add_child(actor)
		actor.set_physics_process(false)
		actor.skeletal.set_physics_process(false)
		actor.grapple.registry.set_physics_process(false)
		actor.grapple.registry.clear_match()
		actor.control_locked = false
		actor.forward = Vector3.FORWARD
		actor.state = Actor.State.GRAPPLE
		anchor.position = Vector3(0,2,-4) if scenario == "low" else Vector3(0,6,-3)
		other.position = Vector3(4,7,-2)
		await physics_frame
		if scenario == "transfer":
			actor.position.y = 2.0
			anchor.position = Vector3(0,6,0)
			var token: int = actor.grapple.registry.issue(1)
			actor.grapple.registry.deploy(token,1,anchor.position,actor.position+Hook.HAND,(actor.position+Hook.HAND).distance_to(anchor.position))
			actor.grapple.fire(false,"grapple_parkour")
		else:
			actor.grapple.fire(false,"grapple_parkour",{"point":anchor.position,"target_id":str(anchor.get_path())})
		for frame: int in 76:
			if scenario == "transfer" and frame == 30:
				check(actor.grapple.retarget({"point":other.position,"target_id":str(other.get_path())}),"worst-case fixture uses real transfer")
			actor.grapple.tick_regen(DT,true)
			if actor.grapple.busy():
				actor.grapple.drive(DT,true,frame>=40)
			actor.animator.tick(DT,actor,false)
			actor.skeletal._physics_process(DT)
			actor.skeletal.retarget()
			if (scenario == "high" and frame == 75) or (scenario == "low" and frame in [60,75]) or (scenario == "transfer" and frame == 60):
				check(actor.grapple.phase == Hook.Phase.HANG,"worst-case fixture reaches actual hang/reel")
				assert_skin(actor,oracle,"skea/"+scenario+"/"+str(frame))
		actor.grapple.registry.clear_match()
		actor.free()
	fixture.queue_free()
	await process_frame

func run() -> void:
	await process_frame
	Actor = load("res://scripts/fighter/Fighter.gd")
	var state: Node = root.get_node("GameState")
	state.skeletal_rig = true
	state.free_move = true
	state.water = null
	var input: Node = root.get_node("InputRouter")
	await crouch_contact_check()
	var stage: Node3D = load("res://scenes/world/CityDistrict.tscn").instantiate()
	root.add_child(stage)
	for hero: String in ["choko","skea"]:
		f = load("res://scenes/fighter/Fighter.tscn").instantiate()
		f.set_script(load("res://scripts/world/CityFighter.gd"))
		f.data = load("res://data/characters/"+hero+".tres")
		root.add_child(f)
		f.set_physics_process(false)
		f.skeletal.set_physics_process(false)
		f.restart_at(Vector3.ZERO)
		buffer_check()
		if hero == "skea":
			var cover: MeshInstance3D = f.skeletal.gear.find_child("GrimoireCoverFace",true,false)
			var uv: PackedVector2Array = cover.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
			check(uv == PackedVector2Array([Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(1,0)]),"rear book face owns a full square cover UV")
			check(cover.material_override == f.skeletal.gear.cover_material and int(cover.material_override.get_shader_parameter("pattern_mode")) == 1,"colored cover has a separate raw albedo material")
			var emblem: MeshInstance3D = f.skeletal.gear.find_child("GrimoireEightSigil",true,false)
			check(emblem != null and emblem.mesh is ArrayMesh,"book has one continuous reference infinity-eight mesh")
			var extent: Vector3 = emblem.mesh.get_aabb().size
			check(extent.x/0.285 >= 0.45 and extent.x/0.285 <= 0.51 and extent.y/0.325 >= 0.22 and extent.y/0.325 <= 0.27,"reference sigil fits horizontal cover proportions")
			check(emblem.position.is_equal_approx(Vector3(0,-0.09,-0.38)),"single eight is centered on rear cover only")
			check((emblem.material_override.get_shader_parameter("albedo") as Color).is_equal_approx(Color("9e4cf2")),"reference violet color is preserved")
			var old_rings: int = 0
			for part: Node in f.skeletal.gear._body.find_children("*","MeshInstance3D",true,false):
				if part.mesh is TorusMesh:
					old_rings += 1
			check(old_rings == 0,"old stacked circle emblem is absent from book")
		var mesh: Mesh = f.skeletal.hero_mesh.mesh
		var duplicate = load("res://scenes/fighter/Fighter.tscn").instantiate()
		duplicate.data = f.data
		root.add_child(duplicate)
		check(duplicate.skeletal.hero_mesh.mesh == mesh,"cached garment buffer shared across same hero")
		check(duplicate.skeletal.gear.cloth_material != f.skeletal.gear.cloth_material,"per-hero material state never shared")
		var hero_material: ShaderMaterial = f.skeletal.hero_mesh.material_override
		var other_material: ShaderMaterial = duplicate.skeletal.hero_mesh.material_override
		check(hero_material != other_material and hero_material.next_pass != other_material.next_pass,"same hero keeps independent surface and outline material instances")
		check((hero_material.next_pass as ShaderMaterial).shader.resource_path == "res://shaders/hero_outline.gdshader","only hero material selects the face-safe hull")
		var original_delight: Variant = hero_material.get_shader_parameter("garment_delight")
		var original_closure: Variant = hero_material.get_shader_parameter("face_closure")
		other_material.set_shader_parameter("garment_delight",0.0)
		other_material.set_shader_parameter("face_closure",Vector2.ONE)
		check(hero_material.get_shader_parameter("garment_delight") == original_delight and hero_material.get_shader_parameter("face_closure") == original_closure,"cached masks never share per-instance face or cloth uniforms")
		duplicate.free()
		var biggest_spring: float = 0.0
		for frame: int in 150:
			await physics_frame
			input.v_set(1,"right",frame < 45)
			input.v_set(1,"up",frame >=45 and frame<80)
			input.v_set(1,"crouch",frame>=110 and frame<135)
			f._physics_process(DT)
			f.skeletal._physics_process(DT)
			f.skeletal._on_mannequin_updated()
			biggest_spring = maxf(biggest_spring,f.skeletal.gear.spring.length())
			pose_check()
		check(biggest_spring > 0.003,"real acceleration produces visible nonzero secondary response")
		input.v_clear(1)
		var gear = f.skeletal.gear
		f.frozen_frames = 4
		var frozen: Array = [gear.serial,gear.spring,gear.spring_velocity]
		for i: int in 4:
			gear.advance(DT)
			gear.update_pose()
		check(frozen == [gear.serial,gear.spring,gear.spring_velocity],"hitstop/freeze holds cloth state")
		f.frozen_frames = 0
		f.hitstop_frames = 3
		gear.advance(DT)
		gear.update_pose()
		check(frozen == [gear.serial,gear.spring,gear.spring_velocity],"independent hitstop also holds cloth state")
		f.hitstop_frames = 0
		paused = true
		gear.advance(DT)
		gear.update_pose()
		check(frozen == [gear.serial,gear.spring,gear.spring_velocity],"scene pause holds cloth state")
		paused = false
		f.restart_at(Vector3(10,0,0))
		f.skeletal._physics_process(DT)
		check(gear.spring == Vector2.ZERO and gear.spring_velocity == Vector2.ZERO,"restart clears inertia rather than whipping")
		# Same fixed physics sequence, different render callback counts (30/60/120Hz).
		var final_samples: Array = []
		for render_rate: int in [30,60,120]:
			f.motion_revision += 1
			gear.advance(DT)
			for frame: int in 90:
				f.skeletal.motion_signals.acceleration = Vector3(4 if frame<30 else -3,0,2)
				gear.advance(DT)
				for render: int in (2 if render_rate==120 else (1 if render_rate==60 or frame%2==0 else 0)):
					gear.update_pose()
			# Observe the same final physics phase at every presentation cadence.
			gear.update_pose()
			final_samples.append([gear.spring,gear.spring_velocity,gear._tails[0].segments[2].global_transform])
		check(final_samples[0] == final_samples[1] and final_samples[1] == final_samples[2],"30/60/120 render cadence preserves same physics cloth state")
		f._spawn_ragdoll(Vector3(1,1,0),true)
		for tick: int in 6:
			await physics_frame
			f.skeletal._physics_process(DT)
			f.skeletal._on_mannequin_updated()
			gear.update_pose()
			check(gear.spring == Vector2.ZERO and gear.spring_velocity == Vector2.ZERO,"actual BoneRagdoll clears secondary inertia")
			pose_check()
		f._clear_ragdoll()
		f.animator.visible = true
		f.restart_at(Vector3(10,0,0))
		await physics_frame
		f.skeletal._physics_process(DT)
		# Late nested shared materials, including surface slots, remain camera-local.
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.make_current()
		camera.position = f.position+Vector3(0,1.25,0.05)
		var proximity = load("res://scripts/world/CityCameraProximity.gd").new()
		proximity.setup(f)
		var nested := Node3D.new()
		gear.add_child(nested)
		var shared: ShaderMaterial = load("res://scripts/core/GearSurface.gd").make("leather",Color("392c38"),Color.WHITE)
		var simple := StandardMaterial3D.new()
		simple.albedo_color = Color.CORAL
		var late: Array[MeshInstance3D] = []
		for source: Material in [shared,simple]:
			var item := MeshInstance3D.new()
			item.mesh = BoxMesh.new()
			item.set_surface_override_material(0,source)
			nested.add_child(item)
			late.append(item)
		var npc := MeshInstance3D.new()
		npc.mesh = BoxMesh.new()
		npc.material_override = shared
		root.add_child(npc)
		for i: int in 30:
			proximity.update(camera,DT)
		check(proximity.visibility < 0.01,"near-body camera fixture actually fades")
		check(float((f.skeletal.hero_mesh.material_override.next_pass as ShaderMaterial).get_shader_parameter("camera_visibility")) < 0.01,"face-safe hero outline participates in camera proximity fade")
		for item: MeshInstance3D in late:
			check(item.get_surface_override_material(0) is ShaderMaterial and float(item.get_surface_override_material(0).get_shader_parameter("camera_visibility")) < 0.01,"late nested surface slot joins fade")
		check(shared.get_shader_parameter("camera_visibility") == null or is_equal_approx(float(shared.get_shader_parameter("camera_visibility")),1.0),"NPC shared shader receives no player fade")
		check(npc.material_override == shared and simple.albedo_color == Color.CORAL,"source NPC/color resources never mutated")
		var replacement: ShaderMaterial = load("res://scripts/core/GearSurface.gd").make("cloth",Color.TEAL,Color.WHITE)
		late[0].set_surface_override_material(0,replacement)
		proximity.update(camera,DT)
		check(late[0].get_surface_override_material(0) != shared,"late slot replacement is respected")
		var tracked: int = proximity._gear.size()
		for cycle: int in 12:
			var transient := MeshInstance3D.new()
			transient.mesh = BoxMesh.new()
			transient.material_override = shared
			nested.add_child(transient)
			proximity.update(camera,DT)
			transient.free()
			proximity.update(camera,DT)
			check(proximity._gear.size() == tracked,"freed nested geometry releases material entries")
		proximity.restore()
		check(late[0].get_surface_override_material(0) == replacement and late[1].get_surface_override_material(0) == simple,"all exact original material pointers restored")
		proximity.setup(f)
		var removed_mesh := MeshInstance3D.new()
		removed_mesh.mesh = BoxMesh.new()
		removed_mesh.set_surface_override_material(0,shared)
		nested.add_child(removed_mesh)
		var override_mesh := MeshInstance3D.new()
		override_mesh.mesh = BoxMesh.new()
		override_mesh.material_override = shared
		nested.add_child(override_mesh)
		for i: int in 30:
			proximity.update(camera,DT)
		removed_mesh.mesh = null
		override_mesh.mesh = null
		# Exit can happen without another update after a customization removes a mesh.
		proximity.restore()
		check(override_mesh.material_override == shared,"exit restores override even after mesh removal")
		check(proximity._gear.is_empty(),"exit releases removed surface-slot material chains")
		camera.free()
		npc.free()
		f.free()
		await process_frame
	stage.queue_free()
	for name: String in ["Sfx","UltMusic","Music"]:
		root.get_node(name).queue_free()
	var until: int = Time.get_ticks_msec()+200
	while Time.get_ticks_msec()<until:
		await process_frame
		OS.delay_msec(1)
	print("HERO_GEAR_COMPLETE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
