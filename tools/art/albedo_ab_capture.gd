extends SceneTree
## Albedo A/B capture — docs/Plans/2026-10-14-T6-Acceptance-Crane-Albedo-AB.md step 5, and variant B3 (Santos
## 2026-10-15 «Зняти Б3», docs/Fix/2026-10-15-Albedo-B3-Fix.md). A tool, not a fixture.
## The product is never written: no resource is saved, game/ stays byte-identical.
##
## What it swaps (in memory, for this process only): the code of the five shaders whose light() puts ALBEDO into
## DIFFUSE_LIGHT (city_surface, toon, sword_dissolve, gear_surface, hero_garment). Variant B1 = the same source with
## every ALBEDO token inside light() replaced by vec3(1.0), so DIFFUSE_LIGHT carries only light and shadow and the
## engine's own post-light() multiply by albedo is the only one left (docs/Research/2026-10-14-Godot-Diffuse-Albedo.md).
## Variant B3 = B1 plus the light strengths re-calibrated in the same shaders (B3_EDITS: exact substitutions on the B1
## source, each must match exactly once), numbers from tools/art/albedo_b3_calibrate.py (Forward+ formula, PLACEHOLDER).
## The swap edits the cached Shader resource, so every material that preloads the file switches at once; the run
## refuses (rc 1) if a shader's light() has no ALBEDO, still has one after the swap, or a material in the world holds
## another Shader instance with the same path (it would silently stay on A).
##
## Per station, with the scene tree paused (same pose, camera, sun and shadow map in every pass):
##   <id>_<hero>_A.png    product as is
##   <id>_<hero>_B1.png   B1 code (reference)
##   <id>_<hero>_B3.png   B3 code
##   <id>_<hero>_label.png every city surface flat-coloured by its CityMaterials key, hero surfaces by shader,
##                         everything else and the sky black (unshaded: an ID pass for the measurement)
##   <id>_<hero>_lit.png  white where the sun band of city_surface is lit — step(0.20, N·L) · step(0.5, ATTENUATION),
##                         city_surface.gdshader:118 — black where it is shadow (same test for hero surfaces)
##   <id>_<hero>_A2.png   A again after restoring: A2 == A proves the swap and the passes are reversible
## plus DIR/receipt.json (renderer, swap counts, materials per shader, label colours, camera of each station).
## Numbers and side-by-side sheets: tools/art/albedo_ab_table.py.
##
## Native only (pixels): tools/art/albedo_ab_capture.sh DIR [-- args], i.e. xvfb + --rendering-method
## gl_compatibility. Godot 4.7 Compatibility differs from Forward+ in colour space (uniforms raw sRGB, EMISSION read
## as sRGB, shadow_tint raw in light()), so frame numbers are "Compatibility / llvmpipe", never "M3".
##   -- --out=/abs/dir [--hero=choko|skea] [--stations=pump,benches,market,plaster,truck,car,hero]
##      [--dump-shaders]   write DIR/shaders/<name>.A.gdshader, .B1.gdshader and .B3.gdshader and quit (for diff -u)
##      [--only-sun]       diagnostic: hide every non-directional Light3D of the world for the whole run, so frame
##                         numbers can be held against the one-sun formula (product frames are without this flag).
##                         city_surface light() multiplies LIGHT_COLOR without ATTENUATION, and Compatibility hands an
##                         omni light's colour over unattenuated (gles3 scene.glsl light_process_omni), so a shop lamp
##                         lights whole meshes it touches; the flag measures how much of a frame that is.
##      [--break=nolight|foreign|stuck|leak|b3drift|stuck3]  negative controls of the run's own integrity (each must fail):
##                         nolight — city_surface without light(): the swap finds no ALBEDO → rc 1;
##                         foreign — one city surface on Shader.duplicate() (no resource_path): the census → rc 1;
##                         stuck — city_surface B1 = A code: albedo_ab_table.py reports city pixels unchanged → rc 1;
##                         leak — the largest city geometry is not restored after the ID pass: A2 != A → rc 1;
##                         b3drift — city_surface's source no longer holds a line a B3 edit replaces: the edit
##                                   matches 0 times → rc 1;
##                         stuck3 — city_surface B3 = B1 code (the re-calibration never reaches the city):
##                                  albedo_ab_table.py reports city pixels unchanged B1 → B3 → rc 1.
## Integrity (each station): frames B1 and B3 must differ from A and from each other, frame A2 must equal A byte for
## byte; else rc 1.
## In "close" mode the world's Label3D nodes outside the hero (resident chatter) are hidden for the shot and restored.

