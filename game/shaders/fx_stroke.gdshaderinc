// Body of fx_ink / fx_glow: a drawn stroke that tears at its edges and burns away in steps.
// The script steps `fade` (Fx.stepped) so the dissolve reads as drawn frames, not a smooth blur.
#include "res://shaders/fx_common.gdshaderinc"

uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.9;
uniform float fade : hint_range(0.0, 1.0) = 1.0;       // 1 = whole, 0 = gone
uniform float seed = 0.0;                              // per-instance, so no two shards tear alike
uniform float tear : hint_range(0.0, 1.0) = 0.6;       // ragged quad edge (0 = clean rectangle)
uniform float rim : hint_range(0.0, 1.0) = 0.0;        // 1 = fresnel ghost (afterimage capsules)
uniform float edge : hint_range(0.0, 0.5) = 0.12;      // width of the band at the burning front
uniform float noise_scale = 6.0;

void fragment() {
	float n = fx_fbm(UV * noise_scale + vec2(seed * 17.13, seed * 5.71));
	// torn paper: the closer to a quad edge, the likelier the noise bites it off
	float e = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)) * 2.0;
	if (e < tear * (0.25 + 0.75 * n)) {
		discard;
	}
	float burn = n * 0.98 + 0.01;
	if (burn > fade) {
		discard;
	}
	float front = smoothstep(fade - edge, fade, burn);
	float f = 1.0 - abs(dot(NORMAL, VIEW));
	float fres = mix(1.0, smoothstep(0.1, 0.85, f) * 1.3 + 0.12, rim);
#ifdef FX_ADD
	ALBEDO = tint.rgb * (1.0 + front * 1.2);
#else
	ALBEDO = mix(tint.rgb, FX_INK, front);
#endif
	ALPHA = clamp(alpha * fres, 0.0, 1.0);
}
