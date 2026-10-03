class_name WeakMarks
extends Node3D
## Skea's passive made visible: pulsing violet rings on the victim's low / mid / high zones.
## Lives on every fighter; shows a ring when that zone is marked or the fighter is Armor-Broken.

const ZONES := {"low": 0.5, "mid": 1.05, "high": 1.6}

var fighter: Fighter
var _rings: Dictionary = {}
var _t: float = 0.0


func setup(f: Fighter) -> void:
	fighter = f
	var mat := Fx.mat(Color(0.72, 0.28, 1.0, 0.95), false)
	var sheet := Flipbook.texture_for("weak_mark") != null
	for z in ZONES.keys():
		if sheet:
			# T6·B's weak_mark reticle: a seamless 16-cell pulse, looped for as long as the fighter lives
			var fb := Flipbook.play(f, "weak_mark", Vector3(0.0, ZONES[z], 0.5), 0.42, {"parent": self, "loop": true, "additive": true})
			if fb != null:
				fb.visible = false
				_rings[z] = fb
			continue
		var tm := TorusMesh.new()
		tm.inner_radius = 0.1
		tm.outer_radius = 0.16
		tm.rings = 16
		tm.ring_segments = 6
		var mi := Fx.mesh(tm, mat)
		mi.rotation.x = PI / 2.0
		mi.position = Vector3(0.0, ZONES[z], 0.5)
		mi.visible = false
		add_child(mi)
		_rings[z] = mi


func _process(delta: float) -> void:
	if fighter == null:
		return
	_t += delta
	var exposed := fighter.armor_break_frames > 0
	var pulse := 1.0 + 0.25 * sin(_t * 9.0)
	for z in _rings.keys():
		var mi: MeshInstance3D = _rings[z]
		mi.visible = (exposed or fighter.weak_marks.has(z)) and fighter.state != Fighter.State.LAUNCHED and fighter.state != Fighter.State.KO
		mi.scale = Vector3.ONE * (1.0 if mi is Flipbook else pulse) * (1.25 if exposed else 1.0)   # the sheet pulses itself
		mi.position.y = ZONES[z] + fighter.animator.root_offset.y
