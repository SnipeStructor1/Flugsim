extends Node3D

var settings: Dictionary
var options := {"profile": "High", "width": "1920", "height": "1080", "warmup": "30", "duration": "60", "output": "", "smoke": "false", "interactive": "false", "render-check": "false", "capture": "", "terrain-stream": "false", "view": "benchmark", "stream-journey": "false", "view-altitude": "", "stream-async": "false"}
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
var scene_environment: Environment
var render_check := false
var streaming := false
var stream_async := false
var stream_manager: Node3D
var ground_objects: Array[Dictionary] = []
var reference_view: Dictionary = {}
var stream_journey := false
var journey_phase := 0
var journey_complete := false
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
	streaming = options["terrain-stream"] == "true"
	stream_journey = options["stream-journey"] == "true"
	stream_async = options["stream-async"] == "true"
	if stream_async and not streaming:
		fail("Async streaming requires terrain streaming")
		return
	if stream_journey and not (smoke and streaming):
		fail("Stream journey is only available for streaming smoke tests")
		return
	if streaming and not smoke and not render_check and options.interactive != "true":
		fail("Experimental terrain streaming is available only for render checks or interactive use")
		return
	if smoke and render_check:
		fail("Smoke and render-check are separate modes")
		return
	if options.interactive == "true" and (smoke or render_check):
		fail("Interactive mode cannot be combined with smoke or render-check")
		return
	var manifest_path := ProjectSettings.globalize_path("res://../../assets/shared/scene.json")
	settings = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if settings != null and settings.has("seed"):
		terrain = preload("res://terrain_model.gd").new(int(settings.seed))
	if settings.is_empty() or not settings.profiles.has(options.profile):
		fail("Missing scene manifest or unknown profile")
		return
	if not options["view-altitude"].is_empty() and (not streaming or not render_check or options.view == "benchmark" or not options["view-altitude"].is_valid_float() or not is_finite(float(options["view-altitude"]))):
		fail("View altitude requires a finite number, streaming and a reference render check")
		return
	if options.view != "benchmark":
		if not render_check:
			fail("Reference views are only supported for render checks")
			return
		var views_path := ProjectSettings.globalize_path("res://../../assets/shared/visual_views.json")
		var views = JSON.parse_string(FileAccess.get_file_as_string(views_path))
		if not views is Dictionary or not views.has("views") or not views.views.has(options.view):
			fail("Unknown or unavailable reference view")
			return
		reference_view = views.views[options.view]
	if float(options.warmup) < 0.0 or float(options.duration) <= 0.0:
		fail("Invalid timing")
		return
	var resolution := [int(options.width), int(options.height)]
	var supported := false
	for size in settings.resolutions:
		if int(size[0]) == resolution[0] and int(size[1]) == resolution[1]: supported = true
	if render_check and resolution[0] == 960 and resolution[1] == 540:
		supported = true
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
	get_tree().root.content_scale_size = Vector2i(resolution[0], resolution[1])
	get_tree().root.size = Vector2i(resolution[0], resolution[1])
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
		var actual_resolution := get_viewport().get_texture().get_size()
		if actual_resolution != Vector2(resolution[0], resolution[1]):
			fail("Actual render resolution %s does not match requested %s" % [actual_resolution, resolution])
			return
	started_us = Time.get_ticks_usec()
	previous_us = started_us
	set_process(true)
	print("SKYBOUND_READY ", JSON.stringify({"smoke": smoke, "render_check": options["render-check"] == "true", "profile": options.profile, "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info().string, "width": resolution[0], "height": resolution[1], "upscaling": "native", "frame_generation": false, "terrain_stream": streaming, "stream_async": stream_async, "view": options.view}))

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

func ground_instance(mesh: Mesh, position: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var instance := mesh_instance(mesh, position, scale_value, mat)
	if streaming:
		var step := float(settings.terrain.size_m) / int(settings.terrain.grid_cells)
		var half := float(settings.terrain.size_m) / 2.0
		var offset := position.y - terrain.mesh_height(position.x, position.z, step, half)
		ground_objects.append({"node": instance, "offset": offset})
		instance.visible = false
	return instance

func sync_ground_objects() -> void:
	var half := float(settings.terrain.size_m) / 2.0
	for entry in ground_objects:
		var instance: MeshInstance3D = entry.node
		var key := Vector2i(floori((instance.position.x + half) / stream_manager.chunk_size), floori((instance.position.z + half) / stream_manager.chunk_size))
		instance.visible = stream_manager.resident.has(key)
		if instance.visible:
			var lod: int = stream_manager.resident[key]
			var chunk_origin: Vector2 = stream_manager.origin + Vector2(key.x, key.y) * stream_manager.chunk_size
			instance.position.y = stream_manager.builder.sample_height(terrain, chunk_origin, stream_manager.chunk_size, stream_manager.cells, lod, instance.position.x, instance.position.z) + float(entry.offset)

func ground_objects_match_resident_chunks() -> bool:
	var half := float(settings.terrain.size_m) / 2.0
	for entry in ground_objects:
		var instance: MeshInstance3D = entry.node
		var key := Vector2i(floori((instance.position.x + half) / stream_manager.chunk_size), floori((instance.position.z + half) / stream_manager.chunk_size))
		var expected_visible: bool = stream_manager.resident.has(key)
		if instance.visible != expected_visible:
			return false
		if expected_visible:
			var lod: int = stream_manager.resident[key]
			var chunk_origin: Vector2 = stream_manager.origin + Vector2(key.x, key.y) * stream_manager.chunk_size
			var expected_y: float = stream_manager.builder.sample_height(terrain, chunk_origin, stream_manager.chunk_size, stream_manager.cells, lod, instance.position.x, instance.position.z) + float(entry.offset)
			if absf(instance.position.y - expected_y) > 0.001:
				return false
	return true

func stream_lod_counts() -> Array[int]:
	var counts: Array[int] = [0, 0, 0]
	if streaming:
		for lod in stream_manager.resident.values():
			counts[int(lod)] += 1
	return counts

func stream_triangle_count() -> int:
	var vertices := 0
	if streaming:
		for node in stream_manager.nodes.values():
			vertices += node.mesh.surface_get_array_len(0)
	return vertices / 3

func stream_is_settled() -> bool:
	var camera_xz := Vector2(camera.position.x, camera.position.z)
	var plan: Dictionary = stream_manager.planner.plan(camera_xz, stream_manager.origin, stream_manager.chunk_size, stream_manager.grid_width, stream_manager.grid_height, stream_manager.resident, stream_manager.max_resident, 1, camera.position.y, stream_manager.height_bounds)
	return plan.valid and plan.unload.is_empty() and plan.build.is_empty() and not stream_manager.has_pending()

func build_scene(profile: Dictionary) -> void:
	var environment := Environment.new()
	scene_environment = environment
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
	var cells := int(settings.terrain.grid_cells)
	var step := float(settings.terrain.size_m) / cells
	var terrain_material := ShaderMaterial.new()
	terrain_material.shader = load("res://terrain_material.gdshader")
	if not streaming:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for z in range(cells):
			for x in range(cells):
				for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)]:
					var px: float = (x + corner.x - cells / 2.0) * step
					var pz: float = (z + corner.y - cells / 2.0) * step
					var h := terrain_height(px, pz)
					surface.set_normal(terrain.normal(px, pz))
					surface.add_vertex(Vector3(px,h,pz))
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
			ground_instance(rock,Vector3(x,h+2,z),Vector3(8,5,7),stone)
		else:
			var tree := CylinderMesh.new()
			tree.top_radius = 0.0
			tree.bottom_radius = 4.0
			tree.height = 15.0
			ground_instance(tree,Vector3(x,h+7.5,z),Vector3.ONE,grass)
	for i in range(8):
		var x := -180.0 + i * 30
		var z := -120.0
		ground_instance(BoxMesh.new(),Vector3(x,terrain.mesh_height(x,z,step,float(settings.terrain.size_m)/2.0)+6,z),Vector3(16,12,20),material(Color(0.57,0.42,0.29),0.75))
	for i in range(4):
		ground_instance(SphereMesh.new(),Vector3(70+i*12,terrain.mesh_height(70+i*12,80,step,float(settings.terrain.size_m)/2.0)+5,80),Vector3(9,9,9),material(Color(0.75,0.7,0.55),0.05+i*0.23,1.0 if i % 2 == 0 else 0.0))
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
	if streaming:
		stream_manager = load("res://terrain_stream_manager.gd").new()
		stream_manager.model = terrain
		stream_manager.async_enabled = stream_async
		stream_manager.terrain_material = terrain_material
		var ground_bounds: Vector2 = terrain.conservative_bounds()
		# Include 32 m skirts and the tallest 15 m ground object.
		stream_manager.height_bounds = Vector2(ground_bounds.x - stream_manager.skirt_depth, ground_bounds.y + 15.0)
		stream_manager.chunk_size = 256.0
		stream_manager.origin = Vector2(-float(settings.terrain.size_m)/2.0, -float(settings.terrain.size_m)/2.0)
		stream_manager.grid_width = int(float(settings.terrain.size_m) / stream_manager.chunk_size)
		stream_manager.grid_height = stream_manager.grid_width
		stream_manager.max_resident = stream_manager.grid_width * stream_manager.grid_height
		stream_manager.build_budget = 8 if render_check else 2
		stream_manager.planner.policy.load_distance = 3000.0
		add_child(stream_manager)
	print("SCENE_CHECK ", JSON.stringify({"children":get_child_count(),"terrain_triangles":cells*cells*2 if not streaming else null,"camera_start":str(camera.position)}))

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
	if not reference_view.is_empty():
		sunlight.rotation_degrees = vector(reference_view.sun_rotation_deg)
	else:
		sunlight.rotation_degrees.y = float(settings.sun.rotation_degrees[1]) + (0.0 if render_check else maxf(0.0,elapsed-warmup)) * 0.05
	if options.interactive == "true" and manual:
		var movement := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camera.position += camera.basis * movement * delta * 120.0
	elif not reference_view.is_empty():
		camera.position = vector(reference_view.position_m)
		if not options["view-altitude"].is_empty():
			camera.position.y = float(options["view-altitude"])
		camera.look_at(vector(reference_view.look_at_m))
	else:
		set_camera(0.0 if render_check else maxf(0.0,elapsed-warmup))
	if stream_journey:
		if journey_phase == 1:
			camera.position = Vector3(10000, 180, 0)
			camera.look_at(camera.position + Vector3.FORWARD)
		else:
			set_camera(0.0)
			if journey_phase == 2:
				camera.position.y = 1250.0
			elif journey_phase == 3:
				camera.position.y = 10000.0
	if streaming:
		# Experimental camera must be able to see the loaded terrain from above.
		# Use the farthest vertical bound and horizontal residency radius, with
		# margin. The default benchmark's fixed clip distance remains unchanged.
		# A bounded-height haze approximation avoids a constant ground-level fog
		# density across the whole viewing ray at flight altitude. This is not a
		# physically complete atmosphere; ground-level baseline remains unchanged.
		scene_environment.fog_density = 0.00035 / (1.0 + maxf(0.0, camera.position.y - 2000.0) / 1000.0)
		var vertical: float = maxf(absf(camera.position.y - stream_manager.height_bounds.x), absf(camera.position.y - stream_manager.height_bounds.y))
		var radius: float = stream_manager.planner.policy.load_distance
		camera.far = maxf(float(settings.camera.far_m), sqrt(vertical * vertical + radius * radius) + 100.0)
		var update: Dictionary = stream_manager.tick(Vector2(camera.position.x, camera.position.z), camera.position.y)
		if not update.valid or update.failed > 0:
			fail("Terrain streaming update failed")
			return
		if update.built > 0 or update.unloaded > 0:
			sync_ground_objects()
		if stream_journey and stream_is_settled():
			var expected_chunks: int = 0 if journey_phase == 1 else stream_manager.grid_width * stream_manager.grid_height
			if stream_manager.resident.size() != expected_chunks or not ground_objects_match_resident_chunks():
				fail("Stream journey chunk/object state mismatch at phase %d" % journey_phase)
				return
			var lods := stream_lod_counts()
			if (journey_phase == 2 and (lods[0] != 0 or lods[1] == 0)) or (journey_phase == 3 and (lods[2] != expected_chunks or camera.far <= camera.position.y - stream_manager.height_bounds.x or scene_environment.fog_density >= 0.0001)) or (journey_phase == 4 and lods[0] == 0):
				fail("Stream journey altitude LOD state mismatch")
				return
			print("STREAM_JOURNEY_PHASE ", journey_phase, " chunks=", expected_chunks, " objects=", ground_objects.size(), " lods=", lods)
			journey_phase += 1
			journey_complete = journey_phase == 5
	if stream_journey and not journey_complete and elapsed >= float(options.duration):
		fail("Stream journey did not complete within the smoke-test limit")
		return
	if elapsed >= warmup and previous_us >= started_us + int(warmup*1000000) and elapsed < warmup+float(options.duration):
		if output != null:
			output.store_csv_line([str(recorded),str(elapsed-warmup),str((now-previous_us)/1000.0)])
		recorded += 1
	previous_us = now
	frame_index += 1
	if options.interactive != "true" and ((stream_journey and journey_complete) or (not stream_journey and ((render_check and frame_index >= 4 and (not streaming or stream_is_settled())) or (not render_check and elapsed >= warmup+float(options.duration))))):
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
			if stream_journey:
				print("STREAM_JOURNEY_PASS phases=5")
			print("SKYBOUND_COMPLETE ", JSON.stringify({"smoke":smoke,"render_check":render_check,"frames":recorded,"total_frames":frame_index,"camera_end":str(camera.position), "terrain_stream":streaming, "stream_async":stream_async, "resident_chunks":stream_manager.resident.size() if streaming else 0, "stream_settled":stream_is_settled() if streaming else false, "lod_counts":stream_lod_counts(), "terrain_triangles":stream_triangle_count() if streaming else int(settings.terrain.grid_cells)*int(settings.terrain.grid_cells)*2, "camera_far_m":camera.far, "fog_density":scene_environment.fog_density}))
			get_tree().quit()
