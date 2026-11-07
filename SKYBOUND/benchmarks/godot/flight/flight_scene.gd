extends Node3D

var model = preload("res://flight/flight_model.gd").new()
var collision_rules = preload("res://flight/collision_rules.gd").new()
var world: Node3D
var aircraft := Node3D.new()
var camera := Camera3D.new()
var hud := Label.new()
var camera_mode := 0
var mouse_enabled := false
var mouse_pitch := 0.0
var mouse_roll := 0.0
var wind := Vector3(2, 0, 0)
var crashed := false
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
	if DisplayServer.get_name() == "headless":
		world.options.interactive = "false"
		world.options.smoke = "true"
	add_child(world)
	if world.camera == null:
		push_error("Landscape initialization failed")
		get_tree().quit(2)
		return
	world.camera.current = false
	apply_flight_atmosphere()
	build_aircraft()
	add_child(aircraft)
	add_child(camera)
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

func part(mesh: Mesh, pos: Vector3, scale_value: Vector3, color: Color, roughness := 0.45) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale_value
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.roughness = roughness
	surface.metallic = 0.15
	node.material_override = surface
	aircraft.add_child(node)
	return node

func build_aircraft() -> void:
	var white := Color(0.78, 0.82, 0.84)
	var blue := Color(0.06, 0.18, 0.30)
	var body := part(CapsuleMesh.new(), Vector3.ZERO, Vector3(2.1, 5.8, 2.1), white)
	body.rotation_degrees.x = 90
	part(BoxMesh.new(), Vector3(0, 0, 0.4), Vector3(14, 0.28, 2.4), white)
	part(BoxMesh.new(), Vector3(0, 0.16, 0.9), Vector3(13.4, 0.12, 0.3), blue)
	part(BoxMesh.new(), Vector3(0, 0.5, 4.3), Vector3(5.0, 0.20, 1.1), white)
	part(BoxMesh.new(), Vector3(0, 1.25, 4.3), Vector3(0.20, 2.1, 1.4), blue)
	part(SphereMesh.new(), Vector3(0, 0.9, -1.1), Vector3(1.65, 1.0, 2.6), Color(0.06, 0.15, 0.20), 0.15)
	part(BoxMesh.new(), Vector3(0, 0, -5.7), Vector3(3.0, 0.10, 0.13), Color(0.10, 0.10, 0.10))

func reset_flight() -> void:
	model = preload("res://flight/flight_model.gd").new()
	var ground: float = world.terrain.mesh_height(0.0, 700.0, float(world.settings.terrain.size_m) / int(world.settings.terrain.grid_cells), float(world.settings.terrain.size_m) / 2.0)
	model.position = Vector3(0, ground + 180, 700)
	model.velocity = Vector3(0, 0, -55)
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
	if not crashed:
		model.step(delta, pitch, roll, yaw, power, wind)
		var half: float = float(world.settings.terrain.size_m) / 2.0
		if absf(model.position.x) <= half and absf(model.position.z) <= half:
			var floor_y: float = world.terrain.mesh_height(model.position.x, model.position.z, float(world.settings.terrain.size_m) / int(world.settings.terrain.grid_cells), half)
			var water_position: Vector3 = world.vector(world.settings.water.position_m)
			var water_size := Vector2(world.settings.water.size_m[0], world.settings.water.size_m[1])
			floor_y = collision_rules.surface_height(floor_y, model.position.x, model.position.z, water_position, water_size)
			if model.position.y <= floor_y + 2.0:
				crashed = true
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
	hud.text = "SKYBOUND  |  %s\nGeschwindigkeit %.0f km/h    Höhe %.0f m    Schub %.0f%%    Wind %.0f m/s%s\nW/S Nicken  A/D Rollen  Q/E Gieren  R/F Schub\nC Kamera  M Maussteuerung  Rücktaste Neustart  Esc Ende" % [label_mode, model.velocity.length() * 3.6, model.position.y, model.throttle * 100.0, wind.length(), "    STRÖMUNGSABRISS" if model.stalled else ""]
	if crashed: hud.text += "\nAUFPRALL – Rücktaste zum Neustart"
	if absf(model.position.x) > float(world.settings.terrain.size_m)/2.0 or absf(model.position.z) > float(world.settings.terrain.size_m)/2.0:
		hud.text += "\nGeländeausschnitt verlassen – bitte wenden"
	if journey_test and (model.position.z <= -750.0 or physics_frames >= 3600 or crashed):
		if crashed or model.position.z > -750.0 or absf(model.position.x) > float(world.settings.terrain.size_m)/2.0:
			push_error("Flight-over-landscape test failed: %s" % str(model.position))
			get_tree().quit(2)
		else:
			print("FLIGHT_JOURNEY_TEST_PASS ", JSON.stringify({"frames": physics_frames, "distance_m": model.position.distance_to(initial_position), "position": str(model.position), "start_altitude_m": 700.0}))
			get_tree().quit()
	if test_mode and not journey_test and physics_frames >= 240:
		if crashed or camera_test_count != 2 or not model.position.is_finite() or model.position.distance_to(initial_position) < 100.0:
			push_error("Flight scene functional test failed")
			get_tree().quit(2)
		else:
			print("FLIGHT_SCENE_TEST_PASS ", JSON.stringify({"frames": physics_frames, "distance_m": model.position.distance_to(initial_position), "position": str(model.position), "camera_switches": camera_test_count}))
			get_tree().quit()

func update_camera() -> void:
	if not capture_path.is_empty() and capture_view == "lake":
		camera.position = Vector3(-400, 80, -230)
		camera.look_at(Vector3(-400, 8, -400), Vector3.UP)
		return
	var orientation := Basis(model.attitude)
	if camera_mode == 0:
		aircraft.visible = true
		camera.position = model.position + orientation * Vector3(0, 7, 25)
		camera.look_at(model.position + orientation * Vector3(0, 0.7, -7), Vector3.UP)
	else:
		aircraft.visible = false
		camera.position = model.position + orientation * Vector3(0, 1.4, -0.4)
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
