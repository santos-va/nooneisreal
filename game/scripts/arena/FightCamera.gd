class_name FightCamera
extends Node3D
## Side camera that frames both fighters: pulls back with separation, lifts with height, shakes on hits.

@onready var cam: Camera3D = $Camera3D

var aim_controller: HarpoonAim
var p1: Fighter
var p2: Fighter
@export_range(0.0, 1.0) var impact_scale: float = 1.0
var _impact: CameraImpact = CameraImpact.new()


func setup(a: Fighter, b: Fighter) -> void:
	if aim_controller == null:
		aim_controller = HarpoonAim.new()
		add_child(aim_controller)
	aim_controller.setup(cam, false)
	p1 = a
	p2 = b
	_impact.reset()
	global_position = _target()


func _target() -> Vector3:
	var mid := (p1.global_position + p2.global_position) * 0.5
	var sep := absf(p1.global_position.x - p2.global_position.x)
	var hi := maxf(p1.global_position.y, p2.global_position.y)
	var dist := clampf(5.5 + sep * 0.78, 7.0, 15.5)
	return Vector3(mid.x, 1.6 + hi * 0.45 + dist * 0.14, dist)


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	var t := _target()
	global_position = global_position.lerp(t, 1.0 - pow(0.0015, delta))
	var hi := maxf(p1.global_position.y, p2.global_position.y)
	var look := Vector3(global_position.x, 1.25 + hi * 0.4, 0.0)
	cam.look_at(look, Vector3.UP)
	var offset: Vector2 = _impact.step(delta, impact_scale * ComfortSettings.get_value("shake"))
	cam.h_offset = offset.x
	cam.v_offset = offset.y


func shake(amount: float) -> void:
	_impact.trigger(amount)
