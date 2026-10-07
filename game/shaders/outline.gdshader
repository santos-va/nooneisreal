// Inverted-hull ink outline. Attach as `next_pass` of the toon material.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

#define CAMERA_PROXIMITY_OUTLINE
#include "res://shaders/camera_proximity.gdshaderinc"
#include "res://shaders/outline_hull.gdshaderinc"
