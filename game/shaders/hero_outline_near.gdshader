// Camera-near twin of hero_outline.gdshader, used only while CityCameraProximity thins the fill.
// It follows camera_proximity_mask.gdshader (render_priority +1) and never writes depth, so the
// mask's depth keeps the hull out of the dithered silhouette: the scene shows through, the outer
// ink ring stays. Being an alpha-queue pass it casts no shadow.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never;

#define CAMERA_PROXIMITY_OUTLINE
#include "res://shaders/camera_proximity.gdshaderinc"
#include "res://shaders/hero_outline_hull.gdshaderinc"
