// Flat illustrated backdrop (Higgsfield-painted stage). Unshaded, slight vignette.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec2 uv = UV;
	vec3 c = texture(tex, uv).rgb * tint.rgb;
	float d = distance(uv, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.35, 0.8, d);
	ALBEDO = c;
}
