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

// Actual aperture landmarks, measured against native screen corners and verified by UV markers.
uniform vec2 face_upper_left[5];
uniform vec2 face_lower_left[5];
uniform vec2 face_upper_right[5];
uniform vec2 face_lower_right[5];

// Return the anatomical upper-to-lower coordinate inside a triangle; -1 outside.
float hero_lid_triangle(vec2 p, vec2 a, vec2 b, vec2 c, vec3 heights) {
	vec2 ab=b-a; vec2 ac=c-a; vec2 ap=p-a;
	float determinant=ab.x*ac.y-ab.y*ac.x;
	if (abs(determinant)<0.00001) { return -1.0; }
	float u=(ap.x*ac.y-ap.y*ac.x)/determinant;
	float v=(ab.x*ap.y-ab.y*ap.x)/determinant;
	if (u<0.0 || v<0.0 || u+v>1.0) { return -1.0; }
	return dot(vec3(1.0-u-v,u,v),heights);
}
float hero_lid_coordinate(vec2 pixel, vec2 upper[5], vec2 lower[5]) {
	for (int i=0;i<4;i++) {
		float y=hero_lid_triangle(pixel,upper[i],upper[i+1],lower[i+1],vec3(0.0,0.0,1.0));
		if (y>=0.0) { return y; }
		y=hero_lid_triangle(pixel,upper[i],lower[i+1],lower[i],vec3(0.0,1.0,1.0));
		if (y>=0.0) { return y; }
	}
	return -1.0;
}
vec3 hero_eye_color(vec3 original, vec2 uv, float lid_y, vec2 ink_uv, vec2 skin_point, float closure) {
	if (lid_y<0.0) { return original; }
	// The exposed iris always uses its original texel, including during brow expressions.
	vec3 eye=texture(albedo_tex,uv).rgb;
	if (closure<=0.00001) { return eye; }
	float edge=max(fwidth(lid_y),0.025);
	float cover=1.0-smoothstep(closure-edge,closure+edge,lid_y);
	if (closure>=0.999) { cover=1.0; }
	vec3 skin=texture(albedo_tex,skin_point/face_atlas_size).rgb;
	vec3 ink=texture(albedo_tex,ink_uv/face_atlas_size).rgb;
	// A narrow lid edge travels downwards within the original dark eye rim.
	float crease=1.0-smoothstep(edge,edge*2.0,abs(lid_y-min(closure,0.94)));
	vec3 lid=mix(skin,ink,crease*0.8);
	return mix(eye,lid,cover);
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
	result = hero_eye_color(result, uv, hero_lid_coordinate(uv*face_atlas_size,face_upper_left,face_lower_left), face_ink_left, face_eye_skin_left, face_closure.x);
	result = hero_eye_color(result, uv, hero_lid_coordinate(uv*face_atlas_size,face_upper_right,face_lower_right), face_ink_right, face_eye_skin_right, face_closure.y);
	result = hero_mouth_color(result,uv,face_mouth_left,face_mouth_axis_left,face_cheek_left);
	result = hero_mouth_color(result,uv,face_mouth_right,face_mouth_axis_right,face_cheek_right);
	return mix(original,result,clamp(mask,0.0,1.0));
}
