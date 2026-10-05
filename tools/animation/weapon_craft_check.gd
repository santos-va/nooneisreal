extends SceneTree
## Actual sword input/progression plus independent grip, clearance and craft geometry.
var checks: int = 0
var failures: int = 0
var actor: GDScript
var moves: GDScript
var input: Node
var world: Node3D
var camera: Camera3D
var caption: Label
var folder: String = ""
var baseline: bool = false
var view: String = "side"
var rows: Array = []
var fx: Node3D
func _initialize() -> void:
 run.call_deferred()
func check(ok: bool, message: String) -> void:
 if baseline: return
 checks += 1
 if not ok:
  failures += 1
  push_error("WEAPON_CRAFT: " + message)
func vec(value: Vector3) -> Array:
 return [value.x,value.y,value.z]
func authority(f) -> Array:
 return [f.transform,f.velocity,f.state,f.move_frame,f.sword_hand,f.sword_drawn,f.sword_form,f.hp,f.meter,str(f._rng.state)]
func present(f) -> void:
 var before: Array = authority(f)
 f.skeletal._physics_process(1.0/60.0)
 check(authority(f)==before,"visuals preserve body, move, hand ownership and RNG")
 if not baseline and f.state==actor.State.ATTACK: validate_attack(f)
func validate_attack(f) -> void:
 var rig: Skeleton3D=f.skeletal.hero_skeleton
 var side: String="Right" if f.attack_sword_hand=="right" else "Left"
 var hand: int=rig.find_bone(side+"Hand")
 var forearm: int=rig.find_bone(side+"ForeArm")
 var final_poses: Array[Transform3D]=[]
 for bone: int in rig.get_bone_count(): final_poses.append(rig.get_bone_pose(bone))
 f.skeletal.retarget()
 var wrist: Vector3=rig.global_transform*rig.get_bone_global_pose(hand).origin
 var raw_hand: Quaternion=rig.get_bone_global_pose(hand).basis.get_rotation_quaternion()
 var raw_forearm: Quaternion=rig.get_bone_global_pose(forearm).basis.get_rotation_quaternion()
 var raw_wrist: Quaternion=rig.get_bone_pose_rotation(hand)
 load("res://scripts/fighter/SwordMotion.gd").apply_transfer(rig,f)
 check((rig.global_transform*rig.get_bone_global_pose(hand).origin).distance_to(wrist)<0.00002,"clearance correction preserves authored world wrist/contact point")
 check(rad_to_deg(raw_hand.angle_to(rig.get_bone_global_pose(hand).basis.get_rotation_quaternion()))<=50.1,"actual hand correction bounded to50 degrees")
 check(rad_to_deg(raw_forearm.angle_to(rig.get_bone_global_pose(forearm).basis.get_rotation_quaternion()))<=45.1,"actual forearm twist bounded to45 degrees")
 check(rad_to_deg(raw_wrist.angle_to(rig.get_bone_pose_rotation(hand)))<=45.1,"actual residual wrist swing bounded to45 degrees")
 f.skeletal._on_mannequin_updated()
 var same: bool=true
 for bone: int in rig.get_bone_count():
  var pose: Transform3D=rig.get_bone_pose(bone)
  same=same and pose.origin.distance_to(final_poses[bone].origin)<0.0001 and pose.basis.get_scale().distance_to(final_poses[bone].basis.get_scale())<0.00001 and rad_to_deg(pose.basis.get_rotation_quaternion().angle_to(final_poses[bone].basis.get_rotation_quaternion()))<0.1
 check(same,"repeat retarget preserves every bone rotation, position and scale")
 if f.move_frame==f.current_move.startup:
  var frozen: Transform3D=f.skeletal.sword.global_transform
  f.hitstop_frames=3
  f.skeletal._physics_process(1.0/60)
  f.skeletal.sword.update_pose()
  check(f.skeletal.sword.global_transform==frozen,"hitstop holds corrected grip exactly")
  f.hitstop_frames=0
