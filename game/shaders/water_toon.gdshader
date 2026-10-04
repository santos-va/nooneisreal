// One displaced surface, shared with WaveField.height/gradient. All animation uses
// its physics clock: no wall-clock TIME, reflection buffers or transparent layers.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 amp = vec3(0.06, 0.035, 0.018);
uniform vec3 wavelength = vec3(7.5, 3.3, 1.7);
uniform vec3 speed = vec3(1.1, -0.75, 1.5);
uniform vec3 phase = vec3(0.0, 1.7, 4.1);
uniform float swell_amp = 0.0;
uniform float wave_time = 0.0;
uniform bool use_z = false;
uniform vec3 dir_deg = vec3(0.0, 35.0, -50.0);
uniform float far_r = 0.0;
uniform float far_z = -17.0;
// Muted river palette; cream foam and graphite contours are painted marks, not gloss.
uniform vec4 deep : source_color = vec4(0.18, 0.20, 0.28, 1.0);
uniform vec4 mid : source_color = vec4(0.22, 0.36, 0.39, 1.0);
uniform vec4 crest : source_color = vec4(0.35, 0.49, 0.49, 1.0);
uniform vec4 foam : source_color = vec4(0.93, 0.86, 0.74, 1.0);
uniform vec4 ink : source_color = vec4(0.169, 0.133, 0.188, 1.0);
uniform vec4 horizon : source_color = vec4(0.22, 0.30, 0.34, 1.0);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.7;
uniform float contour_strength : hint_range(0.0, 1.0) = 0.32;

varying float v_h;
varying vec3 v_world;
varying vec2 v_gradient;

vec2 wave_dir(int i) {
	if (!use_z) {
		return vec2(1.0, 0.0);
	}
	float a = radians(dir_deg[i]);
	return vec2(cos(a), sin(a));
}

// xyz = height, dh/dx, dh/dz. Same phases, projection and swell as WaveField.
vec3 wave_surface(vec2 p) {
	vec3 result = vec3(0.0);
	for (int i = 0; i < 3; i++) {
		vec2 d = wave_dir(i);
		float k = 6.28318530718 / wavelength[i];
		float angle = k * (dot(d, p) - speed[i] * wave_time) + phase[i];
		result.x += amp[i] * sin(angle);
		result.yz += d * amp[i] * k * cos(angle);
	}
	vec2 d0 = wave_dir(0);
	float k0 = 6.28318530718 / wavelength.x;
	float angle0 = k0 * (dot(d0, p) - speed.x * wave_time) + phase.x + 1.2;
	result.x += swell_amp * sin(angle0);
	result.yz += d0 * swell_amp * k0 * cos(angle0);
	return result;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 surface = wave_surface(w.xz);
	VERTEX.y += surface.x;
	NORMAL = normalize(vec3(-surface.y, 1.0, -surface.z));
	v_h = surface.x;
	v_gradient = surface.yz;
	v_world = w + vec3(0.0, surface.x, 0.0);
}

void fragment() {
	float height_range = max(dot(abs(amp), vec3(1.0)) + abs(swell_amp), 0.0001);
	float height_band = v_h / height_range * 0.5 + 0.5;
	vec3 surface_normal = normalize(vec3(-v_gradient.x, 1.0, -v_gradient.y));
	// Fixed illustrative light on the actual slopes gives the wave faces volume
	// without a specular highlight or camera-dependent sparkle.
	float facing = dot(surface_normal.xz, normalize(vec2(-0.6, 0.8)));
	float band = clamp(height_band + facing * 0.8, 0.0, 1.0);
	float aa = max(fwidth(band), 0.004);
	vec3 color = mix(deep.rgb, mid.rgb, smoothstep(0.35 - aa, 0.35 + aa, band));
	color = mix(color, crest.rgb, smoothstep(0.70 - aa, 0.70 + aa, band));

	// Drifting, broken brush strokes follow the primary wave. Their irregularity
	// is continuous in time, avoiding the previous frame-hashed glitter.
	vec2 direction = wave_dir(0);
	vec2 cross_direction = vec2(-direction.y, direction.x);
	vec2 paint = vec2(dot(v_world.xz, direction) - speed.x * wave_time,
		dot(v_world.xz, cross_direction));
	float brush = sin(paint.y * 1.8 + sin(paint.x * 1.2) * 1.4)
		+ 0.45 * sin(paint.y * 4.6 - paint.x * 0.7);
	float broken = smoothstep(-0.20, 0.35, brush);
	float crest_edge = 0.78 + 0.028 * sin(paint.y * 2.4 + paint.x * 0.8);
	float edge_distance = abs(band - crest_edge);
	float line = 1.0 - smoothstep(0.010, 0.010 + aa * 1.5, edge_distance);
	float lower_edge = 1.0 - smoothstep(0.008, 0.008 + aa, abs(band - 0.68));
	color = mix(color, ink.rgb, lower_edge * broken * contour_strength);
	float swell_foam = clamp(abs(swell_amp) / height_range, 0.0, 1.0);
	float crest_patch = smoothstep(0.83, 0.94, band) * smoothstep(0.65, 1.15, brush);
	float foam_mask = clamp(line * broken + crest_patch * (0.25 + swell_foam), 0.0, 1.0);
	color = mix(color, foam.rgb, foam_mask * foam_amount);

	// Retain the existing seam with the distant painted river in both modes.
	float far_t = far_r > 0.0
		? smoothstep(far_r - 9.0, far_r, length(v_world.xz))
		: 1.0 - smoothstep(far_z, far_z + 9.0, v_world.z);
	ALBEDO = mix(color, horizon.rgb, far_t * 0.7);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
