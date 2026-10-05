// City-only matte Sketch-Cel surfaces. Coordinates and joints are measured in world metres.
// No texture samples, loops, normal maps, rim light or stochastic frame-to-frame noise.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled, ambient_light_disabled;

uniform vec4 albedo : source_color = vec4(0.6, 0.5, 0.4, 1.0);
uniform vec4 ink_color : source_color = vec4(0.169, 0.133, 0.188, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.690, 0.478, 0.651, 1.0);
// 0 solid, 1 paving/stone, 2 brick, 3 slate, 4 wood, 5 plaster, 6 cloth.
uniform int surface_kind : hint_range(0, 6) = 0;
uniform vec2 cell_metres = vec2(0.7, 0.45);
uniform float joint_metres : hint_range(0.001, 0.04) = 0.012;
uniform float ink_strength : hint_range(0.0, 1.0) = 0.34;
uniform float variation : hint_range(0.0, 0.2) = 0.05;
// Controlled painted fill and key gain keep the palette readable in Compatibility rendering.
// Artistic PLACEHOLDER values, independent of the global ambient used by hero materials.
uniform float painted_fill : hint_range(0.0, 0.4) = 0.16;
uniform float key_gain : hint_range(0.5, 3.0) = 2.2;
uniform float glow : hint_range(0.0, 0.3) = 0.0;
varying vec3 world_position;
varying vec3 world_normal;

float cell_hash(vec2 point) {
	vec3 p = fract(vec3(point.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Fade each projected frequency before the screen-axis Nyquist limit.
// World-distance fading alone misses grazing/diagonal high-frequency patterns.
float phase_visibility(float phase) {
	float pixel_phase = max(abs(dFdx(phase)), abs(dFdy(phase)));
	return 1.0 - smoothstep(PI * 0.5, PI, pixel_phase);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	// Dominant-face projection avoids stretched box UVs and keeps differently sized bays consistent.
	vec3 normal_axis = abs(normalize(world_normal));
	vec2 metres = world_position.xy;
	if (normal_axis.y > normal_axis.x && normal_axis.y > normal_axis.z) {
		metres = world_position.xz;
	} else if (normal_axis.x > normal_axis.z) {
		metres = world_position.zy;
	}
	float pixel_metres = max(fwidth(metres.x), fwidth(metres.y));
	float detail_visibility = 1.0 - smoothstep(0.018, 0.09, pixel_metres);
	vec3 paint = albedo.rgb;
	if (surface_kind >= 1 && surface_kind <= 3) {
		vec2 grid = metres / max(cell_metres, vec2(0.01));
		float row = floor(grid.y);
		grid.x += mod(row, 2.0) * 0.5;
		vec2 cell = floor(grid);
		vec2 local = fract(grid);
		// A very small fixed wobble softens ruler-perfect courses without noisy texture grain.
		float wobble = sin(metres.x * 2.1 + row * 1.7) * 0.002;
		vec2 edge_distance = min(local, 1.0 - local) * cell_metres;
		float nearest = min(edge_distance.x, edge_distance.y + wobble);
		float joint = 1.0 - smoothstep(joint_metres, joint_metres + max(pixel_metres, 0.001), nearest);
		paint *= 1.0 + (cell_hash(cell) - 0.5) * variation * 2.0 * detail_visibility;
		paint = mix(paint, ink_color.rgb, joint * ink_strength * detail_visibility);
		if (surface_kind == 1) {
			// Broad stone faces; the edge tint stays subordinate to the traversal silhouette.
			float edge_wash = 1.0 - smoothstep(0.0, 0.09, nearest);
			paint *= 1.0 - edge_wash * variation * detail_visibility;
		} else if (surface_kind == 2) {
			// Brick has a pale mortar lip, unlike the dark joints of paving.
			float mortar_lip = smoothstep(joint_metres, joint_metres + pixel_metres + 0.008, nearest);
			mortar_lip *= 1.0 - smoothstep(joint_metres + 0.008, joint_metres + pixel_metres + 0.024, nearest);
			paint = mix(paint, albedo.rgb * 1.12, mortar_lip * 0.22 * detail_visibility);
		} else {
			// Shingle overlaps darken one end of each slate, without a specular/normal-map pass.
			float overlap = 1.0 - smoothstep(0.0, 0.20, local.y);
			paint *= 1.0 - overlap * 0.16 * detail_visibility;
		}
	} else if (surface_kind == 4) {
		float across = metres.x / max(cell_metres.x, 0.01);
		float edge = min(fract(across), 1.0 - fract(across)) * cell_metres.x;
		float seam = 1.0 - smoothstep(joint_metres, joint_metres + max(pixel_metres, 0.001), edge);
		float board = floor(across);
		float along = metres.y / max(cell_metres.y, 0.01) + cell_hash(vec2(board, 0.0));
		float end_distance = min(fract(along), 1.0 - fract(along)) * cell_metres.y;
		float end_seam = 1.0 - smoothstep(joint_metres, joint_metres + max(pixel_metres, 0.001), end_distance);
		seam = max(seam, end_seam * 0.7);
		float grain_phase = across * 13.0 + sin(metres.y * 2.0 + board) * 0.8;
		float grain = sin(grain_phase) * phase_visibility(grain_phase);
		float board_tint = cell_hash(vec2(board, floor(along))) - 0.5;
		paint *= 1.0 + (grain * 0.35 + board_tint) * variation * detail_visibility;
		paint = mix(paint, ink_color.rgb, seam * ink_strength * detail_visibility);
	} else if (surface_kind == 5 || surface_kind == 6) {
		float wash = sin(metres.x * 1.3 + sin(metres.y * 0.7)) * sin(metres.y * 1.1);
		paint *= 1.0 + wash * variation;
		if (surface_kind == 6) {
			// Coarse woven threads appear only at arm's length and fade before aliasing.
			float weave_visibility = 1.0 - smoothstep(0.003, 0.014, pixel_metres);
			vec2 thread_phase = metres * 210.0;
			float diagonal_a = thread_phase.x + thread_phase.y;
			float diagonal_b = thread_phase.x - thread_phase.y;
			// cos(x)*cos(y) = (cos(x+y)+cos(x-y))/2: filter both actual frequencies.
			float weave = 0.5 * (cos(diagonal_a) * phase_visibility(diagonal_a)
				+ cos(diagonal_b) * phase_visibility(diagonal_b));
			paint *= 1.0 + weave * 0.045 * weave_visibility;
		}
	}
	ALBEDO = paint;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = paint * (painted_fill + glow);
}

void light() {
	// LIGHT_COLOR includes PI in Godot. Divide once, rather than blowing pale trim to white.
	// A single directional key gives one lit band and one lilac shadow, including cast shadows.
	float lit = step(0.20, dot(NORMAL, LIGHT)) * step(0.5, ATTENUATION);
	vec3 shaded = ALBEDO * mix(vec3(0.50), shadow_tint.rgb, 0.35);
	DIFFUSE_LIGHT += mix(shaded, ALBEDO, lit) * LIGHT_COLOR * key_gain / PI;
}
