extends SceneTree

func _initialize() -> void:
	var planner = load("res://terrain_stream_plan.gd").new()
	var resident := {}
	var first: Dictionary = planner.plan(Vector2(10, 10), Vector2.ZERO, 256, 4, 4, resident, 3, 2)
	if not first.valid or first.build.size() != 2 or first.unload.size() != 0 or not resident.is_empty() or first.build[0].key != Vector2i(0, 0):
		printerr("Initial budget, priority or mutation failure")
		quit(1)
		return
	for operation in first.build: resident[operation.key] = operation.lod
	var next: Dictionary = planner.plan(Vector2(10, 10), Vector2.ZERO, 256, 4, 4, resident, 3, 2)
	if next.build.size() != 1 or not next.unload.is_empty():
		printerr("Resident budget failed")
		quit(1)
		return
	for operation in next.build: resident[operation.key] = operation.lod
	var moved: Dictionary = planner.plan(Vector2(1000, 1000), Vector2.ZERO, 256, 4, 4, resident, 3, 1)
	if moved.build.size() != 1 or moved.unload.is_empty():
		printerr("Camera movement did not unload/build under budget")
		quit(1)
		return
	for key in moved.unload: resident.erase(key)
	for operation in moved.build: resident[operation.key] = operation.lod
	if resident.size() > 3:
		printerr("Exceeded max resident chunks")
		quit(1)
		return
	var no_budget: Dictionary = planner.plan(Vector2.ZERO, Vector2.ZERO, 256, 4, 4, {}, 3, 0)
	var invalid: Dictionary = planner.plan(Vector2.ZERO, Vector2.ZERO, 0, 4, 4, {}, 3, 1)
	if not no_budget.valid or not no_budget.build.is_empty() or invalid.valid:
		printerr("Zero budget or invalid configuration mishandled")
		quit(1)
		return
	var high: Dictionary = planner.plan(Vector2(100, 100), Vector2.ZERO, 256, 1, 1, {}, 1, 1, 1250.0, Vector2(-252, 698))
	var low: Dictionary = planner.plan(Vector2(100, 100), Vector2.ZERO, 256, 1, 1, {}, 1, 1, 200.0, Vector2(-252, 698))
	var bad_bounds: Dictionary = planner.plan(Vector2.ZERO, Vector2.ZERO, 256, 1, 1, {}, 1, 1, 0.0, Vector2(5, -5))
	if not high.valid or high.build.size() != 1 or high.build[0].lod != 1 or low.build[0].lod != 0 or bad_bounds.valid:
		printerr("Altitude-aware planning or invalid bounds failed")
		quit(1)
		return
	var extreme: Dictionary = planner.plan(Vector2(100, 100), Vector2.ZERO, 256, 1, 1, {}, 1, 1, 10000.0, Vector2(-252, 698))
	if not extreme.valid or extreme.build.size() != 1 or extreme.build[0].lod != 2:
		printerr("Terrain directly below a high-altitude camera disappeared")
		quit(1)
		return
	print("STREAM_PLAN_TEST_PASS priority budget eviction purity invalid_input")
	quit(0)
