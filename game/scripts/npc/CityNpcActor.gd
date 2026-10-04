class_name CityNpcActor
extends Node3D
## Presentation stays inside the unobstructed central pedestrian strip.
var resident_index: int = 0
var visual: Node3D
var walking: bool = false
var clock: float = 0.0
var home := Vector3.ZERO

func setup(index: int, person: Dictionary) -> void:
	resident_index = index
	home = Vector3(-5.0 + (index % 4) * 3.2, 0.0, 2.0 + (index / 4) * 7.0)
	position = home
	visual = NpcAppearance.build(person)
	add_child(visual)

func _physics_process(delta: float) -> void:
	clock += delta
	var speed: float = 0.0
	if walking:
		var target: Vector3 = home + Vector3(0.0, 0.0, sin(clock * 0.3 + resident_index) * 1.6)
		var motion: Vector3 = target - position
		speed = motion.length() / maxf(delta, 0.001)
		position = target
		if absf(motion.z) > 0.0001:
			rotation.y = PI if motion.z > 0.0 else 0.0
	if visual != null and visual.has_method("set_motion"):
		visual.call("set_motion", speed, clock)
