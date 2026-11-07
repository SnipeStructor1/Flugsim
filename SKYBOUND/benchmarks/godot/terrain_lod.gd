extends RefCounted

# LOD 0 is finest, LOD 2 is coarsest, -1 means not resident.
# Distances are in world-space meters. Hysteresis prevents repeated switching
# when a camera hovers around a threshold.
const NEAR_DISTANCE := 320.0
const MID_DISTANCE := 650.0
const LOAD_DISTANCE := 1200.0
var load_distance := LOAD_DISTANCE
const HYSTERESIS := 32.0

func choose(distance: float, previous: int) -> int:
	if not is_finite(distance) or distance < 0.0 or previous < -1 or previous > 2:
		return -1
	if previous == -1:
		if distance > load_distance:
			return -1
		return 0 if distance < NEAR_DISTANCE else (1 if distance < MID_DISTANCE else 2)
	if distance > load_distance + HYSTERESIS:
		return -1
	var lod := previous
	while lod < 2:
		var threshold := NEAR_DISTANCE if lod == 0 else MID_DISTANCE
		if distance <= threshold + HYSTERESIS:
			break
		lod += 1
	while lod > 0:
		var threshold := NEAR_DISTANCE if lod == 1 else MID_DISTANCE
		if distance >= threshold - HYSTERESIS:
			break
		lod -= 1
	return lod

# Distance from camera to the nearest point of a rectangular chunk, not its
# center. Thus a camera inside a large chunk always receives the finest LOD.
func distance_to_chunk(camera_xz: Vector2, chunk_origin: Vector2, chunk_size: float) -> float:
	if chunk_size <= 0.0:
		return INF
	var nearest := Vector2(clampf(camera_xz.x, chunk_origin.x, chunk_origin.x + chunk_size), clampf(camera_xz.y, chunk_origin.y, chunk_origin.y + chunk_size))
	return camera_xz.distance_to(nearest)
