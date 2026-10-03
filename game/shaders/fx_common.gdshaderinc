// Shared bits for the lane-B effect shaders (fx_*.gdshader). Look only — nothing here feeds the fight.
// Palette from docs/Art/Style-Guide.md: line #2B2230, shadow multiplier #B07AA6.

// Linear values: shader maths runs in linear space, so the sRGB hex must be decoded (python, sRGB EOTF).
const vec3 FX_INK = vec3(0.0242, 0.0160, 0.0296);     // #2B2230
const vec3 FX_SHADOW = vec3(0.4342, 0.1946, 0.3813);  // #B07AA6

float fx_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// value noise, 0..1
float fx_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = fx_hash(i);
	float b = fx_hash(i + vec2(1.0, 0.0));
	float c = fx_hash(i + vec2(0.0, 1.0));
	float d = fx_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// two octaves — enough for a torn paper edge, cheap on a phone
float fx_fbm(vec2 p) {
	return fx_noise(p) * 0.65 + fx_noise(p * 2.7 + 13.1) * 0.35;
}
