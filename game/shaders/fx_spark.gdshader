// Hit spark star (additive billboard): a white-hot core and N sharp rays in the hit colour,
// replacing the square placeholder (VFX-Direction § Далі). Look only.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#include "res://shaders/fx_common.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float points = 4.0;        // rays: 4 normal hit, 8 crit
uniform float spin = 0.0;          // radians — each spark lands at its own angle
uniform float sharp : hint_range(1.0, 32.0) = 10.0;
uniform float seed = 0.0;

void vertex() {
	// billboard that keeps the node's scale (same as StandardMaterial3D BILLBOARD_ENABLED)
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x) + spin;
	// uneven ray lengths so the star looks drawn, not stamped
	float k = floor((a / 6.28318 + 0.5) * points);
	float len = 0.65 + 0.35 * fx_hash(vec2(k, seed));
	float ray = pow(abs(cos(a * points * 0.5)), sharp) * len;
	float shape = max(ray, 0.22);
	if (r > shape) {
		discard;
	}
	float core = 1.0 - smoothstep(0.0, 0.3, r);
	ALBEDO = mix(tint.rgb, vec3(1.0), core);
	ALPHA = alpha;
}
