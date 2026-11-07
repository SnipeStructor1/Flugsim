extends Node3D

var settings: Dictionary
var options := {"profile": "High", "width": "1920", "height": "1080", "warmup": "30", "duration": "60", "output": "", "smoke": "false", "interactive": "false", "render-check": "false", "capture": ""}
var camera: Camera3D
var output: FileAccess
var started_us: int
var previous_us: int
var frame_index := 0
var recorded := 0
var manual := false
var yaw := 0.0
var pitch := 0.0
var smoke := false
var sunlight: DirectionalLight3D
var render_check := false
var terrain = preload("res://terrain_model.gd").new()

func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(2)

func _ready() -> void:
	set_process(false)
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=", true, 1)
		if pair.size() != 2 or not options.has(pair[0]):
			fail("Unknown argument: " + argument)
			return
		options[pair[0]] = pair[1]
	smoke = options.smoke == "true"
	render_check = options["render-check"] == "true"
	if smoke and render_check:
		fail("Smoke and render-check are separate modes")
		return
	var manifest_path := ProjectSettings.globalize_path("res://../../assets/shared/scene.json")
	settings = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if settings != null and settings.has("seed"):
		terrain = preload("res://terrain_model.gd").new(int(settings.seed))
	if settings.is_empty() or not settings.profiles.has(options.profile):
		fail("Missing scene manifest or unknown profile")
		return
	if float(options.warmup) < 0.0 or float(options.duration) <= 0.0:
		fail("Invalid timing")
		return
	var resolution := [int(options.width), int(options.height)]
	var supported := false
	for size in settings.resolutions:
		if int(size[0]) == resolution[0] and int(size[1]) == resolution[1]: supported = true
	if not supported:
		fail("Unsupported resolution")
		return
	if not smoke and DisplayServer.get_name() == "headless":
		fail("Headless renderer cannot produce a graphics benchmark; use --smoke=true")
		return
	if not smoke and RenderingServer.get_current_rendering_method() != "gl_compatibility" and RenderingServer.get_current_rendering_method() != "forward_plus":
		fail("Unsupported rendering method")
		return
	if not smoke and RenderingServer.get_current_rendering_method() != "forward_plus":
		fail("Measured runs require Forward+; launch with --rendering-method forward_plus")
		return
	if not smoke and options.interactive != "true" and options["render-check"] != "true" and options.output.is_empty():
		fail("Measured runs require --output=absolute/path.csv")
		return
	DisplayServer.window_set_size(Vector2i(resolution[0], resolution[1]))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().scaling_3d_scale = 1.0
	var profile: Dictionary = settings.profiles[options.profile]
	RenderingServer.directional_shadow_atlas_set_size(int(profile.shadow_atlas), true)
	get_viewport().use_taa = bool(profile.taa) and not smoke
	build_scene(profile)
	if not options.output.is_empty() and not smoke and options["render-check"] != "true":
		output = FileAccess.open(options.output, FileAccess.WRITE)
		if output == null:
			fail("Cannot create CSV")
			return
		output.store_csv_line(["frame", "elapsed_s", "frametime_ms"])
	if not smoke:
		await RenderingServer.frame_post_draw
	started_us = Time.get_ticks_usec()
	previous_us = started_us
	set_process(true)
	print("SKYBOUND_READY ", JSON.stringify({"smoke": smoke, "render_check": options["render-check"] == "true", "profile": options.profile, "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info().string, "width": resolution[0], "height": resolution[1], "upscaling": "native", "frame_generation": false}))

func terrain_height(x: float, z: float) -> float:
	return terrain.height(x, z)

func material(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func mesh_instance(mesh: Mesh, position: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale_value
	instance.material_override = mat
	add_child(instance)
	return instance

func build_scene(profile: Dictionary) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := PhysicalSkyMaterial.new()
	atmosphere.rayleigh_coefficient = 2.0
	sky.sky_material = atmosphere
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_density = 0.00035
	if not smoke:
		environment.ssao_enabled = bool(profile.ssao)
		environment.ssr_enabled = bool(profile.ssr)
		environment.volumetric_fog_enabled = bool(profile.volumetric_fog)
		environment.volumetric_fog_density = 0.008
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sunlight = sun
	sun.rotation_degrees = vector(settings.sun.rotation_degrees)
	sun.light_energy = float(settings.sun.energy)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 1800.0
	add_child(sun)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := int(settings.terrain.grid_cells)
	var step := float(settings.terrain.size_m) / cells
	for z in range(cells):
		for x in range(cells):
			for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)]:
				var px: float = (x + corner.x - cells / 2.0) * step
				var pz: float = (z + corner.y - cells / 2.0) * step
				var h := terrain_height(px, pz)
				surface.set_normal(terrain.normal(px, pz))
				surface.add_vertex(Vector3(px,h,pz))
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = load("res://terrain_material.gdshader")
	mesh_instance(surface.commit(),Vector3.ZERO,Vector3.ONE,terrain_material)
	mesh_instance(PlaneMesh.new(),vector(settings.water.position_m),Vector3(float(settings.water.size_m[0])/2.0,1,float(settings.water.size_m[1])/2.0),material(Color(0.03,0.16,0.22),0.13,0.15))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(settings.seed)
	var rock := SphereMesh.new()
	rock.radial_segments = 12
	rock.rings = 6
	var grass := material(Color(0.14,0.23,0.07),0.95)
	var stone := material(Color(0.38,0.36,0.34),0.85)
	for i in range(240):
		var x := rng.randf_range(-900,900)
		var z := rng.randf_range(-900,900)
		var h := terrain.mesh_height(x,z,step,float(settings.terrain.size_m)/2.0)
		if h < 10: continue
		if i % 3 == 0:
			mesh_instance(rock,Vector3(x,h+2,z),Vector3(8,5,7),stone)
		else:
			var tree := CylinderMesh.new()
			tree.top_radius = 0.0
			tree.bottom_radius = 4.0
			tree.height = 15.0
			mesh_instance(tree,Vector3(x,h+7.5,z),Vector3.ONE,grass)
	for i in range(8):
		var x := -180.0 + i * 30
		var z := -120.0
		mesh_instance(BoxMesh.new(),Vector3(x,terrain.mesh_height(x,z,step,float(settings.terrain.size_m)/2.0)+6,z),Vector3(16,12,20),material(Color(0.57,0.42,0.29),0.75))
	for i in range(4):
		mesh_instance(SphereMesh.new(),Vector3(70+i*12,terrain.mesh_height(70+i*12,80,step,float(settings.terrain.size_m)/2.0)+5,80),Vector3(9,9,9),material(Color(0.75,0.7,0.55),0.05+i*0.23,1.0 if i % 2 == 0 else 0.0))
	# Explicit approximation: opaque geometric clouds, not volumetric cloud scattering.
	for i in range(16):
		var cloud := mesh_instance(rock,Vector3(rng.randf_range(-1400,1400),700+rng.randf_range(0,100),rng.randf_range(-1400,1400)),Vector3(160,24,90),material(Color(0.88,0.90,0.94),1.0))
		cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camera = Camera3D.new()
	camera.fov = float(settings.camera.fov_y_deg)
	camera.near = float(settings.camera.near_m)
	camera.far = float(settings.camera.far_m)
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.current = true
	set_camera(0.0)
	print("SCENE_CHECK ", JSON.stringify({"children":get_child_count(),"terrain_triangles":cells*cells*2,"camera_start":str(camera.position)}))

func vector(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func set_camera(seconds: float) -> void:
	var points: Array = settings.camera.positions_m
	var phase := fposmod(seconds / float(settings.camera.duration_s),1.0) * (points.size()-1)
	var index := int(phase)
	camera.position = vector(points[index]).lerp(vector(points[index+1]),phase-index)
	camera.look_at(vector(settings.camera.look_at_m))

func _unhandled_input(event: InputEvent) -> void:
	if options.interactive != "true": return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		manual = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if manual else Input.MOUSE_MODE_VISIBLE
		if manual:
			yaw = camera.rotation.y
			pitch = camera.rotation.x
	if event is InputEventMouseMotion and manual:
		yaw -= event.relative.x * 0.003
		pitch = clampf(pitch-event.relative.y*0.003,-1.5,1.5)
		camera.rotation = Vector3(pitch,yaw,0)

func _process(delta: float) -> void:
	if camera == null: return
	var now := Time.get_ticks_usec()
	var elapsed := (now-started_us)/1000000.0
	var warmup := float(options.warmup)
	sunlight.rotation_degrees.y = float(settings.sun.rotation_degrees[1]) + (0.0 if render_check else maxf(0.0,elapsed-warmup)) * 0.05
	if options.interactive == "true" and manual:
		var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camera.position += camera.basis * movement * delta * 120.0
	else:
		set_camera(0.0 if render_check else maxf(0.0,elapsed-warmup))
	if elapsed >= warmup and previous_us >= started_us + int(warmup*1000000) and elapsed < warmup+float(options.duration):
		if output != null:
			output.store_csv_line([str(recorded),str(elapsed-warmup),str((now-previous_us)/1000.0)])
		recorded += 1
	previous_us = now
	frame_index += 1
	if options.interactive != "true" and ((render_check and frame_index >= 4) or (not render_check and elapsed >= warmup+float(options.duration))):
		if options["render-check"] == "true" and not options.capture.is_empty():
			set_process(false)
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			if image == null or image.save_png(options.capture) != OK:
				fail("Screenshot failed")
				return
		if output != null: output.close()
		if not render_check and recorded < 2:
			fail("Too few frames")
		else:
			print("SKYBOUND_COMPLETE ", JSON.stringify({"smoke":smoke,"render_check":render_check,"frames":recorded,"total_frames":frame_index,"camera_end":str(camera.position)}))
			get_tree().quit()
