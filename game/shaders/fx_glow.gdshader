// Glowing stroke (additive): light shards, streaks, afterimage ghosts. Burning edge flares brighter.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

#define FX_ADD
#include "res://shaders/fx_stroke.gdshaderinc"
