extends SceneTree

var job
var started_us: int
var phase := 0

func _initialize() -> void:
	job = load("res://terrain_chunk_job.gd").new()
	if job.start(41017, Vector2(-256, 0), 256, 16, 1, 32) != OK or job.start(1, Vector2.ZERO, 256, 16, 0, 32) != ERR_ALREADY_IN_USE:
		printerr("Thread startup or duplicate-job protection failed")
		quit(1)
		return
	started_us = Time.get_ticks_usec()

func _process(_delta: float) -> bool:
	if Time.get_ticks_usec() - started_us > 10000000:
		printerr("Worker did not finish")
		job.finish()
		quit(1)
		return false
	if not job.is_ready(): return false
	var data: Dictionary = job.take()
	if phase == 0:
		var expected: Dictionary = load("res://terrain_chunk_mesh.gd").new().build_data(load("res://terrain_model.gd").new(41017), Vector2(-256, 0), 256, 16, 1, 32)
		if data.is_empty() or data.vertices != expected.vertices or data.normals != expected.normals:
			printerr("Worker geometry differs from main-thread calculation")
			quit(1)
			return false
		if job.start(41018, Vector2.ZERO, 256, 2, 0, 32) != OK:
			printerr("Worker could not be reused")
			quit(1)
			return false
		phase = 1
	else:
		if not data.is_empty() or job.started:
			printerr("Invalid worker job or lifecycle mishandled")
			quit(1)
			return false
		print("CHUNK_JOB_TEST_PASS identical_data duplicate_guard reuse invalid_input")
		quit(0)
	return false
