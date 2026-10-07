// Camera-near twin of outline.gdshader (see hero_outline_near.gdshader): depth-mask variant.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never;

#define CAMERA_PROXIMITY_OUTLINE
#include "res://shaders/camera_proximity.gdshaderinc"
#include "res://shaders/outline_hull.gdshaderinc"
