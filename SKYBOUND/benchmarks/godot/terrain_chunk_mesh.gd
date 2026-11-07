extends RefCounted

# Generate a world-space chunk from the same height source as the original mesh.
# Neighboring LODs share coarse-grid samples. Skirts are a first-line crack
# mitigation; they do not prove seam-free transitions on steep slopes.
func build(model: RefCounted, origin: Vector2, size_m: float, cells: int, lod: int, skirt_depth: float) -> ArrayMesh:
	if size_m <= 0.0 or cells < 4 or cells % 4 != 0 or lod < 0 or lod > 2 or skirt_depth <= 0.0:
		return null
	var stride := 1 << lod
	if cells % stride != 0:
		return null
	var count := cells / stride
	var spacing := size_m / count
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(count):
		for x in range(count):
			for corner in [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,0), Vector2(1,1), Vector2(0,1)]:
				var px: float = origin.x + (x + corner.x) * spacing
				var pz: float = origin.y + (z + corner.y) * spacing
				surface.set_normal(model.normal(px, pz))
				surface.add_vertex(Vector3(px, _vertex_height(model, origin, size_m, cells, px, pz), pz))
	# Four skirts extend downward at chunk boundaries; unneeded internal skirts can
	# be culled after neighbor-aware stitching is implemented and verified.
	for edge in range(4):
		for i in range(count):
			var a := _edge_point(origin, size_m, edge, float(i) / count)
			var b := _edge_point(origin, size_m, edge, float(i + 1) / count)
			var top_a := Vector3(a.x, _vertex_height(model, origin, size_m, cells, a.x, a.y), a.y)
			var top_b := Vector3(b.x, _vertex_height(model, origin, size_m, cells, b.x, b.y), b.y)
			var down_a := top_a - Vector3.UP * skirt_depth
			var down_b := top_b - Vector3.UP * skirt_depth
			var outward := Vector3(0, 0, -1) if edge == 0 else (Vector3(1, 0, 0) if edge == 1 else (Vector3(0, 0, 1) if edge == 2 else Vector3(-1, 0, 0)))
			for vertex in [top_a, top_b, down_a, top_b, down_b, down_a, down_a, top_b, top_a, down_a, down_b, top_b]:
				surface.set_normal(outward)
				surface.add_vertex(vertex)
	return surface.commit()

func _edge_point(origin: Vector2, size_m: float, edge: int, fraction: float) -> Vector2:
	match edge:
		0: return origin + Vector2(fraction * size_m, 0)
		1: return origin + Vector2(size_m, fraction * size_m)
		2: return origin + Vector2((1.0 - fraction) * size_m, size_m)
		_: return origin + Vector2(0, (1.0 - fraction) * size_m)

# All four edges use the same LOD-2 polyline for every LOD. Intermediate edge
# vertices are interpolated, so two independently generated neighboring chunks
# meet even when one is finer. World-grid alignment makes the shared endpoints
# independent of generation order.
func _vertex_height(model: RefCounted, origin: Vector2, size_m: float, cells: int, x: float, z: float) -> float:
	var coarse_step := size_m / (cells >> 2)
	var on_x_edge := is_equal_approx(x, origin.x) or is_equal_approx(x, origin.x + size_m)
	var on_z_edge := is_equal_approx(z, origin.y) or is_equal_approx(z, origin.y + size_m)
	if on_x_edge:
		var along := clampf((z - origin.y) / coarse_step, 0.0, float(cells >> 2))
		var base := minf(floorf(along), float((cells >> 2) - 1))
		return lerpf(model.height(x, origin.y + base * coarse_step), model.height(x, origin.y + (base + 1.0) * coarse_step), along - base)
	if on_z_edge:
		var along := clampf((x - origin.x) / coarse_step, 0.0, float(cells >> 2))
		var base := minf(floorf(along), float((cells >> 2) - 1))
		return lerpf(model.height(origin.x + base * coarse_step, z), model.height(origin.x + (base + 1.0) * coarse_step, z), along - base)
	return model.height(x, z)

# Interpolate exactly the stitched render triangles for ground-object placement.
func sample_height(model: RefCounted, origin: Vector2, size_m: float, cells: int, lod: int, x: float, z: float) -> float:
	var count := cells >> lod
	var spacing := size_m / count
	var gx := clampf((x - origin.x) / spacing, 0.0, float(count))
	var gz := clampf((z - origin.y) / spacing, 0.0, float(count))
	var ix := mini(floori(gx), count - 1)
	var iz := mini(floori(gz), count - 1)
	var fx := gx - ix
	var fz := gz - iz
	var x0 := origin.x + ix * spacing
	var z0 := origin.y + iz * spacing
	var h00 := _vertex_height(model, origin, size_m, cells, x0, z0)
	var h10 := _vertex_height(model, origin, size_m, cells, x0 + spacing, z0)
	var h01 := _vertex_height(model, origin, size_m, cells, x0, z0 + spacing)
	if fx + fz <= 1.0:
		return h00 * (1.0 - fx - fz) + h10 * fx + h01 * fz
	var h11 := _vertex_height(model, origin, size_m, cells, x0 + spacing, z0 + spacing)
	return h10 * (1.0 - fz) + h01 * (1.0 - fx) + h11 * (fx + fz - 1.0)
