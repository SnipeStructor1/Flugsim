shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D grass_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_roughness : repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_normal : repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_height : repeat_enable, filter_linear_mipmap;
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
vec4 triplanar_texture(sampler2D tex, vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= max(w.x + w.y + w.z, 0.001);
	return texture(tex, p.yz) * w.x + texture(tex, p.xz) * w.y + texture(tex, p.xy) * w.z;
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL));
}
void fragment() {
	vec3 n = normalize(world_normal);
	float macro_noise = triplanar_noise(world_position * 0.009, n);
	float mid_noise = triplanar_noise(world_position * 0.045 + vec3(17.0, 8.0, 3.0), n);
	float detail = triplanar_noise(world_position * 0.19 + vec3(4.0, 21.0, 11.0), n);
	float steep = smoothstep(0.12, 0.52, 1.0 - n.y);
	float snow = smoothstep(205.0 + macro_noise * 45.0, 285.0 + macro_noise * 45.0, world_position.y) * smoothstep(0.30, 0.78, n.y);
	vec2 lake_offset = (world_position.xz - vec2(-400.0, -400.0)) / vec2(260.0, 200.0);
	float lake_region = 1.0 - smoothstep(0.85, 1.2, length(lake_offset));
	float shore = (1.0 - smoothstep(7.0, 26.0, world_position.y)) * smoothstep(0.7, 0.95, n.y) * lake_region;
	float strata = 0.5 + 0.5 * sin(world_position.y * 0.36 + mid_noise * 5.0);
	float rock_detail = mix(mid_noise, strata, 0.30);
	vec3 grass = mix(vec3(0.065, 0.105, 0.039), vec3(0.20, 0.25, 0.10), macro_noise);
	vec3 grass_detail = texture(grass_albedo, world_position.xz * 0.12).rgb;
	vec3 grass_broad = texture(grass_albedo, world_position.xz * 0.033 + vec2(11.0, 7.0)).rgb;
	float grass_luma = dot(mix(grass_detail, grass_broad, 0.35), vec3(0.2126, 0.7152, 0.0722));
	grass = mix(grass, grass_detail * vec3(0.50, 0.52, 0.40), 0.58);
	grass *= mix(0.82, 1.18, clamp(grass_luma, 0.0, 1.0)) * mix(0.80, 1.18, mid_noise);
	vec3 rock_sample = triplanar_texture(rock_albedo, world_position * 0.035, n).rgb;
	vec3 rock_sample_far = triplanar_texture(rock_albedo, world_position * 0.013 + vec3(13.0), n).rgb;
	float rock_luma = dot(mix(rock_sample, rock_sample_far, 0.40), vec3(0.2126, 0.7152, 0.0722));
	vec3 rock = mix(vec3(0.10, 0.105, 0.105), vec3(0.40, 0.39, 0.36), clamp(rock_luma * 0.8 + rock_detail * 0.2, 0.0, 1.0));
	vec3 ground = mix(grass, rock, steep);
	ground = mix(ground, vec3(0.37, 0.32, 0.23) * mix(0.82, 1.12, mid_noise), shore * 0.8);
	ground = mix(ground, vec3(0.74, 0.79, 0.80) * mix(0.88, 1.04, mid_noise), snow);
	ALBEDO = ground * mix(0.88, 1.12, detail);
	float rock_rough = triplanar_texture(rock_roughness, world_position * 0.035, n).r;
	ROUGHNESS = mix(mix(0.98, mix(0.72, 0.94, rock_rough), steep), 0.72, snow);
	float height_detail = triplanar_texture(rock_height, world_position * 0.035, n).r * steep * (1.0 - snow);
	vec3 tex_normal = triplanar_texture(rock_normal, world_position * 0.035, n).rgb * 2.0 - 1.0;
	vec3 tangent_x = normalize(dFdx(VERTEX));
	vec3 tangent_y = normalize(dFdy(VERTEX));
	NORMAL = normalize(NORMAL - (tangent_x * (dFdx(height_detail) * 0.38 + tex_normal.x * 0.14 * steep) + tangent_y * (dFdy(height_detail) * 0.38 + tex_normal.y * 0.14 * steep)));
}
