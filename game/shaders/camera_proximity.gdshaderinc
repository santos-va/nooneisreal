// Per-material city camera proximity, opaque dither works in Compatibility too.
// Default 1 preserves all other scenes; no alpha sorting or global actor visibility.
uniform float camera_visibility : hint_range(0.0, 1.0) = 1.0;

varying flat float camera_main_pass;

bool camera_proximity_hidden(vec2 pixel) {
	float threshold = fract(52.9829189 * fract(dot(floor(pixel), vec2(0.06711056, 0.00583715))));
	// A shadow map has the light view, not the active camera view. Preserve it.
	return camera_main_pass > 0.5 && camera_visibility < 1.0 && threshold >= camera_visibility;
}
