extends SceneTree

func _initialize() -> void:
	var model = load("res://terrain_model.gd").new(41017)
	var builder = load("res://terrain_chunk_mesh.gd").new()
	if builder.build(model, Vector2.ZERO, 256, 15, 2, 32) != null:
		printerr("Non-divisible LOD unexpectedly accepted")
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
		if vertices.size() != n * n * 6 + 4 * n * 6:
			printerr("Unexpected triangle count at LOD ", lod, ": ", vertices.size())
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
	print("CHUNK_TEST_PASS lods=3 boundary_samples=5 invalid_input=1")
	quit(0)