const AB_SHADERS: PackedStringArray = [
	"res://shaders/city_surface.gdshader",
	"res://shaders/toon.gdshader",
	"res://shaders/sword_dissolve.gdshader",
	"res://shaders/gear_surface.gdshader",
	"res://shaders/hero_garment.gdshader",
]
const CITY_SHADER_PATH: String = "res://shaders/city_surface.gdshader"
const LIT_DOT: float = 0.20 # city_surface.gdshader:118
const LIT_ATTENUATION: float = 0.5 # city_surface.gdshader:118

## B3 numbers: `python3 -I tools/art/albedo_b3_calibrate.py` (Forward+ formula, median dE76 over the district's 19
## palette keys; lit → the palette hex, shadow → hex × #B07AA6 of the style guide). PLACEHOLDER, artistic.
## albedo_ab_table.py recomputes them and fails (rc 1) when the receipt carries other numbers.
const B3: Dictionary = {
	"painted_fill": 0.028, "key_gain": 1.053, "shadow_base": 0.0, "shadow_share": 1.0, # city_surface (district)
	"hero_gain": 0.914, # toon, sword_dissolve, hero_garment, gear_surface: each DIFFUSE_LIGHT line × hero_gain / PI
	"toon_shadow_strength": 1.0, "sword_shadow_strength": 0.945, "garment_shadow_strength": 0.895, # of the 0.45 default
	"cloth_share": 0.355, # hero_garment cloth and gear_surface: vec3(0.69,0.48,0.65) × 0.75 → × cloth_share
}
## city_surface's own defaults the B3 scales refer to (city_surface.gdshader:17-18): materials that set their own
## painted_fill / key_gain (CityInteriors.gd:21-22, CityBackdrop.gd:27-28) keep their ratio to the district.
const CITY_FILL: float = 0.16
const CITY_GAIN: float = 2.2
const SHADOW_STRENGTH: float = 0.45 # toon / sword_dissolve / hero_garment default (toon.gdshader:11)


## B3 = these exact substitutions on the B1 source (B1 has already turned light()'s ALBEDO into vec3(1.0)).
static func b3_edits() -> Dictionary:
	var hero_gain: String = " * %.3f / PI;" % float(B3.hero_gain)
	var fill: String = "painted_fill * (%.3f / %.2f)" % [float(B3.painted_fill), CITY_FILL]
	var gain: String = "key_gain * (%.3f / %.2f)" % [float(B3.key_gain), CITY_GAIN]
	var cloth: String = "vec3(0.69,0.48,0.65) * %.3f" % float(B3.cloth_share)
	var strength := func(key: String) -> String:
		return "float k = mix(1.0 - clamp(shadow_strength * (%.3f / %.2f), 0.0, 1.0), 1.0, a);" % [float(B3[key]), SHADOW_STRENGTH]
	var rim_old: String = "DIFFUSE_LIGHT += vec3(1.0) * rim * rim_strength * LIGHT_COLOR * ATTENUATION * step(0.0, ndl);"
	var rim_new: String = rim_old.trim_suffix(";") + hero_gain
	var toon_like := func(key: String) -> Array:
		return [
			["float k = mix(1.0 - shadow_strength, 1.0, a);", strength.call(key)],
			["DIFFUSE_LIGHT += shade * LIGHT_COLOR * ATTENUATION;", "DIFFUSE_LIGHT += shade * LIGHT_COLOR * ATTENUATION" + hero_gain],
			[rim_old, rim_new],
		]
	var garment: Array = toon_like.call("garment_shadow_strength")
	garment.append(["mix(vec3(1.0) * vec3(0.69,0.48,0.65) * 0.75, vec3(1.0),", "mix(vec3(1.0) * " + cloth + ", vec3(1.0),"])
	return {
		"res://shaders/city_surface.gdshader": [
			["EMISSION = paint * (painted_fill + glow);", "EMISSION = paint * (" + fill + " + glow);"],
			["vec3 shaded = vec3(1.0) * mix(vec3(0.50), shadow_tint.rgb, 0.35);",
				"vec3 shaded = vec3(1.0) * mix(vec3(%.3f), shadow_tint.rgb, %.3f);" % [float(B3.shadow_base), float(B3.shadow_share)]],
			["DIFFUSE_LIGHT += mix(shaded, vec3(1.0), lit) * LIGHT_COLOR * key_gain / PI;",
				"DIFFUSE_LIGHT += mix(shaded, vec3(1.0), lit) * LIGHT_COLOR * " + gain + " / PI;"],
		],
		"res://shaders/toon.gdshader": toon_like.call("toon_shadow_strength"),
		"res://shaders/sword_dissolve.gdshader": toon_like.call("sword_shadow_strength"),
		"res://shaders/hero_garment.gdshader": garment,
		"res://shaders/gear_surface.gdshader": [
			["vec3 shadow = vec3(1.0) * vec3(0.69,0.48,0.65) * 0.75;", "vec3 shadow = vec3(1.0) * " + cloth + ";"],
			["DIFFUSE_LIGHT += (shaded + vec3(1.0) * edge * rim * step(0.0,ndl)) * LIGHT_COLOR * ATTENUATION;",
				"DIFFUSE_LIGHT += (shaded + vec3(1.0) * edge * rim * step(0.0,ndl)) * LIGHT_COLOR * ATTENUATION" + hero_gain],
		],
	}

