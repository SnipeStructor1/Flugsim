extends RefCounted

# Shared continuous height function: sample world coordinates, never chunk-local coordinates.
# Conservative bounds for this specific height formula, assuming FastNoiseLite
# returns [-1, 1]: 18 - 90 - 180 <= h <= 18 + 90 + 420 + 170.
const MIN_HEIGHT := -252.0
const MAX_HEIGHT := 698.0

func conservative_bounds() -> Vector2:
	return Vector2(MIN_HEIGHT, MAX_HEIGHT)

var seed_value := 41017
var terrain_noise := FastNoiseLite.new()
var ridge_noise := FastNoiseLite.new()

func _init(initial_seed: int = 41017) -> void:
	seed_value = initial_seed
	terrain_noise.seed = seed_value
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.frequency = 0.0018
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.38
	ridge_noise.seed = seed_value + 37
	ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridge_noise.frequency = 0.0015
	ridge_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	ridge_noise.fractal_octaves = 3

func height(x: float, z: float) -> float:
	var broad := terrain_noise.get_noise_2d(x, z)
	var ridge: float = pow(1.0 - absf(ridge_noise.get_noise_2d(x, z)), 3.0)
	var mountain := exp(-((x - 370.0) ** 2 / 260000.0 + (z + 410.0) ** 2 / 390000.0))
	var foothill := exp(-((x + 650.0) ** 2 / 190000.0 + (z + 650.0) ** 2 / 240000.0))
	var lake := exp(-((x + 400.0) ** 2 / 50000.0 + (z + 400.0) ** 2 / 30000.0))
	return 18.0 + 90.0 * broad + mountain * (180.0 + 240.0 * ridge) + foothill * (60.0 + 110.0 * ridge) - 180.0 * lake

func normal(x: float, z: float, epsilon: float = 8.0) -> Vector3:
	return Vector3(height(x - epsilon, z) - height(x + epsilon, z), 2.0 * epsilon, height(x, z - epsilon) - height(x, z + epsilon)).normalized()

# Match the exact triangle interpolation of the render mesh, so placed objects sit on it.
func mesh_height(x: float, z: float, grid_step: float, half_size: float) -> float:
	var gx := (x + half_size) / grid_step
	var gz := (z + half_size) / grid_step
	var ix := floori(gx)
	var iz := floori(gz)
	var fx := gx - ix
	var fz := gz - iz
	var x0 := ix * grid_step - half_size
	var z0 := iz * grid_step - half_size
	var h00 := height(x0, z0)
	var h10 := height(x0 + grid_step, z0)
	var h01 := height(x0, z0 + grid_step)
	if fx + fz <= 1.0:
		return h00 * (1.0 - fx - fz) + h10 * fx + h01 * fz
	var h11 := height(x0 + grid_step, z0 + grid_step)
	return h10 * (1.0 - fz) + h01 * (1.0 - fx) + h11 * (fx + fz - 1.0)
