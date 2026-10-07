// Lethal-fight blood (docs/Art/2026-10-07-Blood-Visual-Language.md, variant A + floor drops): flat Sketch-Cel shapes
// with a hard edge and an ink rim, never a gradient, gloss or volume. Presentation only.
//   shape 0 — comma drop (head + tapering tail along +U), shape 1 — splat with 3–5 torn lobes,
//   shape 2 — floor drop / puddle (irregular blob).
// Colours come from Style-Guide § Колір: fill K1 #A3243B, shade #711126 (K1 × #B07AA6), rim #2B2230.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 fill : source_color = vec4(0.639, 0.141, 0.231, 1.0);
uniform vec4 shade : source_color = vec4(0.443, 0.067, 0.149, 1.0);
uniform vec4 rim_color : source_color = vec4(0.169, 0.133, 0.188, 1.0);
uniform int shape = 0;
uniform float lobes = 4.0;
uniform float rim = 0.05;       // rim width in UV (0 = no rim)
uniform float dry = 0.0;        // 0 fresh, 1 dried: the fill steps to the shade colour
uniform float fade = 1.0;       // 1 whole … 0 gone; callers pass a stepped value
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.13) * 43758.5453);
}

float seg(vec2 p, vec2 a, vec2 b, out float h) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Signed distance (negative inside) in UV units.
float shape_sdf(vec2 uv) {
	if (shape == 0) {
		vec2 c = vec2(0.34, 0.5);
		float head = length(uv - c) - 0.2;
		float h;
		float d = seg(uv, c, vec2(0.94, 0.5), h);
		float tail = d - 0.13 * (1.0 - h);
		return min(head, tail);
	}
	vec2 q = uv - vec2(0.5);
	float a = atan(q.y, q.x);
	float r;
	if (shape == 1) {
		r = 0.27 + 0.1 * cos(lobes * a + seed) + 0.03 * sin(9.0 * a + seed * 2.1);
	} else {
		r = 0.4 + 0.05 * sin(3.0 * a + seed) + 0.035 * sin(7.0 * a + seed * 1.7);
	}
	return length(q) - r;
}

void fragment() {
	float d = shape_sdf(UV);
	if (d > 0.0) {
		discard;
	}
	// Step-dissolve from the edge inward plus torn speckles, never a smooth alpha fade.
	float grain = hash(floor(UV * 18.0));
	if (fade < 1.0 && (grain > fade * 1.15 || -d < (1.0 - fade) * 0.12)) {
		discard;
	}
	vec3 base = mix(fill.rgb, shade.rgb, dry);
	// Shadow side: the lower part of a drop / the rim band of a stain sits in the shade tone.
	bool shadowed = shape == 0 ? UV.y > 0.56 : -d < rim + 0.05;
	vec3 colour = shadowed ? shade.rgb : base;
	if (rim > 0.0 && -d < rim) {
		colour = rim_color.rgb;
	}
	ALBEDO = colour;
	ALPHA = 1.0;
}
