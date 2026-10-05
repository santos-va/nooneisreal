class_name GrimoireFx
extends Node3D
## Skea ultimate «Проклятий фоліант: 12 Печаток (∞8)». Variant B from the design doc:
## the book opens, 12 spectral pages orbit, and sealed villains (shadow projections) strike around
## Skea in a radius on the bass beat. All weak points of the opponent are exposed for the duration,
## so every strike crits. The last strike ragdolls and poisons.
## Launch 3b (docs/GDD/03 § Ульта Skea під бас): every number comes from the MoveData — imprint frames,
## damage, stun, the end on startup + active. The end is a simulation event: the music only listens
## (UltMusic), and time stop pauses this counter and the music together. From SHADOW VEIL the same
## effect runs the long ult: 8 imprints, the body free between them, and the «SKI» signature.

const PAGES := 12
const RADIUS := 3.6
const TAIL := 20                  # pages fade after the end event (normal ult: gone on effect frame 92, as before)
const STROKE_HEIGHT := 1.2        # contour y = 0 sits this high above the anchor (letters in the air)
const FLASH_GAP := 1.6            # «SKI» flash lands this far in front of the opponent, on the stroke's x
const BOOK_HEIGHT := 1.75        # PLACEHOLDER presentation: raised hands of the crossed-leg levitation pose.

var owner_f: Fighter
var move: MoveData
var _f: int = 0                   # effect frame: 0 = the spawn frame = move frame `move.startup`
var _born: int = -1
var _ended: bool = false
var _tail: int = 0
var _pages: Array = []
var _book: Node3D
var _moves: Array = []
var _page_mat: StandardMaterial3D
var _trail_mat: StandardMaterial3D
var _trail: ImmediateMesh
var _strokes: Array = []          # world-space polylines drawn so far
var _anchor: Vector3 = Vector3.ZERO
var _fwd: Vector3 = Vector3.RIGHT
var _right: Vector3 = Vector3.BACK
var _signs: Array = []            # [node, material, frames left] ∞8 on the ground per imprint
## Effect frames of the imprints and of the end event (smoke reads these, the fight does not).
var strike_log: Array[int] = []
var end_frame: int = -1


static func spawn(f: Fighter, m: MoveData) -> GrimoireFx:
	var g := GrimoireFx.new()
	g.owner_f = f
	g.move = m
	Fx.root(f).add_child(g)
	g.global_position = f.global_position
	return g


## The ult is still on (armor, imprints, music): false from the end event on.
func running() -> bool:
	return not _ended


func presentation_frame() -> int:
	return _f


static func cancel_owner(f: Fighter) -> void:
	for node in f.get_tree().get_nodes_in_group("grimoire_ults"):
		var book := node as GrimoireFx
		if book != null and book.owner_f == f:
			book.end_ult()
			book.set_physics_process(false)
			book.queue_free()
	SkeaWave.cancel_owner(f)


