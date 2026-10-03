// Toon river water (docs/World/Stage-River.md § Техніка 2).
// Vertex height = the same three waves + swell as WaveField.gd, fed through uniforms by Water.gd
// with the WaveField's own clock (wave_time), so the surface the fighters stand on is the surface
// you see. Fragment: flat colour bands, ink foam lines on crests, broken lantern glints.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 amp = vec3(0.06, 0.035, 0.018);
uniform vec3 wavelength = vec3(7.5, 3.3, 1.7);
uniform vec3 speed = vec3(1.1, -0.75, 1.5);
uniform vec3 phase = vec3(0.0, 1.7, 4.1);
uniform float swell_amp = 0.0;          // swell_amplitude * swell_env(), already enveloped
uniform float wave_time = 0.0;
uniform bool use_z = false;              // free movement (0.3-5): waves travel along dir_deg in XZ
uniform vec3 dir_deg = vec3(0.0, 35.0, -50.0);
uniform float far_r = 0.0;               // > 0: fade into the painted river by distance from the centre
uniform vec4 deep : source_color = vec4(0.1, 0.16, 0.2, 1.0);
uniform vec4 mid : source_color = vec4(0.14, 0.23, 0.27, 1.0);
uniform vec4 crest : source_color = vec4(0.22, 0.33, 0.36, 1.0);
uniform vec4 foam : source_color = vec4(0.93, 0.86, 0.74, 1.0);
uniform vec4 ink : source_color = vec4(0.08, 0.07, 0.1, 1.0);
uniform vec4 glint : source_color = vec4(1.0, 0.74, 0.4, 1.0);
uniform vec4 horizon : source_color = vec4(0.22, 0.3, 0.34, 1.0);   // matches the painted river far away
uniform float far_z = -17.0;

varying float v_h;
varying vec3 v_world;

// Same formula as WaveField.height(x, z): position projected on each wave's direction.
float along(int i, vec2 p) {
	if (!use_z) {
		return p.x;
	}
	float a = radians(dir_deg[i]);
	return cos(a) * p.x + sin(a) * p.y;
}

float wave_h(vec2 p) {
	float h = 0.0;
	for (int i = 0; i < 3; i++) {
		float k = 6.28318530718 / wavelength[i];
		h += amp[i] * sin(k * (along(i, p) - speed[i] * wave_time) + phase[i]);
	}
	float k0 = 6.28318530718 / wavelength.x;
	h += swell_amp * sin(k0 * (along(0, p) - speed.x * wave_time) + phase.x + 1.2);
	return h;
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = wave_h(w.xz);
	VERTEX.y += h;
	v_h = h;
	v_world = w;
}

void fragment() {
	float range = amp.x + amp.y + amp.z + 0.0001;
	float n = clamp(v_h / range * 0.5 + 0.5, 0.0, 1.0);   // 0 trough … 1 crest
	// flat bands, a little cross-river drift so the bands don't read as perfect stripes
	float drift = 0.035 * sin(v_world.z * 2.6 + v_world.x * 0.9 + wave_time * 0.8);
	float b = n + drift;
	vec3 c = b < 0.42 ? deep.rgb : (b < 0.72 ? mid.rgb : crest.rgb);
	// ink contour just under each crest band edge, foam line on the very top
	float edge = abs(b - 0.72);
	c = mix(c, ink.rgb, (1.0 - smoothstep(0.0, 0.012, edge)) * 0.55);
	float foam_line = smoothstep(0.88, 0.9, b) * (1.0 - smoothstep(0.91, 0.93, b));
	c = mix(c, foam.rgb, foam_line * 0.45 + smoothstep(0.0, 1.0, swell_amp * 6.0) * smoothstep(0.84, 0.95, b) * 0.3);
	// broken lantern glints: sparse dashes that flicker with the waves
	vec2 cell = floor(vec2(v_world.x * 4.0, v_world.z * 14.0));
	float on = step(0.955, hash2(cell + floor(wave_time * 2.0)));
	float dash = step(0.3, fract(v_world.x * 4.0)) * step(fract(v_world.x * 4.0), 0.8);
	c = mix(c, glint.rgb, on * dash * smoothstep(0.45, 0.8, n) * 0.7);
	// melt into the painted river near the backdrop
	float far_t = far_r > 0.0 ? smoothstep(far_r - 9.0, far_r, length(v_world.xz)) : smoothstep(far_z + 9.0, far_z, v_world.z);
	c = mix(c, horizon.rgb, far_t * 0.7);
	ALBEDO = c;
}
