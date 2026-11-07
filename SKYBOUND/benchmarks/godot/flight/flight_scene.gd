extends Node3D

var model = preload("res://flight/flight_model.gd").new()
var collision_rules = preload("res://flight/collision_rules.gd").new()
var world: Node3D
var aircraft := Node3D.new()
var camera := Camera3D.new()
var cockpit := Node3D.new()
var left_flaperon: Node3D
var right_flaperon: Node3D
var hud := Label.new()
var camera_mode := 0
var mouse_enabled := false
var mouse_pitch := 0.0
var mouse_roll := 0.0
var wind := Vector3(2, 0, 0)
var crashed := false
var terrain_loading := false
var physics_frames := 0
var initial_position := Vector3.ZERO
var capture_path := ""
var capture_view := "chase"
var test_mode := false
var journey_test := false
var input_test := false
var input_response_seen := false
var capture_started := false
var capture_frame := 30
var camera_test_count := 0
var control_surface_test_seen := false

func _ready() -> void:
	input_test = OS.get_environment("SKYBOUND_FLIGHT_INPUT_TEST") == "1"
	journey_test = OS.get_environment("SKYBOUND_FLIGHT_JOURNEY") == "1"
	test_mode = OS.get_environment("SKYBOUND_FLIGHT_AUTOTEST") == "1" or journey_test
	capture_path = OS.get_environment("SKYBOUND_FLIGHT_SCREENSHOT")
	capture_view = OS.get_environment("SKYBOUND_FLIGHT_CAPTURE_VIEW") if not OS.get_environment("SKYBOUND_FLIGHT_CAPTURE_VIEW").is_empty() else "chase"
	var frame_env := OS.get_environment("SKYBOUND_FLIGHT_CAPTURE_FRAME")
	if frame_env.is_valid_int(): capture_frame = maxi(1, int(frame_env))
	if not capture_path.is_empty() and capture_view == "cockpit": camera_mode = 1
	world = load("res://main.tscn").instantiate()
	# Configure the existing landscape without modifying its implementation.
	world.options.interactive = "true"
	world.options["terrain-stream"] = "true"
	if DisplayServer.get_name() == "headless":
		world.options.interactive = "false"
		world.options.smoke = "true"
	add_child(world)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	if world.camera == null:
		push_error("Landscape initialization failed")
		get_tree().quit(2)
		return
	world.camera.current = false
	var manager = world.stream_manager
	manager.planner.infinite_grid = true
	manager.flight_vegetation = true
	manager.planner.policy.load_distance = 1000.0
	manager.max_resident = 100
	manager.build_budget = 8
	# Populate the vicinity before enabling flight; then cap per-frame work.
	for i in range(4):
		var result: Dictionary = manager.tick(Vector2(0, 700), 300.0)
		if not result.valid or result.failed:
			push_error("Initial flight terrain build failed")
			get_tree().quit(2)
			return
	manager.build_budget = 2
	world.sync_ground_objects()
	apply_flight_atmosphere()
	build_aircraft()
	add_child(aircraft)
	add_child(camera)
	camera.add_child(cockpit)
	build_cockpit()
	camera.fov = 70
	camera.near = 0.2
	camera.far = 5000
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(12, 10)
	backdrop.size = Vector2(820, 150)
	backdrop.color = Color(0.015, 0.025, 0.04, 0.70)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backdrop)
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color.WHITE)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(hud)
	reset_flight()
	if capture_view == "far" and not capture_path.is_empty():
		model.position = Vector3(0, 350, -5000)
		for i in range(4):
			manager.tick(Vector2(model.position.x, model.position.z), model.position.y)
		world.sync_ground_objects()
		aircraft.position = model.position
		update_camera()
	if journey_test:
		model.position.y = 700.0
		initial_position = model.position
		aircraft.position = model.position
		update_camera()
	print("FLIGHT_READY ", JSON.stringify({"position": str(model.position), "controls": "W/S pitch; A/D roll; Q/E yaw; R/F throttle; C camera; M mouse; Backspace reset"}))