func make_actor(side: String, yaw: float = 0.0):
 var f = load("res://scenes/fighter/Fighter.tscn").instantiate()
 f.data = load("res://data/characters/choko.tres")
 world.add_child(f)
 f.set_physics_process(false)
 f.skeletal.set_physics_process(false)
 f.skeletal.sword.set_physics_process(false)
 f.control_locked = false
 f.state = actor.State.IDLE
 f.forward = Vector3.RIGHT.rotated(Vector3.UP,yaw)
 f.sword_hand = side
 f._rng.seed = 4751
 input.v_clear(1)
 return f
func arena_draws() -> void:
 root.get_node("GameState").free_move=false
 for facing: int in [-1,1]:
  for side: String in ["left","right"]:
   var f=make_actor(side,PI if facing<0 else 0.0)
   f.facing=facing
   f.sword_drawn=false
   f.skeletal.sword.reset_pose_state()
   for frame: int in 20:
    await physics_frame
    f._physics_process(1.0/60)
    present(f)
   var old_tip: Vector3=blade_point(f,1)
   for frame: int in 45:
    input.v_set(1,"weapon_swap",frame==5)
    await physics_frame
    f._physics_process(1.0/60)
    present(f)
    check(clearance(f)>0.13,"2D arena draw clears body in both facings/hands")
    check(blade_point(f,1).distance_to(old_tip)<0.4,"2D arena draw continuous tip")
    old_tip=blade_point(f,1)
   f.free()
   for effect: Node in fx.get_children(): effect.free()
 root.get_node("GameState").free_move=true
func blade_point(f, amount: float) -> Vector3:
 var blade: MeshInstance3D = f.skeletal.sword.blade
 var box: AABB = blade.mesh.get_aabb()
 return blade.global_transform * Vector3(0,lerpf(box.position.y,box.end.y,amount),0)
func distance_segment(point: Vector3, a: Vector3, b: Vector3) -> float:
 var line: Vector3 = b-a
 return point.distance_to(a+line*clampf((point-a).dot(line)/maxf(line.length_squared(),0.00001),0,1))
func clearance(f) -> float:
 var rig: Skeleton3D = f.skeletal.hero_skeleton
 var hips: Vector3 = rig.global_transform*rig.get_bone_global_pose(rig.find_bone("Hips")).origin
 var chest: Vector3 = rig.global_transform*rig.get_bone_global_pose(rig.find_bone("Spine")).origin
 var head: Vector3 = rig.global_transform*rig.get_bone_global_pose(rig.find_bone("Head")).origin+Vector3.UP*0.10
 var result: float = INF
 for index: int in 25:
  var point: Vector3 = blade_point(f,index/24.0)
  result = minf(result,minf(distance_segment(point,hips,chest),point.distance_to(head)))
 return result
func blade_in_hitband(f, move) -> bool:
 var forward: Vector3=f.forward.normalized()
 var lateral: Vector3=forward.cross(Vector3.UP)
 for sample: int in 33:
  var relative: Vector3=blade_point(f,sample/32.0)-f.global_position
  var point:=Vector3(relative.dot(forward),relative.y,relative.dot(lateral))
  var delta: Vector3=(point-move.hitbox_offset).abs()
  if delta.x<=move.hitbox_size.x*.5 and delta.y<=move.hitbox_size.y*.5 and delta.z<=move.hitbox_size.z*.5: return true
 return false
func record(f, sequence: String, frame: int) -> void:
 var w = f.skeletal.sword
 var row: Dictionary = {"sequence":sequence,"frame":frame,"body":vec(f.position),"velocity":vec(f.velocity),"state":f.state,"move_frame":f.move_frame,"hand":f.sword_hand,"form":f.sword_form,"drawn":f.sword_drawn,"rng":str(f._rng.state),"hp":f.hp,"meter":f.meter,"grip":vec(w.global_position),"tip":vec(blade_point(f,1)),"clearance":clearance(f)}
 rows.append(row)
 if folder.is_empty(): return
 caption.text = "Choko | %s | frame %d | %s\nActual 60 Hz | %s" % [sequence,frame,view,f.skeletal.clip]
 var focus: Vector3 = f.position+Vector3.UP*0.95
 camera.position = focus+(Vector3(4.8,0.5,0.45) if view=="front" else Vector3(0.35,0.5,4.8))
 camera.look_at(focus)
 await process_frame
 await RenderingServer.frame_post_draw
 var path: String = folder.path_join(sequence)
 DirAccess.make_dir_recursive_absolute(path)
 root.get_texture().get_image().save_png(path.path_join("%04d.png" % frame))
