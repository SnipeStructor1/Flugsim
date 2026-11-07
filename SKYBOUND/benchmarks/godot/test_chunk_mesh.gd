extends SceneTree

func _initialize() -> void:
	var model = load("res://terrain_model.gd").new(41017)
	var builder = load("res://terrain_chunk_mesh.gd").new()
	if builder.build(model, Vector2.ZERO, 256, 15, 2, 32) != null:
		printerr("Non-divisible LOD unexpectedly accepted")
		quit(1)
		return
	if builder.build(model, Vector2.ZERO, 256, 2, 0, 32) != null:
		printerr("Too few cells unexpectedly accepted")
		quit(1)
		return
	var meshes: Array = []
	for lod in range(3):
		var mesh: ArrayMesh = builder.build(model, Vector2.ZERO, 256, 16, lod, 32)
		if mesh == null or mesh.get_surface_count() != 1:
			printerr("Chunk generation failed for LOD ", lod)
			quit(1)
			return
		var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var n := 16 >> lod
		if vertices.size() != n * n * 6 + 4 * n * 12:
			printerr("Unexpected triangle count at LOD ", lod, ": ", vertices.size())
			quit(1)
			return
		# Compare placement heights to actual emitted triangles, including stitched edges.
		for cell_z in range(n):
			for cell_x in range(n):
				var index := (cell_z * n + cell_x) * 6
				var p0: Vector3 = vertices[index]
				var p1: Vector3 = vertices[index + 1]
				var p2: Vector3 = vertices[index + 2]
				var position := p0 * 0.5 + p1 * 0.25 + p2 * 0.25
				var sampled: float = builder.sample_height(model, Vector2.ZERO, 256, 16, lod, position.x, position.z)
				if absf(position.y - sampled) > 0.001:
					printerr("Object sampling differs from emitted triangle")
					quit(1)
					return
		meshes.append(vertices)
	# At each coarse-grid boundary point, fine and coarse meshes share the exact
	# same world-space height; the neighboring chunk must agree as well.
	var adjacent: ArrayMesh = builder.build(model, Vector2(256, 0), 256, 16, 2, 32)
	var other: PackedVector3Array = adjacent.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for z in range(0, 257, 64):
		var expected := Vector3(256, model.height(256, z), z)
		for vertices in [meshes[0], meshes[2], other]:
			var found := false
			for v in vertices:
				if v.distance_to(expected) < 0.001:
					found = true
					break
			if not found:
				printerr("Shared boundary sample missing: ", expected)
				quit(1)
				return
	# Every fine border position must lie on the adjacent coarse border polyline.
	for z in range(0, 257, 16):
		var left: float = builder.sample_height(model, Vector2.ZERO, 256, 16, 0, 256, z)
		var right: float = builder.sample_height(model, Vector2(256, 0), 256, 16, 2, 256, z)
		if absf(left - right) > 0.001:
			printerr("Mismatched fine/coarse edge at z=", z, " left=", left, " right=", right)
			quit(1)
			return
	# Inspect actual emitted vertices, not only the placement interpolator.
	for z in range(0, 257, 16):
		var lower: int = mini((z / 64) * 64, 192)
		var t := float(z - lower) / 64.0
		var expected_y := lerpf(model.height(256, lower), model.height(256, lower + 64), t)
		var actual_y := INF
		for v in meshes[0]:
			if absf(v.x - 256.0) < 0.001 and absf(v.z - z) < 0.001 and absf(v.y - expected_y) < 0.001:
				actual_y = v.y
				break
		if not is_finite(actual_y):
			printerr("Generated fine mesh misses stitched edge at z=", z)
			quit(1)
			return
	# Also test a north/south edge at every fine-grid sample.
	for x in range(0, 257, 16):
		var top: float = builder.sample_height(model, Vector2.ZERO, 256, 16, 0, x, 256)
		var bottom: float = builder.sample_height(model, Vector2(0, 256), 256, 16, 2, x, 256)
		if absf(top - bottom) > 0.001:
			printerr("Mismatched north/south stitched edge at x=", x)
			quit(1)
			return
	print("CHUNK_TEST_PASS lods=3 boundary_samples=5 invalid_input=1")
	quit(0)
