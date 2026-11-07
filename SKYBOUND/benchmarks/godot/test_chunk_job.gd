extends SceneTree

var job
var started_us: int
var phase := 0
var configured_model

func _initialize() -> void:
	job = load("res://terrain_chunk_job.gd").new()
	configured_model = load("res://terrain_model.gd").new(41017)
	configured_model.terrain_noise.frequency = 0.004
	configured_model.ridge_noise.fractal_gain = 0.7
	var snapshot: Dictionary = configured_model.noise_config()
	for group in ["terrain", "ridge"]:
		for key in snapshot[group]:
			if snapshot[group][key] == null:
				printerr("Unknown FastNoiseLite snapshot property: ", key)
				quit(1)
				return
	if job.start(41017, Vector2(-256, 0), 256, 16, 1, 32, configured_model.noise_config()) != OK or job.start(1, Vector2.ZERO, 256, 16, 0, 32) != ERR_ALREADY_IN_USE:
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
		var expected: Dictionary = load("res://terrain_chunk_mesh.gd").new().build_data(configured_model, Vector2(-256, 0), 256, 16, 1, 32)
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
		print("CHUNK_JOB_TEST_PASS custom_noise_identical duplicate_guard reuse invalid_input")
		quit(0)
	return false
