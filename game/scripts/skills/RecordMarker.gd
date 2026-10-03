class_name RecordMarker
extends Node3D
## Choko S1 «Запис»: a clock glyph fixed where Choko stood, remembering his HP.
## Second press of the skill (or the timer running out) rewinds him here (Fighter.rewind).

const LIFE := 240   # 4 s

var owner_f: Fighter
var recorded_hp: float = 0.0
var left: int = LIFE
var _hand: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _sticker_mat: StandardMaterial3D   # the RECORD sticker on the floor (lane D art); null → the ring


static func spawn(f: Fighter) -> RecordMarker:
	var r := RecordMarker.new()
	r.owner_f = f
	r.recorded_hp = f.hp
	Fx.root(f).add_child(r)
	r.global_position = f.global_position
	return r


func _ready() -> void:
	var c := owner_f.data.vfx_primary
	_ring_mat = Fx.mat(Color(c, 0.85), true)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.68
	tm.rings = 32
	tm.ring_segments = 4
	var sticker := Flipbook.sticker_mesh("choko_record_sticker", 1.5)
	if sticker != null:
		_sticker_mat = sticker.material_override as StandardMaterial3D
		sticker.position = Vector3(0, 0.03, 0)
		add_child(sticker)
	else:
		var ring := Fx.mesh(tm, _ring_mat)
		ring.position = Vector3(0, 0.03, 0)
		add_child(ring)
	var pillar_mat := Fx.mat(Color(c, 0.18), true)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42
	cyl.bottom_radius = 0.5
	cyl.height = 2.0
	var pillar := Fx.mesh(cyl, pillar_mat)
	pillar.position = Vector3(0, 1.0, 0)
	add_child(pillar)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.03, 0.5)
	_hand = Fx.mesh(bm, _ring_mat)
	_hand.position = Vector3(0, 0.05, 0)
	add_child(_hand)
	Sfx.play("rewind", -6)


func _physics_process(_delta: float) -> void:
	if owner_f == null or not is_instance_valid(owner_f):
		queue_free()
		return
	if owner_f.frozen_frames > 0:
		return
	left -= 1
	_hand.rotation.y = -TAU * (1.0 - float(left) / float(LIFE))
	_ring_mat.albedo_color.a = 0.85 if left > 60 or (left / 6) % 2 == 0 else 0.25
	if _sticker_mat != null:
		_sticker_mat.albedo_color.a = 1.0 if left > 60 or (left / 6) % 2 == 0 else 0.3
	if left <= 0:
		owner_f.rewind()
