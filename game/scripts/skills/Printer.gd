class_name Printer
extends Node3D
## Choko's passive «Printer» (T5 Арес, docs/GDD/03-Skills-Framework.md § Пасивка Choko — Printer):
## a drone prints one sticker every 15 s (the first at 8 s of the fight), 1.5 m behind Choko on the floor.
## Choko picks it up by walking through it; the opponent tears it by stepping on it (no effect). A sticker
## lasts 8 s; at most one lies on the floor. Fixed queue, no RNG: Patch → Seen → Spring → Patch …
## Everything counts physics frames from the moment the fight starts, so smoke and replays repeat.
## Numbers are PLACEHOLDER (Ares). The sticker is T6·B's art (sticker_<kind>.png, lane D); the disc is only the fallback.

const FPS := 60
const FIRST_PRINT_FRAMES := 8 * FPS     # PLACEHOLDER
const PRINT_EVERY_FRAMES := 15 * FPS    # PLACEHOLDER
const LIFE_FRAMES := 8 * FPS            # PLACEHOLDER
const BEHIND_M := 1.5                   # PLACEHOLDER
const PICK_RADIUS := 0.6                # how close a foot must come (flat distance), placeholder
const PATCH_HP := 30.0                  # PLACEHOLDER
const SEEN_FRAMES := 4 * FPS            # PLACEHOLDER
const SPRING_FRAMES := 6 * FPS          # PLACEHOLDER
const QUEUE := ["patch", "seen", "spring"]
const COLORS := {"patch": Color(0.35, 0.85, 0.45), "seen": Color(0.65, 0.4, 1.0), "spring": Color(1.0, 0.82, 0.25)}

signal printed(kind: String, at: Vector3)
signal picked(kind: String)
signal torn(kind: String)

var owner_f: Fighter
var fight_frames: int = 0          # frames of fight so far (counts while the owner is not control-locked)
var next_print: int = FIRST_PRINT_FRAMES
var queue_index: int = 0
var sticker_kind: String = ""      # "" = no sticker on the floor
var sticker_age: int = 0
var stats: Dictionary = {"printed": 0, "picked": 0, "torn": 0, "crumbled": 0, "skipped": 0}
var _disc: MeshInstance3D


func setup(f: Fighter) -> void:
	owner_f = f
	process_physics_priority = 10   # after both fighters moved this frame
	top_level = true                # lives in world space, not under the fighter's transform


func reset() -> void:
	fight_frames = 0
	next_print = FIRST_PRINT_FRAMES
	queue_index = 0
	stats = {"printed": 0, "picked": 0, "torn": 0, "crumbled": 0, "skipped": 0}
	_remove_sticker()


func sticker_position() -> Vector3:
	return _disc.global_position if _disc != null else Vector3.ZERO


func _physics_process(_delta: float) -> void:
	if owner_f == null or owner_f.control_locked or owner_f.state == Fighter.State.KO:
		return
	fight_frames += 1
	_tick_sticker()
	if fight_frames >= next_print:
		next_print += PRINT_EVERY_FRAMES
		print_now()


## The sticker on the floor ages first (a fresh one starts next frame, so it lives exactly LIFE_FRAMES),
## then whoever stands on it decides its fate: Choko picks it up, the opponent tears it.
func _tick_sticker() -> void:
	if sticker_kind == "":
		return
	sticker_age += 1
	if _touches(owner_f):
		_apply(sticker_kind)
		stats.picked += 1
		picked.emit(sticker_kind)
		_remove_sticker()
		return
	var o := owner_f.opponent
	if o != null and _touches(o):
		stats.torn += 1
		torn.emit(sticker_kind)
		Sfx.play("ui_move", -6)
		_remove_sticker()
		return
	if sticker_age >= LIFE_FRAMES:
		stats.crumbled += 1
		_remove_sticker()
		return
	_update_disc()


## Prints the next sticker of the queue 1.5 m behind the owner, unless one already lies on the floor
## (max 1: the print is skipped and the queue does not advance). Public for the smoke test.
func print_now() -> bool:
	if sticker_kind != "":
		stats.skipped += 1
		return false
	var kind: String = QUEUE[queue_index % QUEUE.size()]
	queue_index += 1
	var back := Vector3(-owner_f.forward.x, 0.0, -owner_f.forward.z)
	if back.length() < 0.01:
		back = Vector3(-float(owner_f.facing), 0.0, 0.0)
	var at := Fighter.clamp_arena(owner_f.global_position + back.normalized() * BEHIND_M)
	if not GameState.free_move:
		at.z = 0.0
	at.y = GameState.water.height(at.x, at.z) if GameState.water != null else 0.0
	sticker_kind = kind
	sticker_age = 0
	stats.printed += 1
	_make_disc(kind, at)
	Sfx.play("ui_confirm", -10)
	printed.emit(kind, at)
	return true


func _touches(f: Fighter) -> bool:
	if not f.on_ground() or f.state == Fighter.State.LAUNCHED or f.state == Fighter.State.KO:
		return false
	var d := f.global_position - _disc.global_position
	return Vector2(d.x, d.z).length() <= PICK_RADIUS


func _apply(kind: String) -> void:
	match kind:
		"patch":
			owner_f.heal(PATCH_HP)
		"seen":
			if owner_f.opponent != null:
				owner_f.opponent.revealed_frames = SEEN_FRAMES    # refresh, never stack
		"spring":
			owner_f.spring_frames = SPRING_FRAMES               # refresh, one use
	Sfx.play("grapple_hit", -6)


# --- the sticker on the floor: T6·B's sticker art (a flat plane), or a disc in the item colour if the file is missing.
# The node is the pick-up anchor (sticker_position), so it exists whatever Fx.enabled says.
const STICKER_M := 0.8
func _make_disc(kind: String, at: Vector3) -> void:
	_remove_disc()
	_disc = Flipbook.sticker_mesh("sticker_" + kind, STICKER_M)
	if _disc != null:
		add_child(_disc)
		_disc.global_position = at + Vector3(0.0, 0.02, 0.0)
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.32
	cyl.height = 0.02
	cyl.radial_segments = 24
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = COLORS.get(kind, Color.WHITE)
	_disc = MeshInstance3D.new()
	_disc.mesh = cyl
	_disc.material_override = m
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_disc)
	_disc.global_position = at + Vector3(0.0, 0.02, 0.0)


func _update_disc() -> void:
	if _disc == null:
		return
	var left := LIFE_FRAMES - sticker_age
	var m := _disc.material_override as StandardMaterial3D
	m.albedo_color.a = 1.0 if left > FPS else float(left) / float(FPS)   # fades during the last second
	var s := 1.0 + 0.06 * sin(float(sticker_age) * 0.15)
	_disc.scale = Vector3(s, 1.0, s)


func _remove_sticker() -> void:
	sticker_kind = ""
	sticker_age = 0
	_remove_disc()


func _remove_disc() -> void:
	if _disc != null:
		_disc.queue_free()
		_disc = null
