class_name SkeaWave
extends Node3D
## The grimoire extends an ordinary strike, never adds a second damage source.
## Fighter uses hitbox_for for both collision and debug drawing; this node is presentation only.

const COLOR := Color(0.66, 0.25, 1.0, 0.8)
const LIFE := 12 # PLACEHOLDER presentation frames; not an attack window.
var owner_f: Fighter
var _born: int = -1
var _frame: int = 0
var _reach: float = 0.0
var _travel_frames: int = 1
var _ribbon: MeshInstance3D
var _echo: MeshInstance3D
var _material: StandardMaterial3D


static func reach_for(f: Fighter, m: MoveData) -> float:
	if f.data.id != "skea" or m.kind != MoveData.Kind.NORMAL or m.damage <= 0.0 or m.hitbox_size == Vector3.ZERO:
		return 0.0
	if f.ult_fx == null or not is_instance_valid(f.ult_fx) or not f.ult_fx.running():
		return 0.0
	return maxf(0.0, f.data.ultimate_wave_reach)


static func hitbox_for(f: Fighter, m: MoveData) -> Dictionary:
	var reach := reach_for(f, m)
	var size := m.hitbox_size
	var offset := m.hitbox_offset
	size.x += reach
	offset.x += reach * 0.5 # Keep the rear edge fixed: no new hit area behind the limb.
	return {"size": size, "offset": offset}


static func spawn(f: Fighter, m: MoveData) -> SkeaWave:
	var reach := reach_for(f, m)
	if not Fx.enabled or reach <= 0.0:
		return null
	var wave := SkeaWave.new()
	wave.owner_f = f
	wave._reach = reach
	wave._travel_frames = maxi(1, m.active - 1)
	Fx.root(f).add_child(wave)
	wave.global_position = f.global_position + Vector3.UP * m.hitbox_offset.y
	wave.rotation.y = f.yaw() if GameState.free_move else (0.0 if f.facing > 0 else PI)
	wave._build(m)
	return wave


func _ready() -> void:
	_born = Engine.get_physics_frames()
	add_to_group("skea_waves")


static func cancel_owner(f: Fighter) -> void:
	for node in f.get_tree().get_nodes_in_group("skea_waves"):
		var wave := node as SkeaWave
		if wave != null and wave.owner_f == f:
			wave.set_physics_process(false)
			wave.queue_free()


func _build(m: MoveData) -> void:
	_material = Fx.mat(COLOR)
	var ribbon := ImmediateMesh.new()
	ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var edge := m.hitbox_offset.x + m.hitbox_size.x * 0.5
	# A crescent along the limb's actual height, extending to the collision's front edge.
	for i in 17:
		var angle := lerpf(-PI * 0.5, PI * 0.5, float(i) / 16.0)
		var y := sin(angle) * m.hitbox_size.y * 0.5
		var x := edge + cos(angle) * _reach
		ribbon.surface_add_vertex(Vector3(x, y, 0.0))
		ribbon.surface_add_vertex(Vector3(x - 0.14 * cos(angle), y, 0.0))
	ribbon.surface_end()
	_ribbon = Fx.mesh(ribbon, _material)
	add_child(_ribbon)
	_echo = Fx.mesh(ribbon, _material)
	_echo.position.x = -_reach
	add_child(_echo)
	# Crossed ribbons stay legible when the shared camera sees the strike end-on.
	var cross := Fx.mesh(ribbon, _material)
	cross.rotation.x = PI * 0.5
	add_child(cross)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(owner_f) or owner_f.state in [Fighter.State.KO, Fighter.State.INTRO] or owner_f.ult_fx == null:
		queue_free()
		return
	if _born == Engine.get_physics_frames() or owner_f.hitstop_frames > 0 or owner_f.frozen_frames > 0 or TimeStopFx.freezes(global_position, owner_f):
		return
	_frame += 1
	# Contact crest is visible at full reach immediately; its echo travels outward behind it.
	_echo.position.x = -_reach * (1.0 - minf(1.0, float(_frame) / _travel_frames))
	_material.albedo_color.a = COLOR.a * Fx.stepped(1.0 - float(_frame) / LIFE)
	if _frame >= LIFE:
		queue_free()
