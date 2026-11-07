extends RefCounted

# Single worker, one job at a time. Script resources are preloaded; each job
# creates its own noise/model and builder. No scene-tree or rendering resource
# is touched from the worker. The main thread must call take() or finish().
const TerrainModel = preload("res://terrain_model.gd")
const ChunkBuilder = preload("res://terrain_chunk_mesh.gd")

var worker := Thread.new()
var mutex := Mutex.new()
var started := false
var result: Dictionary = {}

func start(seed_value: int, origin: Vector2, size_m: float, cells: int, lod: int, skirt_depth: float) -> Error:
	if started:
		return ERR_ALREADY_IN_USE
	result = {}
	var status := worker.start(_run.bind(seed_value, origin, size_m, cells, lod, skirt_depth))
	if status == OK:
		started = true
	return status

func _run(seed_value: int, origin: Vector2, size_m: float, cells: int, lod: int, skirt_depth: float) -> void:
	var local_model = TerrainModel.new(seed_value)
	var local_builder = ChunkBuilder.new()
	var data: Dictionary = local_builder.build_data(local_model, origin, size_m, cells, lod, skirt_depth)
	mutex.lock()
	result = data
	mutex.unlock()

func is_ready() -> bool:
	return started and not worker.is_alive()

func take() -> Dictionary:
	if not is_ready():
		return {}
	return finish()

func finish() -> Dictionary:
	if not started:
		return {}
	worker.wait_to_finish()
	mutex.lock()
	var completed := result
	result = {}
	mutex.unlock()
	started = false
	return completed
