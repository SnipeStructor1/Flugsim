extends RefCounted

# Original procedural, unarmed F-22-inspired exterior. Dimensions are approximate.
var root: Node3D
var skin := Color(0.32, 0.36, 0.39)
var edge := Color(0.23, 0.27, 0.30)
var dark := Color(0.10, 0.12, 0.13)

func _init(target: Node3D) -> void:
	root = target

func material(color: Color, metallic := 0.25, roughness := 0.55) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result

func polygon(points: Array[Vector3], color: Color) -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, points.size() - 1):
		var normal := (points[i] - points[0]).cross(points[i + 1] - points[0]).normalized()
		for index in [0, i, i + 1]:
			mesh.set_normal(normal)
			mesh.add_vertex(points[index])
	var node := MeshInstance3D.new()
	node.mesh = mesh.commit()
	node.material_override = material(color)
	root.add_child(node)

func ellipsoid(pos: Vector3, size: Vector3, color: Color, gloss := 0.4) -> void:
	var node := MeshInstance3D.new()
	node.mesh = SphereMesh.new()
	node.position = pos
	node.scale = size
	node.material_override = material(color, 0.35, gloss)
	root.add_child(node)

func build() -> void:
	# Forward is -Z. Station lengths produce an approximately 18.9 m airframe.
	var stations := [
		[-9.45, 0.03, 0.00, 0.00], [-6.8, 0.65, 0.55, -0.45],
		[-3.7, 1.35, 0.85, -0.72], [0.0, 2.05, 0.90, -0.90],
		[4.7, 2.0, 0.75, -0.8], [7.4, 1.85, 0.55, -0.65],
		[9.45, 1.55, 0.25, -0.42],
	]
	for i in range(stations.size() - 1):
		var a: Array = stations[i]
		var b: Array = stations[i + 1]
		var ring_a: Array[Vector3] = [Vector3(-a[1],0,a[0]),Vector3(0,a[2],a[0]),Vector3(a[1],0,a[0]),Vector3(0,a[3],a[0])]
		var ring_b: Array[Vector3] = [Vector3(-b[1],0,b[0]),Vector3(0,b[2],b[0]),Vector3(b[1],0,b[0]),Vector3(0,b[3],b[0])]
		for j in range(4):
			polygon([ring_a[j],ring_a[(j+1)%4],ring_b[(j+1)%4],ring_b[j]], skin if j < 2 else edge)
	for side in [-1.0, 1.0]:
		# Swept trapezoidal wings and all-moving tailplanes, 13.56 m span.
		polygon([Vector3(side*1.1,0.15,-3.9),Vector3(side*6.78,0.0,1.3),Vector3(side*6.78,0.0,2.1),Vector3(side*2.0,0.18,4.4)], skin)
		polygon([Vector3(side*1.4,0.22,5.0),Vector3(side*5.1,0.20,7.45),Vector3(side*4.7,0.20,8.25),Vector3(side*1.7,0.22,7.8)], skin)
		# Distinctive outward-canted twin fins.
		polygon([Vector3(side*1.15,0.55,4.1),Vector3(side*2.20,3.15,6.0),Vector3(side*2.20,3.15,7.4),Vector3(side*1.65,0.55,8.0)], edge)
		# Narrow panel lines and contrasting control surfaces give the silhouette
		# more structure; these remain procedural, not a photo-scanned asset.
		var seam := Color(0.18, 0.21, 0.23)
		polygon([Vector3(side*2.45,0.205,3.42), Vector3(side*6.0,0.065,1.83), Vector3(side*5.9,0.067,1.91), Vector3(side*2.45,0.207,3.50)], seam)
		polygon([Vector3(side*1.8,0.60,7.96), Vector3(side*4.48,0.23,7.95), Vector3(side*4.37,0.23,8.08), Vector3(side*1.8,0.60,8.10)], seam)
		polygon([Vector3(side*0.2,0.57,9.10), Vector3(side*1.52,0.57,9.10), Vector3(side*1.50,0.44,9.45), Vector3(side*0.2,0.44,9.45)], edge)
		# Dark intake and paired rectangular exhausts.
		polygon([Vector3(side*1.30,0.35,-2.0),Vector3(side*2.08,0.10,-0.6),Vector3(side*1.95,-0.62,0.15),Vector3(side*1.25,-0.45,-0.3)], dark)
		polygon([Vector3(side*0.25,0.28,9.46),Vector3(side*1.48,0.28,9.46),Vector3(side*1.48,-0.40,9.46),Vector3(side*0.25,-0.40,9.46)], dark)
	ellipsoid(Vector3(0,0.93,-3.65), Vector3(1.06,0.64,2.30), Color(0.23,0.25,0.20), 0.12)