## Stations. "play" = the real CityCamera behind the hero (placement as in T6's acceptance script,
## scratchpad t6-accept/accept_frames.gd); "eye" = fixed audit camera (fov 65 like CityCamera);
## "close" = hero close-up, camera at hero + view·distance, looking at the chest.
const STATIONS: Array[Dictionary] = [
	# Street with the pump (painted iron, paving, market fronts): T6 ir1_pump.
	{"id": "pump", "sheet": "street", "mode": "play", "hero": Vector3(-2.2, 0, 14.0), "face": Vector3(0, 0, 1)},
	# Shop row with the benches and urns: T6 ir3_benches_urns.
	{"id": "benches", "sheet": "street", "mode": "play", "hero": Vector3(-14.0, 0, 3.8), "face": Vector3(-0.3, 0, 1)},
	# Market, west stalls: T2 city-tidy station 02_market_west_stalls (scratchpad city-tidy/frames_capture.gd).
	{"id": "market", "sheet": "market", "mode": "eye", "eye": Vector3(-2.5, 1.6, 21.5), "target": Vector3(-8.5, 1.4, 21.5),
		"hero": Vector3(-1.5, 0, 14.0), "face": Vector3(0, 0, 1)},
	# Plaster facade: SouthEastEastWing (CityLayout.gd:100, plaster, x 22..30, z 12..30) — its west face is in sun,
	# its north face in shadow; the passage lintel (CityLayout.gd:101) is plaster too.
	{"id": "plaster", "sheet": "plaster", "mode": "eye", "eye": Vector3(14.5, 1.7, 5.0), "target": Vector3(22.0, 4.0, 14.0),
		"hero": Vector3(12.0, 0, 2.0), "face": Vector3(0, 0, 1)},
	# Steam vehicles at V2 (CityProps.VEHICLES): T6 ve1_truck_east and ve3_car_west.
	{"id": "truck", "sheet": "vehicles", "mode": "play", "hero": Vector3(25.5, 0, -2.5), "face": Vector3(-1, 0, 0)},
	{"id": "car", "sheet": "vehicles", "mode": "play", "hero": Vector3(10.5, 0, 1.5), "face": Vector3(1, 0, 0)},
	# Hero close-up in open sun: toon / hero_garment / gear / sword. Camera from the south-east, the sun from the
	# south-west (CityWorld.gd sun rotation (-44, -28, 0)): the front is lit, the east side in shadow.
	{"id": "hero", "sheet": "hero", "mode": "close", "hero": Vector3(2.0, 0, 8.0), "view": Vector3(0.55, 0, 1.0),
		"distance": 2.3, "fov": 40.0},
]

const LABEL_SHADER_CODE: String = """shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 label_color : source_color = vec4(1.0);
void fragment() {
	ALBEDO = label_color.rgb;
}
"""
const LIT_SHADER_CODE: String = """shader_type spatial;
render_mode cull_back, specular_disabled, ambient_light_disabled;
void fragment() {
	ALBEDO = vec3(1.0);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		DIFFUSE_LIGHT += vec3(step(%s, dot(NORMAL, LIGHT)) * step(%s, ATTENUATION)) * 4.0;
	}
}
"""

var out_dir: String = ""
var hero_name: String = "choko"
var wanted: PackedStringArray = PackedStringArray()
var dump_only: bool = false
var only_sun: bool = false
var break_mode: String = ""
var world: Node3D
var eye: Camera3D
var originals: Dictionary = {}  # path -> String (A code)
var variants: Dictionary = {}   # path -> String (B1 code)
var variants_b3: Dictionary = {} # path -> String (B3 code)
var b3_counts: Dictionary = {}   # path -> [matches of each B3 edit]
var swap_counts: Dictionary = {} # path -> int (ALBEDO tokens replaced in light())
var palette_keys: Dictionary = {} # "rrggbb" -> CityMaterials key
var district: Dictionary = {} # CityMaterials key -> [painted_fill, key_gain, glow] of CityMaterials.palette()
var city_params: Dictionary = {} # city label -> {"key", "hex", "fill", "gain", "glow"}
const CITY_PARAMS: PackedStringArray = ["painted_fill", "key_gain", "glow"]
var label_names: PackedStringArray = PackedStringArray()
var label_colors: Dictionary = {} # name -> Color
var label_materials: Dictionary = {} # name -> ShaderMaterial
var black: ShaderMaterial
var lit_material: ShaderMaterial
var failures: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
		elif argument.begins_with("--hero="):
			hero_name = argument.trim_prefix("--hero=")
		elif argument.begins_with("--stations="):
			wanted = argument.trim_prefix("--stations=").split(",", false)
		elif argument == "--dump-shaders":
			dump_only = true
		elif argument == "--only-sun":
			only_sun = true
		elif argument.begins_with("--break="):
			break_mode = argument.trim_prefix("--break=")
	_run.call_deferred()


