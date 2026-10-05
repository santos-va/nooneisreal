// One quiet, continuous rear-cover infinity-eight from the signed Skea reference.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
#include "res://shaders/camera_proximity.gdshaderinc"
uniform vec4 albedo : source_color = vec4(0.6196,0.2980,0.9490,1.0);
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
uniform float desat : hint_range(0.0,1.0) = 0.0;
void vertex() {
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz,MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;
}
void fragment() {
	if (camera_proximity_hidden(FRAGCOORD.xy)) { discard; }
	float core = 1.0-smoothstep(0.05,0.48,abs(UV.y-0.5));
	vec3 base = mix(albedo.rgb,vec3(0.86,0.71,1.0),0.35*core);
	float grey = dot(base,vec3(0.3,0.59,0.11));
	base = mix(base,vec3(grey)*vec3(0.72,0.84,1.08),desat);
	ALBEDO = mix(base,vec3(1.0),hit_flash);
	EMISSION = base*0.18; // constant quiet glow; no TIME, pulse or heartbeat.
}