func apply_flight_atmosphere() -> void:
	for child in world.get_children():
		if child is WorldEnvironment and child.environment != null and child.environment.sky != null:
			var sky_material := ShaderMaterial.new()
			sky_material.shader = load("res://flight/flight_sky.gdshader")
			child.environment.sky.sky_material = sky_material
			# Retain distance haze on geometry without washing out the entire sky.
			child.environment.fog_sky_affect = 0.0
			child.environment.volumetric_fog_sky_affect = 0.0
			child.environment.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
		elif child is MeshInstance3D and child.mesh is PlaneMesh:
			# Replace only the flight scene's water mesh/material. The underlying
			# landscape and benchmark terrain remain untouched.
			var water_mesh := PlaneMesh.new()
			water_mesh.subdivide_width = 64
			water_mesh.subdivide_depth = 64
			child.mesh = water_mesh
			var water_material := ShaderMaterial.new()
			water_material.shader = load("res://flight/flight_water.gdshader")
			child.material_override = water_material
		elif child is MeshInstance3D and child.position.y > 600.0 and child.scale.x > 100.0:
			# Hide only the benchmark's geometric cloud discs in the flight scene.
			child.visible = false

func build_aircraft() -> void:
	# Load the checked-in GLB directly so a fresh Windows checkout does not
	# depend on the editor having generated an import cache beforehand.
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var path := ProjectSettings.globalize_path("res://flight/assets/raptor.glb")
	if document.append_from_file(path, state) != OK:
		push_error("Could not load Blender aircraft asset")
		get_tree().quit(2)
		return
	var visual := document.generate_scene(state)
	if visual == null:
		push_error("Could not instantiate Blender aircraft asset")
		get_tree().quit(2)
		return
	aircraft.add_child(visual)
	left_flaperon = visual.find_child("Flaperon L", true, false) as Node3D
	right_flaperon = visual.find_child("Flaperon R", true, false) as Node3D
	if left_flaperon == null or right_flaperon == null:
		push_error("Aircraft control surfaces missing from GLB")
		get_tree().quit(2)

