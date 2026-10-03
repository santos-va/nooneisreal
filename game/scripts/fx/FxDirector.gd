class_name FxDirector
extends Node
## Lane B step 2: T6·B's painted sheets (game/assets/vfx/) in the fight. It only WATCHES the two fighters — their signals and,
## once per physics frame, their state — and spawns Flipbooks; it writes nothing back, so the fight is the same with it or
## without it (the smoke's duel replay runs once with Fx.enabled false and compares the hash). Sizes are PLACEHOLDER (metres).
##
## what → sheet (docs/Art/Prompts/VFX-Sheets-Prompts.md):
##   Choko's normals → slash_choko / slash_heavy_choko / slash_air_choko, from the first active frame
##   a hit → spark_hit (row: cream, crit violet, Choko emerald, blocked blue) — Arena._on_hit
##   K.O. → ko_burst · a dash → trail_chrono (Choko) / trail_flash (Skea's Flash Step) · a grapple shot → grapple_launch
##   landing from a jump → dust_land (water_splash on the river) · a ragdoll settles → dust_land + ground_crack
##   SHADOW VEIL → smoke_veil · TIME STOP → choko_timestop under Choko · armor break → armor_break

const SLASH := {"light": "slash_choko", "crouch_light": "slash_choko", "heavy": "slash_heavy_choko", "air_light": "slash_air_choko"}
const CHEST := 1.15
## spark_hit rows (sheet row 1…4): normal, crit, Choko, blocked.
const SPARK_ROW := {"normal": 0, "crit": 1, "choko": 2, "blocked": 3}

var fighters: Array[Fighter] = []
var _prev: Dictionary = {}   # fighter → [state, on_ground, veil_frames, armor_break_frames, frozen_frames, grapple charges, dash charges]


func setup(a: Fighter, b: Fighter) -> void:
	fighters = [a, b]
	for f in fighters:
		f.move_started.connect(_on_move_started)
		f.knocked_out.connect(_on_ko)
		_prev[f] = _snap(f)


static func _snap(f: Fighter) -> Array:
	return [f.state, f.on_ground(), f.veil_frames, f.armor_break_frames, f.frozen_frames, f.grapple.charges, f.dash_charges_left]


## The hit spark (Arena._on_hit calls it next to HitSpark's lines and flash).
static func hit_spark(near: Node, at: Vector3, attacker: Fighter, damage: float, blocked: bool, crit: bool) -> Flipbook:
	var row: int = SPARK_ROW.blocked if blocked else (SPARK_ROW.crit if crit else (SPARK_ROW.choko if attacker.data.id == "choko" else SPARK_ROW.normal))
	var size := 1.0 if blocked else clampf(1.3 + damage / 90.0, 1.4, 3.2) * (1.4 if crit else 1.0)
	return Flipbook.play(near, "spark_hit", at, size, {"first": row * Flipbook.GRID, "count": Flipbook.GRID})   # MIX: ADD + the hit light burned the star to white, losing the ink line


func _on_move_started(f: Fighter, m: MoveData) -> void:
	if f.data.id != "choko" or not SLASH.has(m.id):
		return
	var at := f.global_position + f.forward * 0.8 + Vector3.UP * CHEST
	Flipbook.play(f, SLASH[m.id], at, 2.4 if m.id == "heavy" else 1.8,
		{"count": 8, "delay": float(m.startup) / 60.0, "additive": true, "flip": f.forward.x < 0.0})


func _on_ko(f: Fighter) -> void:
	Flipbook.play(f, "ko_burst", f.global_position + Vector3.UP * CHEST, 4.0)


func _physics_process(_dt: float) -> void:
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
	# a dash: Choko's Chrono Step enters DASH; Skea's Flash Step spends a charge
	if now[0] == Fighter.State.DASH and p[0] != Fighter.State.DASH and f.data.dash_style != "flash":
		Flipbook.play(f, "trail_chrono", pos + Vector3.UP * 0.9, 2.6, {"count": 12, "additive": true, "flip": f.forward.x < 0.0})
	if f.data.dash_style == "flash" and now[6] < p[6]:
		Flipbook.play(f, "trail_flash", pos + Vector3.UP * 0.9, 2.6, {"count": 12, "flip": f.forward.x < 0.0})
	# a grapple shot (any of the three verbs spends a charge)
	if now[5] < p[5]:
		Flipbook.play(f, "grapple_launch", pos + GrappleHook.HAND + f.forward * 0.4, 1.2, {"count": 9, "flip": f.forward.x < 0.0})
	# a ragdoll settles (LAUNCHED → GETUP, or KNOCKDOWN without a ragdoll; the body stays on the floor while the ragdoll
	# flies, so on_ground() never flips) → dust + a crack decal
	if p[0] == Fighter.State.LAUNCHED and now[0] in [Fighter.State.GETUP, Fighter.State.KNOCKDOWN]:
		Flipbook.play(f, "dust_land", Vector3(pos.x, floor_y + 0.9, pos.z), 2.6)
		Flipbook.play(f, "ground_crack", Vector3(pos.x, floor_y + 0.03, pos.z), 2.4, {"mode": Flipbook.Mode.FLOOR})
	# landing from a jump → dust (a splash on the river)
	elif now[1] and not p[1] and p[0] != Fighter.State.LAUNCHED:
		if GameState.water != null:
			Flipbook.play(f, "water_splash", Vector3(pos.x, floor_y + 0.7, pos.z), 1.8)
		else:
			Flipbook.play(f, "dust_land", Vector3(pos.x, floor_y + 0.6, pos.z), 1.8)
	# SHADOW VEIL rises
	if now[2] > 0 and p[2] == 0:
		Flipbook.play(f, "smoke_veil", pos + Vector3.UP * 1.3, 3.2)
	# armor break lands on this fighter
	if now[3] > 0 and p[3] == 0:
		Flipbook.play(f, "armor_break", pos + Vector3.UP * CHEST, 2.2, {"additive": true})
	# TIME STOP froze this fighter: the dial cracks on the ground under the one who stopped time
	if now[4] > 0 and p[4] == 0 and f.opponent != null:
		var o := f.opponent.global_position
		Flipbook.play(f, "choko_timestop", Vector3(o.x, f.opponent.floor_y() + 0.04, o.z), 7.0, {"mode": Flipbook.Mode.FLOOR, "additive": true})
