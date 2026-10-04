// Cel / toon surface shader — banded diffuse, tinted shadow, rim, hit flash.
// Outline comes from outline.gdshader attached as `next_pass`. Docs: docs/Tech/Cel-Shading.md
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform float bands : hint_range(1.0, 6.0) = 3.0;
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 shadow_tint : source_color = vec4(0.25, 0.3, 0.45, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.3;
uniform float rim_width : hint_range(0.0, 1.0) = 0.55;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;   // TIME STOP: grey-blue frozen look

// PLACEHOLDER art grain. Object coordinates freeze with hitstop; no TIME or random state.
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
	vec3 cell = floor(local_point * 90.0);
	float grain = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	if (dissolve > 0.0 && grain < dissolve) { discard; }

	vec4 tex = texture(albedo_tex, UV);
	vec3 base = albedo.rgb * tex.rgb;
	float g = dot(base, vec3(0.3, 0.59, 0.11));
	base = mix(base, vec3(g) * vec3(0.72, 0.84, 1.08), desat);
	ALBEDO = mix(base, vec3(1.0), hit_flash);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = clamp(ndl * 0.5 + 0.5, 0.0, 1.0);
	float band = floor(lit * bands) / max(bands - 1.0, 1.0);
	float a = clamp(band, 0.0, 1.0);
	float k = mix(1.0 - shadow_strength, 1.0, a);
	vec3 shade = mix(ALBEDO * shadow_tint.rgb, ALBEDO, k);
	DIFFUSE_LIGHT += shade * LIGHT_COLOR * ATTENUATION;
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = smoothstep(1.0 - rim_width, 1.0, rim);
	DIFFUSE_LIGHT += ALBEDO * rim * rim_strength * LIGHT_COLOR * ATTENUATION * step(0.0, ndl);
}