func _fail(message: String) -> void:
	failures += 1
	push_error("ALBEDO_AB: " + message)


func _ticks(count: int) -> void:
	for tick: int in count:
		await physics_frame
		await process_frame


func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame


## B1 source: every ALBEDO token inside the body of light() becomes vec3(1.0). Returns {"code", "replaced", "left"}.
static func b1_source(code: String) -> Dictionary:
	var head: int = code.find("void light()")
	if head < 0:
		return {"code": code, "replaced": 0, "left": -1}
	var open: int = code.find("{", head)
	var depth: int = 0
	var close: int = -1
	for index: int in range(open, code.length()):
		var character: String = code[index]
		if character == "{":
			depth += 1
		elif character == "}":
			depth -= 1
			if depth == 0:
				close = index
				break
	if open < 0 or close < 0:
		return {"code": code, "replaced": 0, "left": -1}
	var token := RegEx.create_from_string("\\bALBEDO\\b")
	var body: String = code.substr(open, close - open + 1)
	var replaced: int = token.search_all(body).size()
	var new_body: String = token.sub(body, "vec3(1.0)", true)
	var left: int = token.search_all(new_body).size()
	return {"code": code.substr(0, open) + new_body + code.substr(close + 1), "replaced": replaced, "left": left}


func _prepare_variants() -> void:
	for path: String in AB_SHADERS:
		var shader: Shader = load(path) as Shader
		if shader == null or shader.code.is_empty():
			_fail("cannot read %s" % path)
			continue
		originals[path] = shader.code
		if break_mode == "nolight" and path == CITY_SHADER_PATH:
			originals[path] = shader.code.replace("void light()", "void light_off()")
		var result: Dictionary = b1_source(String(originals[path]))
		swap_counts[path] = int(result.replaced)
		variants[path] = String(result.code)
		if break_mode == "nolight" and path == CITY_SHADER_PATH:
			originals[path] = shader.code # never render the renamed source
		if break_mode == "stuck" and path == CITY_SHADER_PATH:
			variants[path] = shader.code
		if int(result.replaced) < 1 or int(result.left) != 0:
			_fail("%s light(): replaced=%d left=%d (want >=1 and 0)" % [path, int(result.replaced), int(result.left)])
		print("ALBEDO_AB_SWAP %s albedo_tokens_in_light=%d left_after=%d" % [path.get_file(), int(result.replaced), int(result.left)])
		# B3: the B1 source with every edit of b3_edits() applied, each matching exactly once.
		var b3: String = String(result.code)
		if break_mode == "b3drift" and path == CITY_SHADER_PATH:
			b3 = b3.replace("painted_fill + glow", "glow + painted_fill") # the same sum, but no longer the edited line
		var counts: Array[int] = []
		for edit: Array in b3_edits().get(path, []):
			var found: int = b3.count(String(edit[0]))
			counts.append(found)
			if found != 1:
				_fail("%s B3 edit matches %d times (want 1): %s" % [path, found, String(edit[0])])
			b3 = b3.replace(String(edit[0]), String(edit[1]))
		if counts.is_empty():
			_fail("%s has no B3 edits" % path)
		b3_counts[path.get_file()] = counts
		variants_b3[path] = b3
		if break_mode == "stuck3" and path == CITY_SHADER_PATH:
			variants_b3[path] = String(variants[path])
		print("ALBEDO_AB_B3 %s edits=%s" % [path.get_file(), str(counts)])


func _apply(variant: String) -> void:
	for path: String in AB_SHADERS:
		var shader: Shader = load(path) as Shader
		match variant:
			"A":
				shader.code = String(originals[path])
			"B1":
				shader.code = String(variants[path])
			"B3":
				shader.code = String(variants_b3[path])
			_:
				_fail("unknown variant " + variant)


