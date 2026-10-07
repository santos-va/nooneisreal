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

// Ordered 4x4 Bayer raster on square cells of ~4 px per 1080 px of viewport height (PLACEHOLDER,
// docs/Art/2026-10-07-Tight-Station-Readability-Criteria.md: a regular, graphic dot grid instead of
// 1-px grain). Screen-locked and monotonic in visibility, so a steady value never flickers.
float camera_proximity_threshold(vec2 pixel, vec2 viewport) {
	float cell = max(1.0, floor(viewport.y * 4.0 / 1080.0 + 0.5));
	vec2 a = floor(pixel / cell);
	vec2 h = floor(a * 0.5);
	float coarse = fract(h.x * 0.5 + h.y * h.y * 0.75);
	float fine = fract(a.x * 0.5 + a.y * a.y * 0.75);
	return coarse * 0.25 + fine + 1.0 / 32.0;
}

// Call sites pass FRAGCOORD.xy; the macros add the fragment stage's VIEWPORT_SIZE.
#ifdef CAMERA_PROXIMITY_OUTLINE
bool camera_outline_hidden_at(vec2 pixel, vec2 viewport) {
	// A shadow map has the light view, not the active camera view. Preserve it.
	return camera_main_pass > 0.5 && camera_outline_visibility < 1.0 && camera_proximity_threshold(pixel, viewport) >= camera_outline_visibility;
}
#define camera_outline_hidden(pixel) camera_outline_hidden_at((pixel), VIEWPORT_SIZE)
#else
bool camera_proximity_hidden_at(vec2 pixel, vec2 viewport) {
	// A shadow map has the light view, not the active camera view. Preserve it.
	return camera_main_pass > 0.5 && camera_visibility < 1.0 && camera_proximity_threshold(pixel, viewport) >= camera_visibility;
}
#define camera_proximity_hidden(pixel) camera_proximity_hidden_at((pixel), VIEWPORT_SIZE)
#endif
