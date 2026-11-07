shader_type sky;

uniform float sunset_strength = 0.0;

// Lightweight layered cloud/sky approximation for the flight prototype.
// This is not volumetric cloud rendering or a validated atmospheric solver.
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
float cloud_noise(vec2 p) {
	float sum = 0.0;
	float amplitude = 0.55;
	for (int i = 0; i < 4; i++) {
		sum += amplitude * noise2(p);
		p = p * 2.03 + vec2(13.7, 4.9);
		amplitude *= 0.5;
	}
	return sum;
}
void sky() {
	vec3 direction = normalize(EYEDIR);
	float elevation = max(direction.y, 0.0);
	float sky_gradient = pow(elevation, 0.42);
	vec3 day_horizon = vec3(0.50, 0.64, 0.76);
	vec3 dusk_horizon = vec3(0.74, 0.43, 0.27);
	vec3 horizon_color = mix(day_horizon, dusk_horizon, sunset_strength);
	vec3 zenith_color = mix(vec3(0.075, 0.22, 0.42), vec3(0.12, 0.17, 0.29), sunset_strength);
	vec3 sky_color = mix(horizon_color, zenith_color, sky_gradient);
	vec3 sun_direction = normalize(LIGHT0_DIRECTION);
	float alignment = max(dot(direction, sun_direction), 0.0);
	float glow = pow(alignment, 10.0);
	float disc = smoothstep(0.9992, 0.99975, alignment);
	sky_color += vec3(0.45, 0.32, 0.18) * glow * 0.55 + vec3(1.0, 0.87, 0.66) * disc * 3.0;
	// Two moving noise scales produce an inexpensive, visibly non-volumetric
	// cloud layer. Fade near/below the horizon to avoid projection stretching.
	vec2 cloud_uv = direction.xz / max(direction.y + 0.18, 0.18) * 1.8;
	cloud_uv += vec2(TIME * 0.0025, TIME * 0.0008);
	float shape = cloud_noise(cloud_uv);
	float cloud = smoothstep(0.47, 0.68, shape) * smoothstep(0.035, 0.20, direction.y);
	vec3 cloud_color = mix(vec3(0.55, 0.61, 0.66), vec3(0.95, 0.96, 0.98), clamp(shape * 1.2 + glow * 0.12, 0.0, 1.0));
	cloud_color = mix(cloud_color, cloud_color * vec3(1.0, 0.70, 0.54), sunset_strength * 0.65);
	COLOR = mix(sky_color, cloud_color, cloud * 0.85);
}
