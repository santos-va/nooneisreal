// Procedural Kronshift dusk: gradient sky + flat building silhouettes + lantern dots.
// Used only when the painted backgrounds have not been fetched yet (tools/fetch_assets.sh).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 sky_top : source_color = vec4(0.16, 0.22, 0.32, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.78, 0.42, 0.26, 1.0);
uniform vec4 building : source_color = vec4(0.14, 0.12, 0.18, 1.0);
uniform vec4 lantern : source_color = vec4(1.0, 0.72, 0.35, 1.0);

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float y = 1.0 - uv.y;
	vec3 c = mix(sky_bottom.rgb, sky_top.rgb, smoothstep(0.1, 0.9, y));
	// far row
	float col = floor(uv.x * 18.0);
	float h = 0.22 + 0.25 * hash(col);
	float far = step(y, h);
	c = mix(c, building.rgb * 1.6, far);
	// near row
	float col2 = floor(uv.x * 9.0 + 0.5);
	float h2 = 0.12 + 0.3 * hash(col2 + 37.0);
	float near = step(y, h2);
	c = mix(c, building.rgb, near);
	// windows / lanterns
	vec2 g = fract(vec2(uv.x * 72.0, y * 40.0));
	float win = step(0.7, g.x) * step(0.7, g.y) * near * step(0.6, hash(floor(uv.x * 72.0) * 3.0 + floor(y * 40.0)));
	c = mix(c, lantern.rgb, win * 0.9);
	ALBEDO = c;
}
