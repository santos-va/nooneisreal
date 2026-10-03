// Flat illustrated backdrop (Higgsfield-painted stage). Unshaded, slight vignette.
// The image can be framed inside a larger quad (per-stage, GameState.STAGES "backdrop"):
//   mirror_x — how many image widths the quad spans; outside [0,1] the image is mirrored
//              (until phase 2 outpaints wider art), so the skyline fills a 16:9 view.
//   img_top  — quad V where the image starts; above it the sky fades from the image's top row
//              into sky_top.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.25;
uniform float mirror_x = 1.0;
uniform float img_top : hint_range(0.0, 0.9) = 0.0;
uniform vec4 sky_top : source_color = vec4(0.3, 0.3, 0.42, 1.0);

void fragment() {
	float u = UV.x * mirror_x - (mirror_x - 1.0) * 0.5;
	u = 1.0 - abs(mod(u, 2.0) - 1.0);   // mirrored repeat: 0..1 → 1..0 → ...
	float v = (UV.y - img_top) / max(0.0001, 1.0 - img_top);
	vec3 c;
	if (v < 0.0) {
		vec3 edge = texture(tex, vec2(u, 0.004)).rgb;
		c = mix(sky_top.rgb, edge, smoothstep(0.0, img_top, UV.y));
	} else {
		c = texture(tex, vec2(u, v)).rgb;
	}
	c *= tint.rgb;
	float d = distance(UV, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.35, 0.8, d);
	ALBEDO = c;
}