func cockpit_box(position_value: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	node.mesh = shape
	node.position = position_value
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.roughness = 0.8
	node.material_override = surface
	cockpit.add_child(node)

func build_cockpit() -> void:
	# Simple placeholder panel and canopy frame; not a replica of actual avionics.
	var frame := Color(0.06, 0.08, 0.09)
	cockpit_box(Vector3(0, -0.95, -2.2), Vector3(3.8, 0.55, 0.35), frame)
	cockpit_box(Vector3(-1.95, 0.1, -2.7), Vector3(0.12, 2.4, 0.12), frame)
	cockpit_box(Vector3(1.95, 0.1, -2.7), Vector3(0.12, 2.4, 0.12), frame)
	cockpit_box(Vector3(0, -0.72, -2.39), Vector3(0.75, 0.24, 0.05), Color(0.08, 0.27, 0.22))
	# Generic cockpit displays, not a reproduction of F-22 avionics.
	for x in [-1.08, 0.0, 1.08]:
		cockpit_box(Vector3(x, -0.96, -1.99), Vector3(0.86, 0.34, 0.035), Color(0.025, 0.06, 0.065))
		cockpit_box(Vector3(x, -0.94, -1.965), Vector3(0.67, 0.018, 0.02), Color(0.13, 0.40, 0.28))

func reset_flight() -> void:
	model = preload("res://flight/flight_model.gd").new()
	var ground: float = world.terrain.mesh_height(0.0, 700.0, float(world.settings.terrain.size_m) / int(world.settings.terrain.grid_cells), float(world.settings.terrain.size_m) / 2.0)
	model.position = Vector3(0, ground + 300, 700)
	model.velocity = Vector3(0, 0, -130)
	initial_position = model.position
	aircraft.position = model.position
	aircraft.quaternion = model.attitude
	crashed = false
	physics_frames = 0
	update_camera()

func axis(positive: Key, negative: Key) -> float:
	return float(Input.is_physical_key_pressed(positive)) - float(Input.is_physical_key_pressed(negative))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			camera_mode = 1 - camera_mode
		elif event.keycode == KEY_BACKSPACE:
			reset_flight()
		elif event.keycode == KEY_M:
			mouse_enabled = not mouse_enabled
			mouse_pitch = 0
			mouse_roll = 0
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_enabled else Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().quit()
	if mouse_enabled and event is InputEventMouseMotion:
		mouse_pitch = clampf(mouse_pitch - event.relative.y * 0.008, -1, 1)
		mouse_roll = clampf(mouse_roll + event.relative.x * 0.008, -1, 1)

func _physics_process(delta: float) -> void:
	if world == null or world.camera == null: return
	var pitch := axis(KEY_S, KEY_W) + mouse_pitch
	var roll := axis(KEY_D, KEY_A) + mouse_roll
	var yaw := axis(KEY_E, KEY_Q)
	var power := axis(KEY_R, KEY_F)
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		roll += Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_X)
		pitch += Input.get_joy_axis(pads[0], JOY_AXIS_LEFT_Y)
		yaw += Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_X)
		power += maxf(0.0, Input.get_joy_axis(pads[0], JOY_AXIS_TRIGGER_RIGHT)) - maxf(0.0, Input.get_joy_axis(pads[0], JOY_AXIS_TRIGGER_LEFT))
	if test_mode:
		pitch = 0.0 if journey_test else (0.1 if physics_frames > 60 and physics_frames < 120 else 0.0)
		roll = 0.0 if journey_test else (0.2 if physics_frames > 120 and physics_frames < 180 else 0.0)
		power = 0.0 if journey_test else 0.1
	var manager = world.stream_manager
	var terrain_update: Dictionary = manager.tick(Vector2(model.position.x, model.position.z), model.position.y)
	if not terrain_update.valid or terrain_update.failed:
		push_error("Flight terrain streaming failed")
		get_tree().quit(2)
		return
	if terrain_update.built > 0 or terrain_update.unloaded > 0:
		world.sync_ground_objects()
	if left_flaperon != null and right_flaperon != null:
		left_flaperon.rotation.x = clampf(-pitch * 0.15 - roll * 0.18, -0.3, 0.3)
		right_flaperon.rotation.x = clampf(-pitch * 0.15 + roll * 0.18, -0.3, 0.3)
		if test_mode and absf(left_flaperon.rotation.x - right_flaperon.rotation.x) > 0.01:
			control_surface_test_seen = true
	terrain_loading = false
	if not crashed:
		var predicted: Vector3 = model.position + model.velocity * delta
		var predicted_key := Vector2i(floori((predicted.x - manager.origin.x) / manager.chunk_size), floori((predicted.z - manager.origin.y) / manager.chunk_size))
		if manager.resident.has(predicted_key):
			model.step(delta, pitch, roll, yaw, power, wind)
		else:
			terrain_loading = true
		var key := Vector2i(floori((model.position.x - manager.origin.x) / manager.chunk_size), floori((model.position.z - manager.origin.y) / manager.chunk_size))
		if manager.resident.has(key):
			var chunk_origin: Vector2 = manager.origin + Vector2(key.x, key.y) * manager.chunk_size
			var floor_y: float = manager.builder.sample_height(world.terrain, chunk_origin, manager.chunk_size, manager.cells, manager.resident[key], model.position.x, model.position.z)
			var water_position: Vector3 = world.vector(world.settings.water.position_m)
			var water_size := Vector2(world.settings.water.size_m[0], world.settings.water.size_m[1])
			floor_y = collision_rules.surface_height(floor_y, model.position.x, model.position.z, water_position, water_size)
			if model.position.y <= floor_y + 2.0:
				crashed = true
		else:
			push_error("Flight outran loaded terrain at %s" % str(model.position))
			get_tree().quit(2)
			return
		aircraft.position = model.position
		aircraft.quaternion = model.attitude
	physics_frames += 1
	if input_test and not input_response_seen and Input.is_physical_key_pressed(KEY_S) and (-Basis(model.attitude).z).y > 0.01:
		input_response_seen = true
		print("FLIGHT_KEY_RESPONSE pitch_up")
	if input_test and input_response_seen and camera_mode == 1:
		print("FLIGHT_INPUT_TEST_PASS physical_key_pitch camera_switch")
		get_tree().quit()
	if test_mode and not journey_test and (physics_frames == 30 or physics_frames == 60):
		var toggle := InputEventKey.new()
		toggle.keycode = KEY_C
		toggle.pressed = true
		_unhandled_input(toggle)
		update_camera()
		if camera_mode != (1 if physics_frames == 30 else 0) or aircraft.visible != (camera_mode == 0) or not camera.current:
			push_error("Flight camera toggle failed")
			get_tree().quit(2)
			return
		camera_test_count += 1
	update_camera()
	var label_mode := "Cockpit" if camera_mode == 1 else "Verfolger"
	hud.text = "SKYBOUND  |  F-22-inspiriert  |  %s\nIAS %.0f km/h    Höhe %.0f m    Schubhebel %.0f%%    Wind %.0f m/s%s\nW/S Nicken  A/D Rollen  Q/E Gieren  R/F Schub\nC Kamera  M Maussteuerung  Rücktaste Neustart  Esc Ende" % [label_mode, model.indicated_airspeed * 3.6, model.position.y, model.throttle * 100.0, wind.length(), "    STRÖMUNGSABRISS" if model.stalled else ""]
	if crashed: hud.text += "\nAUFPRALL – Rücktaste zum Neustart"
	if terrain_loading: hud.text += "\nGelände wird geladen …"
	if journey_test and (model.position.z <= -3500.0 or physics_frames >= 3600 or crashed):
		if crashed or model.position.z > -3500.0:
			push_error("Flight-over-landscape test failed: %s" % str(model.position))
			get_tree().quit(2)
		else:
			print("FLIGHT_JOURNEY_TEST_PASS ", JSON.stringify({"frames": physics_frames, "distance_m": model.position.distance_to(initial_position), "position": str(model.position), "start_altitude_m": 700.0, "resident_chunks": manager.resident.size(), "max_resident": manager.max_resident}))
			get_tree().quit()
	if test_mode and not journey_test and physics_frames >= 240:
		if crashed or camera_test_count != 2 or not control_surface_test_seen or not model.position.is_finite() or model.position.distance_to(initial_position) < 100.0:
			push_error("Flight scene functional test failed")
			get_tree().quit(2)
		else:
			print("FLIGHT_SCENE_TEST_PASS ", JSON.stringify({"frames": physics_frames, "distance_m": model.position.distance_to(initial_position), "position": str(model.position), "camera_switches": camera_test_count, "control_surfaces": control_surface_test_seen}))
			get_tree().quit()

