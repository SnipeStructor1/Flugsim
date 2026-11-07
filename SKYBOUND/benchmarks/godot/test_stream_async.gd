extends SceneTree

class FailingCommit:
	extends RefCounted
	func commit_data(_data: Dictionary) -> ArrayMesh:
		return null

var manager
var phase := 0
var started_us: int
var discarded := 0
var original_nodes := {}

func _initialize() -> void:
	manager = load("res://terrain_stream_manager.gd").new()
	root.add_child(manager)
	manager.model = load("res://terrain_model.gd").new(41017)
	manager.grid_width = 4
	manager.grid_height = 4
	manager.max_resident = 3
	manager.build_budget = 1
	manager.async_enabled = true
	var first: Dictionary = manager.tick(Vector2.ZERO)
	if first.started != 1 or not manager.has_pending():
		printerr("Async manager did not start its worker")
		quit(1)
		return
	manager.model.terrain_noise.frequency = 0.004
	if manager.tick(Vector2.ZERO).valid:
		printerr("Noise configuration changed while a worker was active")
		manager.free()
		quit(1)
		return
	manager.model.terrain_noise.frequency = 0.0018
	manager.chunk_size = 512
	if manager.tick(Vector2.ZERO).valid:
		printerr("Geometry configuration changed while a worker was active")
		manager.free()
		quit(1)
		return
	manager.chunk_size = 256
	started_us = Time.get_ticks_usec()

func _process(_delta: float) -> bool:
	if Time.get_ticks_usec() - started_us > 15000000:
		printerr("Async streaming test timed out in phase ", phase)
		manager.free()
		quit(1)
		return false
	if phase == 0:
		# Move beyond loading radius before taking the first result.
		var update: Dictionary = manager.tick(Vector2(10000, 0))
		discarded += int(update.discarded)
		if update.failed != 0 or not manager.resident.is_empty():
			printerr("Obsolete asynchronous chunk was installed")
			manager.free()
			quit(1)
			return false
		if not manager.has_pending():
			if discarded != 1:
				printerr("Stale worker output was not explicitly discarded")
				manager.free()
				quit(1)
				return false
			phase = 1
	elif phase == 1:
		var update: Dictionary = manager.tick(Vector2.ZERO)
		if update.failed != 0 or manager.resident.size() > 3 or manager.get_child_count() != manager.resident.size():
			printerr("Async build or resident limit failed")
			manager.free()
			quit(1)
			return false
		if manager.resident.size() == 3 and not manager.has_pending():
			original_nodes = manager.nodes.duplicate()
			manager.builder = FailingCommit.new()
			phase = 2
	else:
		# Altitude changes desired LOD without changing the desired chunk set.
		var update: Dictionary = manager.tick(Vector2.ZERO, 1250.0)
		if update.failed > 0:
			for key in original_nodes:
				if not manager.nodes.has(key) or manager.nodes[key] != original_nodes[key] or not is_instance_valid(original_nodes[key]):
					printerr("Failed async mesh commit replaced an existing mesh")
					manager.free()
					quit(1)
					return false
			manager.free() # joins the single pending worker, if any
			print("STREAM_ASYNC_TEST_PASS stale_discard budget failed_commit cleanup")
			quit(0)
	return false
