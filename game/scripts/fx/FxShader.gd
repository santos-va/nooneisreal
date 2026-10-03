class_name FxShader
extends RefCounted
## Shader materials for presentation-only effects (sprint lane B). Nothing here decides a hit.
## Seeds come from a private RNG, never the global one, so spawning an effect cannot shift any
## randf() the fight might read (SmokeTest «lane B» stage checks this).

const INK := preload("res://shaders/fx_ink.gdshader")
const GLOW := preload("res://shaders/fx_glow.gdshader")
const SMOKE := preload("res://shaders/fx_smoke.gdshader")
const SPARK := preload("res://shaders/fx_spark.gdshader")
const CHRONO_SCREEN := preload("res://shaders/fx_chrono_screen.gdshader")

static var _rng: RandomNumberGenerator


static func rng() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	return _rng


## A torn, step-dissolving stroke. additive → glow (light), else ink (dark, alpha blend).
## rim 1.0 = fresnel ghost for afterimage capsules; tear 0 = clean edges.
static func stroke(color: Color, alpha: float, additive: bool = true, tear: float = 0.6, rim: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GLOW if additive else INK
	m.set_shader_parameter("tint", Color(color.r, color.g, color.b, 1.0))
	m.set_shader_parameter("alpha", alpha)
	m.set_shader_parameter("tear", tear)
	m.set_shader_parameter("rim", rim)
	m.set_shader_parameter("seed", rng().randf() * 100.0)
	return m


static func smoke(color: Color, alpha: float = 0.85) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SMOKE
	m.set_shader_parameter("base", Color(color.r, color.g, color.b, 1.0))
	m.set_shader_parameter("alpha", alpha)
	m.set_shader_parameter("seed", rng().randf() * 100.0)
	return m


static func spark(color: Color, points: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SPARK
	m.set_shader_parameter("tint", Color(color.r, color.g, color.b, 1.0))
	m.set_shader_parameter("points", float(points))
	m.set_shader_parameter("spin", rng().randf() * TAU)
	m.set_shader_parameter("seed", rng().randf() * 100.0)
	return m


static func chrono_screen() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CHRONO_SCREEN
	return m


## Burn a stroke/smoke material to `k` (1 whole … 0 gone). Callers pass an already stepped k.
static func fade(m: Material, k: float) -> void:
	(m as ShaderMaterial).set_shader_parameter("fade", clampf(k, 0.0, 1.0))
