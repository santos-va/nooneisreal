// Camera-owned depth mask (T3 V3, docs/Research/2026-10-07-Stencil-And-Line-Of-Sight.md): drawn
// right after a dithered body, before its near hull. It writes the body's depth with no colour
// (ALPHA 0), so the hull behind the silhouette fails the depth test while the opaque scene already
// drawn stays visible through the fill holes. Both sides: with the lens inside a head or looking
// into an open garment the body's back faces still cover the hull (measured, Skea t69 in
// docs/Fix/2026-10-07-Camera-Readability-Iteration-2.md). Alpha queue: no shadow, no depth prepass.
shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_always, blend_mix, shadows_disabled;

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
