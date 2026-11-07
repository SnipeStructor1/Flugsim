extends RefCounted

# Generate a world-space chunk from the same height source as the original mesh.
# Neighboring LODs share coarse-grid samples. Skirts are a first-line crack
# mitigation; they do not prove seam-free transitions on steep slopes.
func build(model: RefCounted, origin: Vector2, size_m: float, cells: int, lod: int, skirt_depth: float) -> ArrayMesh:
	if size_m <= 0.0 or cells <= 0 or lod < 0 or lod > 2 or skirt_depth <= 0.0:
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
				surface.add_vertex(Vector3(px, model.height(px, pz), pz))
	# Four skirts extend downward at chunk boundaries; unneeded internal skirts can
	# be culled after neighbor-aware stitching is implemented and verified.
	for edge in range(4):
		for i in range(count):
			var a := _edge_point(origin, size_m, edge, float(i) / count)
			var b := _edge_point(origin, size_m, edge, float(i + 1) / count)
			var top_a := Vector3(a.x, model.height(a.x, a.y), a.y)
			var top_b := Vector3(b.x, model.height(b.x, b.y), b.y)
			var down_a := top_a - Vector3.UP * skirt_depth
			var down_b := top_b - Vector3.UP * skirt_depth
			var outward := Vector3(0, 0, -1) if edge == 0 else (Vector3(1, 0, 0) if edge == 1 else (Vector3(0, 0, 1) if edge == 2 else Vector3(-1, 0, 0)))
			for vertex in [top_a, top_b, down_a, top_b, down_b, down_a]:
				surface.set_normal(outward)
				surface.add_vertex(vertex)
	return surface.commit()

func _edge_point(origin: Vector2, size_m: float, edge: int, fraction: float) -> Vector2:
	match edge:
		0: return origin + Vector2(fraction * size_m, 0)
		1: return origin + Vector2(size_m, fraction * size_m)
		2: return origin + Vector2((1.0 - fraction) * size_m, size_m)
		_: return origin + Vector2(0, (1.0 - fraction) * size_m)
