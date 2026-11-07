"""Convert Ricardo Sanchez's CC-BY tree source (see assets/licenses) to GLB.

Usage: blender -b --python tools/vegetation/build_tree.py -- /path/to/tree/scene.gltf
The source glTF, binary and textures must be present together.
"""
import bpy
import sys
from pathlib import Path
from mathutils import Matrix

source = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
if not meshes:
    raise RuntimeError('Source tree has no meshes')
# Bake inherited transforms and normalize the original model to 15 m height.
for obj in meshes:
    transform = obj.matrix_world.copy()
    for vertex in obj.data.vertices:
        vertex.co = (transform @ vertex.co) * (15.0 / 2470.546)
    obj.parent = None
    obj.matrix_world = Matrix.Identity(4)
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes: obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
meshes[0].name = 'CCBY_Tree'
# Remove the empty hierarchy to keep just one mesh for MultiMesh instancing.
for obj in list(bpy.context.scene.objects):
    if obj.type != 'MESH': bpy.data.objects.remove(obj, do_unlink=True)
out = Path(__file__).resolve().parents[2] / 'benchmarks/godot/flight/assets/vegetation/tree.glb'
bpy.ops.export_scene.gltf(filepath=str(out), export_format='GLB', export_yup=True, export_apply=True)
print('GENERATED', out)
