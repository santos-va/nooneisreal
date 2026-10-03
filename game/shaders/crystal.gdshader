// Faceted emerald crystal — SWORD STORM blades and their shards (launch «crystal ult», look only).
// Flat facets from screen-space derivatives, a bright core, a fresnel rim and a glint band; time-stop desat like toon.
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, specular_disabled, unshaded;

uniform vec4 core : source_color = vec4(0.55, 1.0, 0.78, 1.0);
uniform vec4 deep : source_color = vec4(0.02, 0.32, 0.2, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 0.86;
uniform float glow : hint_range(0.0, 4.0) = 1.6;
uniform float desat : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	float facing = abs(dot(n, normalize(VIEW)));
	float rim = pow(1.0 - facing, 2.0);
	// facets: quantise the facing so each face reads as one flat tone (cel, not glossy)
	float band = floor(facing * 3.0) / 2.0;
	vec3 c = mix(deep.rgb, core.rgb, clamp(band, 0.0, 1.0));
	float glint = step(0.92, fract((VERTEX.y + VERTEX.x) * 2.0));
	c += core.rgb * (rim * glow + glint * 0.6);
	float g = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(g) * vec3(0.72, 0.84, 1.08), desat);
	ALBEDO = c;
	ALPHA = clamp(alpha + rim * 0.3, 0.0, 1.0);
}
