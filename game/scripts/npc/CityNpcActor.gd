class_name CityNpcActor
extends Node3D
## Separate, collision-checked pedestrian lanes for the bounded district slice.
@export var walk_speed: float = 1.15 # PLACEHOLDER metres per second.
@export var stop_seconds: float = 1.8 # PLACEHOLDER local routine pacing.
var resident_index: int = 0
var visual: Node3D
var walking: bool = true
var clock: float = 0.0
var home := Vector3.ZERO
var route: Array[Vector3] = []
var waypoint: int = 0
var pause_left: float = 0.0
var speech_left: float = 0.0
var speech: Label3D

static func home_for(index: int) -> Vector3:
	return Vector3(-5.4 + (index % 4) * 3.6, 0.0, -10.0 + (index / 4) * 15.0)

func setup(index: int, person: Dictionary) -> void:
	resident_index = index
	home = home_for(index)
	position = home
	route = [home + Vector3(-0.5, 0, -4), home + Vector3(0.5, 0, -4),
		home + Vector3(0.5, 0, 4), home + Vector3(-0.5, 0, 4)]
	waypoint = index % route.size()
	visual = NpcAppearance.build(person)
	add_child(visual)
	speech = Label3D.new()
	speech.position.y = 2.25
	speech.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	speech.font_size = 32
	speech.pixel_size = 0.008
	speech.outline_size = 8
	speech.modulate = Color("fff1d8")
	speech.visible = false
	add_child(speech)

func say(text: String, listener: Vector3, duration: float) -> void:
	speech.text = text
	speech_left = duration
	pause_left = maxf(pause_left, duration)
	speech.show()
	var direction: Vector3 = listener - global_position
	if Vector2(direction.x, direction.z).length_squared() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)

func motion_state() -> Dictionary:
	return {"position": position, "waypoint": waypoint, "clock": clock, "pause": pause_left}

func restore_motion(state: Dictionary) -> void:
	position = state.position
	waypoint = state.waypoint
	clock = state.clock
	pause_left = state.pause

func _physics_process(delta: float) -> void:
	clock += delta
	speech_left = maxf(0.0, speech_left - delta)
	speech.visible = speech_left > 0.0
	var speed: float = 0.0
	if walking:
		if pause_left > 0.0:
			pause_left = maxf(0.0, pause_left - delta)
		else:
			var before: Vector3 = position
			position = position.move_toward(route[waypoint], walk_speed * delta)
			var motion: Vector3 = position - before
			speed = motion.length() / maxf(delta, 0.001)
			if motion.length_squared() > 0.000001:
				rotation.y = lerp_angle(rotation.y, atan2(-motion.x, -motion.z), minf(1.0, delta * 8.0))
			if position.distance_to(route[waypoint]) < 0.01:
				waypoint = (waypoint + 1) % route.size()
				pause_left = stop_seconds + (resident_index % 3) * 0.4
	if visual != null and visual.has_method("set_motion"):
		visual.call("set_motion", speed, clock)
