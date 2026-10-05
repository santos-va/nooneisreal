// Surface-only facial controls on original atlas regions. No added geometry or camera-facing quad.
uniform float face_atlas_size = 2048.0;
uniform vec4 face_eye_left = vec4(0.0);
uniform vec4 face_eye_right = vec4(0.0);
uniform vec2 face_axis_left = vec2(1.0, 0.0);
uniform vec2 face_axis_right = vec2(1.0, 0.0);
uniform vec2 face_skin_side = vec2(-1.0);
uniform vec2 face_closure = vec2(0.0);
uniform vec2 face_eye_skin_left = vec2(0.0);
uniform vec2 face_eye_skin_right = vec2(0.0);
uniform vec2 face_ink_left = vec2(0.0);
uniform vec2 face_ink_right = vec2(0.0);
uniform vec4 face_mouth_left = vec4(0.0);
uniform vec4 face_mouth_right = vec4(0.0);
uniform vec2 face_mouth_axis_left = vec2(1.0,0.0);
uniform vec2 face_mouth_axis_right = vec2(1.0,0.0);
uniform vec2 face_cheek_left = vec2(0.0);
uniform vec2 face_cheek_right = vec2(0.0);
uniform vec4 face_brow_left = vec4(0.0);
uniform vec4 face_brow_right = vec4(0.0);
uniform float face_mouth_tension = 0.0;
uniform float face_brow_tension = 0.0;

vec3 hero_eye_color(vec3 original, vec2 uv, vec4 region, vec2 axis, float skin_side, vec2 ink_uv, vec2 skin_point, float closure) {
	if (closure <= 0.00001 || region.z <= 0.0 || region.w <= 0.0) { return original; }
	vec2 normal = vec2(-axis.y, axis.x);
	vec2 offset = uv * face_atlas_size - region.xy;
	vec2 point = vec2(dot(offset, axis) / region.z, dot(offset, normal) / region.w);
	float radius = length(point);
	if (radius >= 1.18) { return original; }
	float aperture = max(0.035, 1.0 - clamp(closure, 0.0, 1.0));
	vec2 skin_uv = skin_point / face_atlas_size;
	vec3 skin = texture(albedo_tex, skin_uv).rgb;
	vec2 source_point = vec2(point.x, point.y / aperture);
	vec2 source_uv = (region.xy + axis * source_point.x * region.z + normal * source_point.y * region.w) / face_atlas_size;
	vec3 eye = texture(albedo_tex, source_uv).rgb;
	float eye_inside = 1.0 - smoothstep(0.82, 1.04, length(source_point));
	vec3 compressed = mix(skin, eye, eye_inside);
	// A closed eyelid keeps the original ink color, sampled at its actual corner.
	vec3 ink = texture(albedo_tex, ink_uv / face_atlas_size).rgb;
	compressed = mix(compressed, skin, smoothstep(0.90,0.98,closure));
	float crease = (1.0 - smoothstep(0.04, 0.14, abs(point.y + 0.10 * (1.0-point.x*point.x)))) * (1.0-smoothstep(0.78,1.0,abs(point.x)));
	compressed = mix(compressed, ink, crease * smoothstep(0.75, 1.0, closure));
	float edge = 1.0 - smoothstep(0.94, 1.18, radius);
	return mix(original, compressed, edge * smoothstep(0.0, 0.16, closure));
}

vec3 hero_mouth_color(vec3 original, vec2 uv, vec4 region, vec2 axis, vec2 cheek) {
	if (face_mouth_tension <= 0.00001 || region.z <= 0.0) { return original; }
	vec2 normal = vec2(-axis.y,axis.x);
	vec2 delta = uv * face_atlas_size - region.xy;
	vec2 point = vec2(dot(delta,axis)/region.z,dot(delta,normal)/region.w);
	float edge = 1.0-smoothstep(0.95,1.20,length(point));
	if (edge <= 0.0) { return original; }
	float aperture = max(0.06,1.0-face_mouth_tension*0.92);
	vec2 source = vec2(point.x,(point.y+face_mouth_tension*0.22*(1.0-point.x*point.x))/aperture);
	vec3 skin = texture(albedo_tex,cheek/face_atlas_size).rgb;
	vec3 mouth = texture(albedo_tex,(region.xy+axis*source.x*region.z+normal*source.y*region.w)/face_atlas_size).rgb;
	float inside = 1.0-smoothstep(0.88,1.12,length(source));
	return mix(original,mix(skin,mouth,inside),edge*smoothstep(0.0,0.16,face_mouth_tension));
}

vec2 hero_brow_uv(vec2 uv,vec4 region,vec2 axis) {
	if (region.z <= 0.0 || abs(face_brow_tension) <= 0.00001) { return uv; }
	vec2 normal = vec2(-axis.y,axis.x);
	vec2 delta = uv*face_atlas_size-region.xy;
	vec2 point = vec2(dot(delta,axis)/region.z,dot(delta,normal)/region.w);
	float envelope = pow(max(0.0,1.0-dot(point,point)),2.0);
	return uv+normal*face_brow_tension*2.0*envelope/face_atlas_size;
}

vec3 hero_face_color(vec3 original, vec2 uv, float mask) {
	if (mask < 0.001) { return original; }
	vec2 brow_uv = hero_brow_uv(uv,face_brow_left,face_axis_left);
	brow_uv = hero_brow_uv(brow_uv,face_brow_right,face_axis_right);
	vec3 result = abs(face_brow_tension)>0.00001 ? texture(albedo_tex,brow_uv).rgb : original;
	result = hero_eye_color(result, uv, face_eye_left, face_axis_left, face_skin_side.x, face_ink_left, face_eye_skin_left, face_closure.x);
	result = hero_eye_color(result, uv, face_eye_right, face_axis_right, face_skin_side.y, face_ink_right, face_eye_skin_right, face_closure.y);
	result = hero_mouth_color(result,uv,face_mouth_left,face_mouth_axis_left,face_cheek_left);
	result = hero_mouth_color(result,uv,face_mouth_right,face_mouth_axis_right,face_cheek_right);
	return mix(original,result,clamp(mask,0.0,1.0));
}
