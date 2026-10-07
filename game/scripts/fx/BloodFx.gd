class_name BloodFx
extends Node
## Lethal-fight blood (ADR-024 п. 4; docs/GDD/02-Combat-System.md § Кров: коли і скільки; look —
## docs/Art/2026-10-07-Blood-Visual-Language.md variant A + floor drops). It only WATCHES the fight — `hit_landed`,
## the decisive KO — and spawns flat shapes; it writes nothing back to a fighter or the match, draws from its own RNG
## and spawns nothing with Fx.enabled off or in a sparring (`flow.lethal` false). So hp, states and hitboxes are the
## same with blood or without (the blood fixture compares the fight tick by tick).
##   clean hit (incl. through Skea's ult armour and on a frozen fighter) → splash by `move.damage` level, crit +1
##     (cap 4); a grounded victim also gets 1/2/3/4 floor drops;
##   the decisive KO of the enemy → splash +1 level and a puddle under the body (three steps in 12 frames to ≈ 1.2 m);
##   block, chip, DoT, grapple pull → nothing (they never emit a clean `hit_landed`).
## ContentSettings.blood: full · muted (shade colours, shorter, no puddle) · ink (attacker-palette ink rays, no drops)
## · off (only the existing sparks). Budgets come from QualityProfile (GraphicsSettings). Every count, size and
## duration here is PLACEHOLDER (T6 review).
const SHADER := preload("res://shaders/fx_blood.gdshader")
const FILL := Color("A3243B")       # K1, Style-Guide § Колір
const SHADE := Color("711126")      # K1 × #B07AA6
const RIM := Color("2B2230")
const MUTED_FILL := Color("711126")
const MUTED_SHADE := Color("4E0819")   # #711126 × #B07AA6, the same shadow rule
## GDD 02 levels by move.damage: < 50 → 1, 50–89 → 2, ≥ 90 → 3, crit +1 (cap 4).
const LEVEL_DAMAGE := Vector2(50.0, 90.0)
const DROPS_BY_LEVEL: Array[int] = [0, 4, 6, 8, 11]    # T6: grows with damage like HitSpark (5 → 8, crit +3)
const FLOOR_BY_LEVEL: Array[int] = [0, 1, 2, 3, 4]     # GDD 02: 1/2/3/4 drops under a grounded victim
const SPLASH_SIZE := 1.0
const FLOOR_SIZE := Vector2(0.10, 0.30)                # T6: 0.1–0.3 m
const PUDDLE_STEPS: Array[float] = [0.45, 0.8, 1.2]   # T6: three steps in 12 frames to ≈ 1.2 m
const PUDDLE_STEP_FRAMES := 4
const PUDDLE_SETTLE_FRAMES := 45                       # wait for the body to land before the pool spreads
const DRY_SECONDS := 3.0                               # T6: fresh → dried in one step after ≈ 3 s
const MUTED_LIFE := 0.5
## Proximity (T6 § Proximity dither): no new blood within this of the lens, nor beside a hero faded below this.
const LENS_MIN := 1.0
const FILL_VISIBILITY_MIN := 0.5
const CHEST := Vector3(0.0, 1.15, 0.0)
const CLEAR_SECONDS := 0.5                             # blood steps out when the pocket closes (Santos Q4 open)

var fighters: Array[Fighter] = []
var flow: MatchFlow
var rng := RandomNumberGenerator.new()
var splashes: int = 0          # fixtures read the counters
var floor_items: Array[MeshInstance3D] = []
var floor_spawned: int = 0     # every floor drop ever spawned (the array itself is capped by the budget)
var puddle: MeshInstance3D = null
var ink_bursts: int = 0
var _puddle_for: Fighter = null
var _puddle_frames: int = -1
var _floor_born: Dictionary = {}   # stain → seconds alive
var _clearing: float = -1.0


func setup(a: Fighter, b: Fighter, owner_flow: MatchFlow) -> void:
	fighters = [a, b]
	flow = owner_flow
	rng.seed = 0x0B100D   # fixed: the same fight draws the same blood (presentation only)
	for f: Fighter in fighters:
		f.hit_landed.connect(_on_hit)


static func mode() -> String:
	return ContentSettings.blood_mode()


static func profile() -> QualityProfile:
	var p := QualityProfile.make(GraphicsSettings.get_profile())
	return p if p != null else QualityProfile.make("high")


## GDD 02 § Кров: level 1…4 from the move's damage and the crit.
static func level_for(damage: float, crit: bool) -> int:
	var level := 1 if damage < LEVEL_DAMAGE.x else (2 if damage < LEVEL_DAMAGE.y else 3)
	return mini(level + (1 if crit else 0), 4)


func active() -> bool:
	return Fx.enabled and flow != null and is_instance_valid(flow) and flow.lethal and _clearing < 0.0


func _on_hit(attacker: Fighter, victim: Fighter, move: MoveData, blocked: bool) -> void:
	if blocked or move == null or not active():
		return
	var at := victim.global_position + CHEST
	if not _may_spawn(victim, at):
		return
	var level := level_for(move.damage, victim.last_hit_crit)
	var decisive: bool = victim.hp <= 0.0 and int(flow.wins.get(attacker.player_index, 0)) + 1 >= GameState.rounds_to_win
	if decisive:
		level = mini(level + 1, 4)
	var m := mode()
	if m == "off":
		return
	if m == "ink":
		# Not black blood: rays and streaks in the attacker's palette (T6 § Перемикач).
		var feet := victim.global_position   # SmearShards lifts its pieces 0.3–1.9 m itself
		SmearShards.burst(Fx.root(victim), feet - attacker.forward * 0.3, feet + attacker.forward * (0.6 + 0.2 * level), [attacker.data.vfx_primary, RIM], 4 + 2 * level, 2 + level)
		ink_bursts += 1
		return
	var q := profile()
	var colours: Array = [MUTED_FILL, MUTED_SHADE, RIM] if m == "muted" else [FILL, SHADE, RIM]
	var count := maxi(1, roundi(float(DROPS_BY_LEVEL[level]) * q.blood_drops))
	BloodSplash.burst(Fx.root(victim), at, attacker.forward, count, SPLASH_SIZE * q.blood_size, colours, q.blood_rim, rng, MUTED_LIFE if m == "muted" else 1.0)
	splashes += 1
	if victim.on_ground():
		for i: int in FLOOR_BY_LEVEL[level]:
			_floor_drop(victim, colours, q)
	if decisive and m == "full" and victim.data.cpu_only:
		_puddle_for = victim
		_puddle_frames = 0


