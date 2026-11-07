extends SceneTree

func _initialize() -> void:
	var policy = load("res://terrain_lod.gd").new()
	var cases := [
		[0.0, -1, 0], [319.0, -1, 0], [320.0, -1, 1], [650.0, -1, 2],
		[1200.0, -1, 2], [1201.0, -1, -1], [351.0, 0, 0], [353.0, 0, 1],
		[289.0, 1, 1], [287.0, 1, 0], [681.0, 1, 1], [683.0, 1, 2],
		[619.0, 2, 2], [617.0, 2, 1], [1232.0, 2, 2], [1233.0, 2, -1],
		[1000.0, 0, 2], [10.0, 2, 0], [-1.0, 0, -1], [1.0, 3, -1]
	]
	for c in cases:
		var actual: int = policy.choose(c[0], c[1])
		if actual != c[2]:
			printerr("LOD mismatch: ", c, " got ", actual)
			quit(1)
			return
	var a: float = policy.distance_to_chunk(Vector2(100, 100), Vector2(0, 0), 256.0)
	var b: float = policy.distance_to_chunk(Vector2(356, 256), Vector2(0, 0), 256.0)
	if a != 0.0 or not is_equal_approx(b, 100.0) or not is_inf(policy.distance_to_chunk(Vector2.ZERO, Vector2.ZERO, 0.0)):
		printerr("Chunk bounding-box distance failed")
		quit(1)
		return
	print("LOD_TEST_PASS cases=20 bounding_box_cases=3")
	quit(0)
