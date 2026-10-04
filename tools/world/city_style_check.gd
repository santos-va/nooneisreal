extends SceneTree
## Native renderer probe: world-scale density, ambient isolation and distant-detail filtering.
## Run with DISPLAY and --rendering-method gl_compatibility; headless cannot supply pixel evidence.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CITY_STYLE: " + label)

func shot() -> Image:
	for frame: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func difference(a: Image, b: Image) -> float:
	var sum: float = 0.0
	var count: int = 0
	for y: int in range(8, a.get_height() - 8, 4):
		for x: int in range(8, a.get_width() - 8, 4):
			var left := a.get_pixel(x, y)
			var right := b.get_pixel(x, y)
			sum += absf(left.r - right.r) + absf(left.g - right.g) + absf(left.b - right.b)
			count += 3
	return sum / maxf(count, 1)

func edge_energy(image: Image) -> float:
	var sum: float = 0.0
	var count: int = 0
	for y: int in range(8, image.get_height() - 8, 3):
		for x: int in range(8, image.get_width() - 9, 3):
			var left := image.get_pixel(x, y)
			var right := image.get_pixel(x + 1, y)
			sum += absf(left.get_luminance() - right.get_luminance())
			count += 1
	return sum / maxf(count, 1)

func _run() -> void:
	await process_frame
	if DisplayServer.get_name() == "headless":
		push_error("CITY_STYLE requires an actual renderer; headless pixel verification unavailable")
		quit(2)
		return
	root.size = Vector2i(640, 360)
	var stage := Node3D.new()
	root.add_child(stage)
	var palette: Dictionary = load("res://scripts/world/CityMaterials.gd").palette()
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(12, 8)
	plane.mesh = mesh
	plane.material_override = palette.paving
	stage.add_child(plane)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.0
	environment_node.environment = environment
	stage.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-44, -28, 0)
	sun.light_energy = 0.95
	sun.light_color = Color(1.0, 0.97, 0.94)
	stage.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.0
	camera.position = Vector3(0, 8, 0)
	camera.rotation_degrees.x = -90
	stage.add_child(camera)
	camera.make_current()
	var near := await shot()
	check(not near.is_empty(), "renderer produced real pixels")
	var near_edges := edge_energy(near)
	check(near_edges > 0.0001, "near paving retains readable joints")
	# The same visible world coordinates survive a different physical mesh extent.
	mesh.size = Vector2(24, 16)
	var larger_mesh := await shot()
	check(difference(near, larger_mesh) < 0.002, "doubling mesh extent preserves material density in metres")
	environment.ambient_light_energy = 8.0
	var ambient := await shot()
	check(difference(larger_mesh, ambient) < 0.002, "strong global ambient cannot wash out city surfaces")
	mesh.size = Vector2(120, 80)
	camera.size = 60.0
	var far := await shot()
	var far_edges := edge_energy(far)
	check(far_edges < near_edges * 0.25, "distant detail fades instead of forming pixel shimmer")
	camera.size = 6.0
	var peak: float = 0.0
	for key: String in palette:
		plane.material_override = palette[key]
		var swatch := await shot()
		var center := swatch.get_pixel(320, 180)
		var brightest := maxf(center.r, maxf(center.g, center.b))
		peak = maxf(peak, brightest)
		check(brightest < 0.94, "%s retains painted colour rather than clipping white" % key)
	print("CITY_STYLE_METRICS near_edges=%f far_edges=%f palette_peak=%f" % [near_edges, far_edges, peak])
	stage.queue_free()
	await process_frame
	for singleton: String in ["Sfx", "UltMusic"]:
		root.get_node(singleton).queue_free()
	var until: int = Time.get_ticks_msec() + 200
	while Time.get_ticks_msec() < until:
		await process_frame
		OS.delay_msec(1)
	print("CITY_STYLE_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
