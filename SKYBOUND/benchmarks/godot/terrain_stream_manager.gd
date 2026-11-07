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
var max_resident := 16
var build_budget := 1
var resident := {}
var nodes := {}

func tick(camera_xz: Vector2) -> Dictionary:
	if model == null:
		return {"valid": false, "unloaded": 0, "built": 0, "failed": 0}
	var plan: Dictionary = planner.plan(camera_xz, origin, chunk_size, grid_width, grid_height, resident, max_resident, build_budget)
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
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.material_override = terrain_material
		add_child(instance)
		# Replace only after success. The old mesh survives failed LOD changes.
		if nodes.has(operation.key):
			nodes[operation.key].free()
		nodes[operation.key] = instance
		resident[operation.key] = operation.lod
		result.built += 1
	return result
