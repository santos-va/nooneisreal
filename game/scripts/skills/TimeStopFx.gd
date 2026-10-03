class_name TimeStopFx
extends Node3D
## Choko S2 «Стоп-час»: a chrono pulse. The opponent inside RADIUS is frozen (Fighter.freeze),
## enemy skill effects inside it pause, the world goes grey-blue. Hits on a frozen fighter deal
## 70 % and their knockback is stored and released when time resumes.

const RADIUS := 4.2

var owner_f: Fighter
var duration: int = 72
var _f: int = 0
var _sphere_mat: ShaderMaterial
var _sphere: MeshInstance3D
var _rect: ColorRect
var _screen: ShaderMaterial   # fx_chrono_screen: grey-blue drain + clock-tick ring (look only)


static func spawn(f: Fighter, frames: int) -> TimeStopFx:
	var t := TimeStopFx.new()
	t.owner_f = f
	t.duration = frames
	Fx.root(f).add_child(t)
	t.global_position = f.global_position + Vector3(0, 1.0, 0)
	return t


## Is `pos` inside a time-stop field that was NOT cast by `caster`?
static func freezes(pos: Vector3, caster: Node) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	for n in tree.get_nodes_in_group("time_stop_fields"):
		var t := n as TimeStopFx
		if t != null and t.owner_f != caster and t.global_position.distance_to(pos + Vector3(0, 1.0, 0)) <= RADIUS:
			return true
	return false


func _ready() -> void:
	add_to_group("time_stop_fields")
	_sphere_mat = FxShader.stroke(Color(0.6, 0.75, 1.0), 0.16, true, 0.0, 1.0)
	var sm := SphereMesh.new()
	sm.radius = RADIUS
	sm.height = RADIUS * 2.0
	_sphere = Fx.mesh(sm, _sphere_mat)
	_sphere.scale = Vector3.ONE * 0.1
	add_child(_sphere)
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	_rect = ColorRect.new()
	_screen = FxShader.chrono_screen()
	_rect.material = _screen
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_rect)
	Sfx.play("time_stop")
	var v := owner_f.opponent
	if v != null:
		var d := v.global_position - owner_f.global_position
		var reach := Vector2(d.x, d.z).length() if GameState.free_move else absf(d.x)   # 3D: a circle (docs/GDD/03 § Як у 3D)
		if reach <= RADIUS and absf(d.y) < 3.0:
			v.freeze(duration)


func _physics_process(_delta: float) -> void:
	if owner_f == null or not is_instance_valid(owner_f):
		queue_free()
		return
	_f += 1
	var grow := minf(1.0, float(_f) / 8.0)
	_sphere.scale = Vector3.ONE * grow
	var fade := 1.0 - clampf(float(_f - duration + 10) / 10.0, 0.0, 1.0)
	_sphere_mat.set_shader_parameter("alpha", 0.16 * fade)
	_screen.set_shader_parameter("strength", 0.8 * fade * grow)
	_screen.set_shader_parameter("ring", minf(1.2, float(_f) / 20.0))
	if _f >= duration:
		queue_free()