## The lens rule: nothing new right at the camera, nothing beside a hero the city camera has faded.
func _may_spawn(victim: Fighter, at: Vector3) -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_to(at) < LENS_MIN:
		return false
	return fill_visibility(victim) >= FILL_VISIBILITY_MIN


## The proximity fill of a fighter's body material (CityCameraProximity sets `camera_visibility`), 1.0 when unset.
static func fill_visibility(f: Fighter) -> float:
	for m: Variant in f.animator.materials:
		if m is ShaderMaterial:
			var v: Variant = (m as ShaderMaterial).get_shader_parameter("camera_visibility")
			if v is float:
				return float(v)
	return 1.0


func _floor_drop(victim: Fighter, colours: Array, q: QualityProfile) -> void:
	var stain := _stain(colours, rng.randf_range(FLOOR_SIZE.x, FLOOR_SIZE.y) * q.blood_size)
	var spot := victim.global_position + Vector3(rng.randf_range(-0.45, 0.45), 0.0, rng.randf_range(-0.45, 0.45))
	stain.global_position = Vector3(spot.x, victim.floor_y() + 0.012 + 0.0005 * float(floor_items.size() % 8), spot.z)
	floor_items.append(stain)
	floor_spawned += 1
	_floor_born[stain] = 0.0
	while floor_items.size() > q.blood_floor_limit:
		var oldest: MeshInstance3D = floor_items.pop_front()
		_floor_born.erase(oldest)
		if is_instance_valid(oldest):
			oldest.queue_free()


func _stain(colours: Array, size: float) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("fill", colours[0])
	m.set_shader_parameter("shade", colours[1])
	m.set_shader_parameter("rim_color", colours[2])
	m.set_shader_parameter("shape", 2)
	m.set_shader_parameter("rim", 0.05)
	m.set_shader_parameter("seed", rng.randf() * 100.0)
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var stain := Fx.mesh(q, m)
	stain.name = "BloodStain"
	Fx.root(self).add_child(stain)
	stain.rotation = Vector3(-PI / 2.0, rng.randf_range(0.0, TAU), 0.0)   # flat on the floor, like Flipbook.Mode.FLOOR
	return stain


func _process(delta: float) -> void:
	if _clearing >= 0.0:
		_clearing += delta
		var k := Fx.stepped(1.0 - _clearing / CLEAR_SECONDS)
		for item: MeshInstance3D in _all_ground():
			(item.material_override as ShaderMaterial).set_shader_parameter("fade", k)
		if _clearing >= CLEAR_SECONDS:
			_free_ground()
			queue_free()
		return
	for stain: MeshInstance3D in floor_items:
		if not is_instance_valid(stain):
			continue
		_floor_born[stain] = float(_floor_born.get(stain, 0.0)) + delta
		if float(_floor_born[stain]) >= DRY_SECONDS:
			(stain.material_override as ShaderMaterial).set_shader_parameter("dry", 1.0)


func _physics_process(_delta: float) -> void:
	if _puddle_frames < 0 or not is_instance_valid(_puddle_for):
		return
	_puddle_frames += 1
	var step := (_puddle_frames - PUDDLE_SETTLE_FRAMES) / PUDDLE_STEP_FRAMES
	if _puddle_frames < PUDDLE_SETTLE_FRAMES:
		return
	if puddle == null:
		puddle = _stain([FILL, SHADE, RIM], 1.0)
		puddle.name = "BloodPuddle"
		var at := _puddle_for.global_position
		puddle.global_position = Vector3(at.x, _puddle_for.floor_y() + 0.01, at.z)
	puddle.scale = Vector3.ONE * PUDDLE_STEPS[clampi(step, 0, PUDDLE_STEPS.size() - 1)]
	if step >= PUDDLE_STEPS.size() - 1:
		_puddle_frames = -1


## Puddle diameter right now (m), 0 when there is none (fixtures read it).
func puddle_size() -> float:
	return puddle.scale.x if is_instance_valid(puddle) else 0.0


func _all_ground() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for stain: MeshInstance3D in floor_items:
		if is_instance_valid(stain):
			out.append(stain)
	if is_instance_valid(puddle):
		out.append(puddle)
	return out


func _free_ground() -> void:
	for item: MeshInstance3D in _all_ground():
		item.queue_free()
	floor_items.clear()
	_floor_born.clear()
	puddle = null


## The pocket closed: no blood stays in the city; it steps out over CLEAR_SECONDS and this node leaves.
func clear() -> void:
	for f: Fighter in fighters:
		if is_instance_valid(f) and f.hit_landed.is_connected(_on_hit):
			f.hit_landed.disconnect(_on_hit)
	_puddle_frames = -1
	_clearing = 0.0


## RETRY FIGHT / a new match: the floor is wiped at once (blood belongs to one match).
func reset_match() -> void:
	_puddle_frames = -1
	_free_ground()
