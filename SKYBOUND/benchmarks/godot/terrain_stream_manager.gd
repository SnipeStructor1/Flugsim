extends Node3D

# Standalone lifecycle component; deliberately not enabled in the benchmark scene
# until the geometry/object lifecycle and visual transitions are validated together.
var planner = preload("res://terrain_stream_plan.gd").new()
var builder = preload("res://terrain_chunk_mesh.gd").new()
var model: RefCounted
var terrain_material: Material
var origin := Vector2.ZERO
var chunk_size := 256.0
var grid_width := 1
var grid_height := 1
var cells := 16
var skirt_depth := 32.0
var height_bounds := Vector2(-252, 698)
var max_resident := 16
var build_budget := 1
var resident := {}
var nodes := {}
var async_enabled := false
var flight_vegetation := false
var tree_mesh: Mesh
var fir_mesh: Mesh
var vegetation_noise := FastNoiseLite.new()
var job = null
var pending: Dictionary = {}
var geometry_config: Dictionary = {}

func has_pending() -> bool:
	return job != null and job.started

func _exit_tree() -> void:
	if has_pending():
		job.finish()
		pending = {}

func _plan(camera_xz: Vector2, camera_y: float, budget: int) -> Dictionary:
	return planner.plan(camera_xz, origin, chunk_size, grid_width, grid_height, resident, max_resident, budget, camera_y, height_bounds)

func _install_mesh(operation: Dictionary, mesh: ArrayMesh) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = terrain_material
	if flight_vegetation:
		_add_flight_trees(instance, operation)
	add_child(instance)
	# Replace only after success. The old mesh survives failed LOD changes.
	if nodes.has(operation.key):
		nodes[operation.key].free()
	nodes[operation.key] = instance
	resident[operation.key] = operation.lod

# Load the licensed tree as a shared mesh once; per-chunk instances own no
# independent textures and are released with their parent chunk.
func _load_visual_mesh(path: String) -> Mesh:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(ProjectSettings.globalize_path(path), state) != OK:
		return null
	var scene := document.generate_scene(state)
	if scene == null:
		return null
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	var result: Mesh = (meshes[0] as MeshInstance3D).mesh if not meshes.is_empty() else null
	scene.free()
	return result

func load_flight_tree() -> bool:
	tree_mesh = _load_visual_mesh("res://flight/assets/vegetation/tree.glb")
	fir_mesh = _load_visual_mesh("res://flight/assets/vegetation/alpine_fir.glb")
	vegetation_noise.seed = int(model.seed_value) + 1207
	vegetation_noise.frequency = 0.0017
	vegetation_noise.fractal_octaves = 3
	return tree_mesh != null and fir_mesh != null

func _add_vegetation_batch(parent: MeshInstance3D, source: Mesh, transforms: Array[Transform3D]) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = source
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	parent.add_child(node)

# Deterministic woodland patches and shrubs. Height and slope limit placement;
# the noise field is in world coordinates so groups cross chunk boundaries.
func _vegetation_transforms(operation: Dictionary) -> Dictionary:
	var chunk_origin: Vector2 = operation.origin
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(operation.key) ^ int(model.seed_value)
	var firs: Array[Transform3D] = []
	var broadleaf: Array[Transform3D] = []
	var shrubs: Array[Transform3D] = []
	for i in range(90):
		var x := chunk_origin.x + rng.randf_range(1.0, chunk_size - 1.0)
		var z := chunk_origin.y + rng.randf_range(1.0, chunk_size - 1.0)
		var y: float = builder.sample_height(model, chunk_origin, chunk_size, cells, operation.lod, x, z)
		var slope: float = model.normal(x, z).y
		var patch: float = vegetation_noise.get_noise_2d(x, z)
		var in_lake := absf(x + 400.0) <= 220.0 and absf(z + 400.0) <= 160.0
		if (in_lake and y < 13.0) or y > 330.0 or slope < 0.72:
			continue
		var angle := rng.randf_range(0.0, TAU)
		if patch > -0.10 and y < 270.0 and slope > 0.79:
			var scale := rng.randf_range(0.72, 1.25)
			var basis := Basis(Vector3.UP, angle).scaled(Vector3(scale, scale * rng.randf_range(0.9, 1.2), scale))
			var transform := Transform3D(basis, Vector3(x, y, z))
			if rng.randf() < 0.82:
				firs.append(transform)
			else:
				broadleaf.append(transform)
		elif patch > -0.30 and rng.randf() < 0.7:
			var scale := rng.randf_range(0.10, 0.23)
			var basis := Basis(Vector3.UP, angle).scaled(Vector3(scale * 1.3, scale * 0.65, scale * 1.3))
			shrubs.append(Transform3D(basis, Vector3(x, y, z)))
	return {"firs": firs, "broadleaf": broadleaf, "shrubs": shrubs}

