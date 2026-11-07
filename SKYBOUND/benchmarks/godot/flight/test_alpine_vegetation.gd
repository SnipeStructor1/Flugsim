extends SceneTree

func _initialize() -> void:
	var manager = load("res://terrain_stream_manager.gd").new()
	manager.model = load("res://terrain_model.gd").new(41017)
	manager.cells = 16
	manager.chunk_size = 256.0
	if not manager.load_flight_tree():
		printerr("Alpine vegetation assets unavailable")
		quit(1)
		return
	var count := 0
	for z in range(-2, 3):
		for x in range(-2, 3):
			var operation := {"key": Vector2i(x, z), "origin": Vector2(x * 256, z * 256), "lod": 0}
			var first: Dictionary = manager._vegetation_transforms(operation)
			var second: Dictionary = manager._vegetation_transforms(operation)
			for group in ["firs", "broadleaf", "shrubs"]:
				if first[group] != second[group]:
					printerr("Vegetation changed after regeneration")
					manager.free()
					quit(1)
					return
				for transform in first[group]:
					var t: Transform3D = transform
					var expected: float = manager.builder.sample_height(manager.model, operation.origin, 256, 16, 0, t.origin.x, t.origin.z)
					var in_lake := absf(t.origin.x + 400.0) <= 220.0 and absf(t.origin.z + 400.0) <= 160.0
					if absf(t.origin.y - expected) > 0.01 or (in_lake and t.origin.y < 13.0) or t.origin.y > 330.0 or manager.model.normal(t.origin.x, t.origin.z).y < 0.72:
						printerr("Vegetation altitude, slope or terrain contact failed")
						manager.free()
						quit(1)
						return
					count += 1
	manager.free()
	if count < 10:
		printerr("Test region did not generate vegetation")
		quit(1)
		return
	print("ALPINE_VEGETATION_TEST_PASS count=", count, " deterministic terrain_contact altitude slope")
	quit(0)