func _dump_shaders() -> void:
	var dir: String = out_dir.path_join("shaders")
	DirAccess.make_dir_recursive_absolute(dir)
	for path: String in AB_SHADERS:
		var stem: String = path.get_file().get_basename()
		for variant: String in ["A", "B1", "B3"]:
			var file := FileAccess.open(dir.path_join("%s.%s.gdshader" % [stem, variant]), FileAccess.WRITE)
			var source: Dictionary = {"A": originals, "B1": variants, "B3": variants_b3}[variant]
			file.store_string(String(source[path]))
			file.close()
	print("ALBEDO_AB_DUMP dir=%s shaders=%d" % [dir, AB_SHADERS.size()])


## A city material's uniform, falling back to the shader's own default (palette() leaves most of them unset).
func _param(material: ShaderMaterial, uniform: String) -> float:
	var value: Variant = material.get_shader_parameter(uniform)
	if value == null:
		value = RenderingServer.shader_get_parameter_default(material.shader.get_rid(), uniform)
	if value == null:
		var found: RegExMatch = RegEx.create_from_string("uniform float " + uniform + "[^=;]*=\\s*([0-9.]+)").search(material.shader.code)
		value = float(found.get_string(1)) if found != null else -1.0
	return float(value)


## City label = palette key by albedo; a material whose painted_fill / key_gain / glow differ from that key in
## CityMaterials.palette() (CityInteriors.gd:14-17 gives its whole copy fill 0.28 and gain 1.65) is its own variant,
## so one label never mixes two lighting formulas.
func _city_label(material: ShaderMaterial) -> String:
	var albedo: Variant = material.get_shader_parameter("albedo")
	var hex: String = (albedo as Color).to_html(false) if albedo is Color else ""
	if not palette_keys.has(hex):
		return "city:other"
	var key: String = palette_keys[hex]
	var values: Array[float] = []
	for uniform: String in CITY_PARAMS:
		values.append(snappedf(_param(material, uniform), 0.0001))
	var name: String = "city:" + key
	if values != district[key]:
		name += "@f%.2fk%.2fg%.2f" % [values[0], values[1], values[2]]
	if not city_params.has(name):
		city_params[name] = {"key": key, "hex": hex, "fill": values[0], "gain": values[1], "glow": values[2]}
	return name


func _setup_labels() -> void:
	var palette: Dictionary = CityMaterials.palette()
	var keys: Array = palette.keys()
	keys.sort()
	for key: String in keys:
		var material: ShaderMaterial = palette[key]
		palette_keys[(material.get_shader_parameter("albedo") as Color).to_html(false)] = key
		var values: Array[float] = []
		for uniform: String in CITY_PARAMS:
			values.append(snappedf(_param(material, uniform), 0.0001))
		district[key] = values
	for key: String in keys:
		_city_label(palette[key])
	# Every city variant present in the world gets its own label.
	for node: Node in world.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: Material = mesh_instance.get_active_material(surface)
			if material is ShaderMaterial and (material as ShaderMaterial).shader != null \
					and (material as ShaderMaterial).shader.resource_path == CITY_SHADER_PATH:
				_city_label(material as ShaderMaterial)
	var city_names: Array = city_params.keys()
	city_names.sort()
	for name: String in city_names:
		label_names.append(name)
	label_names.append("city:other")
	for owner: String in ["hero", "other"]:
		for path: String in AB_SHADERS:
			if path != CITY_SHADER_PATH:
				label_names.append("%s:%s" % [owner, path.get_file().get_basename()])
	label_names.append("hero:other")
	# A 4x4x4 grid of sRGB levels 48 / 112 / 176 / 240: >= 64 levels apart per channel, never near black.
	var levels: Array[int] = [48, 112, 176, 240]
	var grid: Array[Color] = []
	for r: int in levels:
		for g: int in levels:
			for b: int in levels:
				grid.append(Color(r / 255.0, g / 255.0, b / 255.0))
	if label_names.size() > grid.size():
		_fail("%d labels > %d label colours" % [label_names.size(), grid.size()])
	var label_shader := Shader.new()
	label_shader.code = LABEL_SHADER_CODE
	for index: int in mini(label_names.size(), grid.size()):
		var color: Color = grid[(index * 7 + 5) % grid.size()]
		label_colors[label_names[index]] = color
		var material := ShaderMaterial.new()
		material.shader = label_shader
		material.set_shader_parameter("label_color", color)
		label_materials[label_names[index]] = material
	black = ShaderMaterial.new()
	black.shader = label_shader
	black.set_shader_parameter("label_color", Color(0, 0, 0))
	var lit_shader := Shader.new()
	lit_shader.code = LIT_SHADER_CODE % [str(LIT_DOT), str(LIT_ATTENUATION)]
	lit_material = ShaderMaterial.new()
	lit_material.shader = lit_shader


