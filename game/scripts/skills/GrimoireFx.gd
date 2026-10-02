class_name GrimoireFx
extends Node3D
## Skea ultimate «Проклятий фоліант: 12 Печаток (∞8)». Variant B from the design doc:
## the book opens, 12 spectral pages orbit, and three sealed villains (shadow projections)
## strike around Skea in a radius. All weak points of the opponent are exposed for the duration,
## so every strike crits. The last strike ragdolls and poisons.

const PAGES := 12
const RADIUS := 3.6
const STRIKES := [36, 52, 70]
const END := 92

var owner_f: Fighter
var _f: int = 0
var _pages: Array = []
var _book: Node3D
var _moves: Array = []
var _page_mat: StandardMaterial3D


static func spawn(f: Fighter) -> GrimoireFx:
	var g := GrimoireFx.new()
	g.owner_f = f
	Fx.root(f).add_child(g)
	g.global_position = f.global_position
	return g


func _ready() -> void:
	_moves = [
		SkillHit.make("grimoire_page3_blood_grip", 60.0, 22, Vector2(-1.5, 1.0), {"hitstop": 6, "ignore_scaling": true, "sfx": "hit_heavy"}),
		SkillHit.make("grimoire_page7_cursed_burn", 60.0, 22, Vector2(1.5, 1.5), {"hitstop": 6, "ignore_scaling": true, "sfx": "hit_heavy"}),
		SkillHit.make("grimoire_page12_shadow", 90.0, 30, Vector2(7.0, 8.0),
			{"hitstop": 11, "knockdown": true, "ragdoll": 1.3, "ignore_scaling": true, "effect": "poison", "sfx": "ko"}),
	]
	var c := owner_f.data.vfx_primary
	_page_mat = Fx.mat(Color(c, 0.7), true)
	_book = Node3D.new()
	add_child(_book)
	_book.position = Vector3(owner_f.facing * 0.55, 1.35, 0.25)
	var cover := StandardMaterial3D.new()
	cover.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cover.albedo_color = Color(0.22, 0.1, 0.3)
	for side in [-1, 1]:
		var half := Fx.mesh(BoxMesh.new(), cover)
		(half.mesh as BoxMesh).size = Vector3(0.24, 0.04, 0.34)
		half.position = Vector3(side * 0.13, 0, 0)
		half.rotation.z = -side * 0.35
		_book.add_child(half)
	var sigil := Fx.mesh(TorusMesh.new(), Fx.mat(Color(0.85, 0.5, 1.0, 0.95), true))
	(sigil.mesh as TorusMesh).inner_radius = 0.05
	(sigil.mesh as TorusMesh).outer_radius = 0.08
	sigil.position = Vector3(0, 0.08, 0)
	_book.add_child(sigil)
	for i in PAGES:
		var q := QuadMesh.new()
		q.size = Vector2(0.26, 0.36)
		var p := Fx.mesh(q, _page_mat)
		add_child(p)
		_pages.append(p)
	var v := owner_f.opponent
	if v != null:
		v.armor_break_frames = maxi(v.armor_break_frames, END + 30)
	Sfx.play("book")


func _physics_process(_delta: float) -> void:
	if owner_f == null or not is_instance_valid(owner_f):
		queue_free()
		return
	if owner_f.frozen_frames > 0 or TimeStopFx.freezes(global_position, owner_f):
		return
	_f += 1
	global_position = owner_f.global_position
	var open := minf(1.0, float(_f) / 20.0)
	for i in PAGES:
		var p: MeshInstance3D = _pages[i]
		var ang := float(i) / float(PAGES) * TAU + float(_f) * 0.09
		var r := 0.4 + 1.3 * open
		p.position = Vector3(cos(ang) * r, 1.4 + sin(ang * 2.0) * 0.35 * open, sin(ang) * r * 0.5)
		p.rotation = Vector3(0, -ang, sin(ang) * 0.4)
	for k in STRIKES.size():
		if _f == STRIKES[k]:
			_strike(k)
	if _f > END - 12:
		_page_mat.albedo_color.a = 0.7 * Fx.stepped(float(END - _f) / 12.0)
	if _f >= END:
		queue_free()


func _strike(k: int) -> void:
	var v := owner_f.opponent
	var side := -1.0 if k % 2 == 0 else 1.0
	var at := (v.global_position if v != null else owner_f.global_position) + Vector3(side * 1.1, 0, -0.1)
	Afterimage.spawn(Fx.root(owner_f), owner_f.animator.part_snapshot(), Color(0.18, 0.04, 0.26), 0.45, 0.85, false, 1.3,
		at - owner_f.global_position + Vector3(0, 0, -0.2))
	Afterimage.spawn(Fx.root(owner_f), owner_f.animator.part_snapshot(), owner_f.data.vfx_primary, 0.3, 0.45, true, 1.36,
		at - owner_f.global_position + Vector3(0, 0, -0.25))
	if v == null or not v.hurtbox_enabled():
		return
	if absf(v.global_position.x - owner_f.global_position.x) <= RADIUS and absf(v.global_position.y - owner_f.global_position.y) < 3.0:
		SmearShards.burst(Fx.root(owner_f), at, v.global_position, [owner_f.data.vfx_primary, owner_f.data.vfx_secondary, Color(0.05, 0.03, 0.08)], 16, 3)
		v.receive_hit(owner_f, _moves[k])
