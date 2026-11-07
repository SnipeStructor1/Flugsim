shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 world_position;
varying vec3 world_normal;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), u.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x), u.y);
}
float triplanar_noise(vec3 p, vec3 n) {
	vec3 weights = pow(abs(n), vec3(4.0));
	weights /= max(weights.x + weights.y + weights.z, 0.001);
	return noise2(p.yz) * weights.x + noise2(p.xz) * weights.y + noise2(p.xy) * weights.z;
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL));
}
void fragment() {
	vec3 n = normalize(world_normal);
	float macro_noise = triplanar_noise(world_position * 0.014, n);
	float detail = triplanar_noise(world_position * 0.12, n);
	float steep = smoothstep(0.18, 0.62, 1.0 - n.y);
	float snow = smoothstep(300.0 + macro_noise * 75.0, 390.0 + macro_noise * 75.0, world_position.y) * smoothstep(0.45, 0.9, n.y);
	float shore = (1.0 - smoothstep(8.0, 22.0, world_position.y)) * smoothstep(0.7, 0.95, n.y);
	vec3 grass = mix(vec3(0.085, 0.14, 0.055), vec3(0.25, 0.31, 0.13), macro_noise);
	vec3 rock = mix(vec3(0.15, 0.14, 0.13), vec3(0.37, 0.35, 0.31), macro_noise);
	vec3 ground = mix(grass, rock, steep);
	ground = mix(ground, vec3(0.42, 0.37, 0.26), shore * 0.75);
	ground = mix(ground, vec3(0.82, 0.86, 0.88), snow);
	ALBEDO = ground * mix(0.84, 1.16, detail);
	ROUGHNESS = mix(0.95, 0.72, snow);
}