func _classify(material: Material, hero: bool) -> String:
	if material is ShaderMaterial:
		var shader: Shader = (material as ShaderMaterial).shader
		if shader != null and shader.resource_path == CITY_SHADER_PATH:
			var name: String = _city_label(material as ShaderMaterial)
			return name if label_materials.has(name) else "city:other"
		if shader != null and AB_SHADERS.has(shader.resource_path):
			return "%s:%s" % ["hero" if hero else "other", shader.resource_path.get_file().get_basename()]
	return "hero:other" if hero else ""


## Census of every material the world draws with: surface slots or the override, the overlay and every next_pass.
## A shader that is one of the five cached instances is counted. Any other shader whose light() still puts ALBEDO
## into the light — a Shader.duplicate() (it loses resource_path), an embedded copy, a file missing from AB_SHADERS —
## would stay on A in the B1 frame, so it is a failure. Runs at start and again at every station (camera-local
## material copies appear while the camera moves).
func _census(tag: String) -> Dictionary:
	var cached: Dictionary = {}
	for path: String in AB_SHADERS:
		cached[load(path)] = path.get_file()
	var counts: Dictionary = {}
	for path: String in AB_SHADERS:
		counts[path.get_file()] = 0
	var foreign: PackedStringArray = PackedStringArray()
	var light_albedo: Dictionary = {} # Shader -> ALBEDO tokens in its light()
	for node: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		var materials: Array[Material] = [geometry.material_overlay]
		var mesh_instance := geometry as MeshInstance3D
		if geometry.material_override != null or mesh_instance == null or mesh_instance.mesh == null:
			materials.append(geometry.material_override)
		else:
			for surface: int in mesh_instance.mesh.get_surface_count():
				materials.append(mesh_instance.get_active_material(surface))
		for first: Material in materials:
			var material: Material = first
			while material != null:
				var shader: Shader = (material as ShaderMaterial).shader if material is ShaderMaterial else null
				if shader != null:
					if cached.has(shader):
						counts[cached[shader]] = int(counts[cached[shader]]) + 1
					else:
						if not light_albedo.has(shader):
							light_albedo[shader] = int(b1_source(shader.code).replaced)
						if int(light_albedo[shader]) > 0:
							foreign.append("%s (%s)" % [world.get_path_to(geometry), shader.resource_path if not shader.resource_path.is_empty() else "no path"])
				material = material.next_pass
	if not foreign.is_empty():
		_fail("%s: %d slots draw with a shader whose light() has ALBEDO but is not one of the swapped five (would stay A): %s" % [tag, foreign.size(), ", ".join(foreign.slice(0, 3))])
	return {"slots": counts, "foreign": foreign.size()}


## Replace every visible geometry's material for one measurement pass; returns what to restore, exactly.
func _override_pass(kind: String) -> Array:
	var restore: Array = []
	for node: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		if not geometry.is_visible_in_tree():
			continue
		var hero: bool = world.player.is_ancestor_of(geometry)
		restore.append([geometry, -2, geometry.material_overlay])
		geometry.material_overlay = null
		var mesh_instance := geometry as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null and mesh_instance.material_override == null:
			for surface: int in mesh_instance.mesh.get_surface_count():
				var name: String = _classify(mesh_instance.get_active_material(surface), hero)
				restore.append([mesh_instance, surface, mesh_instance.get_surface_override_material(surface)])
				mesh_instance.set_surface_override_material(surface, _pass_material(kind, name))
		else:
			var name: String = _classify(geometry.material_override, hero) if mesh_instance != null else ""
			restore.append([geometry, -1, geometry.material_override])
			geometry.material_override = _pass_material(kind, name)
	return restore


func _pass_material(kind: String, name: String) -> Material:
	if name.is_empty():
		return black
	return label_materials[name] if kind == "label" else lit_material


## --break=leak: drop the restore entry of the largest city-material geometry (the ground), so it is not put back.
func _leak_one(restore: Array) -> void:
	var best: int = -1
	var best_size: float = -1.0
	for index: int in restore.size():
		var saved: Variant = restore[index][2]
		if saved is ShaderMaterial and (saved as ShaderMaterial).shader == load(CITY_SHADER_PATH):
			var size: float = (restore[index][0] as GeometryInstance3D).get_aabb().size.length()
			if size > best_size:
				best = index
				best_size = size
	if best >= 0:
		print("ALBEDO_AB_BREAK leak: %s" % world.get_path_to(restore[best][0]))
		restore.remove_at(best)


func _restore(restore: Array) -> void:
	for index: int in range(restore.size() - 1, -1, -1):
		var entry: Array = restore[index]
		var geometry := entry[0] as GeometryInstance3D
		var slot: int = int(entry[1])
		if slot == -2:
			geometry.material_overlay = entry[2]
		elif slot == -1:
			geometry.material_override = entry[2]
		else:
			(geometry as MeshInstance3D).set_surface_override_material(slot, entry[2])


