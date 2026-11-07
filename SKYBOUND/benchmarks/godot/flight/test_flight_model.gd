extends SceneTree

func _initialize() -> void:
	var script = load("res://flight/flight_model.gd")
	var model = script.new()
	if model.lift_coefficient(deg_to_rad(8.0)) <= model.lift_coefficient(0.0) or model.lift_coefficient(deg_to_rad(40.0)) >= model.lift_coefficient(deg_to_rad(15.0)):
		printerr("Lift/stall curve invalid")
		quit(1)
		return
	var initial: Vector3 = model.position
	for i in range(600):
		model.step(1.0/60.0, 0.0, 0.0, 0.0, 0.2)
		if not model.position.is_finite() or not model.velocity.is_finite() or not model.attitude.is_finite():
			printerr("Non-finite flight state")
			quit(1)
			return
	if model.position.distance_to(initial) < 100.0 or model.throttle > 1.0 or model.throttle < 0.0:
		printerr("Aircraft did not advance or throttle escaped its limits")
		quit(1)
		return
	var controlled = script.new()
	for i in range(60): controlled.step(1.0/60.0, 0.5, 0.7, 0.2, 0.0)
	if controlled.attitude.angle_to(Quaternion.IDENTITY) < 0.05:
		printerr("Control inputs did not change attitude")
		quit(1)
		return
	var roll_test = script.new()
	var yaw_test = script.new()
	var pitch_test = script.new()
	for i in range(60):
		roll_test.step(1.0/60.0, 0, 1, 0, 0)
		yaw_test.step(1.0/60.0, 0, 0, 1, 0)
		pitch_test.step(1.0/60.0, 1, 0, 0, 0)
	if Basis(roll_test.attitude).x.y >= 0.0 or (-Basis(yaw_test.attitude).z).x <= 0.0 or (-Basis(pitch_test.attitude).z).y <= 0.0:
		printerr("Control axes do not match right-bank, right-yaw and pitch-up conventions")
		quit(1)
		return
	var still_air = script.new()
	var crosswind = script.new()
	still_air.step(1.0/60.0, 0, 0, 0, 0, Vector3.ZERO)
	crosswind.step(1.0/60.0, 0, 0, 0, 0, Vector3(12, 0, 0))
	if still_air.velocity.distance_to(crosswind.velocity) < 0.0001:
		printerr("Wind did not affect aerodynamic motion")
		quit(1)
		return
	var collision = load("res://flight/collision_rules.gd").new()
	var water := Vector3(-400, 8, -400)
	var size := Vector2(440, 320)
	if collision.surface_height(-20, -400, -400, water, size) != 8.0 or collision.surface_height(20, -400, -400, water, size) != 20.0 or collision.surface_height(-20, 0, 0, water, size) != -20.0:
		printerr("Flight water-surface collision policy failed")
		quit(1)
		return
	var unchanged: Vector3 = controlled.position
	controlled.step(-1.0, 1, 1, 1, 1)
	if controlled.position != unchanged:
		printerr("Invalid timestep modified state")
		quit(1)
		return
	print("FLIGHT_MODEL_TEST_PASS lift stall motion control finite_state timestep")
	quit(0)
