class_name FxDirector
extends Node
## Lane B step 2: T6·B's painted sheets (game/assets/vfx/) in the fight. It only WATCHES the two fighters — their signals and,
## once per physics frame, their state — and spawns Flipbooks; it writes nothing back, so the fight is the same with it or
## without it (the smoke's duel replay runs once with Fx.enabled false and compares the hash). Sizes are PLACEHOLDER (metres).
##
## what → sheet (docs/Art/Prompts/VFX-Sheets-Prompts.md):
##   Choko's normals → slash_choko / slash_heavy_choko / slash_air_choko, from the first active frame
##   Skea's normals (jab_elbow, roundhouse, low_kick, flying_knee) → slash_skea, same hook, her own size
##   a hit → spark_hit (row: cream, crit violet, Choko emerald, blocked blue) — Arena._on_hit
##   K.O. → ko_burst · a dash → trail_chrono (Choko) / trail_flash (Skea's Flash Step), plus a smoke_puff at the push-off point
##   a grapple shot → grapple_launch
##   landing from a jump → dust_land (water_splash on the river) · a ragdoll settles → dust_land + ground_crack
##   SHADOW VEIL → smoke_veil · TIME STOP → choko_timestop under Choko · armor break → armor_break
##   «Seen» on a fighter → seen_mark over the head while it lasts · Printer Patch picked → patch_heal
##   Spring spent in the air → spring_jump · RECORD rewind → choko_rewind where Choko lands
##   sliding along the soft wall → skid_dust (again every SKID_EVERY frames) · a zip to an anchor → speed_lines
##   a blocked hit → spark_metal on top of the blue spark_hit row
## Still without a hook: electro_arc / electro_arc_kling — no electro mechanic on Fighter yet (T5 Арес, #161).
## (Printer stickers, the RECORD sticker, kunai, grimoire pages, ult sigils and weak marks draw inside their own scripts.)

const SLASH := {"light": "slash_choko", "crouch_light": "slash_choko", "heavy": "slash_heavy_choko", "air_light": "slash_air_choko"}
## Skea's normals all share one sheet; only the size differs (roundhouse is her "heavy").
const SLASH_SKEA := ["jab_elbow", "roundhouse", "low_kick", "flying_knee"]
const CHEST := 1.15
## spark_hit rows (sheet row 1…4): normal, crit, Choko, blocked.
const SPARK_ROW := {"normal": 0, "crit": 1, "choko": 2, "blocked": 3}
## Skid dust at the soft wall: grounded, on the circle, faster than this along it (m/s); one sheet per SKID_EVERY frames.
const SKID_SPEED := 2.5   # PLACEHOLDER
const SKID_EVERY := 20    # PLACEHOLDER

var fighters: Array[Fighter] = []
var _prev: Dictionary = {}   # fighter → see _snap()
var _seen: Dictionary = {}   # fighter → the seen_mark Flipbook over its head
var _skid_at: Dictionary = {}   # fighter → _frame of its last skid_dust
var _frame: int = 0
var _step_distance: Dictionary = {}
var _step_side: Dictionary = {}

## Visual thresholds only (m/s), sampled before collision clears vertical velocity.
const WATER_MEDIUM_SPEED := 4.0 # PLACEHOLDER
const WATER_HEAVY_SPEED := 8.0 # PLACEHOLDER
const WATER_STRIDE := 0.8 # PLACEHOLDER metres travelled per contact


func setup(a: Fighter, b: Fighter) -> void:
	fighters = [a, b]
	for f in fighters:
		f.move_started.connect(_on_move_started)
		f.knocked_out.connect(_on_ko)
		if f.printer != null:
			var who := f
			f.printer.picked.connect(func(kind: String) -> void: _on_picked(who, kind))
		_prev[f] = _snap(f)