var last_image: Image


func _grab(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	last_image = image
	var ok: bool = image != null and image.save_png(out_dir.path_join(name + ".png")) == OK
	if not ok:
		_fail("frame %s not saved" % name)
	return ok


func _place(station: Dictionary) -> Camera3D:
	world.npc_director.process_mode = Node.PROCESS_MODE_INHERIT
	world.player.visible = true
	world.player.restart_at(station.hero)
	await _ticks(10)
	var mode: String = station.mode
	var face: Vector3 = Vector3(station.get("face", station.get("view", Vector3(0, 0, 1)))).normalized()
	world.player._set_forward(face)
	world.camera_rig.reset_view()
	world.camera_rig.aim.yaw_offset = atan2(-face.x, -face.z)
	world.camera_rig.camera.make_current()
	await _ticks(40)
	world.npc_director.process_mode = Node.PROCESS_MODE_DISABLED
	if mode == "eye":
		eye.fov = 65.0
		eye.global_position = station.eye
		eye.look_at(station.target, Vector3.UP)
		eye.make_current()
	elif mode == "close":
		var hero_at: Vector3 = world.player.global_position
		eye.fov = float(station.get("fov", 40.0))
		eye.global_position = hero_at + face * float(station.get("distance", 2.3)) + Vector3(0, 1.25, 0)
		eye.look_at(hero_at + Vector3(0, 1.0, 0), Vector3.UP)
		eye.make_current()
	await _ticks(3)
	return eye if mode != "play" else world.camera_rig.camera


func _capture(station: Dictionary, environment: Environment) -> Dictionary:
	var camera: Camera3D = await _place(station)
	var census: Dictionary = _census(String(station.id))
	var hidden_labels: Array[Label3D] = []
	if String(station.mode) == "close":
		for node: Node in world.find_children("*", "Label3D", true, false):
			var label := node as Label3D
			if label.visible and not world.player.is_ancestor_of(label):
				label.visible = false
				hidden_labels.append(label)
	paused = true
	await _frames(3)
	var name: String = "%s_%s%s" % [station.id, hero_name, "_sun" if only_sun else ""]
	var row: Dictionary = {"id": station.id, "sheet": station.sheet, "mode": station.mode, "hero": hero_name,
		"hero_position": var_to_str(world.player.global_position), "camera_position": var_to_str(camera.global_position),
		"camera_basis": var_to_str(camera.global_basis), "fov": camera.fov, "frames": {}}
	var frames: Dictionary = {}
	_apply("A")
	await _frames(4)
	var saved: bool = await _grab(name + "_A")
	frames["A"] = name + "_A.png" if saved else ""
	var image_a: Image = last_image
	_apply("B1")
	await _frames(4)
	saved = await _grab(name + "_B1")
	frames["B1"] = name + "_B1.png" if saved else ""
	if image_a != null and last_image != null and image_a.get_data() == last_image.get_data():
		_fail("%s: frame B1 is byte-identical to A (the swap did not reach the renderer)" % name)
	var image_b1: Image = last_image
	_apply("B3")
	await _frames(4)
	saved = await _grab(name + "_B3")
	frames["B3"] = name + "_B3.png" if saved else ""
	if image_a != null and last_image != null and image_a.get_data() == last_image.get_data():
		_fail("%s: frame B3 is byte-identical to A (the swap did not reach the renderer)" % name)
	if image_b1 != null and last_image != null and image_b1.get_data() == last_image.get_data():
		_fail("%s: frame B3 is byte-identical to B1 (the re-calibration did not reach the renderer)" % name)
	_apply("A")
	var background: int = environment.background_mode
	var background_color: Color = environment.background_color
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0)
	for kind: String in ["label", "lit"]:
		var restore: Array = _override_pass(kind)
		await _frames(4)
		saved = await _grab(name + "_" + kind)
		frames[kind] = name + "_%s.png" % kind if saved else ""
		if break_mode == "leak" and kind == "label":
			_leak_one(restore)
		_restore(restore)
	environment.background_mode = background
	environment.background_color = background_color
	await _frames(4)
	saved = await _grab(name + "_A2")
	frames["A2"] = name + "_A2.png" if saved else ""
	var reversible: bool = image_a != null and last_image != null and image_a.get_data() == last_image.get_data()
	if not reversible:
		_fail("%s: frame A2 differs from A (swap or measurement pass not reversible)" % name)
	row["a2_equals_a"] = reversible
	row.frames = frames
	row["hidden_labels"] = hidden_labels.size()
	row["census"] = census
	for label: Label3D in hidden_labels:
		label.visible = true
	paused = false
	print("ALBEDO_AB_STATION ", JSON.stringify(row))
	world.camera_rig.camera.make_current()
	return row


