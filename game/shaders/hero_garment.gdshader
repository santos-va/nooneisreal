// Separate bounded face, cloth and highlight masks on the original hero atlas.
// Cel / toon surface shader — banded diffuse, tinted shadow, rim, hit flash.
// Outline comes from outline.gdshader attached as `next_pass`. Docs: docs/Tech/Cel-Shading.md
shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;

#include "res://shaders/camera_proximity.gdshaderinc"

uniform float garment_detail = 1.0;
uniform sampler2D fabric_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float fabric_strength = 0.0;
// Mean must be measured from admitted texture in linear color space. White fallback is neutral.
uniform float fabric_luma_mean = 1.0;
varying float garment_mask;
varying float delight_mask;
varying float face_mask;
// PLACEHOLDER cotton highlight rebalance. Source atlas and protected surfaces stay intact.
uniform float garment_delight : hint_range(0.0, 1.0) = 0.96;
uniform vec4 garment_highlight : source_color = vec4(0.40,0.16,0.50,1.0);
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, hint_default_white;
#include "res://shaders/hero_face.gdshaderinc"
uniform float bands : hint_range(1.0, 6.0) = 3.0;
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 shadow_tint : source_color = vec4(0.25, 0.3, 0.45, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.3;
uniform float rim_width : hint_range(0.0, 1.0) = 0.55;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float desat : hint_range(0.0, 1.0) = 0.0;   // TIME STOP: grey-blue frozen look
// Colour test switch A / B3 (plan 2026-10-14-T6-Acceptance-Crane-Albedo-AB step 8, variant V1).
// GraphicsSettings sets it from the COLOURS (TEST) row; the default lives in project.godot [shader_globals].
// false = A: exactly the code as it was. true = B3: the calibration tool's variant, text for text
// (tools/art/albedo_ab_capture.gd b1_source() + b3_edits()).
// B3 numbers are PLACEHOLDER (artistic, Forward+ formula): docs/Fix/2026-10-15-Albedo-B3-Fix.md.
global uniform bool colour_b3;

void vertex() {
	garment_mask = COLOR.g;
	delight_mask = COLOR.b;
	face_mask = COLOR.r;
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz, MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;
}

void fragment() {
	if (camera_proximity_hidden(FRAGCOORD.xy)) { discard; }
	vec4 tex = texture(albedo_tex, UV);
	tex.rgb = hero_face_color(tex.rgb,UV,face_mask);
	float baked_highlight = smoothstep(0.35,0.85,max(tex.r,max(tex.g,tex.b)));
	// Protected triangles are exactly zero at every LOD; do not leave a broad
	// white interpolation halo within otherwise verified cloth triangles.
	float cloth_coverage = smoothstep(0.0,0.05,delight_mask);
	tex.rgb = mix(tex.rgb,garment_highlight.rgb,baked_highlight * cloth_coverage * garment_delight);
	vec3 base = albedo.rgb * tex.rgb;
	vec2 grid = UV * 700.0;
	float resolved = 1.0 - smoothstep(0.22,0.8,max(fwidth(grid.x),fwidth(grid.y)));
	float weave = sin(grid.x*6.283185) * sin(grid.y*6.283185);
	base *= 1.0 + 0.025 * weave * resolved * garment_mask * garment_detail;
	float fabric = dot(texture(fabric_texture,UV*16.0).rgb,vec3(0.2126,0.7152,0.0722)) - fabric_luma_mean;
	base *= 1.0 + clamp(fabric,-0.5,0.5) * fabric_strength * garment_mask * garment_detail;
	float g = dot(base, vec3(0.3, 0.59, 0.11));
	base = mix(base, vec3(g) * vec3(0.72, 0.84, 1.08), desat);
	ALBEDO = mix(base, vec3(1.0), hit_flash);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = clamp(ndl * 0.5 + 0.5, 0.0, 1.0);
	float band = floor(lit * bands) / max(bands - 1.0, 1.0);
	float a = clamp(band, 0.0, 1.0);
	if (colour_b3) {
		// B3 (PLACEHOLDER): no albedo factor here (the engine multiplies by it once after light());
		// every light line x 0.914 / PI;
		// shadow_strength 0.45 -> 0.895; the cloth shadow vec3(0.69,0.48,0.65) x 0.75 -> x 0.355.
		float k = mix(1.0 - clamp(shadow_strength * (0.895 / 0.45), 0.0, 1.0), 1.0, a);
		vec3 shade = mix(vec3(1.0) * shadow_tint.rgb, vec3(1.0), k);
		vec3 cloth_shade = mix(vec3(1.0) * vec3(0.69,0.48,0.65) * 0.355, vec3(1.0), smoothstep(-0.08,0.08,ndl));
		shade = mix(shade,cloth_shade,garment_mask * garment_detail);
		DIFFUSE_LIGHT += shade * LIGHT_COLOR * ATTENUATION * 0.914 / PI;
		float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		rim = smoothstep(1.0 - rim_width, 1.0, rim);
		DIFFUSE_LIGHT += vec3(1.0) * rim * rim_strength * LIGHT_COLOR * ATTENUATION * step(0.0, ndl) * 0.914 / PI;
	} else {
		float k = mix(1.0 - shadow_strength, 1.0, a);
		vec3 shade = mix(ALBEDO * shadow_tint.rgb, ALBEDO, k);
		vec3 cloth_shade = mix(ALBEDO * vec3(0.69,0.48,0.65) * 0.75, ALBEDO, smoothstep(-0.08,0.08,ndl));
		shade = mix(shade,cloth_shade,garment_mask * garment_detail);
		DIFFUSE_LIGHT += shade * LIGHT_COLOR * ATTENUATION;
		float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		rim = smoothstep(1.0 - rim_width, 1.0, rim);
		DIFFUSE_LIGHT += ALBEDO * rim * rim_strength * LIGHT_COLOR * ATTENUATION * step(0.0, ndl);
	}
}
