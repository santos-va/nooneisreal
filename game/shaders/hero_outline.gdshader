// Hero-only hull: facial ink comes from the measured atlas, never internal hull facets.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

#define CAMERA_PROXIMITY_OUTLINE
#include "res://shaders/camera_proximity.gdshaderinc"
#include "res://shaders/hero_outline_hull.gdshaderinc"
