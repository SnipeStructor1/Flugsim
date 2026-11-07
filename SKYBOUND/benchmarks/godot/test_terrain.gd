extends SceneTree

func _initialize() -> void:
	var model = load("res://terrain_model.gd").new(41017)
	var same = load("res://terrain_model.gd").new(41017)
	var different = load("res://terrain_model.gd").new(41018)
	var min_height := INF
	var max_height := -INF
	var seed_changes := 0
	for x in range(-1000, 1001, 100):
		for z in range(-1000, 1001, 100):
			var value: float = model.height(x, z)
			if not is_finite(value):
				quit(1)
				return
			if not is_equal_approx(value, same.height(x, z)):
				quit(1)
				return
			if not is_equal_approx(value, different.height(x, z)): seed_changes += 1
			var n: Vector3 = model.normal(x, z)
			if not (n.is_finite() and n.y > 0.0 and absf(n.length() - 1.0) < 0.001):
				quit(1)
				return
			min_height = minf(min_height, value)
			max_height = maxf(max_height, value)
	for x in range(-1024, 1025, 128):
		for z in range(-1024, 1025, 128):
			if absf(model.mesh_height(x, z, 16.0, 1024.0) - model.height(x, z)) > 0.001:
				printerr("Mesh and height mismatch at grid vertex")
				quit(1)
				return
	for t in range(1, 10):
		var fraction := t / 10.0
		if absf(model.mesh_height(fraction * 16.0, (1.0-fraction)*16.0, 16.0, 1024.0) - model.mesh_height(fraction*16.0, (1.0-fraction)*16.0 + 0.0001, 16.0, 1024.0)) > 0.01:
			printerr("Mesh interpolation is discontinuous")
			quit(1)
			return
	if seed_changes <= 400 or max_height - min_height <= 250.0 or model.height(-400, -400) >= 8.0:
		printerr("Invalid terrain: seed changes=", seed_changes, " range=", max_height - min_height, " lake=", model.height(-400, -400))
		quit(1)
		return
	print("TERRAIN_TEST_PASS samples=441 min=", min_height, " max=", max_height)
	quit(0)