## [state, on_ground, veil, armor break, frozen, grapple charges, dash charges, revealed, spring, RECORD marker alive, position,
##  velocity]
static func _snap(f: Fighter) -> Array:
	var marker := f.record_marker != null and is_instance_valid(f.record_marker)
	return [f.state, f.on_ground(), f.veil_frames, f.armor_break_frames, f.frozen_frames, f.grapple.charges, f.dash_charges_left,
		f.revealed_frames, f.spring_frames, marker, f.global_position, f.velocity]


## Speed along the soft wall (m/s) when `pos` is on the circle and the fighter is grounded, else 0. Free movement only.
static func wall_slide_speed(pos: Vector3, vel: Vector3, grounded: bool) -> float:
	if not GameState.free_move or not grounded:
		return 0.0
	var flat := Vector2(pos.x, pos.z)
	if flat.length() < Fighter.ARENA_RADIUS - 0.05:
		return 0.0
	var n := flat.normalized()
	var v := Vector2(vel.x, vel.z)
	return (v - n * v.dot(n)).length()


func _on_picked(f: Fighter, kind: String) -> void:
	if kind == "patch":
		Flipbook.play(f, "patch_heal", f.global_position + Vector3.UP * 0.9, 1.8)


## The hit spark (Arena._on_hit calls it next to HitSpark's lines and flash).
static func hit_spark(near: Node, at: Vector3, attacker: Fighter, damage: float, blocked: bool, crit: bool) -> Flipbook:
	var row: int = SPARK_ROW.blocked if blocked else (SPARK_ROW.crit if crit else (SPARK_ROW.choko if attacker.data.id == "choko" else SPARK_ROW.normal))
	var size := 1.0 if blocked else clampf(1.3 + damage / 90.0, 1.4, 3.2) * (1.4 if crit else 1.0)
	if blocked:
		Flipbook.play(near, "spark_metal", at, 1.4)   # MIX: the streaks keep their ink outline
	return Flipbook.play(near, "spark_hit", at, size, {"first": row * Flipbook.GRID, "count": Flipbook.GRID})   # MIX: ADD + the hit light burned the star to white, losing the ink line


func _on_move_started(f: Fighter, m: MoveData) -> void:
	var at := f.global_position + f.forward * 0.8 + Vector3.UP * CHEST
	var sword_limb := m.kind == MoveData.Kind.NORMAL and m.anim.begins_with("sword_")
	if f.data.id == "choko" and (SLASH.has(m.id) or sword_limb):
		var sheet: String = SLASH.get(m.id, "slash_air_choko" if m.anim.ends_with("aircut") else "slash_choko")
		Flipbook.play(f, sheet, at, 2.4 if m.id == "heavy" else 1.8,
			{"count": 8, "delay": float(m.startup) / 60.0, "additive": true, "flip": f.forward.x < 0.0})
	elif f.data.id == "skea" and (SLASH_SKEA.has(m.id) or (m.kind == MoveData.Kind.NORMAL and m.anim.begins_with("limb_"))):
		at.y = f.global_position.y + m.hitbox_offset.y
		Flipbook.play(f, "slash_skea", at, 2.2 if m.id == "roundhouse" or m.anim.contains("leg") else 1.6,
			{"count": 8, "delay": float(m.startup) / 60.0, "additive": true, "flip": f.forward.x < 0.0})


func _on_ko(f: Fighter) -> void:
	Flipbook.play(f, "ko_burst", f.global_position + Vector3.UP * CHEST, 4.0)


func _physics_process(_dt: float) -> void:
	_frame += 1
	for f in fighters:
		if not is_instance_valid(f):
			continue
		var p: Array = _prev[f]
		var now := _snap(f)
		_events(f, p, now)
		_prev[f] = now


