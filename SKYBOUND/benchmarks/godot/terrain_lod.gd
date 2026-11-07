extends RefCounted

# LOD 0 is finest, LOD 2 is coarsest, -1 means not resident.
# Distances are in world-space meters. Hysteresis prevents repeated switching
# when a camera hovers around a threshold.
const NEAR_DISTANCE := 320.0
const MID_DISTANCE := 650.0
const LOAD_DISTANCE := 1200.0
var load_distance := LOAD_DISTANCE
const HYSTERESIS := 32.0

func choose(distance: float, previous: int, load_distance_override: float = -1.0) -> int:
	# An explicit horizontal load distance keeps terrain visible from high altitude;
	# 3D distance controls detail while horizontal distance controls residency.
	var residency_distance := distance if load_distance_override == -1.0 else load_distance_override
	if not is_finite(distance) or distance < 0.0 or not is_finite(residency_distance) or residency_distance < 0.0 or previous < -1 or previous > 2:
		return -1
	if previous == -1:
		if residency_distance > load_distance:
			return -1
		return 0 if distance < NEAR_DISTANCE else (1 if distance < MID_DISTANCE else 2)
	if residency_distance > load_distance + HYSTERESIS:
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

# Conservative 3D distance to a chunk's horizontal rectangle and global terrain
# height interval. Conservative bounds prevent selecting a coarser LOD merely
# because an unsampled mountain peak is absent from an approximate local bound.
func distance_to_chunk_3d(camera: Vector3, chunk_origin: Vector2, chunk_size: float, height_bounds: Vector2) -> float:
	if not camera.is_finite() or not height_bounds.is_finite() or height_bounds.x > height_bounds.y:
		return INF
	var horizontal := distance_to_chunk(Vector2(camera.x, camera.z), chunk_origin, chunk_size)
	if not is_finite(horizontal):
		return INF
	var vertical := maxf(maxf(height_bounds.x - camera.y, camera.y - height_bounds.y), 0.0)
	return sqrt(horizontal * horizontal + vertical * vertical)
