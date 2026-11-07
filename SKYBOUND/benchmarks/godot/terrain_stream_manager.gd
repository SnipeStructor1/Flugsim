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
var tree_mesh: CylinderMesh
var tree_material: StandardMaterial3D
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

# Flight-only decorative trees outside the original authored 2 km area. Their
# seed and transforms depend only on chunk identity, so reloads are repeatable.
func _add_flight_trees(parent: MeshInstance3D, operation: Dictionary) -> void:
	var chunk_origin: Vector2 = operation.origin
	if chunk_origin.x >= -1024.0 and chunk_origin.x < 1024.0 and chunk_origin.y >= -1024.0 and chunk_origin.y < 1024.0:
		return
	if tree_mesh == null:
		tree_mesh = CylinderMesh.new()
		tree_mesh.top_radius = 0.0
		tree_mesh.bottom_radius = 4.0
		tree_mesh.height = 15.0
		tree_mesh.radial_segments = 6
		tree_material = StandardMaterial3D.new()
		tree_material.albedo_color = Color(0.14, 0.23, 0.07)
		tree_material.roughness = 0.95
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(operation.key) ^ int(model.seed_value)
	var transforms: Array[Transform3D] = []
	for i in range(12):
		var x := chunk_origin.x + rng.randf_range(1.0, chunk_size - 1.0)
		var z := chunk_origin.y + rng.randf_range(1.0, chunk_size - 1.0)
		var y: float = builder.sample_height(model, chunk_origin, chunk_size, cells, operation.lod, x, z)
		if y > 10.0 and y < 350.0:
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y + 7.5, z)))
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = tree_mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.material_override = tree_material
	parent.add_child(node)

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
