// Cel / toon surface shader — banded diffuse, tinted shadow, rim, hit flash.
// Outline comes from outline.gdshader attached as `next_pass`. Docs: docs/Tech/Cel-Shading.md
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;

#include "res://shaders/camera_proximity.gdshaderinc"

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
uniform int surface_kind = 0; // 1 blade UV inlay, 2 etched brass, 3 cross-wrapped leather.
uniform int blade_form = 0;
uniform sampler2D inlay_tex : source_color, hint_default_white, filter_linear_mipmap;
uniform bool use_inlay_map = false;
uniform float gold_variant : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ornament_color : source_color = vec4(0.604, 0.537, 0.376, 1.0);

uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
varying vec3 local_point;
void vertex() {
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz, MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;
 local_point = VERTEX; }
void fragment() {
	if (camera_proximity_hidden(FRAGCOORD.xy)) { discard; }
	vec3 cell = floor(local_point * 90.0);
	float grain = fract(sin(dot(cell, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	if (dissolve > 0.0 && grain < dissolve) { discard; }

	vec4 tex = texture(albedo_tex, UV);
	vec3 base = albedo.rgb * tex.rgb;
	// Original deterministic material texture. Pixel derivatives soften subpixel
	// etching at play distance; no TIME-driven shimmer or shared random state.
	float ink = 0.0;
	if (surface_kind == 1) {
		float u = UV.x - 0.5;
		float v = UV.y;
		if (use_inlay_map) {
			// Image origin is top-left; the painted lower diamond belongs at the guard.
			vec3 inlay = texture(inlay_tex, vec2(UV.x, 1.0 - UV.y)).rgb;
			float value = dot(inlay, vec3(0.3, 0.59, 0.11));
			base = mix(inlay, albedo.rgb * clamp(0.5 + value, 0.5, 1.1), gold_variant);
		}
		float aa = max(fwidth(u), 0.0015);
		float centre = 1.0 - smoothstep(0.007, 0.007 + aa, abs(u));
		float diamond = 1.0 - smoothstep(0.009, 0.009 + aa, abs(abs(u) + abs(v - 0.115) * 0.6 - 0.037));
		ink = max(centre * smoothstep(0.015, 0.07, v), diamond);
		if (blade_form == 1) {
			float grooves = 1.0 - smoothstep(0.005, 0.005 + aa, abs(abs(u) - 0.04));
			float ticks = (1.0 - smoothstep(0.02, 0.045, abs(fract(v * 8.0) - 0.5))) * (1.0 - smoothstep(0.065, 0.08, abs(u)));
			ink = max(grooves * step(0.12, v) * step(v, 0.75), ticks * step(0.18, v) * step(v, 0.65));
		} else if (blade_form == 2) {
			float chevron = min(abs(v - 0.09 - abs(u) * 0.65), abs(v - 0.17 - abs(u) * 0.65));
			ink = max(centre * 0.5, (1.0 - smoothstep(0.005, 0.005 + aa, chevron)) * step(v, 0.3));
		}
		base *= mix(0.86, 1.06, smoothstep(0.0, 0.35, abs(u)));
		// Do not stamp a duplicate procedural centre-line/diamond onto a painted map.
		if (!use_inlay_map) { base = mix(base, ornament_color.rgb * 0.82, ink * 0.82); }
	} else if (surface_kind == 2) {
		float etch = abs(fract(UV.x * 7.0 + UV.y * 3.0) - 0.5);
		base *= mix(0.78, 1.0, smoothstep(0.015, max(0.03, fwidth(etch) * 1.3), etch));
	} else if (surface_kind == 3) {
		vec2 weave = abs(fract(vec2(UV.x * 5.0 + UV.y * 8.0, UV.x * 5.0 - UV.y * 8.0)) - 0.5);
		float seam = min(weave.x, weave.y);
		base *= mix(0.42, 1.10, smoothstep(0.02, max(0.045, fwidth(seam) * 1.4), seam));
	}
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