func _ready() -> void:
	_born = Engine.get_physics_frames()
	add_to_group("grimoire_ults")
	# imprints before the last keep the victim on the ground (knockback y 0): the stun is a stun, not a
	# juggle — with beats 10 frames apart a lift made the next imprint an air hit → ragdoll, and the
	# third never landed (3b smoke). Question to T5 Арес: confirm.
	var n := move.beat_frames.size()
	for k in n:
		var dmg: float = move.beat_damage[k] if k < move.beat_damage.size() else 0.0
		if k == n - 1:
			_moves.append(SkillHit.make("imprint_venom_knot", dmg, 30, Vector2(7.0, 8.0),
				{"hitstop": 11, "knockdown": true, "ragdoll": 1.3, "ignore_scaling": true, "effect": "poison", "sfx": "ko"}))
		elif k % 2 == 0:
			_moves.append(SkillHit.make("imprint_blood_grip", dmg, move.beat_stun, Vector2(-1.5, 0.0),
				{"hitstop": 6, "ignore_scaling": true, "sfx": "hit_heavy", "backhit": 0}))
		else:
			_moves.append(SkillHit.make("imprint_cursed_burn", dmg, move.beat_stun, Vector2(1.5, 0.0),
				{"hitstop": 6, "ignore_scaling": true, "sfx": "hit_heavy", "backhit": 0}))
	var c := owner_f.data.vfx_primary
	_page_mat = Fx.mat(Color(c, 0.7), true)
	_book = Node3D.new()
	add_child(_book)
	_book.position = Vector3(owner_f.facing * 0.55, BOOK_HEIGHT, 0.25)
	if GameState.free_move:
		# free movement: the effect's local +x is the gaze, so the book floats in front, not to the screen side
		rotation.y = owner_f.yaw()
		_book.position = Vector3(0.55, BOOK_HEIGHT, 0.25)
	var cover := GearSurface.make("leather",Color("38243f"),Color("927c9a"))
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
		# T6·B's grimoire_page sheet: one page turning, looped over its first 12 cells (the last 4 burn away);
		# the pale quad only when the sheet is missing. Pages are pictures: the imprints below never read them.
		var p: Node3D = null
		if Flipbook.texture_for("grimoire_page") != null:
			p = Flipbook.play(self, "grimoire_page", Vector3.ZERO, 0.55, {"parent": self, "count": 12, "loop": true, "first": (i * 5) % 12})
		else:
			var q := QuadMesh.new()
			q.size = Vector2(0.26, 0.36)
			p = Fx.mesh(q, _page_mat)
			add_child(p)
		if p != null:
			_pages.append(p)
	var v := owner_f.opponent
	if v != null:
		v.armor_break_frames = maxi(v.armor_break_frames, move.active + 50)
		_anchor = v.global_position
		var to := v.global_position - owner_f.global_position
		to.y = 0.0
		if GameState.free_move and to.length() > 0.05:
			_fwd = to.normalized()
			_right = _fwd.cross(Vector3.UP)
		else:
			_fwd = Vector3(float(owner_f.facing), 0, 0)
			_right = Vector3.RIGHT
	if not move.contour.is_empty():
		_trail_mat = Fx.mat(Color(owner_f.data.vfx_secondary, 0.9), true)
		_trail = ImmediateMesh.new()
		var tm := MeshInstance3D.new()
		tm.mesh = _trail
		tm.material_override = _trail_mat
		tm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tm.top_level = true
		add_child(tm)
	Sfx.play("book")
	if move.music != "":
		# the move's frame 0 is the file's 0 s; this is frame `startup`
		UltMusic.play(move.music, float(move.startup) / 60.0)


func _exit_tree() -> void:
	# leaving the scene mid-ult (menu): the music must not hang on; no stinger outside the fight
	if not _ended:
		_ended = true
		UltMusic.finish("")


func _physics_process(_delta: float) -> void:
	if owner_f == null or not is_instance_valid(owner_f):
		queue_free()
		return
	if Engine.get_physics_frames() == _born:
		return
	_tick_signs()
	if _ended:
		_tail += 1
		_page_mat.albedo_color.a = 0.7 * Fx.stepped(float(TAIL - _tail) / float(TAIL))
		for p in _pages:
			if p is Flipbook:
				(p as Flipbook).set_alpha(Fx.stepped(float(TAIL - _tail) / float(TAIL)))
		if _trail_mat != null:
			_trail_mat.albedo_color.a = 0.9 * Fx.stepped(float(TAIL - _tail) / float(TAIL))
		if _tail >= TAIL:
			queue_free()
		return
	var v := owner_f.opponent
	if owner_f.state == Fighter.State.KO or owner_f.state == Fighter.State.INTRO or (v != null and v.state == Fighter.State.KO):
		end_ult()
		return
	var stopped := owner_f.frozen_frames > 0 or TimeStopFx.freezes(global_position, owner_f)
	UltMusic.set_paused(stopped)
	if stopped:
		return
	_f += 1
	global_position = owner_f.global_position
	if GameState.free_move:
		rotation.y = owner_f.yaw()
	# Follow the presentation-only levitation; the book remains just in front of the hands.
	_book.position.y = BOOK_HEIGHT + 0.035 * sin(float(_f) / 30.0)
	if v != null:
		# weak points stay exposed for the ult's own clock: a time stop pauses it, the timer must not run out
		v.armor_break_frames = maxi(v.armor_break_frames, move.active - _f + 50)
	var open := minf(1.0, float(_f) / 20.0)
	for i in _pages.size():
		var p: Node3D = _pages[i]
		var ang := float(i) / float(PAGES) * TAU + float(_f) * 0.09
		var r := 0.4 + 1.3 * open
		p.position = Vector3(cos(ang) * r, 1.4 + sin(ang * 2.0) * 0.35 * open, sin(ang) * r * 0.5)
		p.rotation = Vector3(0, -ang, sin(ang) * 0.4)
	for k in move.beat_frames.size():
		if _f == move.beat_frames[k] - move.startup:
			_strike(k)
	if _f >= move.active:
		end_ult()