func _write_receipt(receipt: Dictionary) -> void:
	var file := FileAccess.open(out_dir.path_join("receipt_%s%s.json" % [hero_name, "_sun" if only_sun else ""]), FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	file.close()


func _run() -> void:
	if out_dir.is_empty():
		push_error("ALBEDO_AB: pass -- --out=/abs/dir")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	_prepare_variants()
	if dump_only:
		_dump_shaders()
		quit(1 if failures > 0 else 0)
		return
	if DisplayServer.get_name() == "headless":
		push_error("ALBEDO_AB: needs pixels — run natively (xvfb), not --headless")
		quit(2)
		return
	await process_frame
	root.get_node("GraphicsSettings").set_profile("high")
	var state: Node = root.get_node("GameState")
	state.p1_character = hero_name
	state.set_free_move(true)
	root.get_node("InputRouter").apply_profile("solo", false)
	world = load("res://scenes/world/CityWorld.tscn").instantiate()
	for flag: String in ["story_save_enabled", "journey_save_enabled", "lower_story_save_enabled"]:
		if flag in world:
			world.set(flag, false)
	root.add_child(world)
	current_scene = world
	world.progress.save_enabled = false
	world.npc_director.save_enabled = false
	await _ticks(30)
	world.onboarding.skip()
	if "events" in world and world.events != null and world.events.has_method("enable_for_test"):
		world.events.enable_for_test(2468)
		world.events.start_chance = 0.0
	world.hud.visible = false
	eye = Camera3D.new()
	eye.name = "AlbedoAbEye"
	eye.near = 0.05
	eye.far = 240.0
	world.add_child(eye)
	_setup_labels()
	var hidden_lights: PackedStringArray = PackedStringArray()
	if only_sun:
		for node: Node in world.find_children("*", "Light3D", true, false):
			if not node is DirectionalLight3D and (node as Light3D).visible:
				(node as Light3D).visible = false
				hidden_lights.append(str(world.get_path_to(node)))
	var environment: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	if break_mode == "foreign":
		for node: Node in world.find_children("*", "MeshInstance3D", true, false):
			var probe := node as MeshInstance3D
			var material: Material = probe.material_override
			if material is ShaderMaterial and (material as ShaderMaterial).shader == load(CITY_SHADER_PATH):
				var twin: ShaderMaterial = (material as ShaderMaterial).duplicate()
				twin.shader = (twin.shader as Shader).duplicate()
				probe.material_override = twin
				print("ALBEDO_AB_BREAK foreign: %s" % world.get_path_to(probe))
				break
	var census: Dictionary = _census("start")
	var receipt: Dictionary = {
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"godot": Engine.get_version_info().string, "window": var_to_str(DisplayServer.window_get_size()),
		"msaa_3d": root.msaa_3d, "scale_3d": root.scaling_3d_scale, "hero": hero_name,
		"swap_albedo_tokens": swap_counts, "census": census, "lit_rule": {"dot": LIT_DOT, "attenuation": LIT_ATTENUATION},
		"b3": B3, "b3_edits": b3_counts, "b3_refs": {"city_fill": CITY_FILL, "city_gain": CITY_GAIN, "shadow_strength": SHADOW_STRENGTH},
		"labels": {}, "palette": {}, "city_params": city_params, "stations": [], "only_sun": only_sun, "hidden_lights": hidden_lights, "break": break_mode}
	for name: String in label_names:
		receipt.labels[name] = (label_colors[name] as Color).to_html(false)
	for hex: String in palette_keys:
		receipt.palette[palette_keys[hex]] = hex
	print("ALBEDO_AB_INFO renderer=%s adapter=%s window=%s msaa=%d hero=%s only_sun=%s hidden_lights=%d census=%s" % [
		receipt.renderer, receipt.adapter, receipt.window, root.msaa_3d, hero_name, only_sun, hidden_lights.size(),
		JSON.stringify(census)])
	for station: Dictionary in STATIONS:
		if not wanted.is_empty() and not wanted.has(String(station.id)):
			continue
		var row: Dictionary = await _capture(station, environment)
		(receipt.stations as Array).append(row)
		_write_receipt(receipt) # after every station: a run cut short keeps what it measured
	print("ALBEDO_AB_COMPLETE stations=%d failures=%d hero=%s" % [(receipt.stations as Array).size(), failures, hero_name])
	_apply("A")
	world.queue_free()
	await _frames(3)
	for singleton: String in ["Sfx", "UltMusic", "Music"]:
		if root.has_node(singleton):
			root.get_node(singleton).queue_free()
	await _frames(3)
	quit(1 if failures > 0 else 0)
