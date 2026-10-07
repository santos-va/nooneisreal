// Hero-only hull body shared by hero_outline.gdshader (opaque, default) and
// hero_outline_near.gdshader (camera-near depth-mask variant). Facial ink comes from the measured
// atlas, never internal hull facets.
uniform vec4 outline_color : source_color = vec4(0.06,0.05,0.09,1.0);
uniform float width : hint_range(0.0,0.1) = 0.006;
varying float protected_face;

void vertex() {
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz,MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;
	protected_face = COLOR.r;
	VERTEX += NORMAL * width * (1.0-clamp(protected_face,0.0,1.0));
}

void fragment() {
	if (camera_outline_hidden(FRAGCOORD.xy) || protected_face > 0.001) { discard; }
	ALBEDO = outline_color.rgb;
}
