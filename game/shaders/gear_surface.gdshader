// Separate clothing/tools only. Actor atlas and skin never receive this shader.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;
#include "res://shaders/camera_proximity.gdshaderinc"
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 accent : source_color = vec4(0.65,0.6,0.5,1.0);
uniform int surface_kind = 0;
uniform sampler2D pattern_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float pattern_strength : hint_range(0.0,1.0) = 0.0;
uniform int pattern_mode = 0; // 0: neutral mean-centered grain; 1: authored full-color cover.
uniform float pattern_luma_mean = 1.0;
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
uniform float desat : hint_range(0.0,1.0) = 0.0;
// Colour test switch A / B3 (plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB step 8, variant V1).
// GraphicsSettings sets it from the COLOURS (TEST) row; the default lives in project.godot [shader_globals].
// false = A: exactly the code as it was. true = B3: the calibration tool's variant, text for text
// (tools/art/albedo_ab_capture.gd b1_source() + b3_edits()).
// B3 numbers are PLACEHOLDER (artistic, Forward+ formula): docs/Fix/2026-10-15-Albedo-B3-Fix.md.
global uniform bool colour_b3;
varying vec3 surface_position;
void vertex() {
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz, MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;
	surface_position = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
}
void fragment() {
	if (camera_proximity_hidden(FRAGCOORD.xy)) { discard; }
	vec3 base = albedo.rgb;
	// Filtered millimetre weave: fades with pixel footprint, no animation/no sparkle.
	vec3 grid = surface_position * 450.0;
	vec3 footprint = fwidth(grid);
	float resolved = 1.0 - smoothstep(0.22,0.8,max(footprint.x,max(footprint.y,footprint.z)));
	float weave = sin(grid.x * 6.283185) * sin(grid.y * 6.283185 + grid.z * 6.283185);
	if (surface_kind == 0) {
		base *= 1.0 + weave * 0.025 * resolved;
		ROUGHNESS = 0.95;
		SPECULAR = 0.12;
	} else if (surface_kind == 1) {
		base *= 0.96 + 0.04 * smoothstep(0.0,0.08,min(UV.x,1.0-UV.x));
		ROUGHNESS = 0.68;
		SPECULAR = 0.25;
	} else {
		ROUGHNESS = 0.42;
		METALLIC = 0.0;
		SPECULAR = 0.4;
		base = mix(base,accent.rgb,0.12);
	}
	vec4 pattern = texture(pattern_texture,UV);
	if (pattern_mode == 1) {
		base = mix(base,pattern.rgb,pattern_strength * pattern.a);
	} else {
		float grain = dot(pattern.rgb,vec3(0.2126,0.7152,0.0722)) - pattern_luma_mean;
		base *= 1.0 + clamp(grain,-0.5,0.5) * pattern_strength * pattern.a;
	}
	float grey = dot(base,vec3(0.3,0.59,0.11));
	base = mix(base,vec3(grey) * vec3(0.72,0.84,1.08),desat);
	ALBEDO = mix(base,vec3(1.0),hit_flash);
}

void light() {
	float ndl = dot(NORMAL,LIGHT);
	float lit = smoothstep(-0.08,0.08,ndl);
	if (colour_b3) {
		// B3 (PLACEHOLDER): no albedo factor here (the engine multiplies by it once after light()); light x 0.914 / PI;
		// the shadow vec3(0.69,0.48,0.65) x 0.75 -> x 0.355.
		vec3 shadow = vec3(1.0) * vec3(0.69,0.48,0.65) * 0.355;
		vec3 shaded = mix(shadow,vec3(1.0),lit);
		float edge = step(0.72,1.0-max(dot(NORMAL,VIEW),0.0));
		float rim = surface_kind == 2 ? 0.08 : 0.025;
		DIFFUSE_LIGHT += (shaded + vec3(1.0) * edge * rim * step(0.0,ndl)) * LIGHT_COLOR * ATTENUATION * 0.914 / PI;
	} else {
		vec3 shadow = ALBEDO * vec3(0.69,0.48,0.65) * 0.75;
		vec3 shaded = mix(shadow,ALBEDO,lit);
		float edge = step(0.72,1.0-max(dot(NORMAL,VIEW),0.0));
		float rim = surface_kind == 2 ? 0.08 : 0.025;
		DIFFUSE_LIGHT += (shaded + ALBEDO * edge * rim * step(0.0,ndl)) * LIGHT_COLOR * ATTENUATION;
	}
}