## The end event (end of active, KO, round reset, or a hit through the armor): stinger + music fade on
## this very sim frame, armor off; the pages fade for TAIL frames.
func end_ult() -> void:
	if _ended:
		return
	_ended = true
	end_frame = _f
	UltMusic.finish(move.end_sfx)
	if owner_f != null and is_instance_valid(owner_f) and owner_f.ult_fx == self:
		owner_f.ult_fx = null


func _strike(k: int) -> void:
	strike_log.append(_f)
	var v := owner_f.opponent
	_sign()
	if k < move.contour.size():
		_stroke(k)
	var side := -1.0 if k % 2 == 0 else 1.0
	var at := (v.global_position if v != null else owner_f.global_position) + Vector3(side * 1.1, 0, -0.1)
	Afterimage.spawn(Fx.root(owner_f), Afterimage.snapshot(owner_f.animator, owner_f.skeletal), Color(0.18, 0.04, 0.26), 0.45, 0.85, false, 1.3,
		at - owner_f.global_position + Vector3(0, 0, -0.2))
	Afterimage.spawn(Fx.root(owner_f), Afterimage.snapshot(owner_f.animator, owner_f.skeletal), owner_f.data.vfx_primary, 0.3, 0.45, true, 1.36,
		at - owner_f.global_position + Vector3(0, 0, -0.25))
	if v == null or not v.hurtbox_enabled():
		return
	var d := v.global_position - owner_f.global_position
	var reach := Vector2(d.x, d.z).length() if GameState.free_move else absf(d.x)   # 3D: a circle (docs/GDD/03 § Як у 3D)
	if reach <= RADIUS and absf(d.y) < 3.0:
		SmearShards.burst(Fx.root(owner_f), at, v.global_position, [owner_f.data.vfx_primary, owner_f.data.vfx_secondary, Color(0.05, 0.03, 0.08)], 16, 3)
		v.receive_hit(owner_f, _moves[k])


## «SKI» stroke k: the trail in the air around the anchor, and (free movement) Skea's body flash-steps
## along it. Presentation and movement only — the imprint's hit test above does not depend on it.
func _stroke(k: int) -> void:
	var pts: PackedVector2Array = move.contour[k]
	var line: Array[Vector3] = []
	for p in pts:
		line.append(_anchor + _right * p.x + Vector3.UP * (STROKE_HEIGHT + p.y))
	_strokes.append(line)
	for i in range(1, line.size()):
		SmearShards.burst(Fx.root(owner_f), line[i - 1], line[i], [owner_f.data.vfx_primary, owner_f.data.vfx_secondary], 3, 1)
	_trail.clear_surfaces()
	for l: Array[Vector3] in _strokes:
		if l.size() < 2:
			continue
		_trail.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for q in l:
			_trail.surface_add_vertex(q)
		_trail.surface_end()
	var v := owner_f.opponent
	if GameState.free_move and v != null and pts.size() > 0:
		var x := clampf(pts[pts.size() - 1].x, -2.0, 2.0)
		owner_f.beat_flash(v.global_position + _right * x - _fwd * FLASH_GAP)


## ∞8 on the ground under Skea for each imprint: T6·B's sigil_imprint sheet (slams in, burns, crumbles); the two rings
## that fade in 40 frames only when the sheet is missing.
func _sign() -> void:
	if Flipbook.texture_for("sigil_imprint") != null:
		Flipbook.play(owner_f, "sigil_imprint", owner_f.global_position + Vector3(0, 0.03, 0), 2.2, {"mode": Flipbook.Mode.FLOOR, "additive": true})
		return
	var mat := Fx.mat(Color(owner_f.data.vfx_primary, 0.8), true)
	var root := Node3D.new()
	root.top_level = true
	add_child(root)
	root.global_position = owner_f.global_position + Vector3(0, 0.03, 0)
	for side in [-1.0, 1.0]:
		var ring := Fx.mesh(TorusMesh.new(), mat)
		(ring.mesh as TorusMesh).inner_radius = 0.42
		(ring.mesh as TorusMesh).outer_radius = 0.5
		ring.position = _right * side * 0.47
		root.add_child(ring)
	_signs.append([root, mat, 40])


func _tick_signs() -> void:
	for i in range(_signs.size() - 1, -1, -1):
		var e: Array = _signs[i]
		e[2] -= 1
		(e[1] as StandardMaterial3D).albedo_color.a = 0.8 * Fx.stepped(float(e[2]) / 40.0)
		if e[2] <= 0:
			(e[0] as Node).queue_free()
			_signs.remove_at(i)
