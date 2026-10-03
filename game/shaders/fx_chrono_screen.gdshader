// Choko's TIME STOP over the whole screen: the picture drains to the same grey-blue as frozen
// fighters (toon.gdshader `desat`), strongest at the edges, with a clock-tick ring sweeping out
// from the centre. Look only — the freeze itself lives in TimeStopFx / Fighter.freeze.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float ring : hint_range(0.0, 1.5) = 0.0;    // ring radius in screen heights
uniform float ticks = 12.0;

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.3, 0.59, 0.11));
	vec3 frozen = vec3(g) * vec3(0.72, 0.84, 1.08);
	vec2 d = SCREEN_UV - 0.5;
	d.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float r = length(d);
	float vig = smoothstep(0.2, 0.75, r);
	vec3 o = mix(c, frozen, strength * (0.45 + 0.55 * vig));
	// ring of clock ticks: a thin band, broken into `ticks` dashes
	float a = atan(d.y, d.x) / 6.28318 + 0.5;
	float dash = step(0.45, fract(a * ticks));
	float band = 1.0 - smoothstep(0.0, 0.006, abs(r - ring));
	o += vec3(0.75, 0.88, 1.0) * band * dash * strength;
	COLOR = vec4(o, 1.0);
}
