extends SceneTree

# Visual QC for the 25 checked-in models, without relying on editor imports.
var visual_root := Node3D.new()
var capture_path := ""
var frames := 0

func _initialize() -> void:
	capture_path = OS.get_environment("SKYBOUND_BUSH_SHOWCASE")
	if capture_path.is_empty():
		printerr("SKYBOUND_BUSH_SHOWCASE must be set")
		quit(2)
		return
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.add_child(visual_root)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.26, 0.31, 0.34)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.85, 0.9)
	environment.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = environment
	visual_root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	visual_root.add_child(sun)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(21, 21)
	var floor := MeshInstance3D.new()
	floor.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.22, 0.13)
	floor_material.roughness = 0.95
	floor.material_override = floor_material
	visual_root.add_child(floor)
	for i in range(25):
		var asset_path := "res://flight/assets/vegetation/bushes/bush_%02d.glb" % i
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		if document.append_from_file(ProjectSettings.globalize_path(asset_path), state) != OK:
			printerr("Missing or invalid model: ", asset_path)
			quit(2)
			return
		var bush := document.generate_scene(state)
		if bush == null:
			printerr("Could not instantiate: ", asset_path)
			quit(2)
			return
		bush.position = Vector3((i % 5 - 2) * 3.2, 0, (i / 5 - 2) * 3.2)
		visual_root.add_child(bush)
		var label := Label3D.new()
		label.text = "%02d" % i
		label.font_size = 44
		label.pixel_size = 0.008
		label.position = bush.position + Vector3(0, 0.08, 1.25)
		label.modulate = Color(0.95, 0.95, 0.88)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		visual_root.add_child(label)
	var camera := Camera3D.new()
	visual_root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.look_at_from_position(Vector3(1, 18, 24), Vector3(0, 0.5, 0), Vector3.UP)
	camera.current = true
	print("BUSH_SHOWCASE_READY count=25")

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 8:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null or image.save_png(capture_path) != OK:
			printerr("Screenshot failed")
			quit(2)
		else:
			print("BUSH_SHOWCASE_CAPTURED ", capture_path)
			quit(0)
	return false