func _events(f: Fighter, p: Array, now: Array) -> void:
	var pos := f.global_position
	var floor_y := f.floor_y()
	_water_steps(f, p, now)
	# a dash: Choko's Chrono Step enters DASH; Skea's Flash Step spends a charge — a push-off puff under the trail either way
	if now[0] == Fighter.State.DASH and p[0] != Fighter.State.DASH and f.data.dash_style != "flash":
		Flipbook.play(f, "trail_chrono", pos + Vector3.UP * 0.9, 2.6, {"count": 12, "additive": true, "flip": f.forward.x < 0.0})
		if GameState.water != null:
			if now[1]:
				_water_contact(f, pos, WaterBurst3D.Kind.DASH, "dash")
		else:
			Flipbook.play(f, "smoke_puff", Vector3(pos.x, floor_y + 0.3, pos.z), 1.6)
	if f.data.dash_style == "flash" and now[6] < p[6]:
		Flipbook.play(f, "trail_flash", pos + Vector3.UP * 0.9, 2.6, {"count": 12, "flip": f.forward.x < 0.0})
		if GameState.water != null:
			if now[1]:
				_water_contact(f, pos, WaterBurst3D.Kind.DASH, "dash")
		else:
			Flipbook.play(f, "smoke_puff", Vector3(pos.x, floor_y + 0.3, pos.z), 1.6)
	# a grapple shot (any of the three verbs spends a charge)
	if now[5] < p[5]:
		Flipbook.play(f, "grapple_launch", pos + GrappleHook.HAND + f.forward * 0.4, 1.2, {"count": 9, "flip": f.forward.x < 0.0})
	# a zip to an anchor: speed lines ride along with the fighter (the sheet points left → right)
	if now[0] == Fighter.State.GRAPPLE and p[0] != Fighter.State.GRAPPLE:
		var left := f.grapple.anchor_point.x < pos.x
		Flipbook.play(f, "speed_lines", Vector3.UP * 1.0, 2.2, {"parent": f, "flip": left})
	# sliding along the soft wall: low dust at the feet (the sheet's feet slide right, the trail goes left)
	if wall_slide_speed(now[10], now[11], now[1]) >= SKID_SPEED and _frame - int(_skid_at.get(f, -SKID_EVERY)) >= SKID_EVERY:
		_skid_at[f] = _frame
		var v: Vector3 = now[11]
		if GameState.water != null:
			_water_contact(f, pos, WaterBurst3D.Kind.DASH, "skid")
		else:
			Flipbook.play(f, "skid_dust", Vector3(pos.x, floor_y + 0.8, pos.z), 1.6, {"flip": v.x < 0.0})
	# a ragdoll settles (LAUNCHED → GETUP, or KNOCKDOWN without a ragdoll; the body stays on the floor while the ragdoll
	# flies, so on_ground() never flips) → dust + a crack decal
	if p[0] == Fighter.State.LAUNCHED and now[0] in [Fighter.State.GETUP, Fighter.State.KNOCKDOWN]:
		if GameState.water != null:
			_water_contact(f, pos, WaterBurst3D.Kind.HEAVY, "land")
		else:
			Flipbook.play(f, "dust_land", Vector3(pos.x, floor_y + 0.9, pos.z), 2.6)
			Flipbook.play(f, "ground_crack", Vector3(pos.x, floor_y + 0.03, pos.z), 2.4, {"mode": Flipbook.Mode.FLOOR})
	# landing from a jump → dust (a splash on the river)
	elif now[1] and not p[1] and p[0] != Fighter.State.LAUNCHED:
		if GameState.water != null:
			var incoming: Vector3 = p[11]
			_water_contact(f, pos, water_landing_kind(incoming.y), "land")
		else:
			Flipbook.play(f, "dust_land", Vector3(pos.x, floor_y + 0.6, pos.z), 1.8)
	# SHADOW VEIL rises
	if now[2] > 0 and p[2] == 0:
		Flipbook.play(f, "smoke_veil", pos + Vector3.UP * 1.3, 3.2)
	# armor break lands on this fighter
	if now[3] > 0 and p[3] == 0:
		Flipbook.play(f, "armor_break", pos + Vector3.UP * CHEST, 2.2, {"additive": true})
	# «Seen»: the eye over the head for as long as it lasts (refreshes keep the same mark)
	if now[7] > 0:
		var mark: Flipbook = _seen.get(f, null)
		if mark == null or not is_instance_valid(mark):
			mark = Flipbook.play(f, "seen_mark", pos + Vector3.UP * 2.3, 0.6, {"loop": true})
			_seen[f] = mark
		if mark != null:
			mark.global_position = pos + Vector3.UP * 2.3
	elif _seen.has(f):
		var old: Flipbook = _seen[f]
		if old != null and is_instance_valid(old):
			old.queue_free()
		_seen.erase(f)
	# Spring spent: the counter drops to 0 at once (not by running out) in the air, outside a hit
	if p[8] > 1 and now[8] == 0 and not now[1] and now[0] != Fighter.State.HITSTUN and now[0] != Fighter.State.LAUNCHED:
		Flipbook.play(f, "spring_jump", Vector3(pos.x, pos.y + 0.2, pos.z), 1.4)
	# RECORD rewind: the marker is gone and the body jumped back to it this frame
	if p[9] and not now[9] and (now[10] as Vector3).distance_to(p[10]) > 0.3:
		Flipbook.play(f, "choko_rewind", pos + Vector3.UP * 1.0, 2.4, {"additive": true})
	# TIME STOP froze this fighter: the dial cracks on the ground under the one who stopped time
	if now[4] > 0 and p[4] == 0 and f.opponent != null:
		var o := f.opponent.global_position
		Flipbook.play(f, "choko_timestop", Vector3(o.x, f.opponent.floor_y() + 0.04, o.z), 7.0, {"mode": Flipbook.Mode.FLOOR, "additive": true})


