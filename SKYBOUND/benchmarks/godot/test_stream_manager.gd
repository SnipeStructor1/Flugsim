extends SceneTree

class FailingBuilder:
	extends RefCounted
	func build(_model: RefCounted, _origin: Vector2, _size: float, _cells: int, _lod: int, _skirt: float) -> ArrayMesh:
		return null

func _initialize() -> void:
	var manager = load("res://terrain_stream_manager.gd").new()
	root.add_child(manager)
	manager.model = load("res://terrain_model.gd").new(41017)
	manager.grid_width = 4
	manager.grid_height = 4
	manager.max_resident = 3
	manager.build_budget = 2
	var a: Dictionary = manager.tick(Vector2(10, 10))
	if not a.valid or a.built != 2 or manager.resident.size() != 2 or manager.get_child_count() != 2:
		printerr("Initial creation or build budget failed")
		quit(1)
		return
	var b: Dictionary = manager.tick(Vector2(10, 10))
	if b.built != 1 or manager.resident.size() != 3 or manager.get_child_count() != 3:
		printerr("Convergence or resident limit failed")
		quit(1)
		return
	var c: Dictionary = manager.tick(Vector2(1000, 1000))
	if c.unloaded < 1 or c.built < 1 or manager.resident.size() > 3 or manager.get_child_count() != manager.resident.size():
		printerr("Camera movement or mesh cleanup failed")
		quit(1)
		return
	manager.free()
	manager = load("res://terrain_stream_manager.gd").new()
	root.add_child(manager)
	manager.model = load("res://terrain_model.gd").new(41017)
	manager.max_resident = 1
	if manager.tick(Vector2.ZERO).built != 1:
		printerr("Failed to establish replacement fixture")
		quit(1)
		return
	var original: Node = manager.nodes[Vector2i.ZERO]
	manager.builder = FailingBuilder.new()
	var failed: Dictionary = manager.tick(Vector2(700, 0))
	if failed.failed != 1 or manager.resident[Vector2i.ZERO] != 0 or manager.nodes[Vector2i.ZERO] != original or not is_instance_valid(original):
		printerr("Failed LOD replacement did not preserve existing mesh")
		quit(1)
		return
	manager.free()
	# Exercise a large teleport beyond the actual experimental scene's 3 km
	# loading radius, followed by a return and gradual budgeted reload.
	manager = load("res://terrain_stream_manager.gd").new()
	root.add_child(manager)
	manager.model = load("res://terrain_model.gd").new(41017)
	manager.origin = Vector2(-512, -512)
	manager.grid_width = 4
	manager.grid_height = 4
	manager.max_resident = 16
	manager.build_budget = 4
	manager.planner.policy.load_distance = 3000.0
	for i in range(4):
		var update: Dictionary = manager.tick(Vector2.ZERO)
		if update.failed != 0 or update.built > 4:
			printerr("Initial world loading failed")
			quit(1)
			return
	if manager.resident.size() != 16 or manager.get_child_count() != 16:
		printerr("Initial world did not converge")
		quit(1)
		return
	var far: Dictionary = manager.tick(Vector2(10000, 0))
	if far.unloaded != 16 or manager.resident.size() != 0 or manager.get_child_count() != 0:
		printerr("Teleport did not free all distant chunks")
		quit(1)
		return
	for i in range(4):
		var update: Dictionary = manager.tick(Vector2.ZERO)
		if update.failed != 0 or update.built > 4:
			printerr("Return loading failed")
			quit(1)
			return
	if manager.resident.size() != 16 or manager.get_child_count() != 16:
		printerr("Return did not restore all chunks")
		quit(1)
		return
	manager.free()
	print("STREAM_MANAGER_TEST_PASS lifecycle budgets cleanup failed_replacement teleport reload")
	quit(0)
