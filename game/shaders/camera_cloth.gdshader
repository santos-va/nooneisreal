// Temporary camera-local replacement for the city's plain matte cloth material.
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
#include "res://shaders/camera_proximity.gdshaderinc"
uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness = 1.0;
uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform vec3 uv_scale = vec3(1.0);
void vertex() {
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz, MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;
}

void fragment() {
	if (camera_proximity_hidden(FRAGCOORD.xy)) { discard; }
	ALBEDO = albedo.rgb * texture(albedo_tex,UV*uv_scale.xy).rgb;
	ROUGHNESS = roughness;
}
