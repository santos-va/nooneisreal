// Inverted-hull ink outline. Attach as `next_pass` of the toon material.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float width : hint_range(0.0, 0.1) = 0.025;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
