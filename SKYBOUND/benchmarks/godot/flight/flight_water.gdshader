shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

varying vec3 surface_world;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_world = world_pos;
	float a = world_pos.x * 0.040 + world_pos.z * 0.016 + TIME * 1.05;
	float b = world_pos.x * -0.021 + world_pos.z * 0.052 + TIME * 0.72;
	VERTEX.y += 0.32 * sin(a) + 0.18 * sin(b);
	float dx = 0.32 * 0.040 * cos(a) - 0.18 * 0.021 * cos(b);
	float dz = 0.32 * 0.016 * cos(a) + 0.18 * 0.052 * cos(b);
	// Plane has nonuniform world scale; compensate so transformed normals
	// correspond to world-space wave slopes.
	float sx = length(MODEL_MATRIX[0].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);
	NORMAL = normalize(vec3(-dx * sx, 1.0, -dz * sz));
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 scene_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float scene_distance = -scene_view.z / max(abs(scene_view.w), 0.00001);
	float thickness = max(scene_distance + VERTEX.z, 0.0);
	float deep = smoothstep(0.0, 30.0, thickness);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 5.0);
	float ripple = sin(surface_world.x * 0.21 + surface_world.z * 0.13 + TIME * 1.1) * sin(surface_world.z * 0.19 - TIME * 0.8);
	vec3 shallow = vec3(0.055, 0.22, 0.20);
	vec3 deep_water = vec3(0.012, 0.070, 0.12);
	vec3 base = mix(mix(shallow, deep_water, deep), vec3(0.27, 0.41, 0.51), fresnel * 0.55);
	float shore = (1.0 - smoothstep(0.2, 2.5, thickness)) * 0.17;
	ALBEDO = mix(base * (1.0 + ripple * 0.035), vec3(0.48, 0.53, 0.48), shore);
	ROUGHNESS = mix(0.11, 0.17, abs(ripple));
	SPECULAR = 0.85;
	METALLIC = 0.05;
	ALPHA = mix(0.42, 0.86, deep);
}
