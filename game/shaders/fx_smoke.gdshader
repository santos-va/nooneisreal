// Cel smoke puff: lumpy sphere, one hard light/shadow split (shadow = base × #B07AA6), a thin ink rim
// #2B2230 and a stepped noise dissolve instead of a fading glass ball. Look only.
shader_type spatial;
render_mode blend_mix, unshaded, cull_back, depth_draw_never, shadows_disabled;

#include "res://shaders/fx_common.gdshaderinc"

uniform vec4 base : source_color = vec4(0.3, 0.2, 0.4, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.85;
uniform float fade : hint_range(0.0, 1.0) = 1.0;   // 1 = whole puff, 0 = gone
uniform float seed = 0.0;
uniform float lump : hint_range(0.0, 0.6) = 0.28;  // how far the noise pushes the surface out
uniform float ink_rim : hint_range(0.0, 0.4) = 0.08;

varying float v_n;

void vertex() {
	vec3 p = VERTEX * 2.2 + vec3(seed * 7.3);
	v_n = fx_noise(p.xy + p.z * 1.7);
	VERTEX += NORMAL * (v_n - 0.5) * lump * 2.0;
}

void fragment() {
	// light from above-front, fixed in world space so every puff agrees
	vec3 l = normalize((VIEW_MATRIX * vec4(0.35, 0.85, 0.4, 0.0)).xyz);
	float n = fx_fbm(UV * 5.0 + vec2(seed * 3.1));
	float lit = dot(NORMAL, l) + (n - 0.5) * 0.5;
	vec3 c = lit > 0.05 ? base.rgb : base.rgb * FX_SHADOW;
	float f = 1.0 - abs(dot(NORMAL, VIEW));
	if (f > 1.0 - ink_rim) {
		c = FX_INK;
	}
	if (n * 0.98 + 0.01 > fade) {
		discard;
	}
	ALBEDO = c;
	ALPHA = alpha;
}