func _add_flight_trees(parent: MeshInstance3D, operation: Dictionary) -> void:
	if tree_mesh == null or fir_mesh == null:
		return
	var groups := _vegetation_transforms(operation)
	_add_vegetation_batch(parent, fir_mesh, groups.firs)
	_add_vegetation_batch(parent, tree_mesh, groups.broadleaf)
	_add_vegetation_batch(parent, tree_mesh, groups.shrubs)

func _tick_async(camera_xz: Vector2, camera_y: float) -> Dictionary:
	var plan: Dictionary = _plan(camera_xz, camera_y, max_resident)
	if not plan.valid:
		return {"valid": false, "unloaded": 0, "built": 0, "failed": 0}
	var result := {"valid": true, "unloaded": 0, "built": 0, "failed": 0, "started": 0, "discarded": 0}
	# Always retire obsolete nodes promptly, even while a worker is busy.
	for key in plan.unload:
		if nodes.has(key):
			nodes[key].free()
			nodes.erase(key)
		resident.erase(key)
		result.unloaded += 1
	if has_pending() and job.is_ready():
		var data: Dictionary = job.take()
		# Camera and resident set may have changed. Commit only a still-desired
		# key and LOD; never resurrect an obsolete chunk after a teleport.
		plan = _plan(camera_xz, camera_y, max_resident)
		var still_needed := false
		for operation in plan.build:
			if operation.key == pending.key and operation.lod == pending.lod:
				still_needed = true
				break
		if still_needed:
			var mesh: ArrayMesh = builder.commit_data(data)
			if mesh == null:
				result.failed += 1
			else:
				_install_mesh(pending, mesh)
				result.built += 1
		else:
			result.discarded += 1
		pending = {}
	if not has_pending() and build_budget > 0:
		plan = _plan(camera_xz, camera_y, max_resident)
		if not plan.build.is_empty():
			if job == null:
				job = load("res://terrain_chunk_job.gd").new()
			var model_seed = model.get("seed_value")
			if model_seed == null:
				result.failed += 1
			else:
				var operation: Dictionary = plan.build[0]
				var error: Error = job.start(int(model_seed), operation.origin, chunk_size, cells, operation.lod, skirt_depth, model.noise_config())
				if error == OK:
					pending = operation
					result.started += 1
				else:
					result.failed += 1
	return result

func tick(camera_xz: Vector2, camera_y: float = 0.0) -> Dictionary:
	if model == null:
		return {"valid": false, "unloaded": 0, "built": 0, "failed": 0}
	# Mesh identity must remain stable while the manager owns chunks or jobs.
	# Recreate the manager to change geometry configuration.
	var current_config := {"model_id": model.get_instance_id(), "noise_config": model.noise_config(), "origin": origin, "chunk_size": chunk_size, "grid_width": grid_width, "grid_height": grid_height, "cells": cells, "skirt_depth": skirt_depth, "async_enabled": async_enabled, "infinite_grid": planner.infinite_grid, "flight_vegetation": flight_vegetation}
	if geometry_config.is_empty():
		geometry_config = current_config
	elif geometry_config != current_config:
		return {"valid": false, "unloaded": 0, "built": 0, "failed": 0}
	if async_enabled:
		return _tick_async(camera_xz, camera_y)
	var plan: Dictionary = _plan(camera_xz, camera_y, build_budget)
	if not plan.valid:
		return {"valid": false, "unloaded": 0, "built": 0, "failed": 0}
	var result := {"valid": true, "unloaded": 0, "built": 0, "failed": 0}
	for key in plan.unload:
		if nodes.has(key):
			nodes[key].free()
			nodes.erase(key)
		resident.erase(key)
		result.unloaded += 1
	for operation in plan.build:
		var mesh: ArrayMesh = builder.build(model, operation.origin, chunk_size, cells, operation.lod, skirt_depth)
		if mesh == null:
			result.failed += 1
			continue
		_install_mesh(operation, mesh)
		result.built += 1
	return result
