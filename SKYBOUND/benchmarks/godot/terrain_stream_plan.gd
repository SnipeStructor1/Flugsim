extends RefCounted

# Pure planning step. The caller owns loaded meshes and applies the returned
# unload operations before build operations. This class never claims an operation
# succeeded and never mutates the caller's resident-state dictionary.
var policy = preload("res://terrain_lod.gd").new()

func plan(camera_xz: Vector2, grid_origin: Vector2, chunk_size: float, grid_width: int, grid_height: int, resident: Dictionary, max_resident: int, build_budget: int, camera_y: float = 0.0, height_bounds: Vector2 = Vector2(-252, 698)) -> Dictionary:
	if chunk_size <= 0.0 or grid_width <= 0 or grid_height <= 0 or max_resident <= 0 or build_budget < 0 or not camera_xz.is_finite() or not is_finite(camera_y) or not height_bounds.is_finite() or height_bounds.x > height_bounds.y:
		return {"valid": false, "unload": [], "build": []}
	var candidates: Array[Dictionary] = []
	for z in range(grid_height):
		for x in range(grid_width):
			var key := Vector2i(x, z)
			var origin := grid_origin + Vector2(x * chunk_size, z * chunk_size)
			var horizontal: float = policy.distance_to_chunk(camera_xz, origin, chunk_size)
			var distance: float = policy.distance_to_chunk_3d(Vector3(camera_xz.x, camera_y, camera_xz.y), origin, chunk_size, height_bounds)
			var lod: int = policy.choose(distance, int(resident.get(key, -1)), horizontal)
			if lod >= 0:
				candidates.append({"key": key, "origin": origin, "distance": distance, "lod": lod})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.distance != b.distance: return a.distance < b.distance
		if a.key.y != b.key.y: return a.key.y < b.key.y
		return a.key.x < b.key.x)
	var desired := {}
	for i in range(mini(max_resident, candidates.size())):
		desired[candidates[i].key] = candidates[i]
	var unload: Array[Vector2i] = []
	for key in resident:
		if not desired.has(key):
			unload.append(key)
	unload.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	var build: Array[Dictionary] = []
	for i in range(mini(max_resident, candidates.size())):
		var candidate: Dictionary = candidates[i]
		if int(resident.get(candidate.key, -1)) != int(candidate.lod):
			if build.size() >= build_budget: break
			build.append(candidate)
	return {"valid": true, "unload": unload, "build": build}
