extends RefCounted

# Flight collision policy. Terrain height is supplied by the existing world;
# this module does not generate or modify terrain.
func surface_height(ground_height: float, x: float, z: float, water_position: Vector3, water_size: Vector2) -> float:
	var inside_water := absf(x - water_position.x) <= water_size.x * 0.5 and absf(z - water_position.z) <= water_size.y * 0.5
	return maxf(ground_height, water_position.y) if inside_water else ground_height
