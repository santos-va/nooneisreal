// Inverted-hull ink body shared by outline.gdshader (opaque, default) and outline_near.gdshader.
uniform vec4 outline_color : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform float width : hint_range(0.0, 0.1) = 0.025;

void vertex() {
	camera_main_pass = distance(INV_VIEW_MATRIX[3].xyz, MAIN_CAM_INV_VIEW_MATRIX[3].xyz) < 0.001 ? 1.0 : 0.0;

	VERTEX += NORMAL * width;
}

void fragment() {
	if (camera_outline_hidden(FRAGCOORD.xy)) { discard; }
	ALBEDO = outline_color.rgb;
}
