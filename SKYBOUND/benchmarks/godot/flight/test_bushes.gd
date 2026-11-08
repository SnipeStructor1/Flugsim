extends SceneTree

func _initialize() -> void:
	var manager = load("res://terrain_stream_manager.gd").new()
	manager.model = load("res://terrain_model.gd").new(41017)
	manager.chunk_size = 256.0
	manager.cells = 16
	if not manager.load_flight_tree() or manager.bush_meshes.size() != 25:
		printerr("Could not load all 25 shrub assets")
		manager.free()
		quit(1)
		return
	var fingerprints := {}
	for index in range(manager.BUSH_VARIANT_COUNT):
		var path := "res://flight/assets/vegetation/bushes/bush_%02d.glb" % index
		var digest := FileAccess.get_sha256(path)
		var bounds: AABB = manager.bush_meshes[index].get_aabb()
		if digest.is_empty() or fingerprints.has(digest) or bounds.size.x < 0.1 or bounds.size.y < 0.1 or bounds.size.z < 0.1:
			printerr("Invalid or duplicate shrub asset: ", path, " bounds=", bounds)
			manager.free()
			quit(1)
			return
		fingerprints[digest] = true
	# Check that the grouped instances really refer to the matching variant,
	# not just that their transforms were generated and classified.
	var batch_op := {"key": Vector2i(0, -20), "origin": Vector2(0, -5120), "lod": 0}
	var groups: Array = manager._bush_transforms(batch_op)
	var chunk := MeshInstance3D.new()
	manager._add_flight_trees(chunk, batch_op)
	for index in range(25):
		var node := chunk.get_node_or_null("Bush_%02d" % index) as MultiMeshInstance3D
		if (not groups[index].is_empty() and (node == null or node.multimesh.mesh != manager.bush_meshes[index])) or (groups[index].is_empty() and node != null):
			printerr("Wrong shrub asset assigned to instance group ", index)
			chunk.free()
			manager.free()
			quit(1)
			return
	chunk.free()
	var seen := {}
	var count := 0
	for z in range(-4, 5):
		for x in range(-4, 5):
			var operation := {"key": Vector2i(x, z), "origin": Vector2(x * 256, z * 256), "lod": 0}
			var first: Array = manager._bush_transforms(operation)
			var second: Array = manager._bush_transforms(operation)
			if first.size() != 25 or first != second:
				printerr("Bush placement is nondeterministic")
				manager.free()
				quit(1)
				return
			for variant in range(25):
				for transform in first[variant]:
					var t: Transform3D = transform
					var h: float = manager.builder.sample_height(manager.model, operation.origin, 256, 16, 0, t.origin.x, t.origin.z)
					var in_lake := absf(t.origin.x + 400.0) <= 220.0 and absf(t.origin.z + 400.0) <= 160.0
					if absf(h - t.origin.y) > 0.01 or (in_lake and h < 13.0) or h > 330.0 or manager.model.normal(t.origin.x, t.origin.z).y < 0.72:
						printerr("Shrub placement is outside its terrain habitat")
						manager.free()
						quit(1)
						return
					seen[variant] = true
					count += 1
	manager.free()
	if count < 100 or seen.size() != 25:
		printerr("Shrub placement insufficiently varied: ", count, ", variants=", seen.size())
		quit(1)
		return
	print("BUSH_TEST_PASS assets=", fingerprints.size(), " placements=", count, " variants=", seen.size(), " deterministic contact habitat")
	quit(0)