## Classify visual landings only; never alter jump/fall/combat data.
static func water_landing_kind(incoming_y: float) -> int:
	var speed := maxf(0.0, -incoming_y)
	if speed >= WATER_HEAVY_SPEED:
		return WaterBurst3D.Kind.HEAVY
	return WaterBurst3D.Kind.MEDIUM if speed >= WATER_MEDIUM_SPEED else WaterBurst3D.Kind.LIGHT


func _water_contact(f: Fighter, at: Vector3, kind: int, sound_event: String) -> void:
	if not Fx.enabled or f.frozen_frames > 0 or f.hitstop_frames > 0:
		return
	var slot := fighters.find(f)
	WaterBurst3D.play(f, at, f.velocity, kind, _frame * 31 + slot * 997 + kind * 13)
	Sfx.play_surface_water(sound_event, slot)
	if kind >= WaterBurst3D.Kind.MEDIUM:
		var heavy := kind == WaterBurst3D.Kind.HEAVY
		var surface := GameState.water.height(at.x, at.z)
		Flipbook.play(f, "water_splash", Vector3(at.x, surface + 0.65, at.z), 2.3 if heavy else 1.8, {"count": 8})


func _water_steps(f: Fighter, p: Array, now: Array) -> void:
	if GameState.water == null or not Fx.enabled or f.frozen_frames > 0 or f.hitstop_frames > 0 or not now[1] or not p[1] or now[0] != Fighter.State.WALK:
		_step_distance[f] = 0.0
		return
	var delta: Vector3 = now[10] - p[10]
	delta.y = 0.0
	# Teleports/rewinds cannot leave a chain of step splashes.
	if delta.length() > WATER_STRIDE:
		_step_distance[f] = 0.0
		return
	var distance := float(_step_distance.get(f, 0.0)) + delta.length()
	if distance >= WATER_STRIDE:
		distance = fmod(distance, WATER_STRIDE)
		var side := -float(_step_side.get(f, -1.0))
		_step_side[f] = side
		var at := f.global_position + Vector3(-f.forward.z, 0.0, f.forward.x) * side * 0.16
		_water_contact(f, at, WaterBurst3D.Kind.STEP, "step")
	_step_distance[f] = distance
