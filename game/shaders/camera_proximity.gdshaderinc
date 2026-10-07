// Per-material city camera proximity, opaque dither works in Compatibility too.
// Default 1 preserves all other scenes; no alpha sorting or global actor visibility.
// Ink hulls `#define CAMERA_PROXIMITY_OUTLINE` first: the line has its own camera-owned value,
// so the policy can thin the fill while the outline stays (Sketch-Cel "line stays, fill goes").
#ifdef CAMERA_PROXIMITY_OUTLINE
uniform float camera_outline_visibility : hint_range(0.0, 1.0) = 1.0;
#else
uniform float camera_visibility : hint_range(0.0, 1.0) = 1.0;
#endif

varying flat float camera_main_pass;

float camera_proximity_threshold(vec2 pixel) {
	return fract(52.9829189 * fract(dot(floor(pixel), vec2(0.06711056, 0.00583715))));
}

#ifdef CAMERA_PROXIMITY_OUTLINE
bool camera_outline_hidden(vec2 pixel) {
	// A shadow map has the light view, not the active camera view. Preserve it.
	return camera_main_pass > 0.5 && camera_outline_visibility < 1.0 && camera_proximity_threshold(pixel) >= camera_outline_visibility;
}
#else
bool camera_proximity_hidden(vec2 pixel) {
	// A shadow map has the light view, not the active camera view. Preserve it.
	return camera_main_pass > 0.5 && camera_visibility < 1.0 && camera_proximity_threshold(pixel) >= camera_visibility;
}
#endif