func update_camera() -> void:
	if not capture_path.is_empty() and capture_view == "lake":
		camera.position = Vector3(-400, 80, -230)
		camera.look_at(Vector3(-400, 8, -400), Vector3.UP)
		return
	var orientation := Basis(model.attitude)
	if not capture_path.is_empty() and capture_view == "aircraft":
		aircraft.visible = true
		cockpit.visible = false
		camera.position = model.position + orientation * Vector3(19, 9, 20)
		camera.look_at(model.position, Vector3.UP)
		return
	cockpit.visible = camera_mode == 1
	if camera_mode == 0:
		aircraft.visible = true
		camera.position = model.position + orientation * Vector3(0, 9, 33)
		camera.look_at(model.position + orientation * Vector3(0, 0.7, -7), Vector3.UP)
	else:
		aircraft.visible = false
		camera.position = model.position + orientation * Vector3(0, 1.4, -3.8)
		camera.quaternion = model.attitude

func _process(_delta: float) -> void:
	if not capture_path.is_empty() and not capture_started and physics_frames >= capture_frame:
		capture_started = true
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		if crashed:
			push_error("Aircraft crashed before screenshot")
			get_tree().quit(2)
			return
		if image == null or image.save_png(capture_path) != OK:
			push_error("Flight screenshot failed")
			get_tree().quit(2)
		else:
			print("FLIGHT_CAPTURE_OK ", capture_path)
			get_tree().quit()