func run() -> void:
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--capture="): folder=arg.trim_prefix("--capture=")
  if arg=="--baseline": baseline=true
  if arg.begins_with("--view="): view=arg.trim_prefix("--view=")
 await process_frame
 actor=load("res://scripts/fighter/Fighter.gd")
 moves=load("res://scripts/fighter/LimbMoves.gd")
 var gs: Node=root.get_node("GameState")
 gs.skeletal_rig=true
 gs.free_move=true
 gs.water=null
 root.get_node("Sfx")._players.clear()
 input=root.get_node("InputRouter")
 input.apply_profile("solo",false)
 world=Node3D.new()
 root.add_child(world)
 current_scene=world
 fx=Node3D.new()
 fx.name="FX"
 fx.visible=false # Anatomy capture: effects still spawn/expire, hidden in both baseline/candidate.
 world.add_child(fx)
 var body:=StaticBody3D.new()
 var shape:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(50,1,50)
 shape.shape=box
 body.add_child(shape)
 body.position.y=-0.5
 world.add_child(body)
 if not folder.is_empty():
  root.size=Vector2i(900,700)
  DirAccess.make_dir_recursive_absolute(folder)
  var environment:=WorldEnvironment.new()
  environment.environment=Environment.new()
  environment.environment.background_mode=Environment.BG_COLOR
  environment.environment.background_color=Color("24303e")
  environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
  environment.environment.ambient_light_energy=0.8
  world.add_child(environment)
  var light:=DirectionalLight3D.new()
  light.rotation_degrees=Vector3(-40,-35,0)
  world.add_child(light)
  var floor_mesh:=MeshInstance3D.new()
  floor_mesh.mesh=PlaneMesh.new()
  floor_mesh.mesh.size=Vector2(50,50)
  world.add_child(floor_mesh)
  camera=Camera3D.new()
  camera.current=true
  camera.fov=35
  world.add_child(camera)
  var layer:=CanvasLayer.new()
  root.add_child(layer)
  caption=Label.new()
  caption.position=Vector2(15,15)
  caption.add_theme_font_size_override("font_size",18)
  layer.add_child(caption)
 for side: String in ["right","left"]:
  var f=make_actor(side)
  f.sword_drawn=false
  f.skeletal.sword.reset_pose_state()
  for frame: int in 24:
   await physics_frame
   f._physics_process(1.0/60)
   present(f)
  var previous_tip: Vector3=blade_point(f,1)
  var previous_grip: Vector3=f.skeletal.sword.global_position
  var previous_rotation: Quaternion=f.skeletal.sword.global_basis.get_rotation_quaternion()
  for frame: int in 125:
   input.v_set(1,"weapon_swap",frame==10 or frame==50 or frame==90)
   await physics_frame
   f._physics_process(1.0/60)
   present(f)
   var w=f.skeletal.sword
   var tip: Vector3=blade_point(f,1)
   var rotation: Quaternion=w.global_basis.get_rotation_quaternion()
   check(tip.distance_to(previous_tip)<0.40,"actual draw/transfer tip continuity "+side+"/"+str(frame))
   check(w.global_position.distance_to(previous_grip)<0.12,"actual draw/transfer grip continuity")
   check(rad_to_deg(rotation.angle_to(previous_rotation))<24.0,"actual draw/transfer orientation continuity")
   check(clearance(f)>0.13,"blade avoids head/torso throughout actual draw/transfer "+side+"/"+str(frame))
   check(w.global_basis.determinant()>0.99,"proper unit handed weapon frame")
   if frame<10:
    var rig: Skeleton3D=f.skeletal.hero_skeleton
    var shoulder_y: float=maxf((rig.global_transform*rig.get_bone_global_pose(rig.find_bone("LeftArm")).origin).y,(rig.global_transform*rig.get_bone_global_pose(rig.find_bone("RightArm")).origin).y)
    check(w.global_position.y>shoulder_y+0.07,"stored handle above both shoulders")
    check(tip.y<w.global_position.y-0.50,"stored tip points down independently of socket helper")
   if f.state==actor.State.SWAP and f.sword_swap_drawing and f.sword_swap_frame in [8,9,10,11]:
    if not baseline:
     check(w.hand_grip(f.sword_swap_to).origin.distance_to(w.back_grip().origin)<0.003,"actual palm reaches shared physical handle before release "+side)
   previous_tip=tip
   previous_grip=w.global_position
   previous_rotation=rotation
   await record(f,side+"_draw_swap",frame)
  if not baseline:
   for form: int in 3:
    f.sword_form=form
    f.state=actor.State.IDLE
    present(f)
    var mesh: ArrayMesh=f.skeletal.sword.blade.mesh
    check(mesh.get_aabb().size.x<=0.145 and mesh.get_aabb().size.z<=0.023,"thin physical blade profile")
    var data: Array=mesh.surface_get_arrays(0)
    check((data[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size()==(data[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(),"crafted blade carries real UV coordinates")
    check(f.skeletal.sword.blade_material.get_shader_parameter("surface_kind")==1,"blade UV consumed by inlay material")
  f.free()
  for effect: Node in fx.get_children(): effect.free()
 if not baseline and folder.is_empty(): await arena_draws()
 for form: int in ([0] if baseline or not folder.is_empty() else [0,1,2]):
  for yaw: float in ([0.0,PI/2.0] if form==0 else [0.0]):
   for side: String in ["right","left"]:
    for variant: String in ["cut","thrust","rising","cleave","lowcut","aircut"]:
     var f=make_actor(side,yaw)
     f.sword_drawn=true
     f.sword_form=form
     f.skeletal.sword.stow_weight=0.0
     for settle: int in 20:
      await physics_frame
      f._physics_process(1.0/60)
      present(f)
     var index: int=0 if variant in ["cut","lowcut","aircut"] else (1 if variant=="thrust" else 2)
     var move=moves.resolve(f.data,side+"_hand",index,"",variant=="lowcut",variant=="aircut",side,"right_hand>left_hand>right_hand" if variant=="cleave" else "")
     if variant=="aircut":
      f.position.y=2.0
      f.state=actor.State.JUMP
      f.move_and_slide()
     f._start_move(move)
     var contact_band_seen: bool=false
     for frame: int in move.startup+move.active+move.recovery+18:
      await physics_frame
      f._physics_process(1.0/60)
      present(f)
      if f.state==actor.State.ATTACK and f.move_frame>=move.startup and f.move_frame<move.startup+move.active:
       contact_band_seen=contact_band_seen or blade_in_hitband(f,move)
      check(clearance(f)>0.13,"authored sword body clearance "+side+"/form"+str(form)+"/"+variant+"/"+str(frame))
      if f.state==actor.State.ATTACK and f.move_frame==move.startup and variant=="cut":
       check((blade_point(f,1)-f.skeletal.sword.global_position).normalized().dot(f.forward)>0.30,"first-active cut blade leads ahead, never back into own leg")
       check(f.skeletal.sword.global_basis.determinant()>0.99,"armed attack proper grip frame")
      if yaw==0.0:
       if not baseline: exact_skin(f,side+"/form"+str(form)+"/"+variant+"/"+str(f.move_frame))
       if form==0: await record(f,side+"_"+variant,frame)
     check(contact_band_seen,"actual blade crosses declared hitband during ACTIVE "+side+"/form"+str(form)+"/"+variant)
     f.free()
     for effect: Node in fx.get_children(): effect.free()
 if not folder.is_empty():
  var file:=FileAccess.open(folder.path_join("trace.json"),FileAccess.WRITE)
  file.store_string(JSON.stringify(rows))
  file.close()
 world.queue_free()
 await process_frame
 print("WEAPON_CRAFT_COMPLETE checks=%d failures=%d" % [checks,failures])
 quit(1 if failures else 0)

## Independent T4 regression oracle: full imported skin weights and actual blade
## triangle edges, in both intersection directions. No production capsule/helper calls.
func exact_skin(f, label: String) -> void:
 if f.current_move==null or f.state!=f.State.ATTACK:return
 var selected: bool=false
 for kind: String in ["cut","thrust","lowcut","cleave"]:
  if not f.current_move.anim.ends_with("_"+kind):continue
  var frames: Array={"cut":[16],"thrust":[14,15,16],"lowcut":[6,7,8,9],"cleave":[16]}[kind]
  selected=f.move_frame in frames
 if not selected:return
 var mesh: MeshInstance3D=f.skeletal.hero_mesh
 var sk: Skeleton3D=f.skeletal.hero_skeleton
 var contacts: Array=[]
 var blade: MeshInstance3D=f.skeletal.sword.blade
 var blade_faces: PackedVector3Array=blade.mesh.get_faces()
 for i: int in blade_faces.size():blade_faces[i]=blade.global_transform*blade_faces[i]
 var blade_box:=AABB(blade_faces[0],Vector3.ZERO)
 for p: Vector3 in blade_faces:blade_box=blade_box.expand(p)
 var edges: Array=[]
 var seen: Dictionary={}
 for tri: int in blade_faces.size()/3:
  for i: int in 3:
   var x: Vector3=blade_faces[tri*3+i]
   var y: Vector3=blade_faces[tri*3+(i+1)%3]
   var key: String=str(x)+"|"+str(y) if str(x)<str(y) else str(y)+"|"+str(x)
   if not seen.has(key):seen[key]=true;edges.append([x,y])
 for surface: int in mesh.mesh.get_surface_count():
  var arrays: Array=mesh.mesh.surface_get_arrays(surface)
  var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var ids: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
  var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
  var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  var stride: int=ids.size()/vertices.size()
  var mapped: Array=[]
  for bind: int in mesh.skin.get_bind_count():mapped.append(sk.find_bone(mesh.skin.get_bind_name(bind)) if mesh.skin.get_bind_name(bind)!=&"" else mesh.skin.get_bind_bone(bind))
  var skin_poses: Array[Transform3D]=[]
  for bind: int in mesh.skin.get_bind_count(): skin_poses.append(sk.get_bone_global_pose(mapped[bind])*mesh.skin.get_bind_pose(bind))
  var world:=PackedVector3Array()
  var allowed:=PackedByteArray()
  world.resize(vertices.size());allowed.resize(vertices.size())
  for vertex: int in vertices.size():
   var p:=Vector3.ZERO
   var body_weight: float=0.0
   for j: int in stride:
    var offset: int=vertex*stride+j
    if weights[offset]<=0.000001:continue
    var bind: int=ids[offset]
    var bone: int=mapped[bind]
    p+=(skin_poses[bind]*vertices[vertex])*weights[offset]
    if sk.get_bone_name(bone) in ["Hips","Spine","Spine01","Spine02","neck","Head","headfront","LeftUpLeg","RightUpLeg","LeftLeg","RightLeg"]:body_weight+=weights[offset]
   world[vertex]=sk.global_transform*p
   allowed[vertex]=1 if body_weight>=0.5 else 0
  for triangle: int in indices.size()/3:
   var x: int=indices[triangle*3]
   var y: int=indices[triangle*3+1]
   var z: int=indices[triangle*3+2]
   if allowed[x]+allowed[y]+allowed[z]<3:continue
   var face_box:=AABB(world[x],Vector3.ZERO).expand(world[y]).expand(world[z])
   if not face_box.grow(.000001).intersects(blade_box.grow(.000001)):continue
   for edge: Array in edges:
    var point: Variant=Geometry3D.segment_intersects_triangle(edge[0],edge[1],world[x],world[y],world[z])
    if point!=null:contacts.append([point.x,point.y,point.z])
   for tri: int in blade_faces.size()/3:
    for edge: Array in [[world[x],world[y]],[world[y],world[z]],[world[z],world[x]]]:
     var point: Variant=Geometry3D.segment_intersects_triangle(edge[0],edge[1],blade_faces[tri*3],blade_faces[tri*3+1],blade_faces[tri*3+2])
     if point!=null:contacts.append([point.x,point.y,point.z])
 check(contacts.is_empty(),"actual blade edges avoid independently skinned body at "+label)
